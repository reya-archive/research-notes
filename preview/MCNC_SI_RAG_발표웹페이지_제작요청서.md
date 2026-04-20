# MCNC SI RAG 시스템 발표용 웹페이지 제작 요청서

## 📋 문서 목적

본 문서는 **MCNC 영업팀 및 의사결정권자 대상 발표**를 위한 웹페이지 제작을 LLM(Claude Code, Cursor 등 AI 개발 도구)에 요청하기 위한 요구사항 명세서입니다.

웹페이지는 **3가지 SI용 RAG 시스템 프로토타입**을 비교 소개하고, 각 제품을 **자세히 조사한 내용**을 시각적으로 전달하는 것을 목표로 합니다.

---

## 🎯 요청 사항 요약

다음 3가지 제품에 대해 **웹 검색 기반 최신 정보를 반영하여 조사**하고, 그 결과를 **사내 `research-notes` 레포(Private GitHub Pages)에 편입할 정적 리서치 페이지**로 제작해주세요. 빌드 도구 · 외부 CDN · 프레임워크 없이 **vanilla HTML/CSS/JS만** 사용합니다 (레포 `CLAUDE.md` 절대 원칙).

### 조사 대상 3개 제품

1. **Dify + Amazon Bedrock + Nextcloud** (OSS 셀프호스팅)
2. **Amazon Q Business** (AWS 관리형 SaaS, 시드니 리전)
3. **Gemini Enterprise + Google Drive** (Google 관리형 SaaS)

---

## 1. 프로젝트 배경 (웹페이지 맨 앞에 포함되어야 할 내용)

### 회사 소개

- **회사명**: MCNC
- **사업 영역**: 일반 민간 기업 대상 모바일/웹 SI (System Integration)
  - ⚠️ **공공/금융/국방 아님** - 조사 및 서술에서 해당 분야 언급 금지
- **주력 플랫폼**: 자체 개발 bizMOB Xross 프레임워크 (Vue 3 + Ionic Vue 7)
- **보유 역량**: Spring Boot, Vue 3, Python FastAPI, PostgreSQL/PGVector, Node.js MCP 서버, vLLM/Ollama, Open WebUI 기반 mcnc-rag 서비스

### 이 웹페이지의 목적

MCNC가 신규 SI 프로젝트에 반복적으로 투입할 **사내 LLM + RAG 시스템**을 선정하기 위해, 3가지 후보 제품을 프로토타입 검증 후 **사내 영업팀 및 결정권자에게 발표**하기 위한 자료. 고객사 공개 자료가 아니며, 접근은 `research-notes` Private 레포 권한자로 한정됨.

### 핵심 요구사항

- **규모**: 프로젝트당 **총 등록 사용자 약 50명** (SI 개발팀 + 협업팀 + SM 운영팀 누적), **동시 사용자 약 20~30명** (초기 분석/설계 단계 피크 기준). 구독 비용은 등록 사용자 기준, 리소스 사이징은 동시 사용자 기준으로 분리해 산정
- **운영 모델**: MCNC는 각 SI 프로젝트마다 **독립된 경량 인스턴스를 새로 구축**하여 해당 프로젝트 팀만 사용. 고객사 전체가 공유하는 통합 시스템이 아니므로, 고객사의 기존 클라우드 벤더(AWS/GCP/Azure)와 맞출 필요는 없음
- **데이터 규모**: 파일 약 591개, 폴더 125개, 총 용량 약 0.9GB (기획서·회의록·인수인계 문서 등, 폴더 평균 4.7 파일, 파일 평균 1.55MB, 이미지·도표 포함)
- **파일 형식 분포**(상위 비중): PPTX 37%, XLSX 26%, XML 18%, MD 6%, PDF 4%, 기타 9% → PPTX + XLSX가 **전체의 63%**를 차지하므로 Office 문서 파싱 품질이 핵심 평가 기준
- **제약 조건**:
  - 클라우드 기반
  - 데이터가 LLM 학습에 사용되지 않을 것 (3사 모두 약관으로 보장)
  - 계약비 내에서 저비용 유지
  - 반복 배포 가능한 패키징
  - SI → SM(유지보수)팀 이관 가능한 구조
- **결정권자**: 영업팀 (비개발자) - 따라서 **업로드 과정부터 시연 가능해야 함**

### 평가 범위와 한계

