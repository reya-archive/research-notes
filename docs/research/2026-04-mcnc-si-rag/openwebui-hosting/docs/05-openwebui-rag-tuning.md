# 05. Open WebUI RAG 튜닝 - 모바일 하이브리드 앱 SI/SM 문서 기준

[03-post-install.md](./03-post-install.md) · [04-admin-settings.md](./04-admin-settings.md) 가 "Open WebUI 를 기동하고 한 번 둘러보는" 가이드라면, 이 문서는 **Open WebUI 의 RAG 기능 (Admin Panel → Settings → Documents) 을 MCNC 가 실제로 다루는 문서군에 맞춰 튜닝하는 방법**을 정리합니다.

자매 문서인 [Dify RAG 튜닝 가이드](../../oss-hosting/docs/04-dify-rag-tuning.md) 와 같은 구조로 작성됐습니다. 두 문서를 나란히 놓고 비교하면 "같은 문서군을 두 제품에서 어떻게 다르게 다루는가" 를 한눈에 볼 수 있습니다.

대상 Open WebUI 버전: **v0.8.x 이상 `main-stable`**. 22개 옵션 전체가 노출되는 버전.

## 왜 튜닝이 필요한가

Open WebUI 의 Documents 설정값들은 대부분 **PersistentConfig** 로 분류되어 있습니다. 첫 부팅 시에만 `docker-compose.yml` 의 env 를 seed 로 받아 DB (`webui.db`) 에 저장되고, 이후에는 DB 값이 우선이라 env 를 고쳐도 무시됩니다. 그래서 이 번들은 env 로 모든 튜닝을 자동화하지 않고, **관리자가 Admin Panel 에서 한 번 제대로 잡아두는 흐름**을 택합니다.

게다가 Open WebUI 의 RAG 는 Dify 의 Parent-child 같은 계층 청킹이 없습니다. 대신 **Chunk Min Size Target + Hybrid Search + Reranker + Top K 리랭커** 조합으로 품질을 보완합니다. 기본값 그대로 두면 식별자 (REQ-F-022, TKT-20260115-003, SCR-045) 매칭이 약해 Open WebUI 의 장점이 전혀 살지 않습니다.

즉 **최초 세팅 30분이 이후 시연 품질을 결정**합니다.

## 시뮬레이션 대상 문서 (MCNC 모바일 하이브리드 앱 SI/SM)

아래와 같은 문서 mix 를 Knowledge 에 올린다고 가정합니다.

| 분류 | 문서 예시 | 포맷 | 분량 | 특징 |
|---|---|---|---|---|
| 사업/영업 | 차세대 모바일 뱅킹 앱 구축사업 제안서 v2.1 | PDF | 150 p | 이력/목차, 단가표, 인력투입 표, 일정표 |
| 화면 설계 | 민원 앱 화면설계서 | XLSX / PDF | 200 p | 화면 번호 (SCR-001), 와이어프레임, 필드 정의표 |
| API 명세 | 공통 API 연동 명세서 v3 | DOCX | 80 p | REST endpoint 표, 요청/응답 JSON |
| 하이브리드 기술 가이드 | Cordova-Capacitor 전환 매뉴얼 | Markdown | 30 p | `#` / `##` 헤더, 코드 블록, CLI 예시 |
| SM 이슈 로그 | A사 모바일 앱 SM 2026Q1 티켓 export | PDF | 60 p | 티켓 ID (TKT-20260115-003), 증상/재현/조치 |
| 배포 절차 | 앱스토어/플레이스토어 배포 체크리스트 | DOCX | 15 p | 단계 bullet + 제출 메타데이터 |
| 코딩/보안 규약 | MCNC 모바일 앱 보안 규약 2026 | PDF | 40 p | 제1조, 제2조 조항, OWASP Mobile Top 10 |
| 사내 기술표준 | 공통 라이브러리 사용 가이드 | Markdown | 20 p | 코드 블록 밀집, 예제 snippet |
| 주간회의록 | 2026-04 1주차 주간회의록 | DOCX | 6 p | 결정사항 bullet, 담당자·일정 |
| 요구사항 정의서 | B사 모바일 앱 리뉴얼 요구사항정의서 v1.2 | PDF | 300 p | REQ-F-xxx 식별자, 표, 다이어그램 |

예상 질의 (사용자 입장):

