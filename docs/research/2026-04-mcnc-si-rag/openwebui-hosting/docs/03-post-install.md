# 03. 최초 관리자 + RAG 테스트

설치가 끝나고 두 컨테이너가 healthy 면 여기부터 시작.

## A. 최초 관리자 계정 만들기

1. 브라우저로 `http://<VM>:13000` 접속
2. 첫 화면 "**Sign up**" 으로 이동 → 이름 · 이메일 · 비밀번호 입력
3. **가입 첫 명이 자동으로 관리자 role** 을 받습니다
4. 이후 다른 사람이 signup 을 시도하면 `DEFAULT_USER_ROLE=pending` 설정 때문에 `pending` 상태로 생성되어 로그인이 막힙니다. Admin Panel → **Users** 에서 role 을 `user` 로 변경해야 접근 가능. 완전히 signup 자체를 닫고 싶다면 Admin Panel → Settings → General → User Permissions 에서 Signup 토글 OFF

만약 가입 직후 "You do not have permission to access this resource" 가 뜨면 `docker-compose.yml` 의 `ENABLE_SIGNUP` 이 `"false"` 로 되어 있지 않은지 확인하세요. `"true"` 로 바꾼 뒤 `docker compose up -d --force-recreate open-webui` 로 재생성해야 반영됩니다.

이미 볼륨에 사용자가 생성된 뒤 signup 을 재시도하는 경우에는 기존 계정으로 로그인하거나, 완전 초기화가 필요하면 `docker compose down -v` (주의: 모든 대화 · Knowledge 삭제).

## B. 모델 노출 확인

로그인 직후 상단 모델 드롭다운에 아래 2개가 보여야 정상.

- `claude-sonnet-4-6` - 채팅 · RAG 답변용
- `titan-embed-v2` - 임베딩 전용. 채팅에서 선택 의미 없고 RAG 용.

필요해지면 `litellm_config.yaml` 의 주석 블록을 풀어 Claude Sonnet 4.5 · Haiku 4.5 를 추가할 수 있습니다. 수정 후 `docker compose restart litellm` 으로 반영.

보이지 않으면:

```bash
docker compose exec open-webui env | grep OPENAI_API_BASE_URL
# http://litellm:4000/v1
docker compose logs open-webui | grep -i openai
```

LiteLLM 쪽에서 `/v1/models` 가 제대로 내려오는지 [06-troubleshooting.md](./06-troubleshooting.md) 참고.

## C. 간단한 채팅 테스트

1. 모델을 `claude-sonnet-4-6` 으로 선택
2. 새 채팅 → "한국어로 자기소개 한 문장 해줘" 입력
3. 응답이 스트리밍으로 출력되면 LLM 경로 OK

실패하면 Admin Panel → **Settings → Connections** 에서 OpenAI API 섹션의 Base URL 이 `http://litellm:4000/v1`, API Key 가 `.env` 의 `LITELLM_MASTER_KEY` 와 같은지 확인 (compose 가 자동 주입했지만 override 된 경우가 있음).

## D. RAG Knowledge 테스트 (임베딩 경로)

이 번들의 핵심 검증 포인트. 임베딩이 Bedrock Titan 으로 잘 내려가는지 확인합니다.

### 1) 임베딩 설정 확인

- Admin Panel → **Settings → Documents**
- 기본값 확인:
  - **Embedding Model Engine**: `OpenAI` (compose env 로 프리셋됨)
  - **Embedding Model**: `titan-embed-v2`
- 값이 비어 있으면 `RAG_EMBEDDING_ENGINE` · `RAG_EMBEDDING_MODEL` 환경변수가 제대로 주입되지 않은 것 — `docker compose up -d --force-recreate` 로 재생성

### 2) Knowledge 생성 · 파일 업로드

- 좌측 **Knowledge** → **+ Create** → 이름 지정
- 파일 1 ~ 2개 드래그 & 드롭 (PDF · docx · txt 등)
- 업로드 후 처리 완료 배지가 뜰 때까지 대기 (수 초 ~ 수십 초)

### 3) 임베딩 호출 로그 확인

다른 터미널에서:

```bash
docker compose logs -f litellm | grep -i embed
```

업로드 중 `titan-embed-v2` 에 대한 호출이 찍히면 경로 OK. 실패 로그면 보통 IAM 권한 혹은 Titan 모델 액세스 미승인.

### 4) RAG 질의

- 새 채팅 → 모델 `claude-sonnet-4-6` 선택
- `+` 버튼 → 방금 만든 Knowledge 첨부 (또는 `#` 으로 호출)
- 문서 내용 관련 질문 → 답변에 출처 표시가 붙으면 RAG 경로 OK

> 실제 시연 품질을 올리려면 Chunk · Hybrid · Reranker · Top K 등 22개 옵션 튜닝이 필요합니다. 상세는 [05-openwebui-rag-tuning.md](./05-openwebui-rag-tuning.md).

## E. 외부 클라이언트 (선택)

다른 서버 · 로컬 스크립트에서 LiteLLM 을 직접 쓰고 싶을 때.

```bash
export LITELLM_MASTER_KEY=$(grep ^LITELLM_MASTER_KEY .env | cut -d= -f2-)
export BASE_URL=http://<VM>:14000/v1
```

### curl - Chat

```bash
curl -sS "$BASE_URL/chat/completions" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4-6",
    "messages": [{"role": "user", "content": "한국어로 자기소개 한 문장"}]
  }'
```

### curl - Embedding

```bash
curl -sS "$BASE_URL/embeddings" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "titan-embed-v2", "input": "안녕하세요"}'
```

응답 `data[0].embedding` 이 길이 1024 배열이면 정상.

### Python OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://<VM>:14000/v1",
    api_key="... LITELLM_MASTER_KEY ...",
)

resp = client.chat.completions.create(
    model="claude-sonnet-4-6",
    messages=[{"role": "user", "content": "한 줄 요약"}],
)
print(resp.choices[0].message.content)
```

스트리밍도 `stream=True` 로 동일.

## 다음 단계

- Admin Panel 세부 세팅 (Arena OFF · 청크 튜닝 · 커스텀 에이전트 · 백업) → [04-admin-settings.md](./04-admin-settings.md)
- RAG 품질 튜닝 (22개 옵션 MCNC 문서 기준) → [05-openwebui-rag-tuning.md](./05-openwebui-rag-tuning.md)
- 문제 생겼다면 → [06-troubleshooting.md](./06-troubleshooting.md)
- 다른 프로바이더(OpenAI · Ollama 등) 추가 → `litellm_config.yaml` 의 `model_list:` 에 섹션만 append 후 `docker compose restart litellm`