본 웹페이지는 **조사 · 비교 · 시연 자료**입니다. 제품 선택은 영업팀/상급자의 판단 영역이며, 실무자(MCNC 기술팀)는 다음 범위까지만 수행합니다.

- **수행 범위**: 검증 가능한 기준에 근거한 기술 팩트 비교 (가격, 스펙, 기능), 조건별 분기 가이드, 시연 시나리오 제공
- **수행하지 않는 것**: 단일 최종 권장안 제시, 제품 간 "어느 것이 더 낫다"는 주관적 종합 평가
- **별점의 성격**: 판단 재료이며 권장이 아님. 모든 별점은 평가 기준과 함께 표시되어야 함

---

## 2. 3개 제품 상세 조사 요구사항

각 제품별로 아래 항목을 **반드시 웹 검색으로 최신 정보(2026년 4월 기준)를 확인하여** 조사해주세요. 조사 결과는 웹페이지의 각 제품 상세 섹션에 반영됩니다.

### 공통 조사 항목 (3개 제품 모두)

1. **제품 개요**
   - 정식 명칭, 제공사, 출시 시기, 제품 카테고리
   - 한 줄 소개 및 핵심 가치 제안

2. **주요 기능**
   - RAG 엔진 / 문서 파싱 품질 (**특히 PPTX + XLSX 파싱 품질** - MCNC 데이터의 63% 비중)
   - 지원 파일 형식 및 최대 파일 수/용량
   - **특수 파일 형식 처리 지원 여부**
     - 오디오(m4a) - 음성→텍스트 transcription 지원 여부
     - 다이어그램(drawio, mmd) - 파싱 가능 여부, 이미지 변환 권장 여부
     - XML 테이블 정의 파일 - 구조화 데이터로 인식되는지
   - LLM 모델 선택지 (제품별 제공 모델)
   - 임베딩 모델
   - 폴더 구조 유지 여부
   - 검색 방식 (벡터 검색, 하이브리드, 키워드 등)
   - 권한 관리 및 인증 (SSO, IAM 연동)
   - 워크플로우/Agent 빌더 지원 여부

3. **가격 정책 (2026년 4월 기준)**
   - 사용자당 월 비용 (Lite/Pro/Business/Standard 등 티어별)
   - 인덱스/스토리지 비용
   - LLM 추론 비용 (토큰 단가)
   - 무료 트라이얼 조건 (기간, 사용자 수, 크레딧)
   - 연 약정 vs 월 약정 차이

4. **예상 총 비용 (2가지 시나리오)**
   - ※ 본 시나리오의 "명"은 §1 규모의 **총 등록 사용자 기준**. 동시 접속은 20~30명이지만 SaaS 구독비는 등록 인원당 과금되므로 등록 기준으로 산정
   - **기본 운영 기준**: 50명 × 6개월
   - **소규모 초기 운영 기준**: 10명 × 1개월
   - 원화 환산 포함 (환율 1USD = 1,500원 가정)
   - 최소·평균·최대 시나리오 제시

5. **데이터 처리 정책**
   - 데이터 학습 미사용 보장 약관

6. **보안 및 규정 준수**
   - 암호화 (KMS/CMEK 등)
   - VPC/네트워크 격리
   - 주요 인증 (ISO, SOC, HIPAA 등)

7. **강점 (장점 5가지)**

8. **약점 (단점 5가지)**

9. **공식 문서 / 레퍼런스 링크** (인용 출처)

### 제품별 추가 조사 항목

#### 🟧 Dify + Amazon Bedrock + Nextcloud

- **Dify 구조**: Docker Compose 기반 아키텍처, 내장 구성 요소 (Weaviate, Postgres, Redis 등)
- **LLM 연결 방식**: Bedrock API를 통한 Claude Sonnet 4 / Amazon Nova Pro 호출
- **Nextcloud 역할**: 드롭박스 스타일 파일 관리 UI로서 영업팀 업로드 시연 대응
- **동기화 메커니즘**: Nextcloud 폴더 ↔ Dify Knowledge Base 동기화 방법
- **라이선스**: Apache 2.0 - 상업적 사용 범위 확인 (MCNC는 프로젝트별 독립 인스턴스 운영 모델이므로 멀티테넌트 SaaS 제약은 해당 없음)
- **MCNC 기존 노하우 활용도**: mcnc-rag, Open WebUI, vLLM 경험과의 호환성
- **참고**: Dify는 WebUI + RAG 관리 + 워크플로우 + API 게이트웨이 역할만 하며, LLM은 외부 클라우드 API(Bedrock 등)를 호출하는 구조임을 명확히 설명