- "TKT-20260115-003 원인 알려줘" - 티켓 ID 정확 매칭
- "SCR-045 필드 명세 뭐야" - 화면 번호 정확 매칭
- "Cordova 에서 Capacitor 로 전환할 때 주의사항 정리해줘" - 서술/요약
- "우리 팀이 쓰는 공통 API 엔드포인트 전부 나열" - 나열/종합
- "파일 업로드 API 샘플 코드 보여줘" - 코드 블록 검색
- "모바일 앱 보안 규약 제3조 내용" - 조항 번호
- "4월 1주차에 결정한 배포 일정" - 짧은 bullet 매칭

이 질의들이 모두 정답을 내려면 아래 튜닝이 필요합니다.

## 튜닝 포인트

Admin Panel → **Settings → Documents** 에서 위에서 아래로 마주치는 필드 순서대로 정리합니다. 각 옵션마다 **영향 · 권장값 · 근거** 를 묶어 둡니다.

### 일반 (General) - 9개 옵션

#### 1. 콘텐츠 추출 엔진 (Content Extraction Engine)

| 옵션 | 의미 | 언제 |
|---|---|---|
| (기본, 빈 값) | 내장 PyPDF / python-docx 로 추출 | 단순 텍스트 PDF 만 올릴 때 |
| **Tika** ✅ | Apache Tika 서버 경유. docx/xlsx/pptx/pdf 범용 강함 | **MCNC 기본값 (번들에 포함)** |
| Docling | IBM Docling. 레이아웃/표 구조 보존 품질 최고 | 화면설계서 · 단가표 복잡한 케이스, 메모리 여유 충분할 때 |
| MinerU · External · Mistral OCR | 특수 목적 | 필요 시 |

**권장**: Tika. 내장 PyPDF 는 화면설계서 같은 표 중심 PDF 에서 셀이 깨지거나 섞입니다. 이 번들은 `docker-compose.yml` 에 `tika` 서비스가 이미 포함돼 있고, `open-webui` 에 `CONTENT_EXTRACTION_ENGINE=tika` · `TIKA_SERVER_URL=http://tika:9998` 가 프리셋되어 있어 **추가 설치 없이 바로 사용 가능**합니다.

**새 볼륨 (최초 기동) 이라면**: env 가 seed 로 자동 적용되어 별도 조치 불필요.

**기존 볼륨 (이미 Admin Panel 설정이 있는 경우) 이라면**: `CONTENT_EXTRACTION_ENGINE` 과 `TIKA_SERVER_URL` 은 PersistentConfig 라 env 가 무시됩니다. Admin Panel 에서 수동 전환하세요.

```
Admin Panel → Settings → Documents →
  콘텐츠 추출 엔진 : Tika
  Tika Server URL  : http://tika:9998
  → Save
```

저장 후 기존 Knowledge 는 **Reindex 필요** (추출 엔진 변경은 재인덱싱 대상).

**Tika 서버 헬스 체크**: VM 에서 `docker compose ps tika` 결과가 `healthy` 여야 Open WebUI 에서 정상 호출됩니다. 접속 자체가 안 되면 [06-troubleshooting.md](./06-troubleshooting.md) 의 Tika 섹션 참고.

**Docling 으로 업그레이드 고려**: 제안서 PDF 의 표 구조가 특히 중요해지면 Docling 으로 전환 가능. 단 이미지 크기 4~6 GB · 메모리 2~4 GB · 권장 GPU. 전환 시 `docker-compose.yml` 에서 `tika` 서비스를 `docling` 으로 바꾸고 env 를 `CONTENT_EXTRACTION_ENGINE=docling` + `DOCLING_SERVER_URL=http://docling:5001` 로 교체.

#### 2. PDF 이미지 추출 (PDF Extract Images - OCR)

| 값 | 의미 |
|---|---|
| **OFF** ✅ | 이미지 무시. **MCNC 기본값** |
| ON | 이미지 기반 PDF 에서 OCR 수행 |

**권장**: OFF. MCNC 문서 mix 는 대부분 텍스트 PDF. OCR ON 은 업로드 1건당 수 분씩 늘어납니다. 스캔 원본 (제안서 붙임문서 등) 이 특수하게 필요하면 해당 파일만 별도 전처리 후 업로드.

#### 3. PDF Loader Mode

| 값 | 의미 |
|---|---|
| **default** ✅ | 문서 전체를 한 번에 로드 |
| page | 페이지 단위로 먼저 분할 후 청킹 |

