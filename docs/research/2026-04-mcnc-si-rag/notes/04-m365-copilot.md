# Microsoft 365 Copilot

## 제품 개요

- **정식 명칭**: Microsoft 365 Copilot
- **제공사**: Microsoft
- **출시**: 2023-11 GA (Enterprise)
- **카테고리**: Microsoft 관리형 SaaS 엔터프라이즈 AI 어시스턴트
- **핵심**: M365 네이티브 통합 + SharePoint RAG 자동화 + Office 앱 내장 AI

## 아키텍처

사용자 프롬프트 → Microsoft Graph + Semantic Index 검색(Grounding) → Azure OpenAI LLM → 후처리 → 응답

| 계층 | 컴포넌트 |
|---|---|
| 오케스트레이터 | Copilot Orchestrator |
| 검색 인덱스 | Semantic Index (테넌트/사용자 레벨 벡터) |
| 데이터 레이어 | Microsoft Graph (메일, 채팅, 문서, 일정 등) |
| LLM | Azure OpenAI (GPT 계열 - 최신 세대 기본 + 이전 세대 폴백) |
| 확장 | Copilot Studio (커스텀 에이전트, 플러그인, MCP) |
| 거버넌스 | Entra ID, Purview, 조건부 접근 |

## 주요 기능

### 문서 파싱
- Office 네이티브 파서로 PPTX/XLSX/DOCX 원본 포맷 직접 이해
- 텍스트 박스, 표, 차트, 발표자 노트, SmartArt 텍스트 모두 추출
- 2025년 말부터 vision 모델로 임베디드 이미지 분석 (OCR)
- 문서 요약 최대 약 150만 단어 (약 3,000페이지)

### 지원 파일 포맷
- 문서: DOCX, DOC, PDF, TXT, RTF, MD, HTML
- 프레젠테이션: PPTX, PPT
- 스프레드시트: XLSX, XLS, CSV, TSV
- 이미지: PNG, JPG, GIF, BMP, TIFF
- 코드: JS, Python, Java, C#, SQL 등 20여 종
- 기타: JSON, XML, YAML, Loop/Fluid, LOG

### LLM
- GPT 계열 (최신 세대 기본 + 이전 세대 폴백)
- 멀티모델: Anthropic Claude Sonnet 계열, Claude Opus 계열 (Researcher 에이전트)
- 사용자 직접 모델 선택: 기본 Copilot에서 불가, Copilot Studio에서만 가능

### 커넥터
- 기본: SharePoint, OneDrive, Teams, Exchange, OneNote, Loop
- 외부: 100+ 사전 구축 커넥터 (Confluence, Salesforce, Jira, SAP 등)
- 커스텀: Graph Connectors API로 자체 개발 가능

## 가격 (2026-04)

### MCNC 권장: Business 플랜
MCNC는 100명 이하 + SI 프로젝트 50명 이하이므로 **Business 플랜 (300명 한도)으로 충분**.
Business와 Enterprise는 **Copilot 엔진 자체와 RAG 능력은 100% 동일**하며, 사용자 한도와 일부 거버넌스 기능에서만 차이.

| 플랜 | 가격 (user/mo) | 사용자 한도 | 비고 |
|---|---|---|---|
| **Copilot Business** | **$21** | 300명 | MCNC 권장. Business Standard/Premium 베이스 필요 |
| Copilot Enterprise | $30 | 무제한 | E3/E5 베이스 필요 |
| Copilot Chat | $0 | - | M365 구독 포함, 웹 채팅만 (RAG 불가) |
| Copilot Studio | $200/tenant/mo | - | 커스텀 에이전트 빌더 (선택) |

### Business vs Enterprise 차이 (Copilot 기능)

| 항목 | Business | Enterprise |
|---|---|---|
| SharePoint/OneDrive 그라운딩 | ✅ | ✅ |
| Semantic Index | ✅ | ✅ |
| Graph Connectors (50M items 한도) | ✅ | ✅ |
| Copilot Studio 통합 | ✅ | ✅ |
| 외부 시스템 RAG 연동 | ✅ | ✅ |
| 사용자 수 | 300명 한도 | 무제한 |
| Purview 자동 민감도 레이블 | ❌ | E5만 |
| Communication Compliance | ❌ | E5만 |
| DSPM for AI | ❌ | E5만 |