#### 🟦 Amazon Q Business

- **시드니 리전(ap-southeast-2) 사용 이유**: 서울 리전 미지원 현황 및 시드니 선택 배경
- **시드니에서 미지원되는 기능**: Q Apps, Q Actions, Audio/Video 등 구체적 목록
- **Lite ($3/user) vs Pro ($20/user) 차이**: 구체적 기능 차이
- **인덱스 타입**: Starter Index ($0.14/h, 최대 5유닛) vs Enterprise Index ($0.264/h) 차이와 591파일 규모에 적합한 타입
- **60일 무료 트라이얼 조건**: 50명, 1500 인덱스 시간 한도 상세
- **40+ 엔터프라이즈 커넥터**: 대표적 목록 (SharePoint, Confluence, Salesforce, ServiceNow 등)
- **권한 자동 상속 메커니즘**: IAM Identity Center 연동 방식
- **업로드 UX 제약**: S3 콘솔 업로드가 영업팀 시연에 부적합한 이유와 대안
- **MCNC 기존 노하우 활용도**: IAM Identity Center · AWS CDK/CloudFormation · Bedrock 등 AWS 기반 스택과의 호환성

#### 🟥 Gemini Enterprise + Google Drive

- **Gemini Enterprise vs NotebookLM vs Vertex AI Search 관계**: 계층 구조 명확화 (Gemini Enterprise = Agentspace 후신, 완제품 / Vertex AI Search = 그 하위 RAG 엔진 / NotebookLM Enterprise = 부가 기능)
- **6개 핵심 컴포넌트**: Gemini 모델, Agent Workbench, 사전 제작 에이전트, 데이터 커넥터, Agent Gallery, 거버넌스
- **에디션 비교**: Business($21), Standard($30 연약정/$35 월약정), Plus($30~60), Frontline
- **Google Drive Cataloging**: Gemini Enterprise에서는 정식 GA 상태 (Vertex AI Search 단독에서는 Preview+Allowlist였음)
- **30일 무료 트라이얼 조건**: Business 300명 한도, Standard/Plus 무제한
- **리전**: 한국 없음, 도쿄/싱가포르/global multi-region 중 권장
- **Gemini 3 Pro 컨텍스트**: 1M~2M 토큰 컨텍스트 윈도우의 실제 의미
- **Document AI 품질**: 복잡한 기획서/화면설계서 파싱 품질이 3사 중 최상인 이유
- **Deep Research 에이전트**: 내부 문서 기반 자동 리서치 기능
- **주의사항**: NotebookLM Plus (Workspace 번들)와 Gemini Enterprise NotebookLM은 다른 제품임을 명확히 구분
- **MCNC 기존 노하우 활용도**: Google Workspace · GCP · Vertex AI 기반 스택과의 호환성

---

## 3. 제품 간 비교 매트릭스 (웹페이지 핵심 섹션)

웹페이지 중앙에 **3개 제품을 나란히 비교하는 인터랙티브 표**를 배치해주세요.

### 비교 카테고리

| 카테고리 | 세부 항목 |
|---|---|
| **기본 정보** | 제품 유형, 제공사, 카테고리, 출시 |
| **가격** | 사용자당 월 단가, 인덱스 비용, 10명×1개월 총비용, 50명×6개월 총비용, 무료 트라이얼 |
| **인프라** | 배포 리전, 운영 책임 모델 |
| **기능** | LLM 모델 선택, 문서 수 제한, 폴더 구조, 커넥터 수, 워크플로우 |
| **시연 친숙도** | 업로드 UX, 영업팀 시연 가능성, 결정권자 평가 관점 |
| **SI 적합도** | 반복 배포 용이성, SM 이관 용이성, 프로젝트 간 이식성(신규 프로젝트에 패키지 그대로 재사용 가능 여부) |
| **커스터마이징** | UI 변경, 브랜딩, 워크플로우 확장, 사내 시스템 연동 |
| **보안** | 데이터 학습 미사용, 암호화, VPC, 인증 |
| **MCNC 노하우 활용도** | 기존 기술 스택과의 호환성 |

### 평가 방식

