# 01. 선결 조건 (VM · AWS 준비)

`setup.sh` 를 실행하기 전에 이 장의 체크리스트를 모두 통과해야 합니다.

## 1) VM 사양

리서치 페이지에서 권장한 최소 스펙이며, Dify 공식 권장치보다 약간 넉넉합니다.

| 항목 | 최소 | 권장 |
|---|---|---|
| CPU | 4 vCPU | 8 vCPU |
| RAM | 8 GB | 16 GB |
| Disk | 50 GB | 100 GB (gp3) |
| OS  | Ubuntu 22.04 LTS 또는 Amazon Linux 2023 | 〃 |
| 도커 | Docker 24+ · Docker Compose v2 | 〃 |

Docker 미설치 시 공식 스크립트로 한 번에 설치:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# 다시 로그인 후
docker compose version
```

## 2) 방화벽 / 보안 그룹 인바운드

| 포트 | 용도 | 공개 범위 |
|---|---|---|
| 22   | SSH        | 운영 IP 만 |
| 80   | Dify 웹    | 시연 대상 |

443(HTTPS) 은 이 프로토타입에서 사용하지 않습니다 (사용자 합의).

## 3) Bedrock 모델 활성화 (도쿄 리전)

AWS Console → Bedrock → `ap-northeast-1` 으로 리전 전환.

2025년 중반부터 Bedrock 콘솔이 바뀌어 기존 "Model access" 요청 페이지의 UX 가 크게 간소화됐습니다. 계정·리전 상태에 따라 다음 중 하나가 보입니다.

- **이미 활성화됨** : 모델이 바로 호출 가능. 추가 조치 불필요
- **Enable model 토글** : "Foundation models" 화면에서 한 번 토글하면 즉시 활성
- **Request access 필요** : 일부 모델(특히 신규 출시 직후) 은 여전히 요청·승인 흐름 유지

필요한 모델:

- **Anthropic Claude Sonnet 계열** (추론용). Anthropic 사 약관 동의 페이지가 한 번 뜰 수 있음
- **Amazon Titan Embeddings v2** (임베딩용, 필수)

> **Claude 4.x 는 Inference Profile 로만 호출 가능**
> 2025 년부터 Claude 4.x 계열은 직접 model ID 로 on-demand 호출이 차단됐습니다. Dify 에 등록할 때도 `jp.anthropic.claude-sonnet-4-6` 같은 inference profile ID 를 써야 합니다. 데이터 주권 고려 시 `jp.` prefix 권장 (docs/03-post-install.md 3) 항목에 상세).

### 활성화 상태 확인 (CLI 로 명확히)

콘솔 UX 가 계속 바뀌는 중이므로, **실제 호출이 되는지**로 판단하는 게 제일 확실합니다. IAM 키 또는 아래 4) 의 Bedrock API Key 를 발급한 뒤:

```bash
aws bedrock list-foundation-models \
  --region ap-northeast-1 \
  --query "modelSummaries[?contains(modelId,'claude') || contains(modelId,'titan-embed')].[modelId,modelLifecycle.status]" \
  --output table
```

그리고 간단한 실제 호출 테스트:

```bash
aws bedrock-runtime invoke-model \
  --region ap-northeast-1 \
  --model-id amazon.titan-embed-text-v2:0 \
  --body '{"inputText":"hello"}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/out.json && echo OK
```

`AccessDeniedException: You don't have access to the model` 가 뜨면 해당 모델만 콘솔에서 Enable/Request 진행.

## 4) 인증 방식 (둘 중 택1)

Dify 의 Bedrock 프로바이더는 두 가지 인증을 모두 받습니다. 프로토타입에선 **A) 전통적인 IAM Access Key** 방식이 가장 호환성이 좋습니다.

### A) IAM 사용자 + Access Key (권장, 호환성 최상)

콘솔 IAM → 새 사용자 → "Access key - Programmatic access" 발급 → 아래 인라인 정책 부여:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BedrockPrototype",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels",
        "bedrock:GetFoundationModel"
      ],
      "Resource": "*"
    }
  ]
}
```

Access Key ID / Secret Access Key 를 `.env` 의 `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` 에 기입.

### B) Bedrock API Key (신규, 더 간단함)

2025년부터 Bedrock 콘솔에서 **Bedrock API Keys** 메뉴가 제공됩니다. IAM 사용자 생성 없이 단일 키로 호출 가능.

- 콘솔 → Bedrock → **API Keys** (또는 좌측 메뉴의 "API keys") → Create
- Long-term / Short-term 선택. 프로토타입엔 Long-term 권장
- 발급된 `bedrock-api-key-...` 문자열 복사

Dify UI 의 Bedrock Provider 설정 화면에 **"Bedrock API Key"** 필드가 있다면 거기에 붙여넣기 (AKID/SAK 필드는 비워둠). 버전에 따라 이 필드가 없을 수도 있는데, 그런 경우엔 A) 방식을 그대로 씁니다.

> 어느 방식을 쓰든 3) 의 모델 활성화는 동일하게 필요합니다.

## 5) 네트워크 (Bedrock 호출 가능 여부)

VM 에서 다음 curl 이 HTTP 200 또는 401 을 반환해야 합니다 (403/연결 타임아웃은 네트워크 문제).

```bash
curl -I https://bedrock.ap-northeast-1.amazonaws.com
```

Private Subnet 에 둔 VM 이라면 Bedrock VPC Endpoint 를 만들거나 NAT Gateway 경유를 확인하세요.

## 6) 디스크 공간

Dify 이미지 약 3 GB + 이미지 캐시 감안 최소 8 GB 여유를 두세요. `df -h /var/lib/docker` 로 확인 가능.

---

준비 완료되면 [02-install.md](./02-install.md) 로 진행.
