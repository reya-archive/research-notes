# Open WebUI + Bedrock 번들 (openwebui-hosting)

MCNC SI RAG 리서치([`../index.html`](../index.html))의 후속 작업으로, **RAG · 임베딩을 자유롭게 실험할 수 있는 독립된 Open WebUI 인스턴스**를 Amazon Bedrock 위에 올리는 번들입니다. 기존에 운영 중인 `mcnc-llm-webui` (포트 3000) 는 건드리지 않고, 이 스택은 별도 컨테이너 · 볼륨 · 포트로 격리되어 병행 운영됩니다.

내부적으로 LiteLLM Proxy 를 끼워 Bedrock → OpenAI 호환 API 변환을 수행하지만, 사용자는 이를 의식할 필요 없이 Open WebUI 만 보면 됩니다.

## 이 번들이 하는 일

```
[사용자 브라우저]
   │
   ▼  http://<VM>:13000
[Open WebUI (openwebui-hosting-webui)]
   │  내부 DNS: tika:9998 (콘텐츠 추출)
   │  내부 DNS: litellm:4000 (LLM · 임베딩)
   │
   ├──────────────────────────┐
   ▼                          ▼
[Apache Tika                 [LiteLLM Proxy
 (openwebui-hosting-tika)]    (openwebui-hosting-litellm)]
                                │  AWS SigV4
                                ▼
                             [Amazon Bedrock · ap-northeast-1]
                                · Claude Sonnet 4.6             (메인, 쿼터 증액 후)
                                · Claude Haiku 4.5              (프로토타입 Claude, Sonnet 쿼터 막힐 때 대체)
                                · Amazon Nova Lite              (비-Claude 대안, Marketplace 이슈 없음)
                                · Titan Embeddings v2           (Knowledge 임베딩 프리셋)
                                · Inference Profile: global.(Claude) / apac.(Nova) - 시연 기본
                                · (선택) Claude Sonnet 4.5 / Nova Pro - litellm_config.yaml 주석 해제로 추가
```

- **Open WebUI** : 브라우저 UI · 사용자/대화 관리 · Knowledge (RAG) · 내장 ChromaDB
- **Tika** : 업로드 문서의 콘텐츠 추출 (docx/xlsx/pptx/pdf 범용 파서). 내장 PyPDF 대비 표 · 한국어 SI 문서 품질 개선
- **LiteLLM** : OpenAI 호환 API ↔ Bedrock InvokeModel 변환, 모델 별칭, 파라미터 정규화
- **Bedrock** : LLM 추론 + 임베딩. 도쿄 리전, 학습 미사용 약관

## 빠른 시작 (10분 내외)

```bash
# 1. 이 폴더를 VM 으로 가져간 뒤
cd openwebui-hosting

# 2. 환경변수 템플릿을 .env 로 복사 후 편집
cp .env.example .env
vi .env          # AWS 키 + LITELLM_MASTER_KEY + WEBUI_SECRET_KEY

# 3. 한 방에 기동
chmod +x setup.sh
./setup.sh
```

스크립트가 이미지 pull, 두 컨테이너 기동, 헬스 체크, 접근 URL 출력까지 자동 수행.

이후 브라우저로 접속해 최초 관리자 계정을 만들면 끝. 상세 절차 → [03-post-install.md](./docs/03-post-install.md).

## 기본 포트

기존 서버의 사용 중인 포트 (80/443/3000/4000/5003/7000-7080/15432) 와 겹치지 않도록 기본값을 아래와 같이 잡았습니다. `.env` 에서 조정 가능.

| 서비스 | 호스트 포트 | 컨테이너 내부 |
|---|---|---|
| Open WebUI | **13000** | 8080 |
| LiteLLM Proxy | **14000** | 4000 |
| Tika | (공개 안 함) | 9998 |

외부 클라이언트(SDK · 다른 서비스) 가 LiteLLM 을 직접 쓰고 싶으면 `http://<VM>:14000/v1` + `${LITELLM_MASTER_KEY}` 로 호출. Tika 는 Open WebUI 전용이라 호스트로 공개하지 않고 내부 네트워크에서만 호출됩니다.

## 문서 가이드

| 문서 | 언제 |
|---|---|
| [01-prerequisites.md](./docs/01-prerequisites.md)  | 시작 전 VM / AWS / IAM / Bedrock 모델 액세스 체크리스트 |
| [02-install.md](./docs/02-install.md)              | 설치 상세 (빠른 시작의 풀버전) |
| [03-post-install.md](./docs/03-post-install.md)    | 최초 관리자 계정 · RAG Knowledge 테스트 · 외부 클라이언트 연결 |
| [04-admin-settings.md](./docs/04-admin-settings.md) | Admin Panel 에서 수동으로 맞춰야 할 항목 체크리스트 |
| [05-openwebui-rag-tuning.md](./docs/05-openwebui-rag-tuning.md) | RAG 22개 옵션을 MCNC 문서 (모바일 하이브리드 앱 SI/SM) 기준으로 튜닝 |
| [06-troubleshooting.md](./docs/06-troubleshooting.md) | 시연 중 막혔을 때 |