- **별점(★) 시스템**: 1~5점으로 시각화. 단, **주관적 "종합 평가" 별점은 금지**하며, 모든 별점 항목은 **평가 기준을 함께 명시**해야 함
  - 예: 업로드 UX = "파일 업로드 완료까지의 클릭/단계 수" 기준
  - 예: 문서 파싱 품질 = "샘플 기획서/화면설계서 테스트 결과" 기준
  - 예: 반복 배포 용이성 = "신규 프로젝트 투입 시 셋업 시간" 기준
- **컬러 하이라이트**: 각 항목별 최고 제품에 자동 강조 (검증 가능한 수치 기반 항목에 한함)
- **필터링**: 사용자가 카테고리별로 접고 펼 수 있어야 함

---

## 4. 웹페이지 구성 요구사항

### 4.1 전체 구조 (추천 섹션 순서)

1. **페이지 헤더** (`main.css`의 `.page-header` 구조 활용)
   - `.page-header__eyebrow`: "2026-04 · MCNC SI RAG"
   - `.page-header__title`: "MCNC SI RAG 시스템 프로토타입 검증 결과"
   - `.page-header__lede`: "3가지 접근 방식을 동일 기준으로 비교"
   - 3개 제품 아이콘(인라인 SVG) 나란히 표시
   - 내부 섹션 앵커 링크: "비교 매트릭스로 이동" / "제품별 상세"

2. **배경 및 요구사항 섹션**
   - MCNC 상황 요약 (§1 내용)
   - 핵심 제약 조건 카드 형태로 표시
   - 실제 데이터 규모 시각화 (591 파일 / 0.9GB 인포그래픽)

3. **3개 제품 개요 섹션** (한 화면에 3컬럼 카드)
   - 각 카드: 제품명, 한 줄 소개, 카테고리 태그(OSS/AWS SaaS/Google SaaS), 대표 강점 3가지, "자세히 보기" 버튼

4. **제품별 상세 조사 결과** (제품마다 1개 섹션씩, 총 3개)
   - §2의 공통 조사 항목 전체 반영
   - 아키텍처 다이어그램 (텍스트 기반 또는 간단한 SVG)
   - 비용 계산 카드
   - 강점/약점 대비
   - 공식 문서 링크

5. **비교 매트릭스 섹션** (§3 내용)
   - 인터랙티브 비교표
   - 카테고리별 필터링

6. **영업팀 시연 관점 평가 섹션**
   - 업로드 과정 시연 가능성을 ★로 표시
   - 각 제품별 10분 시연 시나리오 요약
   - 표준 질문 5가지 예시 (실제 폴더 구조 기반, 각 질문에 **기대 답변 예시**를 함께 표시해 시연 성공 기준 명확화):
     1. "프로젝트 핵심 목표와 TO-BE 방향은?" (요약, `01.분석(AS-IS)` + `02.설계(TO-BE)`)
        - 기대 답변 예: "AS-IS는 Rule이 코드에 하드코딩된 구조. TO-BE는 Rule을 데이터로 분리 · 외부화하여 비개발자도 관리 가능한 구조로 전환"
     2. "최근 주간회의에서 결정된 사항 3가지는?" (날짜/회의록 검색, `99.관리/주간보고`)
        - 기대 답변 예: "① 교문사업부 상품 프로세스 정리 일정 확정, ② API 정의서 1차 리뷰 진행, ③ 시스템 구성도 초안 공유"
     3. "TO-BE Rule 기반 구조의 핵심 변경점은?" (설계서 파싱, `02.설계(TO-BE)/06.2_Rule구조설계`)
        - 기대 답변 예: "Rule 엔진 도입, 조건-액션 테이블 기반의 데이터 구조화, UI/API 분리"
     4. "교문사업부와 온라인사업부의 업무 차이는?" (분류, `01.분석(AS-IS)` 사업부별 폴더)
        - 기대 답변 예: "교문사업부는 오프라인 유통 · 도서 상품 중심, 온라인사업부는 디지털 구독 · 멤버십 중심의 프로세스"
     5. "착수 단계의 주요 산출물 목록은?" (구체 정보 검색, `99.산출물/01_착수`)
        - 기대 답변 예: "착수보고서, 프로젝트 실행 계획서, 투입 인력 계획서, 리스크 관리 계획서 등"

