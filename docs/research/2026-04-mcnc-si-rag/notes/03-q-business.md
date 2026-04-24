# Amazon Q Business

> 작성일: 2026-04-15
> 조사 기준일: 2026년 4월
> 환율: 1 USD = 1,500 KRW

## 제품 개요

- **정식 명칭**: Amazon Q Business
- **제공사**: AWS (Amazon Web Services)
- **출시**: 2024년 5월 GA (시드니 리전 2025년 3월 출시)
- **카테고리**: AWS 관리형(Managed) SaaS 엔터프라이즈 RAG 어시스턴트
- **한 줄 소개**: AWS가 운영하는 엔터프라이즈 검색 · 생성형 AI. 40+ 커넥터로 사내 데이터 소스에 바로 연결
- **핵심 가치 제안**: S3·SharePoint·Confluence 등 기존 시스템에 커넥터만 붙이면 되는 관리형 RAG. IAM Identity Center와 권한 자동 상속

## 시드니 리전(ap-southeast-2) 사용 배경

- **서울 리전 미지원**: 2026-04 기준 서울(ap-northeast-2)에서 Amazon Q Business 제공 안 됨
- **아시아 퍼시픽 최근접 리전**: 시드니(ap-southeast-2)가 MCNC 관점에서 현실적 선택
- **지연 시간**: 시드니 - 서울 왕복 약 130~160ms. 대화형 UX에서 체감 가능하나 치명적이지는 않음
- **데이터 상주 고려**: 고객사가 "한국 내 데이터 보관"을 요구할 경우 시드니 리전은 부적합 - 민간 일반 SI 맥락에서는 수용 가능한 경우가 많음

### 시드니 리전에서 **미지원** 기능 (2026-04)

- Amazon Q Apps (사용자 지정 앱 빌더)
- Amazon Q Actions (외부 시스템 호출 에이전트)
- Audio/Video 파일 파싱 (m4a 등)
- Q in QuickSight 일부 기능

### 시드니에서 **지원** 기능

- 엔터프라이즈 RAG 질의응답
- 파일 업로드 (PDF, 이미지 포함)
- 표 기반 데이터(Tabular Search) 소규모 테이블
- 스캔 PDF OCR
- 임베디드 이미지가 포함된 파일 처리
- 콘텐츠 생성 (요약, 초안 작성)

## 주요 기능

### RAG 엔진 / 문서 파싱
- **파싱 엔진**: Amazon Textract + 자체 파이프라인. 스캔 PDF OCR, 표 구조 인식 지원
- 지원 포맷: PDF (스캔 포함), DOCX, PPTX, XLSX, TXT, HTML, MD, CSV, JSON 등
- **PPTX/XLSX 파싱 품질**:
  - PPTX: 슬라이드별 텍스트 + 임베디드 이미지 OCR 가능. 도형 레이아웃 일부 손실
  - XLSX: 표 구조 인식 (Tabular Search). 단, 시드니 리전은 "작은 표(small tables)"만 지원
  - 3사 중 중상위. Document AI(Gemini) 대비 복잡 레이아웃에서 열세, Dify 대비 우위

### 특수 파일 형식
- **오디오 (m4a)**: 시드니 리전 **미지원**. 미국 리전은 지원
- **다이어그램 (drawio, mmd)**: 네이티브 파싱 없음. PNG/SVG로 변환 후 임베디드 이미지 OCR 경로 사용
- **XML 테이블**: 표 구조 자동 인식 기대하기 어려움. XLSX로 변환 권장

### LLM / 임베딩
- **LLM**: AWS가 내부 선택. 사용자가 모델을 직접 선택할 수 없음 (모델 추상화)
- **임베딩**: AWS 내부 (공개되지 않음, Titan 계열 추정)
- **벤더 락인**: AWS 스택 의존. Claude, Nova 등 특정 모델을 고정해서 쓸 수 없음

### 기타
- **폴더 구조**: 소스(S3 버킷 등)에 저장된 구조를 메타데이터로 유지하나, UI는 평면적 검색 중심
- **검색 방식**: 벡터 + 키워드 하이브리드 (관리형, 내부 구현 비공개)
- **권한/SSO**: **IAM Identity Center 필수**. 사용자별 ACL을 데이터 소스에서 자동 상속 (예: SharePoint 권한이 Q Business 답변 필터링에 반영)
- **워크플로우/Agent**: 미국 리전은 Q Apps, Q Actions 지원. **시드니는 제한**

## 가격 정책 (2026-04)

