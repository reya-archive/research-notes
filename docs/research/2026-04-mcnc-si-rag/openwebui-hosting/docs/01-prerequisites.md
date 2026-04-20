# 01. 사전 준비

설치 전 확인해야 할 VM · AWS · 네트워크 체크리스트.

## VM

| 항목 | 최소 | 권장 |
|---|---|---|
| vCPU | 2 | 2 ~ 4 |
| RAM | 2 GB | 4 GB |
| 디스크 | 10 GB | 20 GB |
| OS | Ubuntu 22.04 / Rocky Linux 9 등 최신 리눅스 | Ubuntu 24.04 |

Open WebUI 가 내장 ChromaDB (RAG 벡터 저장) 를 쓰기 때문에 단순 프록시보다 메모리 · 디스크 여유가 조금 더 필요합니다. 대용량 Knowledge 업로드를 반복하면 디스크가 주요 제약이 되므로 여유 있게.

LLM 추론은 전부 Bedrock 에서 수행되므로 GPU 불필요.

### 설치 소프트웨어

- Docker Engine 24+ (또는 Docker Desktop)
- docker compose v2 (`docker compose version` 으로 확인)
- `curl` (헬스 체크 · 테스트에 사용)
- `git` (번들을 VM 으로 내려받을 때)

Ubuntu 기준:

```bash
# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER    # 재로그인 후 적용
# 기타
sudo apt-get install -y curl git
```

## AWS 측 체크리스트

### 1. Bedrock Model access

도쿄 리전(`ap-northeast-1`)에서 아래 모델들이 **Access granted** 상태여야 합니다.

AWS 콘솔 → Bedrock → **Model access** → 필요 모델 선택 → **Request model access**.

| 모델 | 용도 | `litellm_config.yaml` 기본 상태 |
|---|---|---|
| Anthropic · Claude Sonnet 4.6 | 메인 LLM (쿼터 증액 후) | **활성** |
| Anthropic · Claude Haiku 4.5 | 프로토타입 테스트용 Claude | **활성** |
| Amazon · Nova Lite | 비-Claude 비교용 대안 | **활성** |
| Amazon · Titan Embeddings v2 | 임베딩 (Knowledge 프리셋) | **활성** |
| Anthropic · Claude Sonnet 4.5 | Sonnet 백업 (4.6 미가용 시) | 주석 (필요 시 해제) |
| Amazon · Nova Pro | Nova Lite 보다 고품질 비교 | 주석 (필요 시 해제) |

**주의 - Claude 와 Nova 는 Model access 요청 경로가 다릅니다**:

- **Anthropic 계열 (Claude)** : AWS Marketplace 를 경유한 구독 확인이 필요. IAM 정책에 `aws-marketplace:ViewSubscriptions` · `aws-marketplace:Subscribe` 액션 필요 (2 번 섹션 참조)
- **Amazon 네이티브 (Nova · Titan)** : Marketplace 없음. `bedrock:InvokeModel` 권한만 있으면 됨. Nova 는 Request access 도 보통 **즉시 승인**

Sonnet 4.6 은 신규 계정 기본 일일 토큰 쿼터가 거의 0 수준이라 **실제 테스트는 Haiku 4.5 또는 Nova Lite 로 시작하고**, Sonnet 은 Service Quotas 에서 증액 승인 뒤에 전환하는 흐름을 권장합니다.

Anthropic 계열은 승인이 수 시간 걸리는 경우도 있음. Nova · Titan 은 보통 즉시.

### 2. IAM 권한

LiteLLM 에 꽂을 Access Key 에 최소 권한을 붙입니다.

