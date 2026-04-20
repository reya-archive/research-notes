# 04. Dify RAG 튜닝 - 한국어 SI 문서 기준

[03-post-install.md](./03-post-install.md) · [06-ollama.md](./06-ollama.md) 가 "단순 경로로 Dify 를 돌려보는" 가이드라면, 이 문서는 **Dify 의 RAG 기능을 제대로 활용하기 위해 Knowledge 생성 시 어떤 옵션을 어떻게 잡을지** 를 한국어 SI 사업 문서 기준으로 정리합니다.

## 왜 튜닝이 필요한가

Dify 의 Knowledge 는 생성 시점에 선택한 **Index Method · Retrieval Mode · Chunking · Rerank** 가 그대로 "파이프라인" 으로 고정됩니다. 일반 사용자는 이후 파일만 드래그하면 되지만, 이 4가지를 관리자가 제대로 잡아두지 않으면 Dify 의 장점 (Parent-Child · Hybrid + Rerank) 이 전혀 동작하지 않고 Open WebUI 수준의 flat RAG 가 됩니다.

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

## 튜닝 포인트 5가지

Dify Knowledge 생성 화면에서 순서대로 마주치는 옵션들입니다.

### 1. Index Method - Parent-Child 선택

**Knowledge 생성 → Chunk settings → Index Method**

| 옵션 | 언제 |
|---|---|
| General (flat) | 짧은 문서 · FAQ · 단답형 Q&A |
| **Parent-Child** ✅ | **위 SI 문서군 전체. 기본 선택** |

**왜 Parent-Child 를 써야 하나**

한국어 SI 문서는 대부분 **표 · 조항 · 목록** 구조입니다. "REQ-F-015 응답시간" 질의에서:

- Child (200~400 토큰, 표의 한 row) 로 "REQ-F-015" 를 **정확히 찾음**
- Parent (1500~2500 토큰, 해당 표를 포함한 섹션 전체) 를 **LLM 에 컨텍스트로 전달**

Flat 청킹이면 큰 청크 안에 REQ 수백 개가 섞여 있어 LLM 이 15번 row 를 정확히 집지 못합니다.

**권장 설정값** (한국어 기준):

| 필드 | 권장값 | 영어 기준 대비 |
|---|---|---|
| Parent Chunk Size | **1800 tokens** | 영어 2500 의 약 70% |
| Child Chunk Size | **300 tokens** | 영어 500 의 60% |
| Parent-Child Overlap | **100 tokens** | - |

한국어 토큰이 영어보다 조금 촘촘해 chunk size 를 60~70% 수준으로 낮춥니다.

### 2. Segmentation - 구분자 힌트

같은 화면의 **Segmentation** 항목:

- **Separator**: `\n\n` (기본) 외에 한국어 SI 문서에 자주 나오는 경계 문자 추가:
  - `제\d+조` (조항)
  - `\d+\.\d+` (목차 번호 1.1, 1.2)
  - `□ ` / `■ ` / `◎ ` (많이 쓰이는 bullet)
- **Max Chunk Length**: Parent Chunk Size 와 동일
- **Chunk Overlap**: 위의 100

구분자를 명시하면 "제1조 목적" 과 "제2조 정의" 가 잘못 한 청크에 붙어버리는 것을 막습니다.

### 3. Embedding Model

**Knowledge 생성 → Embedding Model**

| 시나리오 | 선택 |
|---|---|
| 현재 (Bedrock 대기) | **`bge-m3` (Ollama)** |
| Bedrock 승인 후 | `amazon.titan-embed-text-v2:0` 또는 유지 |

**bge-m3 를 쓰는 이유**

- 한국어 · 일본어 · 중국어 · 영어 혼용 문서에 강함
- 8192 token context 지원 (긴 parent chunk 도 한 번에 임베딩)
- 오픈소스 · 로컬 실행 · 사내 데이터 외부 유출 없음
- Dense + Sparse + Multi-vector 동시 출력 (Dify 가 Hybrid Search 에 활용)

> **주의**: 임베딩 모델을 바꾸면 기존 색인이 의미를 잃고 재임베딩이 필요합니다. 시연 중 Ollama ↔ Bedrock 비교를 할 거면 지식베이스를 **두 개로 분리** 하세요 ([06-ollama.md](./06-ollama.md) 4) 참고).

### 4. Retrieval Setting - Hybrid + Rerank

**Knowledge 생성 후 → Knowledge 상세 화면 → Retrieval Setting (우상단)** (또는 생성 마지막 단계)

| 필드 | 권장값 | 이유 |
|---|---|---|
| **Retrieval Method** | **Hybrid Search** ✅ | Vector(의미) + Full-text(키워드) 동시 |
| **Weight - Semantic** | 0.5 | 문맥 기반 유사도 |
| **Weight - Keyword** | 0.5 | "REQ-F-015" · "제3조" 같은 정확 매칭용 |
| **Top K** | **8** | 한국어 recall 을 위해 기본 3 보다 높게 |
| **Score Threshold** | OFF (또는 0.3) | 너무 높이면 결과 0 건, 처음엔 OFF 로 감 잡기 |
| **Rerank Model** | (가능하면) Cohere Rerank Multilingual v3 · BGE Reranker Large | Top-K 재정렬 |

**Hybrid 가 꼭 필요한 이유 (한국어 SI 문서 특성)**

- 고유 식별자 (`REQ-F-015`, `IF-ACCT-001`, `제23조`) 는 vector similarity 로 잘 안 잡힘 → Keyword 검색이 확실함
- 서술 질의 (`회계 모듈 흐름 설명해줘`) 는 반대로 vector 가 강함
- 반반씩 섞는 Hybrid 로 양쪽 다 커버

