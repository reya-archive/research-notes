# 05. 트러블슈팅

시연 중 자주 막히는 지점 모음. **원인 → 조치** 순서로.

## LiteLLM · Bedrock 경로

### `AccessDeniedException: You don't have access to the model`

원인 A) Bedrock Model access 미승인
- AWS 콘솔 → Bedrock → Model access → 해당 모델이 **Access granted** 인지 확인
- Claude Sonnet 4.6 의 경우 `Anthropic` vendor 전체 액세스를 요청해야 함

원인 B) IAM 권한 부족
- Access Key 의 정책에 `bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream` 이 포함되어 있는지 확인
- Resource 에 `inference-profile/*` 가 없으면 Claude 호출만 실패함 ([01-prerequisites.md](./01-prerequisites.md#2-iam-권한) 참고)

### `ValidationException: Invocation of model ID ... isn't supported`

원인 : Claude 4.x 를 raw model ID 로 부르고 있음. `litellm_config.yaml` 에서 `bedrock/anthropic.claude-*` 가 아니라 `bedrock/global.anthropic.claude-*` (inference profile) 형식인지 확인. prefix 는 `jp.` · `apac.` · `global.` 중 하나여야 함.

```bash
grep -n 'bedrock/' litellm_config.yaml
```

### `ResourceNotFoundException: Could not resolve the foundation model`

원인 : `aws_region_name` 과 Inference Profile prefix 가 불일치. 예) 도쿄의 `jp.` 프로필을 다른 리전에서 부르거나, 해당 계정에 `global./apac.` 프로필 접근 권한이 없는 경우.
- `.env` 의 `AWS_REGION=ap-northeast-1` 확인
- `docker compose config | grep AWS_REGION_NAME` 로 컨테이너에 제대로 전달됐는지 확인
- `apac.` / `global.` prefix 는 해당 리전 세트 모두에서 Anthropic Model access 가 승인되어 있어야 함

### `RateLimitError: BedrockException - Too many tokens per day`

원인 : Bedrock 의 **일일 토큰 쿼터** 초과. 계정 · 리전 · Inference Profile 단위로 독립 적용. 신규 계정이거나 `jp.` (단일 리전) 프로필 사용 시 흔함.

해결 A) 이 번들 기본은 `global.` 프로필 → 쿼터 풀이 가장 넓음. 혹시 주석 블록을 해제했다면 거기도 `global.` 인지 확인.

해결 B) Service Quotas 현재값 조회 후 증액 신청

```bash
aws service-quotas list-service-quotas \
  --service-code bedrock \
  --region ap-northeast-1 \
  --query "Quotas[?contains(QuotaName, 'Claude') && contains(QuotaName, 'tokens per day')].[QuotaName,Value]" \
  --output table
```

- 콘솔 경로: Service Quotas → AWS services → Amazon Bedrock → 해당 항목 → **Request quota increase**
- 승인까지 수 시간 ~ 영업일 1~2일

해결 C) 다른 모델로 임시 대체 (쿼터 버킷이 독립이라 즉시 우회 가능)

현재 번들은 기본적으로 아래 두 대체 모델을 활성화해 두고 있습니다 - Sonnet 4.6 없이도 드롭다운에서 바로 선택 가능:

- **`claude-haiku-4-5`** - Claude 계통 유지하며 쿼터 회피. 답변 톤 · 한국어 표현이 Sonnet 과 유사해 이후 이식 부담 최소
- **`nova-lite`** (Amazon Nova Lite) - 비-Claude. Marketplace 구독 권한 이슈 없음, 한국어 공식 지원. Claude 와 품질/비용 비교 용도로 유용

LiteLLM 재시작 없이 Open WebUI 모델 드롭다운에서 바로 전환하면 됩니다. 둘 다 동작 안 하면 해당 모델의 Bedrock Model access 승인 여부 확인.