## 파일 구조

```
openwebui-hosting/
├── README.md                  ← 지금 이 파일
├── setup.sh                   ← 원샷 부트스트랩
├── .env.example               ← 환경변수 템플릿 (.env 로 복사해서 사용)
├── docker-compose.yml         ← LiteLLM + Tika + Open WebUI 3개 서비스
├── litellm_config.yaml        ← 모델 매핑 (Bedrock Claude + Titan)
└── docs/                      ← 단계별 세부 가이드
```

## 업데이트 / 재적용

`.env`, `docker-compose.yml`, `litellm_config.yaml` 중 무엇을 바꿨든, 혹은 이미지를 올리든 **아래 한 번의 흐름으로 전부 처리**됩니다.

1. 로컬에서 파일 수정
2. 파일질라(SFTP) 등으로 VM 의 `openwebui-hosting/` 아래 해당 파일을 덮어쓰기
3. VM 에서 아래 두 줄 실행

```bash
cd /path/to/openwebui-hosting
docker compose pull                         # 최신 이미지 내려받기
docker compose up -d --force-recreate       # 전체 재생성 + 변경 반영
```

볼륨 `openwebui-hosting-data` (대화 · 사용자 · 내장 ChromaDB) 는 위 명령에서 **보존**됩니다. 완전 초기화가 필요할 때만 `docker compose down -v` (복구 불가).

> ⚠ `.env` 는 `.gitignore` 에 들어 있고 VM 에만 있는 시크릿 파일입니다. 로컬에서 수정해 덮어쓸 때 **VM 의 실제 AWS 키 · MASTER_KEY · SECRET_KEY 를 지우지 않도록** 주의. 값 자체를 바꿀 게 아니면 `.env` 는 SFTP 전송에서 빼두세요.

자세한 파일별 변경 포인트는 [docs/02-install.md](./docs/02-install.md#6-설정-변경-시-반영-절차) 참고.

## 설계 원칙

1. **기존 서비스 불가침** - compose 프로젝트명 `openwebui-hosting`, 컨테이너명 `openwebui-hosting-*`, 볼륨 `openwebui-hosting-data` 로 기존 `mcnc-llm-webui` · `docker-*` (Dify) 와 완전 격리.
2. **공식 이미지만 사용, fork 하지 않는다** - Open WebUI · LiteLLM · Tika 전부 공식 이미지 (`main-stable` / `main` / `latest-full`). 업그레이드는 `docker compose pull && docker compose up -d`.
3. **시크릿은 `.env` 한 곳**에만. `.gitignore` 에 `.env` 포함. 코드에 키를 박지 않음.
4. **모델 ID 는 config 파일 한 곳** - 사용자에게는 `claude-sonnet-4-6` 같은 짧은 이름으로 노출, Bedrock Inference Profile ID 는 `litellm_config.yaml` 에서만 관리.

## 번들이 다루지 않는 것

- HTTPS / 리버스 프록시 (운영 투입 시 Caddy · nginx 추가 권장)
- LiteLLM 사용량 추적 · 과금 (Postgres · Langfuse · Prometheus)
- 멀티 프로바이더 (OpenAI 직접 · Anthropic 직접 · Ollama — 필요 시 `litellm_config.yaml` 에 model 섹션 추가)
- Open WebUI SSO / LDAP (내부 자체 인증만)
- 백업 · 모니터링 · 알람 · 고가용성

## 비용 힌트

- 이 스택 자체는 **모두 오픈소스 / 무료**. LiteLLM Apache-2.0, Open WebUI BSD-3-Clause, Apache Tika Apache-2.0.
- AWS 과금은 Bedrock LLM · Embedding 호출분 + (선택) VPC Endpoint 만. 리서치 페이지의 "LLM 토큰 사용 비용" 표 기준 산정.
- VM 은 2 vCPU / 4 GB RAM 이 최소, **4 GB 이상 권장** (Open WebUI + ChromaDB + Tika JVM heap 포함). Tika JVM 은 기본 `-Xmx1g`, 큰 PDF 배치 처리 시 `-Xmx2g` 로 상향 가능 (`docker-compose.yml` 의 `JAVA_OPTS`).

## 참고

- LiteLLM: <https://github.com/BerriAI/litellm>, <https://docs.litellm.ai/>
- Open WebUI: <https://github.com/open-webui/open-webui>, <https://docs.openwebui.com/>
- Apache Tika: <https://tika.apache.org/>, <https://hub.docker.com/r/apache/tika>
- Bedrock: <https://aws.amazon.com/bedrock/pricing/>
- 상위 리서치: [../index.html](../index.html)
- 자매 번들 (Dify + Bedrock 풀스택): [../oss-hosting/README.md](../oss-hosting/README.md)