**권장**: default. 운영 매뉴얼처럼 "페이지 N에 있음" 인용이 중요해지면 `page` 로 전환 재검토.

#### 4. 임베딩 검색 우회 (Bypass Embedding and Retrieval)

| 값 | 의미 |
|---|---|
| **OFF** ✅ | 업로드 파일을 청킹/임베딩/검색 모두 수행 |
| ON | 파일 전체를 그대로 프롬프트에 주입. 검색 skip |

**권장**: OFF. 문서량이 많아 전체 주입은 컨텍스트 초과. ON 은 채팅에서 짧은 단일 파일을 임시 첨부할 때만 개별 사용.

#### 5. 텍스트 나누기 (Text Splitter)

| 값 | 의미 |
|---|---|
| character | 글자 수 기준 |
| **token** ✅ | 토큰 수 기준 |

**권장**: token. Titan Embeddings v2 의 8192 토큰 상한에 맞추려면 토큰 단위 관리가 안정적. 한국어 문자 수 기준은 같은 800 자라도 토큰 수가 들쭉날쭉.

#### 6. Markdown Header Text Splitter

| 값 | 의미 |
|---|---|
| **ON** ✅ | `#` ~ `######` Markdown 헤더로 먼저 분할 후 재청킹 |
| OFF | 헤더 무시하고 일반 splitter 만 |

**권장**: ON. MCNC 의 `Cordova-Capacitor 전환 매뉴얼.md`, `공통 라이브러리 사용 가이드.md`, 리서치 노트들이 Markdown 이고 `## 섹션` 구조가 명확합니다. ON 으로 두면 섹션별로 쪼개져 "섹션 요약" 류 질의가 잘 동작.

단, 헤더가 너무 촘촘하면 10~30자 짜리 토막이 양산됩니다. 다음 옵션 (Chunk Min Size Target) 으로 보정.

#### 7. 청크 크기 (Chunk Size)

| 값 (token) | 특성 |
|---|---|
| 300 ~ 500 | 정확 매칭 강, 맥락 보존 약 |
| **800** ✅ | **MCNC 기본값 - 균형점** |
| 1000 (기본) | 맥락 보존 강, 정확 매칭 약간 약 |
| 1500+ | 표/코드 블록 보존 유리, 하지만 노이즈 혼입 |

**권장**: 800 토큰. 표 row · 코드 블록 · 한국어 문단이 섞인 MCNC 문서에서 정확도와 recall 균형점. Dify 권장 child 500 · parent 3500 의 중간값에 해당.

#### 8. 청크 중첩 (Chunk Overlap)

| 값 | 의미 |
|---|---|
| 50 | 중첩 거의 없음 |
| 100 (기본) | 약한 경계 보존 |
| **150** ✅ | **MCNC 기본값** |
| 200+ | 중첩 크지만 중복 증가 |

**권장**: 150. 표 경계, 코드 블록 경계, 조항 경계 문맥 유지용. 기본 100 은 "제18조" 와 본문이 두 청크로 찢어질 수 있음.

#### 9. Chunk Min Size Target

| 값 | 의미 |
|---|---|
| 0 (기본, 비활성) | 작은 토막 그대로 유지 |
| **400** ✅ | Chunk Size (800) 의 50%. **MCNC 기본값** |

**권장**: 400. Markdown Header Splitter ON 상태에서 `### 1.1.1` 같은 세부 헤더 때문에 생긴 10~30 자 청크들을 이웃과 병합. 너무 크게 잡으면 (ex: 700) 오히려 코드 블록과 해설 문단이 억지로 섞여 품질 저하. 800 × 0.5 가 안전 지점.

---

### 임베딩 (Embedding) - 3개 옵션

> **두 모드 병기**: 임베딩 #11·#12 는 "속도 우선 (일상 운영)" 과 "안정 우선 (최초 대량 업로드)" 두 가지 프리셋을 가집니다. 최초 Knowledge 대량 적재 시에는 안정 모드로 내려 Bedrock Titan 분당 쿼터 초과(429) 를 피하고, 적재가 끝나 일상 질의 단계로 들어가면 속도 우선으로 되돌려도 무방합니다. 둘 다 PersistentConfig 라 Admin Panel 에서 즉시 토글 가능 · Reindex 불필요.
>
> **전환 기준**: LiteLLM 로그에 `RateLimitError: Too many requests` 또는 `429` 가 관측되면 즉시 안정 모드. 실제 MCNC 환경(ap-northeast-1, 신규 계정, Bedrock 쿼터 미증액)에서 엑셀 · 200p 이상 PDF 업로드 시 재현되는 것이 확인됨.

#### 10. 임베딩 배치 크기 (Embedding Batch Size)

| 값 | 언제 |
|---|---|
| **32** (기본, 유지) ✅ | **MCNC 기본값 - 두 모드 공통** |
| 8 ~ 4 | 로컬 GPU OOM 시 |

**권장**: 32 유지. Bedrock Titan v2 는 LiteLLM 이 단건으로 분해 호출해 실효 배치는 1. 이 값을 늘려도 네트워크/쿼터 이득 없음. 로컬 임베딩 (BGE-M3 등) 으로 전환하면 GPU 사양에 맞춰 재조정.

#### 11. Async Embedding Processing

| 값 | 의미 | 언제 |
|---|---|---|
| **ON** ✅ | 비동기 병렬 임베딩 | **속도 우선 (일상 운영 기본)** |
| **OFF** ✅ | 순차 처리 | **안정 우선 (최초 대량 업로드)** |

**권장**: 기본은 ON. **Bedrock Titan 429 가 관측되거나 최초로 엑셀 · 대형 PDF 를 Knowledge 에 올리는 단계에서는 OFF** 로 내립니다. Async 를 끄면 Open WebUI 가 청크를 한 건씩 직렬로 임베딩해 쿼터 초과가 원천 차단됩니다. 적재가 끝나고 일상 질의만 남으면 다시 ON.

#### 12. Embedding Concurrent Requests

| 값 | 의미 | 언제 |
|---|---|---|
| 0 (기본, 무제한) | 제한 없음 - Bedrock TPS 쿼터 히트 가능 | 비권장 |
| **5** ✅ | 동시 Titan 호출 5개 | **속도 우선 (일상 운영 기본)** |
| **1** ✅ | 순차 (Async ON 이어도 실효 직렬) | **안정 우선 (최초 대량 업로드)** |
| 10+ | 쿼터 여유 있으면 속도 우선 | Bedrock 쿼터 증액 후 |

**권장**: 기본 5. **안정 모드로 전환할 때는 1 로 내립니다.** #11 Async OFF 와 중복 안전장치이기도 하지만, 관리자가 Async 를 OFF 로 바꾸는 것을 잊어도 Concurrent 1 만으로 실효 순차가 확보됩니다. LiteLLM 측 `num_retries: 10` (지수 백오프 자동) 과 조합되면 분당 쿼터가 낮은 신규 Bedrock 계정에서도 대량 업로드가 완주합니다.

---

### 검색 (Retrieval) - 10개 옵션

#### 13. 전체 컨텍스트 모드 (Full Context Mode)

| 값 | 의미 |
|---|---|
| **OFF** ✅ | 검색 수행 후 상위 K개만 주입 |
| ON | Knowledge 전체를 컨텍스트로 주입 (검색 skip) |

**권장**: OFF. MCNC 는 문서 수 · 총 분량이 많아 전체 주입 불가. "보안 규약" 같은 짧은 단일 Knowledge 에서만 ON 재검토.

#### 14. 하이브리드 검색 (Hybrid Search)

| 값 | 의미 |
|---|---|
| OFF (기본) | Vector (의미) 만 사용 |
| **ON** ✅ | Vector + BM25 (키워드) 동시. **MCNC 기본값** |

**권장**: ON. `TKT-20260115-003`, `SCR-045`, `REQ-F-022`, `제3조` 같은 고유 식별자는 vector similarity 로 잘 안 잡힘. Hybrid 필수.

**참고**: v0.6 대에서 Hybrid 성능 저하 이슈가 반복 보고됐으나 v0.8 대에서 상당 부분 개선. 그럼에도 체감 지연이 있으면 Reranker 를 빼고 Hybrid + TopK 만으로 가거나 Relevance Threshold 를 활용.

#### 15. Enrich Hybrid Search Text

| 값 | 의미 |
|---|---|
| OFF (기본) | 원문 그대로 BM25 인덱싱 |
| **ON** ✅ | 텍스트에 동의어 · 메타데이터 주입 후 BM25 인덱싱 |

**권장**: ON. MCNC 문서군은 "API", "엔드포인트", "연동", "인터페이스" 처럼 같은 개념을 다른 한국어/영어 용어로 부릅니다. Enrich 가 이 격차를 일부 메움.

