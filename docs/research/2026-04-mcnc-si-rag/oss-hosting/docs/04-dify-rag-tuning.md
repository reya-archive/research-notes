# 04. Dify RAG 튜닝 - 한국어 SI 문서 기준

[03-post-install.md](./03-post-install.md) · [06-ollama.md](./06-ollama.md) 가 "단순 경로로 Dify 를 돌려보는" 가이드라면, 이 문서는 **Dify 의 RAG 기능을 제대로 활용하기 위해 Knowledge 생성 시 어떤 옵션을 어떻게 잡을지** 를 한국어 SI 사업 문서 기준으로 정리합니다.

Dify 공식 문서 (2026-04 기준) 의 실제 UI 필드명을 그대로 사용합니다.

## 왜 튜닝이 필요한가

Dify 의 Knowledge 는 생성 시점에 선택한 **Index Method · Chunk Mode · Retrieval Setting** 이 그대로 "파이프라인" 으로 고정됩니다. 일반 사용자는 이후 파일만 드래그하면 되지만, 이 값들을 관리자가 제대로 잡아두지 않으면 Dify 의 장점 (Parent-child · Hybrid + Rerank) 이 전혀 동작하지 않고 Open WebUI 수준의 flat RAG 가 됩니다.

즉 **Knowledge 첫 생성 30분이 이후 6개월 답변 품질을 결정** 합니다.

## 시뮬레이션 대상 문서 (전형적인 한국어 SI 자료 묶음)

아래와 같은 실제 현장 문서 구성을 가정합니다.

| 문서 종류 | 파일 예시 | 분량 | 특징 |
|---|---|---|---|
| 요구사항 정의서 | `차세대 ERP 구축 사업 - 요구사항정의서 v1.3.pdf` | 400p | 표 중심, REQ-F-xxx 식별자 반복 |
| 시스템 설계서 | `보건의료 정보시스템 기능설계서.pdf` | 250p | 다이어그램 · 인터페이스 표 |
| 기술 제안서 | `금융 데이터 플랫폼 기술제안서.pdf` | 180p | 아키텍처 설명 + 인력 투입 표 |
| 운영 매뉴얼 | `민원포털 운영자 매뉴얼.docx` | 120p | 화면 번호 · 절차형 문단 |
| 회의록 | `2026-03 1주차 주간회의록.docx` | 8p | 짧은 bullet + 결정사항 |
| 사내 규정 | `MCNC 정보보호 규정 2026 개정.pdf` | 60p | 조항 번호 "제1조" 체계 |

예상 질의 (사용자 입장):

- "REQ-F-015 의 응답시간 요건이 뭐야?" ← 표의 한 row 정확 매칭
- "회계 모듈 데이터 입력 흐름 설명해줘" ← 한 섹션 요약
- "인사 시스템과 연계되는 인터페이스 전부 나열해줘" ← 여러 섹션 종합
- "개인정보 파기 관련 규정 몇 조야?" ← 조항 번호 lookup
- "김팀장이 1주차 회의에서 결정한 마감일 언제야?" ← 회의록 단문 정확 매칭

이 질의들이 모두 정답을 내게 하려면 아래 튜닝이 필요합니다.

## 튜닝 포인트 6가지

Dify Knowledge 생성 화면에서 순서대로 마주치는 옵션들입니다.

### 1. Index Method - **High Quality** 선택

**Knowledge 생성 → Index Method** 섹션

| 옵션 | 의미 | 언제 |
|---|---|---|
| **High Quality** ✅ | 문서를 임베딩 모델로 벡터화해 Weaviate 에 저장. Vector / Full-Text / Hybrid Search 전부 사용 가능 | **SI 문서 전체. 기본 선택** |
| Economical | 임베딩 없이 inverted index 만 구축. 토큰 비용 0 이지만 의미 기반 검색 불가 (키워드 매칭만) | 비용 초소형 POC · 순수 키워드 lookup 만 쓸 때 |

Economical 을 고르면 이후 Retrieval Setting 에서 Hybrid · Vector 선택지가 사라지고 `Inverted Index` 로 고정됩니다. 이 문서의 튜닝은 전부 **High Quality 선택** 을 전제로 합니다.

### 2. Chunk Mode - **Parent-child** 선택

**Knowledge 생성 → Chunk Settings → Chunk Mode** 섹션

| 옵션 | 언제 |
|---|---|
| General (flat) | 짧은 문서 · FAQ · 단답형 Q&A |
| **Parent-child** ✅ | **위 SI 문서군 전체. 기본 선택** |

**왜 Parent-child 를 써야 하나**

한국어 SI 문서는 대부분 **표 · 조항 · 목록** 구조입니다. "REQ-F-015 응답시간" 질의에서:

- Child (작은 청크, 표의 한 row) 로 "REQ-F-015" 를 **정확히 찾음**
- Parent (큰 청크, 해당 표를 포함한 섹션 전체) 를 **LLM 에 컨텍스트로 전달**

General (flat) 청킹이면 큰 청크 안에 REQ 수백 개가 섞여 있어 LLM 이 15번 row 를 정확히 집지 못합니다.

### 3. Parent-child 세부 설정

Chunk Mode 에서 Parent-child 를 고르면 아래 필드들이 나타납니다.

#### Parent Chunk Mode

| 옵션 | 의미 | 언제 |
|---|---|---|
| **Paragraph** ✅ | 문서를 구분자 기준으로 문단/섹션 단위로 분할해 parent 로 사용 | **기본. SI 문서 대부분** |
| Full Doc | 문서 1개 전체 = parent 1개 | 짧은 규정 · 단일 섹션 문서 · parent 가 매우 커도 되는 케이스 |

400 페이지 요구사항정의서를 Full Doc 로 두면 LLM context 에 한 번에 못 들어갑니다. Paragraph 가 정답.

#### Chunk 크기 · 구분자 · Overlap

Dify 는 **character (문자 수)** 단위를 씁니다 (토큰 아님, 주의). max 4000.

| 필드 | Dify 기본값 | **한국어 SI 권장값** | 이유 |
|---|---|---|---|
| **Parent Maximum Chunk Length** | 500 | **3500** | 한 섹션 · 여러 문단 묶음 (조항/절 단위 보존) |
| Parent **Delimiter** | `\n\n` | `\n\n` + (필요 시) 커스텀 | 문단 경계 |
| **Child Maximum Chunk Length** | 200 | **500** | 한 문단 · 표 한 row |
| Child **Delimiter** | `\n` | `\n` | 줄 단위 |
| **Chunk Overlap** (child) | 50 | **80** | 경계 맥락 보존 |
| **Replace consecutive spaces, newlines and tabs** | ON | ON (그대로) | 전처리 정리 |
| **Remove all URLs and email addresses** | OFF | OFF (SI 문서에선 URL/메일도 정보) | - |

한국어 SI 문서에서 Dify 기본 200/500 은 너무 작아 조항 하나가 수십 조각으로 쪼개집니다. 3500/500 정도가 "한 섹션 = parent, 한 문단 = child" 수준으로 맞춰져 실전에 적합.

#### 구분자 정규식 힌트 (선택)

Delimiter 필드에 기본 `\n\n` 외에 한국어 SI 문서 특성상 추가해두면 좋은 패턴 (UI 지원 여부는 Dify 버전에 따라 다름 - 지원하지 않으면 `\n\n` 만):

- `제\d+조` (조항 경계)
- `\d+\.\d+` (목차 번호 1.1, 1.2)

UI 에 regex 지원 표시가 없으면 단순 `\n\n` 로 두고, Dify Knowledge Pipeline (1.x) 을 쓰면 더 세밀한 전처리 가능.

### 4. Embedding Model

**Knowledge 생성 → Embedding Model**

| 시나리오 | 선택 |
|---|---|
| 현재 (Bedrock 대기) | **`bge-m3` (Ollama)** |
| Bedrock 승인 후 비교 | `amazon.titan-embed-text-v2:0` 로 두 번째 Knowledge 생성해 병행 |

**bge-m3 를 쓰는 이유**

- 한국어 · 일본어 · 중국어 · 영어 혼용 문서에 강함
- 8192 token context 지원 (긴 parent chunk 3500 chars 도 한 번에 임베딩)
- 오픈소스 · 로컬 실행 · 사내 데이터 외부 유출 없음
- Dense + Sparse + Multi-vector 동시 출력 (Dify 가 Hybrid Search 에 활용)

> **주의**: Embedding Model 은 Knowledge 생성 이후 변경 불가입니다 (변경하려면 재생성 + 재임베딩). 시연 중 Ollama ↔ Bedrock 비교를 할 거면 지식베이스를 **두 개로 분리** 하세요 ([06-ollama.md](./06-ollama.md) 4) 참고).

### 5. Retrieval Setting - Hybrid Search

**Knowledge 생성 마지막 단계 → Retrieval Setting**  
(또는 이후 Knowledge 상세 화면 우상단에서 변경 가능 - Index Method / Chunk Mode 와 달리 이건 **런타임 변경 가능**)

| 필드 | 권장값 | 이유 |
|---|---|---|
| **Retrieval Method** | **Hybrid Search** ✅ | Vector (의미) + Full-text (키워드) 동시 |
| **Retrieval Strategy** | **`weight_rerank`** (Ollama 만 있을 때) / **`rerank_model`** (외부 Rerank 모델 있을 때) | 아래 설명 |
| **Semantic Value** | 0.5 | 의미 기반 가중치 |
| **Keyword Value** | 0.5 | "REQ-F-015" · "제3조" 같은 정확 매칭용 |
| **TopK** | **8** | Dify 기본 3. 한국어 recall 위해 올림 |
| **Score Threshold** | OFF (기본 0.5) | Rerank Model 전략일 때만 적용됨. 초기엔 OFF 권장 |

