# Gemini Enterprise + Google Drive

> 작성일: 2026-04-15
> 조사 기준일: 2026년 4월
> 환율: 1 USD = 1,500 KRW

## 제품 개요

- **정식 명칭**: Gemini Enterprise
- **제공사**: Google Cloud
- **출시**: 2025년 말 GA (Google Agentspace의 후신 · 리브랜딩)
- **카테고리**: Google 관리형 SaaS 엔터프라이즈 AI 에이전트 플랫폼
- **한 줄 소개**: Gemini Pro 계열 LLM + Vertex AI Search + NotebookLM Enterprise + Agent Builder가 결합된 완제품
- **핵심 가치 제안**: 1M 토큰 컨텍스트, 최고 수준의 Document AI 파싱 품질, Google Workspace(Drive) 네이티브 연동

## 제품 계층 구조 명확화

**중요**: 유사 제품들의 관계 혼동이 잦음

| 계층 | 제품 | 역할 |
|---|---|---|
| **플랫폼(완제품)** | **Gemini Enterprise** | 사용자 대상 엔터프라이즈 AI 어시스턴트. Agentspace의 후신 |
| 런타임/빌더 | Vertex AI Agent Builder | 에이전트 개발·배포·관찰 SDK/플랫폼 (개발자 대상) |
| RAG 엔진 | Vertex AI Search | Gemini Enterprise의 하위 검색 엔진 |
| 리서치 UI | NotebookLM Enterprise | Gemini Enterprise 번들에 포함된 리서치 에이전트 |
| Workspace 번들 | NotebookLM Plus | **별도 제품**. Gemini Enterprise NotebookLM과 혼동 금지 |
| 소비자 플랜 | Google AI Pro / Ultra | 개인용. 본 조사 범위 밖 |

## 6개 핵심 컴포넌트

1. **Gemini 모델**: Gemini Pro 계열 (1M 토큰 컨텍스트, 최대 64K 출력), Gemini Flash 계열 등 - 세대 주기적 갱신
2. **Agent Workbench**: 에이전트 설계·오케스트레이션 UI
3. **사전 제작 에이전트**: Deep Research, NotebookLM, Idea Generation 등 즉시 사용 가능
4. **데이터 커넥터**: 100+ 엔터프라이즈 앱 연결 (Google Drive, Workspace, Vertex AI Search, Apigee 등)
5. **Agent Gallery**: 사내 에이전트 공유·큐레이션
6. **거버넌스**: 권한 인식 검색(permission-aware search), 감사 로그, 데이터 상주

## 주요 기능

### RAG 엔진 / 문서 파싱
- **파싱 엔진**: Google Document AI (기업 문서 파싱 특화). 레이아웃 이해·표 구조·도형 인식 최강
- 지원 포맷: PDF, DOCX, PPTX, XLSX, TXT, HTML, MD, CSV, JSON, 이미지(OCR), 오디오, 비디오
- **PPTX/XLSX 파싱 품질**:
  - **3사 중 최상위** (복잡한 기획서 · 화면설계서 · 표 많은 Excel)
  - Gemini Pro 계열의 1M 토큰 컨텍스트로 대용량 문서를 통째로 이해 가능
  - Document AI는 텍스트뿐 아니라 시각적 레이아웃 · 도형 · 차트 라벨까지 인식
- 청킹/리랭킹: 자동 최적화 (관리형)

### 특수 파일 형식
- **오디오 (m4a)**: 네이티브 지원. 음성 → 텍스트 자동 전사. 다국어(한국어 포함)
- **다이어그램 (drawio, mmd)**: 이미지 파싱 경로로 처리. PNG 사전 변환 시 라벨 추출 가능
- **XML 테이블**: 구조 이해 능력이 3사 중 가장 우수 (1M 컨텍스트 + Gemini 구조 이해)

### LLM / 임베딩
- **LLM**: Gemini Pro 계열 (기본), Gemini Flash 계열 (저비용). 사용자 선택 가능
- **임베딩**: Google 자체 (gemini-embedding 계열, 관리형)

### 기타
- **폴더 구조**: Google Drive 구조 그대로 반영. 125개 폴더 트리 보존 가능 - **강점**
- **검색 방식**: 시맨틱 + 키워드 하이브리드 + 권한 인식 (관리형)
- **권한/SSO**: Google Workspace SSO 네이티브. IAM도 가능
- **워크플로우/Agent**: Agent Workbench + Agent Gallery. Vertex AI Agent Builder 통해 확장

## Google Drive Cataloging

- Gemini Enterprise에서는 **정식 GA 상태** (2025년 말)
- Vertex AI Search 단독 사용 시에는 Preview + Allowlist 필요했으나, Gemini Enterprise 번들에서는 제약 해제
- Drive 폴더를 Data Store로 등록하면 권한 인식 상태에서 검색 가능

## 가격 정책 (2026-04)

### 에디션 (사용자당 월)
- **Business**: **$21/user/mo** (연 약정 기준). 중소기업 · 부서 단위 권장
- **Standard**: **$30/mo 연 약정** / **$35/mo 월 약정**. 중견기업 전사
- **Plus**: **$30~60/mo** (범위). 대기업 확장 기능
- **Frontline**: 현장 근로자 전용 저가 티어
- **볼륨 할인**: 500명 이상 10~20% 협의

### 무료 트라이얼
- **Business 에디션 30일 무료** (이메일만으로 시작 가능, IT 셋업 불필요)
- Business 트라이얼 후 Starter(무료 티어)로 계속 사용 가능
- Standard/Plus는 Google Cloud 영업 연락으로 트라이얼 협의