해결 D) 다음 날 UTC 00:00 이후 재시도 (일일 쿼터는 매일 리셋, 한국 시간 오전 9시)

### `401 {"error": "Invalid proxy server token"}`

원인 : 클라이언트가 보내는 Bearer 토큰이 `LITELLM_MASTER_KEY` 와 불일치.
- `.env` 의 값을 다시 복사해서 붙이기 (앞뒤 공백 · 따옴표 주의)
- `.env` 를 수정했으면 `docker compose up -d` 로 컨테이너 재생성 필요 (restart 만으로는 env 재주입 안 됨)
- Open WebUI 내부에서 발생하는 401 은 compose env 에 `OPENAI_API_KEY` 가 주입됐는지 확인: `docker compose exec open-webui env | grep OPENAI`

### LiteLLM 컨테이너가 계속 재시작

```bash
docker compose logs --tail 100 litellm
```

흔한 메시지:

- `Error loading config: ...` → `litellm_config.yaml` YAML 문법 오류. 탭/들여쓰기 확인
- `pydantic.ValidationError` → 모델 섹션 필드명 오타
- `botocore.exceptions.NoCredentialsError` → `.env` 에 AWS 키 누락 또는 이름 오타

### 외부 호스트에서만 접속 불가

- 프록시 VM 방화벽/보안그룹이 inbound `${LITELLM_PORT}` (기본 14000) 을 막고 있음
- 꼭 필요한 소스 IP 만 허용 권장 (0.0.0.0/0 비권장)

### `/v1/models` 응답이 빈 배열

대부분 `litellm_config.yaml` 의 `model_list` 가 컨테이너에 마운트되지 않은 경우.

```bash
docker compose exec litellm cat /app/config.yaml | head -20
```

호스트의 최신 내용이 보이지 않는다면:
- `docker-compose.yml` 의 볼륨 경로(`./litellm_config.yaml:/app/config.yaml:ro`) 확인
- 이미지 캐시 문제면 `docker compose up -d --force-recreate`

## Open WebUI 경로

### 로그인 화면이 계속 돌기만 함 · 토큰 에러

원인 : `WEBUI_SECRET_KEY` 가 비어 있어 재시작마다 새 랜덤 키가 생성됨 → 기존 JWT 전부 invalid.
- `.env` 에 `WEBUI_SECRET_KEY` 고정 값 지정 (`openssl rand -hex 32`)
- `docker compose up -d --force-recreate open-webui` 로 재생성

### "You do not have permission to access this resource" · "Signup is disabled"

원인 A) `docker-compose.yml` 의 `ENABLE_SIGNUP=false` (최초 관리자 생성도 여기서 막힘)
- `ENABLE_SIGNUP: "true"` + `DEFAULT_USER_ROLE: pending` 으로 변경 후
- `docker compose up -d --force-recreate open-webui` 로 컨테이너 재생성

원인 B) 볼륨에 이미 사용자가 있음 (과거 기동 흔적 · 이름 충돌)
- 기존 계정 이메일로 로그인 시도
- 완전히 초기화하려면 `docker compose down -v` (볼륨 삭제) 후 재기동 — **모든 대화 · Knowledge 가 사라짐**

원인 C) signup 은 성공했는데 로그인 시 위 메시지가 뜸
- `DEFAULT_USER_ROLE=pending` 때문에 이 유저가 `pending` role 로 생성된 상태
- 기존 admin 이 Admin Panel → Users 에서 role 을 `user` 로 승격해야 함

### 모델 드롭다운이 비어 있음

- `docker compose logs open-webui | grep -i "openai\|litellm\|models"` 에 연결 오류가 있는지 확인
- LiteLLM 쪽 `/v1/models` 가 정상인지 먼저 확인
- Admin Panel → **Settings → Connections** 에서 OpenAI API Base URL 이 `http://litellm:4000/v1` (컨테이너 간 DNS) 여야 함. 호스트 IP 로 바꿔 넣으면 컨테이너 네트워크 안에서는 해석 실패