#### 16. Reranking 엔진 (Reranking Engine)

| 값 | 언제 |
|---|---|
| **없음 (빈 값)** ✅ | **MCNC 시연 1단계 기본값** - Hybrid + TopK 상향으로 우선 검증 |
| **External** | **MCNC 2단계 · 권장 경로** - LiteLLM (Cohere Rerank via Bedrock) 연결 |
| Cohere | Cohere 직접 API 키 연결 (LiteLLM 미경유 - 이 번들에선 권장 안 함) |
| Local (CrossEncoder) | GPU 여유 있으면 BGE-Reranker 로컬 구동 |

**권장**: 처음엔 빈 값 (= Reranker OFF) 로 시연. 답변 품질이 아쉬우면 **External** 로 전환하고 LiteLLM 의 rerank 엔드포인트를 가리키는 방식이 이 번들의 아키텍처 (Bedrock 통합 + 시크릿 일원화) 와 맞음.

> ⚠ 드롭다운의 **"Cohere"** 옵션은 Cohere 직접 API 를 호출하는 경로라 LiteLLM 을 우회합니다. Bedrock Cohere Rerank 를 쓰려면 반드시 **"External"** 을 고르세요.

#### 17. Reranking 모델 (Reranking Model)

엔진별 조합:

| 엔진 | 모델 | 비고 |
|---|---|---|
| External + LiteLLM | `cohere-rerank` (litellm_config.yaml 의 `model_name`) | **MCNC 권장**. Bedrock Cohere Rerank v3.5 를 LiteLLM 으로 프록시 |
| External + Jina 직접 | `jina-reranker-v2-base-multilingual` | Jina API 키 필요. Bedrock 에 rerank 미가용일 때 대안 |
| Cohere 직접 | `rerank-multilingual-v3` | Cohere API 키 필요 |
| Local | `BAAI/bge-reranker-v2-m3` | 다국어 특화, 한국어 품질 검증 |

##### External + LiteLLM + Bedrock Cohere 설정 절차

**전제** (2026-04 조사 확정):

- Cohere Rerank 3.5 는 **도쿄 (ap-northeast-1) 포함 5개 리전** 에서 가용 (us-east-1, us-west-2, ca-central-1, eu-central-1, ap-northeast-1)
- 모델 ID: `cohere.rerank-v3-5:0`
- Cross-region inference profile (`us.` / `apac.` / `global.`) 없음 - 단일 리전 model ID 로만 호출
- 기존 `.env` 의 `AWS_REGION=ap-northeast-1` 그대로 유지. Chat/Embedding 과 같은 리전에서 rerank 도 돌아 데이터 도쿄 상주 유지