### LLM 추론 비용
- Gemini Enterprise 구독에 LLM 사용 포함 (별도 토큰 과금 없음, 공정 사용 정책 내)
- Vertex AI 직접 호출 시에는 토큰 단가 별도 (입력 $1.25/1M, 출력 $5/1M 수준)

### 리전 (한국 없음)
- 아시아: **도쿄(asia-northeast1)**, **싱가포르(asia-southeast1)**, **global multi-region**
- MCNC 관점 권장: **도쿄** (한국 근접, 지연 30~50ms)

## 예상 총 비용 (2 시나리오)

### 시나리오 A: 기본 운영 50명 × 6개월
- Business $21 × 50 × 6 = **$6,300** (약 **₩9,450,000**)
- Standard $30 × 50 × 6 = **$9,000** (약 **₩13,500,000**)
- Plus $50 × 50 × 6 = **$15,000** (약 **₩22,500,000**)
- **최소 (Business 연약정)**: $6,300 (약 ₩945만)
- **평균 (Standard 연약정)**: $9,000 (약 ₩1,350만)
- **최대 (Plus 평균가)**: $15,000 (약 ₩2,250만)

### 시나리오 B: 소규모 초기 운영 10명 × 1개월
- Business $21 × 10 × 1 = **$210** (약 **₩315,000**) → 30일 무료로 $0 가능
- Standard $35(월약정) × 10 × 1 = **$350** (약 **₩525,000**)
- Plus $50 × 10 × 1 = **$500** (약 **₩750,000**)
- **최소**: $0 (Business 트라이얼 내) ~ $210
- **평균**: $350
- **최대**: $500

### 프로토타입 비용
- Business 30일 무료로 실질 $0 가능 (300명 한도 내)
- Standard/Plus 검증은 Google Cloud 영업 협의

## 데이터 처리 정책

- **Google 약관**: 고객 데이터를 모델 학습에 사용하지 않음 (기본 설정)
- 처리 데이터는 조직이 지정한 리전에 저장
- Vertex AI Search 데이터 암호화 (전송 중 · 저장 중)

## 보안 및 규정 준수

- **암호화**: 기본 Google 관리 키. **CMEK (Customer-Managed Encryption Keys)** 지원 (Standard/Plus)
- **VPC Service Controls**: 지원
- **인증**: ISO 27001/17/18, SOC 1/2/3, HIPAA, FedRAMP High (미국 리전), PCI DSS
- **데이터 상주**: 도쿄 리전 기준 일본 내 저장. "한국 내 저장" 요구 시 부적합

## 강점 5가지

1. **Document AI 파싱 품질 최상위**: MCNC 데이터의 63% 비중을 차지하는 PPTX/XLSX 인식에서 3사 중 가장 우수. 복잡 기획서 · 화면설계서에 강점
2. **1M~2M 토큰 컨텍스트**: Gemini Pro 계열의 대용량 컨텍스트로 폴더 전체를 한 번에 이해 가능. 긴 회의록·문서 여러 개 동시 질의 가능
3. **NotebookLM 내장**: "여러 문서 리서치" UX가 즉시 사용 가능. 영업팀 친숙도 높음 (소비자 제품 인지도)
4. **Google Drive 네이티브**: 폴더 구조 그대로 반영. 125개 폴더 트리 보존, 고객사가 Drive 쓰면 즉시 연동
5. **Deep Research 에이전트**: 내부 문서 기반 자동 리서치. 영업팀 기획서 초안 작성 등 실무 활용도 높음

## 약점 5가지

1. **최고가**: 50명×6개월 Business만 해도 ₩945만, Plus는 ₩2,250만. 3사 중 최대 비용
2. **리전 제약**: 한국 리전 없음. 도쿄/싱가포르 선택 시 데이터 상주 제약 가능성
3. **MCNC 기존 노하우 활용 제한**: AWS 중심 스택과 호환성 낮음. Workspace/GCP 경험 재활용도 제한적
4. **SSO 유연성**: Workspace SSO 외 일반 SAML 연동은 에디션·협의 필요
5. **벤더 락인**: Google 생태계 의존. 다른 LLM 제공자로 교체 어려움

## MCNC 기존 노하우 활용도

- **낮음~중간**: Google Cloud 직접 경험이 제한적이라면 초기 학습 곡선 존재
- Vertex AI · Gemini API 경험이 있다면 확장성 높음
- 일반적으로 Workspace를 이미 쓰는 고객사에 제안 시 시너지 큼

## SI 적합도

- **반복 배포 용이성**: Google Cloud 프로젝트 분리 + Workspace 조직 설정. 영업 담당자 배정 필요 (Self-serve 한계)
- **SM 이관**: 관리형이라 운영 부담 낮음. 단, Google 협의 채널 유지 필요
- **프로젝트 간 이식성**: 높음. 단 에디션 · 볼륨 할인 재협의 필요

## 주의사항

- **NotebookLM Plus (Workspace 번들) ≠ Gemini Enterprise NotebookLM**: 전자는 Workspace 추가 기능, 후자는 Gemini Enterprise 내장. 결정권자 대상 자료에서 구분 명시 필수
- **Agentspace 용어**: 2025년까지 사용. 2026년 현재 공식명은 "Gemini Enterprise"
- **Gemini Pro 계열 최신 세대**: 정기적으로 갱신되며 에이전트 과제 특화 개선이 누적됨 - 도입 시점에 최신 세대 확인 권장

## 공식 문서 / 레퍼런스

- Gemini Enterprise 공식: https://cloud.google.com/gemini-enterprise
- Edition 비교: https://docs.cloud.google.com/gemini/enterprise/docs/editions
- Release notes: https://docs.cloud.google.com/gemini/enterprise/docs/release-notes
- Gemini 모델 전체: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini
