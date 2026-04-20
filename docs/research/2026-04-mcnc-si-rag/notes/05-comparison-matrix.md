# 비교 매트릭스 (4개 제품)

> 작성일: 2026-04-15
> 조사 기준일: 2026년 4월
> 환율: 1 USD = 1,500 KRW

## 비교 원칙

- **주관적 "종합 평가" 별점 금지**: 모든 별점 항목은 평가 기준을 함께 명시
- **최고 제품 자동 하이라이트**: 검증 가능한 수치 기반 항목에 한함
- **단일 최종 권장안 미제공**: 판단 재료만 제공

## 1. 기본 정보

| 카테고리 | Dify + Bedrock | Amazon Q Business | Gemini Enterprise + Drive | Microsoft 365 Copilot |
|---|---|---|---|---|
| **제품 유형** | OSS 셀프호스팅 + SaaS API | AWS 관리형 SaaS | Google 관리형 SaaS | Microsoft 관리형 SaaS |
| **제공사** | LangGenius + AWS | AWS | Google Cloud | Microsoft |
| **카테고리** | LLMOps + RAG | 엔터프라이즈 RAG | 엔터프라이즈 AI 에이전트 | M365 통합 AI 어시스턴트 |
| **출시** | Dify 2023, Bedrock 2023 | 2024-05 GA (시드니 2025-03) | 2025 말 GA (Agentspace 후신) | 2023-11 GA (Enterprise) |

## 2. 가격 (2026-04)

### 사용자당 월 단가

| 제품 | 최소 | 평균 | 최대 |
|---|---|---|---|
| Dify + Bedrock | $0 (OSS) + 토큰 사용량 | 실질 $0~5 | $10+ (Claude 위주) |
| Q Business | $3 (Lite) | $3~20 | $20 (Pro) |
| Gemini Enterprise | $21 (Business 연) | $30 (Standard) | $50~60 (Plus) |
| M365 Copilot | $21 (Business, 300명 한도) | $21 | $30 (Enterprise, 300명 초과) |

> M365 Copilot은 Business와 Enterprise의 **Copilot 엔진과 RAG 능력이 100% 동일**. 차이는 사용자 한도(300 vs 무제한)와 E5 전용 거버넌스 기능뿐. MCNC는 100명 이하 + SI 50명 이하라 Business로 충분.

### 50명 × 6개월 총비용 (평균 시나리오)

| 제품 | 금액 (USD) | 금액 (KRW) |
|---|---|---|
| **Dify + Bedrock** | **$1,241** | **₩1,862,000** |
| Q Business (Lite + Enterprise Index) | $2,058 | ₩3,087,000 |
| Q Business (Pro + Enterprise Index) | $7,158 | ₩10,737,000 |
| Gemini Enterprise (Business) | $6,300 | ₩9,450,000 |
| Gemini Enterprise (Standard) | $9,000 | ₩13,500,000 |
| M365 Copilot (Business, Copilot만) | $6,300 | ₩9,450,000 |
| M365 Copilot (Business + Business Standard) | $10,050 | ₩15,075,000 |

### 10명 × 1개월 총비용 (평균 시나리오)

| 제품 | 금액 (USD) | 금액 (KRW) |
|---|---|---|
| **Dify + Bedrock** | **$192** | **₩288,000** |
| Q Business (Lite + Enterprise) | $223 | ₩335,000 |
| Q Business (Pro + Enterprise) | $393 | ₩590,000 |
| Gemini Enterprise (Business 연) | $210 | ₩315,000 |
| Gemini Enterprise (Standard 월) | $350 | ₩525,000 |
| M365 Copilot (Business, Copilot만) | $210 | ₩315,000 |
| M365 Copilot (Business + Business Standard) | $335 | ₩502,500 |

### 무료 트라이얼 요약

| 제품 | 기간 | 사용자 한도 | 기타 |
|---|---|---|---|
| Dify (Community) | 영구 무료 | 무제한 | 셀프호스팅 인프라 비용 별도 |
| Q Business | 60일 | 50명 | 인덱스 1,500시간 포함 |
| Gemini Enterprise | 30일 (Business) | 300명 | Standard/Plus는 영업 협의 |
| M365 Copilot | 없음 | - | Pay-as-you-go, Copilot Chat (무료) 대안 |

## 3. 인프라