### 사용자 구독 (사용자당 월)
- **Lite**: **$3/user/mo** - 기본 Q&A, 권한 반영 응답
- **Pro**: **$20/user/mo** - 전체 기능 (Q Apps, Q in QuickSight Reader Pro 등. 시드니는 일부 기능 제한)
- 사용자가 Lite + Pro 둘 다 할당되면 Pro 요금만 부과 (중복 제거)

### 인덱스 비용 (시간당)
- **Starter Index**: $0.14/hr/unit (단일 AZ, 최대 20,000 문서 or 200MB, 최대 5 유닛)
- **Enterprise Index**: $0.264/hr/unit (3개 AZ, CMK 암호화 추가, 확장성 높음)
- 월 환산 (730시간):
  - Starter 1 유닛: $102/월
  - Enterprise 1 유닛: $193/월

### 591 파일 / 0.9GB 규모 적합성
- MCNC 데이터는 591 파일 × 평균 1.55MB ≈ 0.9GB. **Starter Index**(20,000 문서, 200MB 한도)를 초과함
- 200MB 한도: 추출된 텍스트 기준이라 실제 저장 사이즈에 근접하지만, PPTX+XLSX 위주 데이터는 텍스트 추출량이 상대적으로 작아 Starter로도 가능성 있음 - 단, 안전 마진 확보 위해 Enterprise Index 권장
- **권장**: Enterprise Index 1 유닛 (Starter 여러 유닛으로 분할 시 Enterprise 1 유닛이 비용 대비 효율적)

### 무료 트라이얼
- **60일 무료**: 최대 50명, Lite 또는 Pro 어느 쪽이든
- **인덱스 1,500 시간 무료** (60일 기준 Starter 1 유닛 ≈ 1,440시간 상응. 충분)
- **프로토타입 전 기간 트라이얼 내에서 해결 가능**

## 예상 총 비용 (2 시나리오)

### 시나리오 A: 기본 운영 50명 × 6개월
- Pro ($20) × 50명 × 6개월 = $6,000
- Lite ($3) × 50명 × 6개월 = $900
- Enterprise Index 1 유닛 × 6개월 = $193 × 6 = $1,158
- Starter Index 1 유닛 × 6개월 = $102 × 6 = $612
- **최소 (Lite + Starter Index)**: $900 + $612 = **$1,512** (약 **₩2,268,000**)
- **평균 (Lite + Enterprise)**: $900 + $1,158 = **$2,058** (약 **₩3,087,000**)
- **최대 (Pro + Enterprise)**: $6,000 + $1,158 = **$7,158** (약 **₩10,737,000**)

### 시나리오 B: 소규모 초기 운영 10명 × 1개월
- Pro × 10 × 1 = $200
- Lite × 10 × 1 = $30
- Starter Index × 1개월 = $102
- Enterprise Index × 1개월 = $193
- **최소 (Lite + Starter)**: $30 + $102 = **$132** (약 **₩198,000**) → 단, 60일 무료 트라이얼로 $0 가능
- **평균 (Lite + Enterprise)**: $30 + $193 = **$223** (약 **₩335,000**)
- **최대 (Pro + Enterprise)**: $200 + $193 = **$393** (약 **₩590,000**)

### 프로토타입 비용
- 60일 무료 트라이얼(50명, 1,500 인덱스 시간)로 실질 $0 가능
- LLM 추론은 구독에 포함 (별도 토큰 과금 없음)

## 40+ 커넥터 (대표 목록)

- **콘텐츠/위키**: Confluence (Cloud/Server), SharePoint (Cloud/Server), Microsoft Teams, Microsoft Exchange, OneDrive, Google Drive, Box, Dropbox
- **CRM/티켓**: Salesforce, ServiceNow, Jira, Zendesk
- **커뮤니케이션**: Slack, Gmail, Google Calendar (Preview)
- **저장소**: Amazon S3, Amazon FSx Windows, Smartsheet
- **개발**: GitHub (Cloud/Server)
- **커스텀**: Custom Data Source Connector (API), Web Crawler

## IAM Identity Center 권한 자동 상속

- Q Business는 IAM Identity Center **필수 연동**
- 소스 시스템(SharePoint, Confluence 등)의 사용자별 ACL을 Q Business가 상속 - 답변에서 사용자 권한 범위 밖 문서는 자동 필터링
- 예: 영업팀 사용자가 재무팀 폴더 문서를 못 보는 상태라면, Q Business 답변에서도 그 내용 제외
- MCNC SI 맥락에서는 **고객사 조직 보안 모델 그대로 반영 가능**이 강점