7. **프로토타입 비용 및 일정 섹션**
   - 프로토타입 구축 예상 비용 (약 ₩25,000~50,000, 환율 1USD = 1,500원 기준. 3개 제품을 각각 **무료 트라이얼 기간 내에 구축**하고 일부 유료 기능 검증 시 예상되는 **소액 과금**(Bedrock 토큰 사용, 임베딩 호출 등)만을 상정)
   - 2주 구축 일정표 (간트차트 형태)

8. **FAQ / 예상 질문 섹션**
    - "왜 Claude Team은 제외되었는가?"
    - "왜 Azure OpenAI는 제외되었는가?"
    - "SI 후 SM 이관은 어떻게 되는가?"
    - "업로드한 문서가 LLM 학습에 재사용되지 않는가?"
    - "프로젝트 종료 후 인스턴스/데이터 정리는 어떻게 되나?"
    - "3개 중 1개만 선택해서 쓸 건지, 프로젝트마다 다른 제품을 쓸 수도 있는 건지?"

9. **Footer**
    - 작성자, 작성일 (2026년 4월)
    - 참고 문서 링크

### 4.2 디자인 가이드라인

- **전체 톤**: 레포 `CLAUDE.md` 기준 - 미니멀, 회사 보고용, 화이트/그레이 + 단일 링크 색(`--color-link`). 그림자/애니메이션은 150ms hover transition 수준까지만
- **색상 팔레트**:
  - **배경·본문**: 화이트/그레이 유지 (`--color-bg`, `--color-surface`, `--color-text` 등 기존 토큰 사용)
  - **링크/강조**: `--color-link` 한 가지
  - **제품 구분 색**: 태그/배지/차트 범례 등 **국소 지점에만** 소극적으로 사용 (전면 Primary/Accent로 쓰지 말 것)
    - Dify 계열: 주황 톤
    - Q Business 계열: AWS 다크네이비 톤
    - Gemini Enterprise 계열: Google 블루 톤
- **타이포그래피**: `main.css`의 `--font-sans` 토큰을 그대로 상속 (별도 폰트 선언 불필요, 외부 웹 폰트/폰트 CDN 로드 금지)
- **레이아웃**:
  - 반응형 (데스크톱 우선, 태블릿/모바일 대응)
  - 페이지 폭은 `var(--max-page)` (1080px), 본문 가독 영역은 `var(--max-content)` (760px) 기준
  - 간격은 8px 그리드 `--space-*` 토큰 재사용
- **시각 요소** (외부 라이브러리 · CDN 금지):
  - 아이콘: 인라인 SVG 직접 삽입 (아이콘 패키지 로드 금지)
  - 차트: 인라인 SVG 또는 순수 HTML/CSS 기반 막대 (Recharts/Chart.js 등 외부 스크립트 금지)
  - 아키텍처 다이어그램: 인라인 SVG 정적 삽입 (Mermaid 사용 시 사전 변환한 SVG만 포함)
  - **제품 UI 이미지**: 공식 마케팅 이미지/문서 캡처만 사용 (직접 캡처·2차 가공 금지, 저작권 준수)
- **인터랙션**:
  - 부드러운 스크롤
  - 섹션 이동 네비게이션 (상단 고정)
  - 비교표 필터링
  - 호버 효과 (150ms 배경색 수준)

### 4.3 기술 스택

- **사용 가능**: vanilla HTML / CSS / JavaScript (ES2017+, 모듈 시스템 없이 `<script>` 태그로만 로드)
- **금지**:
  - 빌드 도구: npm, webpack, vite, sass, postcss 등 (`package.json` 생성 금지)
  - 외부 CDN: Tailwind CDN, Bootstrap, jQuery, 웹 폰트 CDN 등
  - 프레임워크/라이브러리: Next.js, React, Vue, Alpine.js, shadcn/ui 등
  - 트랜스파일러 일체