### RAG 업로드 시 "Embedding failed"

- `docker compose logs litellm | grep -i embed` 에 Titan 호출 에러가 찍히는지
- 가장 흔한 원인: Titan Embeddings v2 **Model access 미승인** · IAM `foundation-model/*` resource 누락
- `/v1/embeddings` 를 curl 로 직접 쏴봐서 LiteLLM 쪽에서 정상인지 먼저 격리

### Knowledge 조회는 되는데 답변에 반영이 안 됨

- 채팅 시 `+` 버튼 → Knowledge 첨부 또는 `#` 으로 지정했는지 확인
- Admin Panel → **Settings → Documents → Chunk size / Top K** 값이 지나치게 작으면 context 가 누락됨. 이 번들 기본 프리셋은 800 / 150 / 5

### env 를 바꿨는데 반영이 안 됨 (PersistentConfig)

원인 : Open WebUI 의 상당수 설정(Arena · RAG 청크/Top-K · 임베딩 · Signup 등) 은 **첫 부팅 시에만** env 에서 읽어 DB (`webui.db`) 에 저장되고, 이후에는 DB 값이 우선입니다. 즉 이미 볼륨이 있는 상태에서 `docker-compose.yml` 의 env 만 바꿔도 반영 안 됨.

이 이유로 **이 번들은 env 로 세팅을 자동화하지 않고, Admin Panel 에서 수동 맞추는 절차를 [04-admin-settings.md](./04-admin-settings.md) 에 체크리스트로 정리**해 두었습니다. 이쪽을 먼저 확인하세요.

## 일반

### 스트리밍 응답이 중간에 끊김

- LiteLLM `request_timeout` 기본 600 초. 그보다 오래 걸리는 작업이면 `litellm_config.yaml` 의 `litellm_settings.request_timeout` 증가
- 브라우저 · 프록시 사이에 nginx · Cloudflare 등이 있으면 각 계층 timeout 도 함께 조정

### 데이터 상주가 궁금할 때

`litellm_config.yaml` 의 model prefix 에 따라 다릅니다:
- `bedrock/jp.anthropic.*` → 도쿄 내 고정
- `bedrock/apac.anthropic.*` → 아시아-태평양 내 여러 리전
- `bedrock/global.anthropic.*` → 전 세계 (미국 포함) — **현재 번들 기본값**

이 번들은 시연 단계 기본값으로 `global.` 을 사용합니다. 운영 배포 시에는 `docs/01-prerequisites.md` 의 "운영 전환 체크리스트" 를 참고해 `jp.` / `apac.` 전환과 쿼터 증액을 선행하세요. 상위 리서치 페이지의 `data-policy` 섹션도 함께 재확인.

### 포트 충돌

`setup.sh` 가 `bind: address already in use` 로 실패:

```bash
# 누가 쓰는지 확인
sudo ss -tlnp | grep -E ':(13000|14000)'
```

기존 서비스가 맞다면 `.env` 의 `LITELLM_PORT` · `OPENWEBUI_PORT` 를 다른 값으로 변경 후 `docker compose up -d`.

### 기존 스택을 건드렸을까 걱정될 때

이 번들의 모든 리소스는 아래 prefix 로만 생성됩니다. 외 다른 이름에 영향 없음.

```bash
docker ps --filter 'name=openwebui-hosting-'
docker volume ls --filter 'name=openwebui-hosting-'
docker network ls --filter 'name=openwebui-hosting'
```

전체 제거 (볼륨 포함):

```bash
docker compose down -v
```

## 그래도 막히면

1. 전체 로그 스냅샷: `docker compose logs > /tmp/openwebui-hosting.log`
2. 상위 리서치 페이지: [../../index.html](../../index.html)
3. LiteLLM 이슈: <https://github.com/BerriAI/litellm/issues>
4. Open WebUI 이슈: <https://github.com/open-webui/open-webui/issues>