> "The technical Copilot engine is completely identical." (Universal.cloud 분석)

### 기본 라이선스 (필수)

**Business 플랜 (MCNC 권장)**
- M365 Business Basic: $6/mo
- M365 Business Standard: $12.50/mo
- M365 Business Premium: $22/mo
- M365 Apps for Business: $8.25/mo

**Enterprise 플랜 (300명 초과 시)**
- M365 E3: $36/mo (2026.7부터 $39)
- M365 E5: $57/mo (2026.7부터 $60)

총 비용 = 기본 라이선스 + Copilot

### 트라이얼
- **엔터프라이즈 무료 트라이얼 없음**
- 대안: Pay-as-you-go, Copilot Chat (무료), CSP 파트너 월단위

### 비용 시뮬레이션 (Business 플랜 기준, Copilot만)

| 시나리오 | 비용 |
|---|---|
| 10명 x 1개월 | $210 (₩315,000) |
| 30명 x 1개월 | $630 (₩945,000) |
| 50명 x 6개월 | $6,300 (₩9,450,000) |

### 총 비용 시뮬레이션 (Business Standard + Copilot Business, 1인당 월)
- $12.50 + $21 = **$33.50/user/mo**
- 50명 x 6개월: $33.50 × 50 × 6 = **$10,050 (₩15,075,000)**

> 참고: Enterprise(E3 + Copilot Enterprise) 조합은 $66/user/mo로 약 2배.

## 데이터 처리 · 보안

- **Microsoft 약관**: 프롬프트 · 응답 · Graph 데이터를 기반 LLM 학습에 사용하지 않음
- M365 서비스 경계 내부 처리, 전송 중 · 저장 시 암호화
- Entra ID + RBAC + 조건부 접근 + MFA
- Purview 민감도 레이블 · DLP 정책 존중
- **인증**: ISO 27001/27018, ISO 42001, SOC 2 Type II, GDPR, HIPAA, FedRAMP High

## 리전

- 데이터 저장: **한국 포함** (Product Terms 데이터 레지던시 커밋)
- LLM 처리: 한국 in-country 아직 미지원
- Advanced Data Residency(ADR) 추가 구매 시 강화 가능

## 강점

1. M365 네이티브 통합 - Word/Excel/PPT/Outlook/Teams에서 바로 AI 사용
2. Office 문서 파싱 최고 - PPTX/XLSX 원본 포맷 직접 이해
3. SharePoint RAG 자동화 - 추가 설정 없이 즉시 검색
4. 100+ 커넥터 - 외부 시스템 연동
5. 한국 데이터 상주 가능

## 약점

1. 이중 라이선스 - Business+Copilot $33.50/user/mo (Enterprise 조합은 $66)
2. 트라이얼 없음 - 연약정 필수
3. LLM 선택 제한 - Copilot Studio 별도 구매 필요
4. MCNC AWS 노하우 재사용 불가
5. LLM 처리 한국 리전 미지원

## MCNC · SI 적합도

- **권장 라이선스**: **Copilot Business** ($21/user/mo) + Business Standard ($12.50/user/mo)
  - MCNC 100명 이하, SI 프로젝트 50명 이하이므로 Business 한도(300명) 충분
  - RAG 능력은 Enterprise와 100% 동일
- **기존 노하우**: 낮음 (AWS 중심)
- **반복 배포**: M365 테넌트 단위, 사이트 컬렉션 분리 필요
- **SM 이관**: 관리형 운영, M365 관리자 역량 필요
- **이식성**: M365 사용 고객사 한정

## 참고 URL

- https://www.microsoft.com/en-us/microsoft-365-copilot
- https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-privacy
- https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-architecture
- https://learn.microsoft.com/en-us/microsoftsearch/semantic-index-for-copilot
- https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-licensing