- **준수 규칙** (`research-notes` 레포):
  - `<base href="/research-notes/">` 모든 HTML에 포함
  - `<meta name="robots" content="noindex, nofollow, noarchive">` 모든 HTML에 포함 (사내 Private 자료 - `/validate-research-site` skill이 누락 시 FAIL 처리)
  - `<title>` 포맷: `"<페이지 제목> - Research Notes"`
  - 공통 header/footer는 `<div data-include="assets/partials/header.tpl"></div>` · `footer.tpl` + `<script src="assets/js/include.js"></script>` 방식으로 주입 (직접 마크업 금지). `<body data-include-pending>` 속성 유지
  - partial 파일은 반드시 `.tpl` 확장자 (`.html`이면 Live Server가 hang)
  - 공통 스타일은 `docs/assets/css/main.css`의 디자인 토큰(`--color-*`, `--space-*`, `--max-page`, `--font-sans` 등) 재사용. 색상/간격 직접 하드코딩 금지
  - 기존 컴포넌트 클래스 **재사용 우선**: `.page`, `.page--narrow`, `.breadcrumb`, `.page-header__eyebrow/__title/__lede`, `.prose`, `.section-title`, `.download-btn`, `.tag`, `.card`. 신규 클래스는 폴더 ID prefix 권장 (`.r-2026-04-mcnc-si-rag__...`)
  - 리서치별 커스텀은 `docs/research/2026-04-mcnc-si-rag/assets/style.css`, `assets/script.js`에 작성
- **데이터**: 비교 매트릭스 · 비용 · FAQ 등은 JSON 파일 또는 HTML 하드코딩으로 포함. 백엔드 없음
- **상세 가이드**: 레포 루트의 `README.md`, `CLAUDE.md` 준수. 기존 구현 레퍼런스는 `docs/research/2026-04-example-topic/index.html` 참조

### 4.4 배포 및 접근 제한

- **호스팅**: `main` 브랜치의 `docs/` 폴더가 Private GitHub Pages로 자동 배포됨. 별도 빌드/배포 파이프라인 없음
- **배치 위치**: `docs/research/2026-04-mcnc-si-rag/` (레포 규칙: `YYYY-MM-slug`)
- **manifest 등록**: `docs/data/manifest.json`에 항목 1건 추가 (id, title, summary, date, tags, path, pages 스키마)
- **접근 제한**: Private 레포 + Pages 조합으로 **MCNC 조직 멤버만 접근 가능**. 고객사 공개 자료 아님, URL 공유도 사내 한정
- **로컬 검증**: VSCode Live Server로 `http://127.0.0.1:5500/research-notes/` 접근 (워크스페이스에 mount 매핑 사전 설정됨, 상세 절차는 `README.md` 참고)

### 4.5 접근성 및 품질

- WCAG AA 수준 준수
- 키보드 네비게이션 지원
- 이미지 alt 텍스트
- 한국어 lang 속성 적용
- 인쇄 시 깔끔한 레이아웃 (사내 오프라인 회의에서 PDF로 공유 가능하도록). 공통 `main.css`에는 `@media print` 규칙이 없으므로 리서치별 `assets/style.css`에 인쇄 스타일 추가

---

## 5. 콘텐츠 작성 톤 & 원칙

1. **비개발자 친화적 용어 사용**
   - RAG → "문서 기반 검색 AI"
   - Embedding → "의미 분석"
   - Vector DB → "검색용 데이터베이스"
   - 단, 기술 용어는 첫 등장 시 괄호로 병기

2. **객관적 비교**
   - 특정 제품에 과도하게 치우치지 않기
   - 단점도 명확히 기술
   - **단일 최종 권장안은 포함하지 않음**. 제품 선택은 영업팀/상급자의 판단 영역이며, 본 문서는 판단 재료만 제공

3. **숫자 기반 근거 중심**
   - 모든 가격/용량/일정은 구체적 숫자로 표시
   - 추정치는 "약", "대략"으로 명시
   - 출처 각주 필수

4. **한국어 작성**
   - 모든 UI 텍스트와 설명은 한국어
   - 제품명, 고유명사는 원문 유지 (예: Amazon Q Business, Gemini Enterprise)
   - 필요 시 영문 병기

5. **MCNC SI 사업 관점 일관성**
   - 모든 평가 기준은 "MCNC가 반복 구축하는 SI 프로젝트에 적합한가"
   - 공공/금융/국방 사례 언급 금지
   - 민간 기업 일반 SI 맥락 유지

---

## 6. 인용 및 출처 처리

- 모든 가격, 기능, 정책 정보는 **공식 문서 또는 최신 블로그/뉴스(2026년 4월 기준)**를 출처로 인용
- 각 주장에 대해 `[출처: Amazon Q Business Pricing, AWS 공식 문서]` 형식의 각주 또는 hover 툴팁 제공
- 공식 문서 URL은 Footer의 "참고 자료" 섹션에 모아서 표시
- 직접 인용은 15단어 미만, 한 소스당 최대 1개만 사용 (저작권 준수)