#### Retrieval Strategy 두 가지 중 선택

Dify 의 Hybrid Search 는 **retrieve 한 결과를 섞는 방식** 을 두 가지 중 고르게 되어 있습니다:

| 전략 | 동작 | 언제 |
|---|---|---|
| **`weight_rerank`** (Weighted Score Fusion) | 외부 Rerank 모델 없이 Semantic Value · Keyword Value 가중치로 점수 합산 · 정렬 | **Ollama 만 있는 현재**. 추가 인프라 필요 없음 |
| **`rerank_model`** (External Cross-Encoder) | 후보 청크를 외부 Rerank API (Cohere Rerank · BGE Reranker 등) 로 재정렬 | Bedrock 에 Cohere Rerank Multilingual v3 연결 가능할 때 |

`weight_rerank` 는 Dify 가 내부적으로 해주는 가중합이라 **외부 모델 의존 0** 이면서도 Hybrid 의 장점을 충분히 살립니다. 과거에 "Rerank 모델이 없으면 flat vector 로 회귀" 라고 알려진 것은 이 옵션 도입 전 얘기입니다.

**현 시점 권장**:
- Ollama 단독 기동 = `weight_rerank` + Semantic 0.5 / Keyword 0.5
- Bedrock 승인 + Cohere Rerank 연결 = `rerank_model` + Cohere Rerank Multilingual v3 + Score Threshold 0.3~0.5

#### Hybrid 가 꼭 필요한 이유 (한국어 SI 문서 특성)

- 고유 식별자 (`REQ-F-015`, `IF-ACCT-001`, `제23조`) 는 vector similarity 로 잘 안 잡힘 → Keyword 검색이 확실함
- 서술 질의 (`회계 모듈 흐름 설명해줘`) 는 반대로 vector 가 강함
- 반반씩 섞는 Hybrid 로 양쪽 다 커버

### 6. Metadata - 문서 카테고리 태깅

Dify Knowledge 는 파일마다 **Metadata** 를 수동/자동으로 붙일 수 있습니다. SI 프로젝트라면 최소 아래 3개 태그:

| Metadata key | 값 예시 |
|---|---|
| `doc_type` | `requirement` / `design` / `manual` / `meeting` / `policy` |
| `project` | `erp-2026` / `hmis-2025` / `fdp-2026` |
| `version` | `v1.3` / `2026-03-07` |

챗봇 앱의 **Context** 에서 이 Metadata 로 **필터**를 걸면 "인사 시스템 관련 설계서만 보고 답해" 같은 scoped 질의가 됩니다.

프로토타입 단계에서는 `doc_type` 하나만 수동 입력해도 충분합니다.

## 시뮬레이션 - 예상 질의별 RAG 동작

위 튜닝이 적용된 Knowledge 에 앞서 예시한 6개 문서를 넣었다고 가정.

### 질의 1. "REQ-F-015 응답시간 요건이 뭐야?"

1. Hybrid Search
   - Keyword: "REQ-F-015" 에 강한 hit → 요구사항정의서의 해당 row 를 정확히 찾음
   - Vector: 부족하지만 보완
2. Parent-child
   - Child = "REQ-F-015 | 주문 조회 | 평균 1.5초 이내 | 피크 3초" 같은 row
   - Parent = "3.2 성능 요구사항" 섹션 전체 (용어 정의 · 측정 조건 · 예외)
3. `weight_rerank` 로 상위 3~5개 → LLM
4. 답변 : "REQ-F-015 의 응답시간 요건은 평균 1.5초 이내 (피크 상황 3초 허용) 입니다. (출처: 요구사항정의서 v1.3, 3.2 성능 요구사항)"

### 질의 2. "회계 모듈 데이터 입력 흐름 설명해줘"

1. Vector 비중 큼 - "회계 모듈", "데이터 입력 흐름" 문맥 매칭
2. Parent-child
   - Child 여러 개 매칭 (입력 프로세스 단계별 문단)
   - 각 Parent 를 모아 LLM 에 전달 → 전체 흐름 서술
3. 답변 : 5단계 흐름 요약 + 출처 3개 인용

### 질의 3. "인사 시스템과 연계되는 인터페이스 전부 나열"

1. Hybrid - "인사", "인터페이스" · IF-HR 식별자 모두
2. TopK = 8 로 여러 row 확보 → `weight_rerank` 로 관련 인터페이스 6개만 상위
3. 답변 : IF-HR-001 ~ 006 표 형태 나열

### 질의 4. "개인정보 파기 관련 규정 몇 조야?"

1. Keyword 강 - "개인정보", "파기"
2. Child = "제18조 개인정보 파기 … " 단일 조항 hit
3. Parent = "제5장 개인정보 처리" 전체 컨텍스트
4. 답변 : "정보보호 규정 제18조 (개인정보 파기) 에 명시. 주요 내용: …"

### 질의 5. "김팀장이 1주차 회의에서 결정한 마감일?"

1. Vector + Keyword 둘 다 ("김팀장", "1주차", "마감일")
2. Child = 회의록의 결정사항 bullet 하나
3. Parent = 해당 회의록 전체
4. 답변 : 구체 날짜 + 회의록 링크

## 시연 전 검증 절차

Knowledge 생성 · 파일 업로드 후 **Retrieval Testing** 탭에서 위 5개 질의를 실제로 쏴보세요.

- Dify → Knowledge 상세 화면 → 우상단 **Retrieval Testing** 탭
- 질의 입력 → **Test** → 반환된 청크 목록 확인

검증 기준:

| 체크 | 통과 조건 |
|---|---|
| 질의 1 (정확 ID) | 최상위 청크에 정확히 REQ-F-015 포함 |
| 질의 3 (나열형) | TopK 8 안에 IF-HR-* 중 최소 5개 |
| 질의 4 (조항) | 최상위 청크가 제18조 |
| 질의 2, 5 (서술) | 상위 3개 중 최소 1개가 실제 정답 섹션 |

통과 못 하면 가장 흔한 조정 순서:

1. Chunk 크기 조정 (너무 크면 섞임, 너무 작으면 맥락 손실)
2. Delimiter 재검토 (구분자가 맞는지)
3. Semantic Value / Keyword Value 비율 조정 (ID 정확 매칭 중요하면 Keyword 0.6~0.7)
4. TopK 올리기

## 변경 빈도 (운영 중 얼마나 자주 건드리나)

| 항목 | 변경 가능성 | 변경 시 영향 |
|---|---|---|
| **Index Method** (High/Economical) | **거의 바꾸지 않음** | 전면 재인덱싱 |
| **Embedding Model** | **거의 바꾸지 않음** | 전면 재임베딩 |
| **Chunk Mode** (General ↔ Parent-child) | **거의 바꾸지 않음** | 전면 재청킹 |
| Chunk Length / Delimiter | 초기 튜닝 후 드물게 | 재청킹 (같은 Knowledge 내) |
| Retrieval Method / Strategy | 운영 중 조정 가능 | **즉시 반영** (재인덱싱 불필요) |
| Semantic / Keyword Value · TopK · Score Threshold | 언제든 변경 | **즉시 반영** |
| Metadata | 파일마다 개별 관리 | 개별 파일만 영향 |

**재인덱싱이 필요한 상위 3개 (Index Method · Embedding Model · Chunk Mode)** 를 초기에 잡는 데 시간을 쓰는 게 이 문서의 목적입니다.

## 요약 - 최초 세팅 권장값 (복붙용)

```
Knowledge 이름            : si-docs-main

[Index Method]
- High Quality ✅

[Embedding Model]
- bge-m3 (Ollama)
  (Bedrock 승인 후 비교용으로 titan-embed-text-v2:0 로 별도 Knowledge 생성)

[Chunk Settings]
- Chunk Mode                          : Parent-child
- Parent Chunk Mode                   : Paragraph
- Parent Maximum Chunk Length         : 3500   (문자 수, max 4000)
- Parent Delimiter                    : \n\n
- Child Maximum Chunk Length          : 500
- Child Delimiter                     : \n
- Chunk Overlap                       : 80
- Replace consecutive spaces...       : ON
- Remove all URLs and email addresses : OFF

[Retrieval Setting]
- Retrieval Method       : Hybrid Search
- Retrieval Strategy     : weight_rerank (Ollama 단독 시)
                           rerank_model (Cohere Rerank 연결 시)
- Semantic Value         : 0.5
- Keyword Value          : 0.5
- TopK                   : 8
- Score Threshold        : OFF  (rerank_model 전략일 때만 적용됨)

[Metadata 권장 키]
- doc_type, project, version
```

## 다음 단계

- Ollama 로 먼저 이 설정 적용 → 실측 → [05-troubleshooting.md](./05-troubleshooting.md) 참고
- Bedrock 승인 후: Embedding 을 Titan v2 로 전환한 두 번째 Knowledge 생성해 품질 비교 → [06-ollama.md](./06-ollama.md) 4) 의 "케이스별 지식베이스 분리" 참고
- Bedrock Cohere Rerank 연결이 되면 `Retrieval Strategy` 를 `rerank_model` 로 전환, Score Threshold 를 0.3~0.5 로 설정 후 답변 품질 재측정