## 업로드 UX (중요)

- **Admin 콘솔 업로드 + S3 커넥터 중심 설계**: 영업팀이 AWS 콘솔로 직접 업로드하는 것은 UX가 나쁨
- **대안 1**: S3 버킷을 직관적 FE(자체 구축)로 추상화. 업로드 → S3 → Q Business 자동 크롤링
- **대안 2**: Q Business Web Experience (내장 챗 UI)에 첨부 업로드 기능 활용. 단, 영구 인덱싱이 아닌 대화 컨텍스트 한정
- **대안 3**: SharePoint/Drive 등 이미 쓰는 시스템을 커넥터로 연결 (영업팀 기존 도구 유지가 가능)
- **결론**: 시연용으로 자체 추상화 UI 또는 SharePoint 커넥터가 현실적

## 데이터 처리 정책

- **AWS 약관**: 고객 데이터를 모델 학습에 사용하지 않음
- 입출력 데이터는 AWS 가 저장하지 않음 (Q Business 인덱스 내 저장은 제외)
- HIPAA BAA, ISO, SOC 1/2/3 인증

## 보안 및 규정 준수

- **암호화**: 기본 AWS 관리형 키. Enterprise Index는 CMK (Customer Managed Key) 지원
- **VPC 엔드포인트**: 지원. Private 트래픽 가능
- **인증서**: ISO 27001/27017/27018, SOC 1/2/3, HIPAA BAA, PCI DSS, FedRAMP Moderate (미국 리전)
- **데이터 상주**: 시드니 리전이므로 **호주 내 저장**. "한국 내 보관" 필요 시 부적합

## 강점 5가지

1. **40+ 커넥터**: SharePoint/Confluence/S3/Salesforce 등 고객사 기존 시스템에 즉시 붙일 수 있음. 고객사별 연동 개발 최소화
2. **권한 자동 상속**: IAM Identity Center + 소스 ACL 자동 반영으로 조직 보안 모델 그대로 유지. 별도 권한 재설계 불필요
3. **관리형 운영**: 패치/스케일링/백업 모두 AWS 책임. SM 이관 시 운영 부담 최소화
4. **60일 무료 트라이얼**: 프로토타입 구축을 실질 $0으로 검증 가능
5. **MCNC 기존 AWS 노하우**: IAM Identity Center, S3, CloudFormation/CDK, Bedrock 경험 직결

## 약점 5가지

1. **영업팀 업로드 UX**: 기본 경로가 S3/Admin 콘솔이라 비개발자 시연이 어려움. 추상화 UI 필요
2. **시드니 리전 기능 제약**: Q Apps/Actions, Audio/Video 미지원. 최신 기능은 1~2년 격차
3. **LLM 선택 불가**: AWS가 내부 모델 선택. Claude/Nova 명시 불가, 벤더 락인 강함
4. **Pro 요금 부담**: 50명 × Pro × 6개월 = $6,000 (₩900만). 소규모 SI 프로젝트에 과투자 리스크
5. **한국 외 데이터 상주**: 시드니 리전이라 "한국 내 보관" 요구 고객사에 부적합

## MCNC 기존 노하우 활용도

- **높음**: IAM Identity Center, S3, CloudFormation/CDK, VPC 설계, Bedrock 경험 전부 이식
- Q Business 자체는 관리형이라 운영 노하우가 상대적으로 덜 필요. 대신 연동(커넥터 설정, ACL 맵핑)이 주 작업

## SI 적합도

- **반복 배포 용이성**: 애플리케이션(Q Business Application) 단위로 프로젝트별 분리. CDK 템플릿화 시 수 시간 내 셋업
- **SM 이관**: 관리형이라 운영 부담 낮음. 콘솔 권한과 커넥터 설정만 인계
- **프로젝트 간 이식성**: 높음. CDK 템플릿만 재사용

## 공식 문서 / 레퍼런스

- Amazon Q Business 공식: https://aws.amazon.com/q/business/
- Pricing: https://aws.amazon.com/q/business/pricing/
- Subscription Tiers & Index Types: https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/tiers.html
- Supported Connectors: https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/connectors-list.html
- Sydney Region Announcement: https://aws.amazon.com/about-aws/whats-new/2025/03/amazon-q-business-asia-pacific-sydney-region/
- IAM Identity Center Integration: https://aws.amazon.com/blogs/machine-learning/build-private-and-secure-enterprise-generative-ai-apps-with-amazon-q-business-and-aws-iam-identity-center/