| 항목 | Dify + Bedrock | Q Business | Gemini Enterprise | M365 Copilot |
|---|---|---|---|---|
| **배포 리전** | MCNC 선택 (도쿄/서울 등) | 시드니 (ap-southeast-2) | 도쿄/싱가포르/global | 한국 (저장) / 해외 (LLM 처리) |
| **운영 책임** | MCNC 전담 | AWS 대부분 | Google 대부분 | Microsoft 대부분 |
| **한국 리전** | Bedrock 한국 미지원 (도쿄 근접) | 서울 미지원 | 한국 리전 없음 | 데이터 저장 한국 가능, LLM 처리 미지원 |
| **데이터 상주** | MCNC 지정 가능 | 호주(시드니) | 일본(도쿄) 등 | 한국 (Product Terms) |

## 4. 기능

| 항목 | Dify + Bedrock | Q Business | Gemini Enterprise | M365 Copilot |
|---|---|---|---|---|
| **LLM 모델 선택** | 자유 (Claude Sonnet / Haiku / Opus 계열) | 불가 (AWS 내부) | 선택 가능 (Gemini Pro/Flash 계열) | 불가 (GPT 계열, Studio에서만 가능) |
| **문서 수 제한** | 무제한 (인프라 한도 내) | Starter 20k/Enterprise 무제한 | 에디션별 (사실상 충분) | Graph Connectors 50M items |
| **폴더 구조** | 제한적 (평면 + 태그) | 메타데이터 유지 | Drive 구조 그대로 | SharePoint/OneDrive 그대로 |
| **커넥터 수** | Google Drive, Notion 등 (확장 중) | **40+** (SharePoint, S3, Salesforce 등) | **100+** (Drive 네이티브) | **100+** (Confluence, Salesforce, Jira 등) |
| **워크플로우** | 비주얼 빌더 (Chatflow, Agent) | Q Apps (시드니 미지원) | Agent Workbench | Copilot Studio (별도 $200/tenant/mo) |
| **오디오 (m4a)** | Whisper 플러그인 | 시드니 미지원 | 네이티브 지원 | Teams 회의 녹음 전사/요약 |
| **PPTX/XLSX 품질** | 중간 (Unstructured 연동 시 향상) | 중상위 | **최상위** | **최상위 (Office 네이티브 파서)** |
| **컨텍스트 윈도우** | LLM 의존 (Claude 200k) | 비공개 | **1M~2M 토큰** | GPT 계열 기준 (공식 수치 미공개) |

## 5. 시연 친숙도 (별점 + 기준)

### 업로드 UX (기준: 파일 업로드 완료까지의 클릭/단계 수)

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★★☆ | Dify Knowledge 화면에 드래그&드롭 → 즉시 인제스트. 다중 파일 · 진행률 표시 |
| Q Business | ★★☆☆☆ | S3 콘솔 또는 Admin UI (영업팀 시연 부적합). 추상화 UI 별도 구축 필요 |
| Gemini Enterprise | ★★★★★ | Drive 드래그&드롭 (영업팀 완전 친숙). 별도 UI 구축 불필요 |
| M365 Copilot | ★★★★★ | SharePoint/OneDrive 자동 + Copilot Chat 드래그&드롭 |

### 영업팀 시연 가능성 (기준: "업로드 → 질문" 플로우가 10분 안에 시연 가능한가)

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★★☆ | Dify UI 설명 필요. 업로드 직후 Indexing 1~2 분 대기 |
| Q Business | ★★★☆☆ | Web Experience는 가능하나 "업로드" 시연은 추상화 UI 필수 |
| Gemini Enterprise | ★★★★★ | Drive + NotebookLM으로 즉시 시연 가능 |
| M365 Copilot | ★★★★☆ | Word/Excel/PPT 내장 + Copilot Chat. 트라이얼 없어 데모 환경 셋업 필요 |

### 결정권자(영업팀) 평가 관점 (기준: 시각적 완성도 + 답변 품질)

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★☆☆ | Dify UI는 개발자 친화적, 영업팀에는 설명 필요 |
| Q Business | ★★★★☆ | Web Experience 완성도 높음 |
| Gemini Enterprise | ★★★★★ | NotebookLM은 소비자용으로 검증된 UX |
| M365 Copilot | ★★★★★ | Word/Excel/PPT 네이티브 통합, 영업팀 익숙도 최상 |

## 6. SI 적합도 (별점 + 기준)

### 반복 배포 용이성 (기준: 신규 프로젝트 투입 시 셋업 시간)

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★★☆ | Terraform/CDK 템플릿으로 수 시간 |
| Q Business | ★★★★★ | CDK 템플릿 + 계정 분리 (관리형이라 간편) |
| Gemini Enterprise | ★★★☆☆ | Google Cloud 영업 협의 필요, Self-serve 한계 |
| M365 Copilot | ★★★★☆ | M365 테넌트 단위, 사이트 컬렉션 분리 필요 |