1. **Bedrock 콘솔 Model access 승인**: AWS 콘솔 → Bedrock → 리전 도쿄 → Model access → Modify model access → `Cohere Rerank 3.5` 체크 → Submit. 보통 수 분 내 승인.

   추가로 **IAM 정책에 `bedrock:Rerank` 액션** 이 있어야 합니다. InvokeModel 과는 별개의 API 라 기존 정책에 이 액션이 없으면 403 `not authorized to perform: bedrock:Rerank` 가 발생. 상세는 [01-prerequisites.md](./01-prerequisites.md#2-iam-권한) 의 최소 정책 JSON 참고.

2. **`litellm_config.yaml`** 의 주석 블록 해제 (이 번들에 미리 심어져 있음). 중요: `model:` 라인에 **full ARN 필수** (LiteLLM 의 Bedrock Rerank 프로바이더는 short form 을 rerank 로 인식 못 함):

   ```yaml
   - model_name: cohere-rerank
     litellm_params:
       model: bedrock/arn:aws:bedrock:ap-northeast-1::foundation-model/cohere.rerank-v3-5:0
       aws_region_name: os.environ/AWS_REGION_NAME
     model_info:
       mode: rerank
   ```

   `docker compose restart litellm` 으로 반영 후 로그에 `cohere-rerank` 가 load 됐는지 확인.

3. **LiteLLM 단독 검증** (Open WebUI 에 연결하기 전에 먼저 격리). 엔드포인트는 `/rerank` 또는 `/v1/rerank`:

   ```bash
   source .env
   curl -s "http://localhost:${LITELLM_PORT}/rerank" \
     -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "cohere-rerank",
       "query": "모바일 앱 보안 규약 제3조",
       "documents": ["제1조 (목적) ...", "제3조 (인증) ...", "12장 빌드 절차 ..."],
       "top_n": 2
     }'
   ```

   응답에 `results` 배열 + `relevance_score` + `index` 가 나오면 성공. AccessDeniedException 이면 Model access 미승인 또는 IAM.

4. **Open WebUI Admin Panel → Settings → Documents**:

   | 필드 | 값 |
   |---|---|
   | 하이브리드 검색 | **ON** (리랭커는 Hybrid 가 전제) |
   | Reranking 엔진 | **External** |
   | Reranking 모델 | `cohere-rerank` |
   | External Reranker URL | `http://litellm:4000/rerank` |
   | External Reranker API Key | `${LITELLM_MASTER_KEY}` 의 실제 값 |

   > URL 은 Tika 와 같은 이유로 Docker 내부 DNS 이름 `litellm` 사용. 브라우저 URL (`http://<VM>:14000/...`) 이 아님.

5. **채팅 질의로 end-to-end 검증**. 다른 터미널에서 `docker compose logs -f litellm | grep -i rerank` 로 호출 로그 확인.

##### 리전/프로필 이해 (헷갈리기 쉬움)

- `.env` 의 `AWS_REGION=ap-northeast-1` 는 **API 진입 리전 (SigV4 서명)**
- Claude 모델 앞의 `global.` · Nova 의 `apac.` 는 **추론 풀 (실제 실행 위치)** 을 가리키는 Inference Profile
- Cohere Rerank 는 inference profile 접두사가 **존재하지 않음**. 대신 실제로 도쿄에 raw 모델이 배포되어 있어서, 기존 AWS_REGION (도쿄) 을 그대로 써서 호출하면 됨
- 과거 문서에 "Cohere Rerank 는 US 리전 전용" 이라고 적힌 글이 돌아다니는 것은 2024-12 초기 출시 때 얘기. 2026-04 현재는 도쿄 포함 5개 리전으로 확장됨

#### 18. Top K

| 값 | 의미 |
|---|---|
| 3 (기본) | 후보 3개 |
| **8** ✅ | **MCNC 기본값** - Dify 권장값과 동일 |

**권장**: 8. 나열/종합 질의 ("공통 API 전부 나열") 대응 위해 후보 풀 확대.

#### 19. Top K 리랭커 (Top K Reranker)

| 값 | 의미 |
|---|---|
| 3 (기본) | 리랭커 통과 후 3개 유지 |
| **4** ✅ | **MCNC 기본값 - Top K (8) 의 절반** |

**권장**: 4. Reranker 켤 때 최종 LLM 투입 개수. Top K 보다 크면 의미 없음.

#### 20. 관련성 임계값 (Relevance Threshold)

| 값 | 의미 |
|---|---|
| **0.0** (기본, 초기) ✅ | 필터링 없음 |
| 0.2 ~ 0.3 | 검증 후 노이즈 많을 때 |

**권장**: 0.0 으로 시작. Retrieval 테스트 결과 엉뚱한 청크가 섞이면 단계적으로 0.2 → 0.3 상향.

#### 21. BM25 가중치 (BM25 Weight)

| 값 | 의미 |
|---|---|
| 0.0 | 순수 vector |
| **0.5** ✅ | **균형 - MCNC 기본값** |
| 0.6 ~ 0.7 | 식별자 매칭 비중 크게 |
| 1.0 | 순수 BM25 |

**권장**: 0.5. Dify 쪽 Semantic 0.5 / Keyword 0.5 와 같은 감각. 식별자 recall 이 더 중요해지면 0.6.

#### 22. RAG 템플릿 (RAG Template)

LLM 에 컨텍스트를 주입할 때 쓰는 프롬프트 템플릿. `{{CONTEXT}}` · `{{QUERY}}` placeholder 지원. 기본값은 영문 템플릿이라 한국어 존댓말 · 출처 인용 규칙이 없습니다.

**권장**: 아래 한국어 커스텀 템플릿으로 교체.

```text
당신은 MCNC 사내 지식 어시스턴트입니다. 아래 [컨텍스트] 에서 근거를 찾아
사용자 질문에 한국어 존댓말로 답변하세요.

규칙:
- 컨텍스트에 근거가 없으면 "첨부된 문서에서 해당 내용을 찾지 못했습니다" 라고
  명시하고 추측하지 마세요.
- 답변 끝에 참조한 문서명과 섹션/페이지를 [출처: ...] 형식으로 표기하세요.
- 표/목록으로 답하는 게 적절하면 그 형식을 그대로 사용하세요.

[컨텍스트]
{{CONTEXT}}

[질문]
{{QUERY}}
```

## 시뮬레이션 - 예상 질의별 RAG 동작

위 22개 튜닝값이 적용된 Knowledge 에 앞서 예시한 10종 문서를 넣었다고 가정.

### 질의 1. "TKT-20260115-003 원인 알려줘"

1. Hybrid Search - BM25 가중치 0.5 로 "TKT-20260115-003" 정확 hit
2. TopK 8 에 해당 티켓 청크 상위 노출
3. (Reranker 켠 상태면) Top K Reranker 4 로 티켓 앞뒤 문단 정렬
4. RAG 템플릿 적용 → 답변 : "TKT-20260115-003 은 iOS 15 이하 기기에서 푸시 토큰 갱신 실패가 원인이며, 조치는 ... 입니다. [출처: A사 모바일 앱 SM 2026Q1 티켓]"

### 질의 2. "Cordova 에서 Capacitor 로 전환할 때 주의사항"

1. Markdown Header Splitter ON 으로 `## 마이그레이션 주의사항` 섹션이 하나의 청크로 보존
2. Vector 비중이 크지만 Hybrid 가 자동 밸런싱
3. TopK 8 중 상위 4개 (리랭커 통과) 가 전부 해당 매뉴얼 섹션
4. 답변 : 5 ~ 6 포인트 요약 + [출처: Cordova-Capacitor 전환 매뉴얼.md, 3. 마이그레이션 주의사항]

### 질의 3. "공통 API 엔드포인트 전부 나열"

1. Enrich Hybrid Search Text ON 으로 "API", "엔드포인트", "인터페이스" 동의어 보강
2. TopK 8 전부 API 명세서의 표 청크
3. 답변 : 표 형식으로 endpoint 나열 (`POST /v1/auth/login` 등)

### 질의 4. "모바일 앱 보안 규약 제3조 내용"

1. BM25 우세 hit - "제3조" 정확 매칭
2. Chunk Overlap 150 덕분에 조항 제목과 본문이 한 청크에 보존
3. 답변 : "제3조 (인증) 은 ... [출처: MCNC 모바일 앱 보안 규약 2026, 제3조]"

### 질의 5. "파일 업로드 API 샘플 코드"

1. Markdown Header Splitter 가 ```` ``` ```` 코드 블록을 헤더 경계 안에 보존
2. Chunk Min Size Target 400 이 코드 블록 주변 해설과 코드를 함께 묶음
3. Vector 가 강하지만 Hybrid 로 "파일 업로드" 키워드 보완
4. 답변 : 코드 블록 그대로 + 설명 + [출처]

## 시연 전 검증 절차

Dify 에는 Knowledge 상세에 **Retrieval Testing** 탭이 있지만, Open WebUI 에는 이 기능이 없습니다. 대신 채팅에서 직접 확인합니다.

1. **Admin Panel → Settings → Documents** 에서 위 권장값 적용 → **Save**
2. 기존에 올려둔 Knowledge 가 있다면 **Knowledge 페이지 → 각 Knowledge → Reindex 버튼** 클릭 (청킹 관련 옵션 #1, #2, #3, #5, #6, #7, #8, #9 변경분은 재인덱싱 없이는 반영 안 됨)
3. Knowledge 생성 후 앞의 5개 질의를 채팅에서 실제로 쏴봄
4. 다른 터미널에서 임베딩 호출 기록 모니터링:

   ```bash
   docker compose logs -f litellm | grep -i embed
   ```

5. 답변에 `[출처: ...]` 인용이 붙는지 확인
6. Hybrid Search 를 OFF 로 토글 후 같은 질의 반복 → 식별자 질의에서 recall 차이 체감

통과 못 하면 조정 순서:

1. Chunk 크기 조정 (너무 크면 섞임, 너무 작으면 맥락 손실)
2. Markdown Header / Chunk Min Size Target 재검토
3. BM25 가중치 조정 (ID 정확 매칭 중요하면 0.6 ~ 0.7)
4. Top K · Top K Reranker 상향
5. Relevance Threshold 0.2 ~ 0.3 으로 노이즈 컷

## 변경 빈도 (운영 중 얼마나 자주 건드리나)

| 분류 | 항목 | 변경 시 영향 |
|---|---|---|
| **재인덱싱 필요** | #1 콘텐츠 추출 엔진, #2 PDF OCR, #3 PDF Loader, #5 Text Splitter, #6 Markdown Header, #7 Chunk Size, #8 Chunk Overlap, #9 Chunk Min Size Target, 임베딩 모델 | Knowledge 별 **Reindex 버튼** 필요 |
| **즉시 반영** | #4 Bypass, #10 Batch Size, #11 Async, #12 Concurrent, #13 Full Context, #14 Hybrid, #15 Enrich, #16 Reranking Engine, #17 Reranking Model, #18 Top K, #19 Top K Reranker, #20 Threshold, #21 BM25 Weight, #22 RAG Template | 저장 즉시 다음 질의부터 적용 |

재인덱싱이 필요한 9개 (Chunk 관련 + 임베딩 모델) 를 초기에 제대로 잡는 데 시간을 쓰는 게 이 문서의 목적입니다.

## 요약 - 최초 세팅 권장값 (복붙용)

Admin Panel → **Settings → Documents** 에서 위에서 아래로:

```
[일반]
- 콘텐츠 추출 엔진                    : Tika
- PDF 이미지 추출 (OCR)               : OFF
- PDF Loader Mode                     : default
- 임베딩 검색 우회                    : OFF
- 텍스트 나누기                       : token
- Markdown Header Text Splitter       : ON
- 청크 크기                           : 800
- 청크 중첩                           : 150
- Chunk Min Size Target               : 400

[임베딩 - 속도 우선 (일상 운영)]
- 임베딩 배치 크기                    : 32    (기본 유지)
- Async Embedding Processing          : ON
- Embedding Concurrent Requests       : 5

[임베딩 - 안정 우선 (최초 대량 업로드 시 전환)]
- 임베딩 배치 크기                    : 32    (동일 유지)
- Async Embedding Processing          : OFF   ← 변경
- Embedding Concurrent Requests       : 1     ← 변경
  (Bedrock Titan 429 스로틀링 회피. 적재 완료 후 위 속도 우선으로 복귀)

[검색]
- 전체 컨텍스트 모드                  : OFF
- 하이브리드 검색                     : ON
- Enrich Hybrid Search Text           : ON
- Reranking 엔진                      : (빈 값)   → Bedrock Cohere Rerank 승인 후 External 로 전환
- Reranking 모델                      : (빈 값)   → 전환 시 cohere-rerank (litellm_config.yaml 블록 주석 해제)
- External Reranker URL               : (빈 값)   → 전환 시 http://litellm:4000/v1/rerank
- External Reranker API Key           : (빈 값)   → 전환 시 ${LITELLM_MASTER_KEY}
- Top K                               : 8
- Top K 리랭커                        : 4
- 관련성 임계값                       : 0.0       → 검증 후 0.2 상향 가능
- BM25 가중치                         : 0.5       → 식별자 중요 시 0.6
- RAG 템플릿                          : (아래 한국어 커스텀 템플릿)

[임베딩 모델 (별도 탭, 이미 프리셋됨)]
- Embedding Model Engine              : OpenAI
- OpenAI API Base URL                 : http://litellm:4000/v1
- OpenAI API Key                      : ${LITELLM_MASTER_KEY}
- Embedding Model                     : titan-embed-v2
```

## 다음 단계

- 값 적용 후 막히면 → [06-troubleshooting.md](./06-troubleshooting.md) 의 "RAG 업로드 시 Embedding failed" · "Knowledge 조회는 되는데 답변에 반영이 안 됨" 항목 참고
- Dify 쪽 튜닝과 비교 시연 → [../../oss-hosting/docs/04-dify-rag-tuning.md](../../oss-hosting/docs/04-dify-rag-tuning.md) 의 Parent-child · weight_rerank 접근과 나란히 시연
- Bedrock Cohere Rerank Multilingual v3 승인 후: Reranking 엔진을 Cohere 로, 모델을 `rerank-multilingual-v3` 으로 전환 → Top K 리랭커 4 유지 → 답변 품질 재측정
- 로컬 임베딩 (BGE-M3) 전환 고려 시: `litellm_config.yaml` 에 Ollama model 섹션 추가 + Admin Panel 에서 Embedding Model 교체 → 전체 Knowledge 재인덱싱 필수
