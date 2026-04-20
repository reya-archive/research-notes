# 03. 초기 설정 (Dify + Bedrock)

스택이 떠 있는 상태에서 한 번만 수행하는 웹 UI 설정입니다.

## 1) Dify 관리자 계정 생성

1. 브라우저에서 `http://<VM_IP>/install` 접속
2. 이메일 · 관리자 이름 · 패스워드 입력 → **Setup** 클릭
3. `http://<VM_IP>/signin` 으로 리다이렉트되면 방금 만든 계정으로 로그인

## 2) Bedrock Model Provider 추가

1. 우측 상단 프로필 → **Settings** → **Model Provider**
2. 목록에서 **Amazon Bedrock** 카드의 **Setup** 클릭
3. 다음을 입력:

   | 필드 | 값 |
   |---|---|
   | AWS Access Key ID     | `.env` 의 `AWS_ACCESS_KEY_ID` |
   | AWS Secret Access Key | `.env` 의 `AWS_SECRET_ACCESS_KEY` |
   | AWS Region            | `ap-northeast-1` |
   | Bedrock Endpoint URL  | 비움 (기본) |
   | Available Model Name  | `jp.anthropic.claude-sonnet-4-6` |
   | Bedrock Proxy URL     | 비움 |

4. **Save** 클릭 → "Credentials validated" 녹색 배지가 뜨면 성공

   실패 시:
   - `AccessDeniedException` → [01-prerequisites.md](./01-prerequisites.md) 3) 모델 활성화 상태 재확인 (CLI 호출로 판단)
   - `SignatureDoesNotMatch` → Access Key 오타 확인
   - `UnknownHostException` → VM 에서 bedrock 엔드포인트까지 네트워크 경로 확인

### 임베딩 모델 추가 등록

같은 Bedrock 카드에서 **+ Add Model** 클릭:

| 필드 | 값 |
|---|---|
| Model Type          | **Text Embedding** |
| Available Model Name | `amazon.titan-embed-text-v2:0` |
| 나머지              | 자동 채워짐 |

Save → Bedrock 카드에 LLM + 임베딩 2개 모델이 녹색 체크.

## 3) 시스템 기본 모델 지정

같은 Model Provider 화면 상단의 **System Model Settings**:

| 역할 | 입력값 (Model / Inference Profile ID) |
|---|---|
| Reasoning Model (LLM)  | `jp.anthropic.claude-sonnet-4-6` (Bedrock) |
| Embedding Model        | `amazon.titan-embed-text-v2:0` (Bedrock) |
| Rerank Model           | 비움 (프로토타입에선 불필요) |
| Speech-to-Text / TTS   | 비움 |

> **중요 · Claude 4.x 는 Inference Profile 필수**
> AWS Bedrock 은 2025 년부터 Claude 4.x 계열에 대해 직접 model ID(`anthropic.claude-sonnet-4-6`) 로의 on-demand 호출을 차단했습니다. 반드시 **prefix 가 붙은 inference profile ID** 를 입력하세요.
>
> | Prefix | 데이터 상주 | 예시 |
> |---|---|---|
> | `jp.`     | 도쿄 리전 고정 | `jp.anthropic.claude-sonnet-4-6` (권장) |
> | `apac.`   | 아시아-태평양 크로스 리전 | `apac.anthropic.claude-sonnet-4-20250514-v1:0` |
> | `global.` | 전 세계 크로스 리전 | `global.anthropic.claude-sonnet-4-6` |
>
> 데이터 주권이 우선이면 `jp.` 프로필을 쓰세요. Titan Embeddings 는 inference profile 이 필요 없어 직접 model ID 로 호출합니다.

**Save** 후 Model Provider 화면을 새로고침해 각 모델이 녹색 체크로 보이는지 확인.

## 4) 지식베이스 생성 + 파일 업로드

1. Dify 상단 **Knowledge** 탭 → **Create Knowledge** → **Create from empty Knowledge Base**
2. 이름: `rag-demo` → **Create**
3. 지식베이스 상세 화면에서 준비해 둔 샘플 파일들을 **드래그&드롭** 으로 업로드
   - PDF · PPTX · XLSX · DOCX · MD · TXT 등 지원
4. 각 문서가 **"Indexing"** → **"Available"** 상태로 바뀔 때까지 대기 (파일 크기에 따라 수십 초 ~ 수 분)

## 5) 질의 응답으로 마무리

1. Dify 상단 **Studio** → **Create from Blank** → **Chatbot** 선택 → 이름 아무거나
2. 생성된 앱의 **Context** 섹션 → **Add** → 방금 만든 `rag-demo` 지식베이스 선택
3. 우측 **Debug and Preview** 에 "업로드한 문서 요약해 줘" 입력
4. Bedrock (Claude Sonnet 계열) 답변 + 인용 파일명 표시되면 end-to-end 성공

## 6) 헬스 체크

이 시점에서 확인해 두면 좋은 것들:

```bash
docker compose \
  -f dify/docker/docker-compose.yaml \
  --env-file .env \
  ps
```

Dify 관련 모든 컨테이너가 `running` / `healthy` 상태여야 합니다.

---

Ollama 도 함께 시연하려면 [06-ollama.md](./06-ollama.md) 로 진행.