### SM 이관 용이성 (기준: 운영 매뉴얼 작성 및 인계 부담)

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★☆☆ | MCNC 전담 운영 경험 축적 필요 |
| Q Business | ★★★★★ | 관리형 + 콘솔만 인계 |
| Gemini Enterprise | ★★★★☆ | 관리형이나 Google 협의 채널 유지 필요 |
| M365 Copilot | ★★★★★ | 관리형, M365 관리자 역량 필요 |

### 프로젝트 간 이식성 (기준: 패키지 재사용 가능성)

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★★★ | 구성 전체가 사내 자산 |
| Q Business | ★★★★☆ | CDK 템플릿 재사용 |
| Gemini Enterprise | ★★★☆☆ | 에디션/할인 재협의 필요 |
| M365 Copilot | ★★★☆☆ | M365 사용 고객사 한정 |

## 7. 커스터마이징 (별점 + 기준)

### UI 변경 / 브랜딩

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★★★ | OSS이므로 소스 수정 자유 |
| Q Business | ★★☆☆☆ | 제한적 (로고, 색상 일부) |
| Gemini Enterprise | ★★★☆☆ | 에이전트 설정 중심, UI 자체는 제한 |
| M365 Copilot | ★★☆☆☆ | M365 UI 고정. Copilot Studio로 일부 커스텀 |

### 워크플로우 확장

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★★★ | 비주얼 워크플로우 + 외부 API 자유 호출 |
| Q Business | ★★★☆☆ | Q Actions (시드니 미지원), Lambda 연동 |
| Gemini Enterprise | ★★★★★ | Agent Builder + 100+ Integration Connectors |
| M365 Copilot | ★★★★☆ | Copilot Studio (별도 구매), MCP 지원 |

### 사내 시스템 연동

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★★★ | 어떤 API든 자유 호출 |
| Q Business | ★★★★☆ | 40+ 커넥터 + Custom Connector |
| Gemini Enterprise | ★★★★★ | 100+ 커넥터 + Apigee |
| M365 Copilot | ★★★★★ | 100+ 커넥터 + Graph Connectors API |

## 8. 보안

| 항목 | Dify + Bedrock | Q Business | Gemini Enterprise | M365 Copilot |
|---|---|---|---|---|
| **데이터 학습 미사용** | ✓ (Bedrock 약관 + 셀프호스팅) | ✓ (AWS 약관) | ✓ (Google 약관) | ✓ (Microsoft 약관) |
| **암호화 (KMS)** | EBS + Bedrock KMS | 기본 AWS 키 / Enterprise Index CMK | 기본 + CMEK (Standard/Plus) | BitLocker + 파일별 암호화 / ADR 옵션 |
| **VPC 격리** | 완전 지원 | VPC Endpoint | VPC Service Controls | M365 서비스 경계 (VPC 개념 없음) |
| **SSO** | Enterprise Edition만 (유료) | **IAM Identity Center 필수** | Workspace SSO / SAML | Entra ID (Azure AD) / SAML / 조건부 접근 |
| **주요 인증** | Bedrock ISO/SOC/HIPAA | ISO/SOC/HIPAA/FedRAMP Moderate | ISO/SOC/HIPAA/FedRAMP High | ISO 27001/27018, ISO 42001, SOC 2, GDPR, HIPAA, FedRAMP High |

## 9. MCNC 노하우 활용도 (별점 + 기준)

### 기술 스택 호환성 (기준: mcnc-rag, Docker, PostgreSQL, Bedrock 등 기존 자산 재사용도)

| 제품 | 별점 | 기준 |
|---|---|---|
| Dify + Bedrock | ★★★★★ | Docker Compose, PGVector, Bedrock 경험 100% 활용 |
| Q Business | ★★★★☆ | IAM Identity Center, S3, CDK 경험 활용 |
| Gemini Enterprise | ★★☆☆☆ | Google Cloud 직접 경험 제한적 |
| M365 Copilot | ★☆☆☆☆ | AWS 중심 스택과 호환성 낮음, Microsoft 생태계 학습 필요 |

## 종합 비교표 (한 줄 요약)

| 관점 | 선택지 |
|---|---|
| **저비용 + 데이터 주권** | Dify + Bedrock |
| **AWS 생태계 + 관리형** | Amazon Q Business |
| **최고 품질 파싱 + UX** | Gemini Enterprise + Drive |
| **M365 생태계 + Office 내장 AI** | Microsoft 365 Copilot |

※ 단일 최종 권장안은 제공하지 않음. 프로젝트별 고객사 환경 · 예산 · 데이터 상주 요구에 따라 선택.