**Rerank 있으면 반드시 켜는 이유**

- Top K = 8 로 후보를 넉넉히 뽑은 뒤 **Rerank 로 상위 3~5 개만 LLM 에 전달**
- "Retrieve 를 많이, LLM 에 들어가는 컨텍스트는 적게" 가 한국어 SI 문서 기준 가장 안정적 패턴
- Rerank 모델이 없으면 OFF 하되, 그 경우 Top K 를 5로 낮추는 편이 나음

**현 시점 주의**: 사내 Ollama 에 Rerank 모델이 보통 없습니다. `ollama list` 에 `bge-reranker-*` 같은 게 없으면 Rerank 는 우선 OFF 로 두고, Bedrock 승인 후 **Cohere Rerank Multilingual v3** 를 Bedrock Provider 에 추가해 연결하는 걸 권장.

### 5. Metadata - 문서 카테고리 태깅

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
2. Parent-Child
   - Child = "REQ-F-015 | 주문 조회 | 평균 1.5초 이내 | 피크 3초" 같은 row
   - Parent = "3.2 성능 요구사항" 섹션 전체 (용어 정의 · 측정 조건 · 예외)
3. Rerank 상위 3개 → LLM
4. 답변 : "REQ-F-015 의 응답시간 요건은 평균 1.5초 이내 (피크 상황 3초 허용) 입니다. (출처: 요구사항정의서 v1.3, 3.2 성능 요구사항)"

### 질의 2. "회계 모듈 데이터 입력 흐름 설명해줘"

1. Vector 비중 큼 - "회계 모듈", "데이터 입력 흐름" 문맥 매칭
2. Parent-Child
   - Child 여러 개 매칭 (입력 프로세스 단계별 문단)
   - 각 Parent 를 모아 LLM 에 전달 → 전체 흐름 서술
3. 답변 : 5단계 흐름 요약 + 출처 3개 인용

### 질의 3. "인사 시스템과 연계되는 인터페이스 전부 나열"

1. Hybrid - "인사", "인터페이스" · IF-HR 식별자 모두
2. Top K = 8 로 여러 row 확보 → Rerank 로 관련 인터페이스 6개만 상위
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

Knowledge 생성 · 파일 업로드 후 **Retrieval Test** 탭에서 위 5개 질의를 실제로 쏴보세요.

- Dify → Knowledge 상세 화면 → 우상단 **Retrieval Testing** 탭
- 질의 입력 → **Test** → 반환된 청크 확인

검증 기준:

| 체크 | 통과 조건 |
|---|---|
| 질의 1 (정확 ID) | 최상위 청크에 정확히 REQ-F-015 포함 |
| 질의 3 (나열형) | Top 8 안에 IF-HR-* 중 최소 5개 |
| 질의 4 (조항) | 최상위 청크가 제18조 |
| 질의 2, 5 (서술) | 상위 3개 중 최소 1개가 실제 정답 섹션 |

통과 못 하면 가장 흔한 조정 순서:

1. Chunk Size 조정 (너무 크면 섞임, 너무 작으면 맥락 손실)
2. Separator 재검토
3. Weight - Semantic/Keyword 비율 바꾸기 (ID 정확 매칭 중요하면 Keyword 0.6~0.7)
4. Top K 올리기

## Knowledge 를 만든 뒤 건드리는 빈도

| 항목 | 변경 빈도 |
|---|---|
| Embedding Model | **거의 바꾸지 않음** (바꾸면 재임베딩) |
| Index Method (Parent-Child vs General) | **거의 바꾸지 않음** (재인덱싱) |
| Chunk Size / Separator | 초기 튜닝 후 드물게 |
| Retrieval Method / Weights | 운영 중 가볍게 조정 가능 |
| Top K / Rerank | 언제든 변경 · 즉시 반영 |
| Metadata | 파일마다 개별 관리 |

**재인덱싱이 필요한 상위 3개 (모델 · Index Method · Chunk Size)** 를 초기에 잡는 데 시간을 쓰는 게 이 문서의 목적입니다.

## 요약 - 최초 세팅 권장 값 (복붙용)

```
Knowledge 이름      : si-docs-main
Embedding Model     : bge-m3 (Ollama)   | 또는 titan-embed-text-v2:0 (Bedrock)
Index Method        : Parent-Child
  - Parent Chunk Size  : 1800
  - Child Chunk Size   : 300
  - Chunk Overlap      : 100
  - Separator          : "\n\n", "제\\d+조", "\\d+\\.\\d+"

Retrieval Method    : Hybrid Search
  - Semantic Weight    : 0.5
  - Keyword Weight     : 0.5
  - Top K              : 8
  - Score Threshold    : OFF (초기)
  - Rerank Model       : Cohere Rerank Multilingual v3 (Bedrock 승인 후) / OFF (지금)

Metadata 기본 키     : doc_type, project, version
```

## 다음 단계

- Ollama 로 먼저 이 설정 적용 → 실측 → [05-troubleshooting.md](./05-troubleshooting.md) 참고
- Bedrock 승인 후: Embedding 을 Titan v2 로 전환한 두 번째 Knowledge 생성해 품질 비교 → [06-ollama.md](./06-ollama.md) 4) 의 "케이스별 지식베이스 분리" 참고
- Bedrock Cohere Rerank 연결이 되면 Rerank ON 후 답변 품질 재측정