**최소 정책 JSON**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BedrockInvoke",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": [
        "arn:aws:bedrock:*::foundation-model/*",
        "arn:aws:bedrock:*:*:inference-profile/*"
      ]
    },
    {
      "Sid": "BedrockMarketplaceForAnthropic",
      "Effect": "Allow",
      "Action": [
        "aws-marketplace:ViewSubscriptions",
        "aws-marketplace:Subscribe",
        "aws-marketplace:Unsubscribe"
      ],
      "Resource": "*"
    }
  ]
}
```

- `foundation-model/*` 은 Titan 같은 raw model ID 호출용
- `inference-profile/*` 은 `global.anthropic.claude-*` · `apac.amazon.nova-*` 호출용 — 둘 다 필요
- Resource 에 `*` (전 리전) 을 허용하는 이유: `global.` · `apac.` 같은 크로스 리전 프로필은 여러 리전을 경유하므로 단일 리전으로 제한하면 런타임 거부
- `aws-marketplace:*` 블록은 **Anthropic Claude 에만 필요** (Amazon Nova · Titan 은 Marketplace 구독 없이 직접 호출)

### 3. Inference Profile 개념 (중요)

Claude 4.x 계열은 raw model ID 로 직접 호출이 막혀 있고 반드시 **Inference Profile** 을 경유해야 합니다. Profile prefix 에 따라 데이터가 흐르는 리전과 쿼터 풀이 달라집니다.

| prefix | 데이터 상주 | 일일 토큰 쿼터 | 권장 용도 |
|---|---|---|---|
| `jp.`     | 도쿄 내 고정 | 가장 타이트 | 데이터 주권 필수 운영 |
| `apac.`   | APAC 여러 리전 | 중간 | 아시아 내 허용되는 운영 |
| `global.` | 여러 대륙 (미국 포함) | 가장 여유 | **시연 · 검증** 또는 리전 제약 없는 운영 |

### 현재 번들 기본값 - `global.`

이 번들은 현재 **`global.` 프로필로 설정되어 있습니다.** 사유: 신규 계정 · 시연 단계에서 `jp.` 쿼터가 쉽게 막혀 `RateLimitError: Too many tokens per day` 로 호출이 실패하기 때문. 쿼터 때문에 실험 흐름이 자주 끊기는 것을 피하려고 가장 여유로운 풀을 기본값으로 잡았습니다.

### ⚠ 운영 전환 체크리스트

실제 사용자에게 오픈하는 시점에는 **데이터 주권 요건을 다시 평가**하고 아래 중 하나로 전환하세요.

1. Bedrock **Service Quotas** 콘솔에서 `jp.` (또는 `apac.`) 의 일일 토큰 쿼터를 실제 사용량 대비 충분히 증액 신청
2. `litellm_config.yaml` 의 model 라인에서 `bedrock/global.*` → `bedrock/jp.*` 혹은 `bedrock/apac.*` 로 일괄 교체 (주석 블록도 동일하게)
3. 상위 리서치 페이지 `data-policy` 섹션 재점검 및 상급자 공지 문구 업데이트
4. `docker compose restart litellm` 으로 반영

증액 신청 없이 `jp.` 로 되돌리면 실서비스 중 `Too many tokens per day` 가 재발할 수 있으므로 1번을 꼭 선행해야 합니다.

## 네트워크

### Outbound (VM → 외부, 443)

- `bedrock-runtime.ap-northeast-1.amazonaws.com`
- `ghcr.io` · `pkg-containers.githubusercontent.com` (최초 이미지 pull 시만)

방화벽 / 보안그룹에서 차단된 상태면 setup.sh 가 `i/o timeout` 으로 실패합니다.

### Inbound (사용자 브라우저 · 외부 클라이언트 → VM)

| 포트 | 용도 | 공개 범위 |
|---|---|---|
| **13000** | Open WebUI | 사내 IP 대역만 허용 권장 |
| **14000** | LiteLLM (외부 클라이언트용, 선택) | 꼭 필요한 서버 IP 에만 허용 |

인터넷 전역에 열지 마세요 - Open WebUI 기본 세션 키 만료 · `LITELLM_MASTER_KEY` brute force 만으로는 공격을 전부 막지 못합니다. 운영 투입 시 Caddy · nginx 리버스 프록시 + HTTPS 추가 권장.

### 기존 서비스와의 포트 충돌 확인

이 서버는 2026-04 현재 아래 포트를 이미 점유하고 있습니다. 새 번들은 이 표와 겹치지 않게 13000 / 14000 으로 기본값이 잡혀 있습니다.

| 포트 | 기존 점유자 |
|---|---|
| 80 / 443 | `docker-nginx-1` (Dify 앞단) |
| 3000 | `mcnc-llm-webui` (기존 Open WebUI v0.8.12) |
| 4000 | `gitlab` |
| 5003 | `docker-plugin_daemon-1` (Dify) |
| 7000 / 7010 / 7020 / 7080 | `mcnc-rag-*` |
| 15432 | `mcnc-rag-postgre` (pgvector) |

새 포트를 쓰고 싶으면 `.env` 의 `LITELLM_PORT` · `OPENWEBUI_PORT` 만 바꾸면 됩니다.

## 다음 단계

체크리스트가 전부 통과하면 → [02-install.md](./02-install.md)