---

## 7. 산출물

다음을 산출물로 제출해주세요:

1. **리서치 폴더**: `docs/research/2026-04-mcnc-si-rag/`
   - `index.html` (화면 진입점, `<base href="/research-notes/">` 포함)
   - `assets/style.css`, `assets/script.js`
   - (필요 시) `pages/NN-*.html` 다중 페이지, `notes/NN-*.md` 조사 원본
2. **manifest 항목**: `docs/data/manifest.json`에 해당 리서치 항목 1건 추가
3. **데이터 JSON** (선택) - 3개 제품 정보를 `products.json` 등으로 분리해 `docs/research/2026-04-mcnc-si-rag/assets/` 하위 배치
4. **스크린샷** (선택) - 주요 섹션 3~5장 (`assets/img/` 하위)
5. **조사 과정 요약** - `notes/` 하위 Markdown으로 작성

---

## 8. 작업 순서 제안

LLM 작업 순서는 다음과 같이 진행해주세요:

1. **Phase 1: 조사** (웹 검색 기반)
   - 3개 제품 공식 문서 확인
   - 2026년 4월 기준 가격 확인
   - 최신 기능 변경 사항 확인
   - 조사 결과를 마크다운으로 먼저 정리

2. **Phase 2: 구조 설계**
   - 위 4.1 섹션 구성에 따라 와이어프레임 스케치
   - 비교 매트릭스 데이터 구조 설계
   - 사용할 컴포넌트 목록 작성

3. **Phase 3: 구현**
   - **권장**: `/new-research 2026-04-mcnc-si-rag` skill 실행 (폴더 복사 + `research/_template/` → `research/2026-04-mcnc-si-rag/` 경로 치환 + `manifest.json` 항목 추가까지 자동 처리)
   - **수동 진행 시**: `docs/research/_template/` 복사 → `docs/research/2026-04-mcnc-si-rag/`로 rename한 뒤, 폴더 내 HTML/CSS/JS/MD의 `research/_template/` 문자열을 `research/2026-04-mcnc-si-rag/`로 일괄 치환하고 `docs/data/manifest.json`에 항목 append
   - vanilla HTML/CSS/JS 작성 (base href · noindex 메타 · `.tpl` partial 주입 · 기존 컴포넌트 클래스/디자인 토큰 재사용 규칙 준수)
   - 반응형 레이아웃 + vanilla JS 인터랙션 구현
   - `/validate-research-site` skill로 무결성 정적 검사

4. **Phase 4: 검증**
   - 모든 링크 동작 확인
   - 숫자/가격 크로스체크
   - 모바일/태블릿/데스크톱 반응형 테스트

5. **Phase 5: 산출물 제출**
   - 최종 파일 정리
   - 조사 과정 요약 문서 작성 (`notes/` 하위 Markdown)

---

## 9. 제외 사항 (중요)

다음 내용은 **포함하지 말아주세요**:

- ❌ 공공, 금융, 국방 분야 사례나 용어
- ❌ Claude Team/Enterprise 비교 (이미 부적합 결론, 별도 섹션에서 FAQ로만 간단히 언급)
- ❌ Azure OpenAI / Microsoft 365 Copilot 비교 (범위 외)
- ❌ NotebookLM 단독 제품 (Gemini Enterprise에 내장된 NotebookLM Enterprise만 다룸)
- ❌ HyperCLOVA X 등 국산 LLM (범위 외)
- ❌ 벤처 추천/제휴 문구
- ❌ 실무자가 제시하는 단일 최종 권장안
- ❌ 고객사 환경별 매칭 가이드 (MCNC는 프로젝트별 독립 구축 모델이므로 불필요)

---

## 10. 예상 작업 규모

- **조사**: 2~4시간 (웹 검색 기반)
- **구현**: 4~8시간 (단일 HTML 기준)
- **총 예상**: 6~12시간

---

## 11. 문의

추가 요청 사항이나 불명확한 부분이 있으면 작업 시작 전에 질문해주세요. 특히:

- 특정 섹션의 우선순위 조정 필요 여부
- 기술 스택 변경 요청
- 추가/제외할 내용
- 디자인 레퍼런스 제공 가능 여부

---

**작성자**: 최명훈 (MCNC)
**작성일**: 2026년 4월 14일 (최초), 2026년 4월 15일 (최신 수정)
**문서 버전**: v1.4
