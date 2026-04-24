# Dify + Amazon Bedrock

> 작성일: 2026-04-15
> 조사 기준일: 2026년 4월
> 환율: 1 USD = 1,500 KRW

## 제품 개요

- **정식 명칭**: Dify (langgenius/dify)
- **제공사**: LangGenius (中国发行, 2023년 출시). 2026년 3월 $30M 투자 유치
- **카테고리**: OSS 셀프호스팅 LLMOps 플랫폼 + Amazon Bedrock 연동
- **라이선스**: Apache 2.0 (Community Edition, 100% 기능)
- **한 줄 소개**: Docker Compose 한 번으로 설치 가능한 오픈소스 LLM 워크플로우 · RAG · 에이전트 빌더
- **핵심 가치 제안**: 셀프호스팅으로 사내 보관 유지, Bedrock API 로 최신 Claude 모델 호출, Dify 네이티브 업로드 UI 로 영업팀 사용 가능한 2-Tier 구성

## 아키텍처

```
[사용자/영업팀]
   │ (Dify Knowledge 에 드래그 & 드롭 업로드)
   ▼
[Dify] ── Knowledge Pipeline (OCR · 파싱 · 청킹 · 임베딩) ──▶ [Weaviate (벡터 DB)]
   │          [내장 컴포넌트]                                      │
   │          - PostgreSQL (메타)                                  │
   │          - Redis (캐시 · 큐)                                  │
   │          - Celery (워커)                                      │
   │                                                              │
   └──────▶ Bedrock API ──▶ [Amazon Bedrock]
                                · Claude Sonnet 계열
                                · Titan Embeddings v2
```

- **Dify 역할**: 업로드 UI + RAG 관리 + 워크플로우 + API 게이트웨이. LLM 자체는 호스팅하지 않음
- **Bedrock 역할**: LLM 추론 (Claude Sonnet 계열), 임베딩 (Titan Embeddings v2), KMS 암호화
- **업로드 흐름**: Dify 1.x 의 네이티브 업로드 UI 가 드래그&드롭 · 다중 파일 · 진행률 · 즉시 인제스트를 모두 지원. 별도 파일 서버나 동기화 워커 불필요

## 주요 기능

### RAG 엔진 / 문서 파싱
- **Knowledge Pipeline** (2025~2026 도입): 비주얼 파이프라인으로 OCR → 파싱 → 구조화 추출 → 청킹 → 임베딩 단계를 조립
- 지원 포맷: PDF, DOCX, PPTX, XLSX, MD, HTML, TXT, CSV, JSON 등
- **PPTX/XLSX 파싱 품질**:
  - 기본(Dify ETL): 텍스트 추출 위주. PPTX 도형/슬라이드 구조 일부 손실 가능
  - Unstructured ETL 연동: 레이아웃 인식 향상 (유료 API 또는 self-host)
  - 3사 중 중간 수준. Document AI(Gemini) 대비 복잡 기획서에서 열세, Q Business 대비 유사
- 청킹: 문자 기반, 시맨틱, 부모-자식(hierarchical) 등 선택 가능
- 리랭커 교체 가능 (BGE-Reranker, Cohere Rerank 등)

### 특수 파일 형식
- **오디오 (m4a)**: 네이티브 transcription 없음. Whisper 플러그인 또는 외부 변환 후 업로드
- **다이어그램 (drawio, mmd)**: 텍스트 내부까지는 추출되나 시각 구조 손실. PNG/SVG 로 사전 변환 권장
- **XML 테이블**: 텍스트로 읽히나 구조화 인식은 제한적. Excel 로 변환 후 업로드가 실용적

### LLM/임베딩
- **LLM 선택지** (Bedrock 경유):
  - Claude Sonnet 계열 (Anthropic) - 복잡 추론·문서 이해
  - Claude Haiku 계열 - 저비용/빠른 응답
  - Claude Opus 계열 - 최고 품질
  - Claude 4.x 는 inference profile (`jp.` / `apac.` / `global.`) 로만 호출 가능
- **임베딩**: Amazon Titan Text Embeddings v2 (기본), Cohere Embed, 또는 OSS (bge-m3 등 self-host)

### 기타
- **폴더 구조**: Dify Knowledge 는 기본적으로 플랫 구조. 태그/메타데이터로 의사 폴더 구현 필요 (제약)
- **검색 방식**: 벡터 + 풀텍스트 + 하이브리드 + 리랭커
- **권한/SSO**: Community Edition 은 기본 Workspace 단위. SSO(SAML/OIDC)는 Enterprise Edition(유료)만
- **워크플로우/Agent**: Chatflow, Workflow, Agent (ReAct/Function Call) 모두 지원. 비주얼 빌더

## 가격 정책 (2026-04)

### Dify 본체
- **Community Edition (셀프호스팅)**: 무료. Apache 2.0. 전 기능 사용 가능
- **Dify Cloud (참고, 본 검증에서는 사용 안 함)**: Sandbox Free / Pro $59/mo / Team $159/mo / Enterprise 별도
- MCNC 구성은 Community 셀프호스팅이므로 Dify 자체 구독비 **$0**

### Amazon Bedrock (LLM 토큰 요금, 도쿄 리전 기준)
- Claude Sonnet 계열 on-demand (현행 세대 기준): 입력 $3/1M 토큰, 출력 $15/1M 토큰
- Titan Embeddings v2: $0.02/1M 토큰
- Batch inference: 50% 할인
- Prompt caching: 5분 TTL (write 1.25x, read 0.1x) 또는 1시간 TTL

### 인프라 (셀프호스팅 필수 비용)
- EC2 (예: t3.xlarge, 4 vCPU / 16 GB): 도쿄 월 약 $135
- EBS 100GB gp3: 월 약 $10
- **인프라 합계**: 월 약 $145

### 무료 트라이얼
- Dify Community: 영구 무료
- AWS Bedrock: 신규 계정 초기 크레딧 활용 가능. Claude 프리 티어는 없음

## 예상 총 비용 (2 시나리오)

※ "명"은 등록 사용자 기준

### 시나리오 A: 기본 운영 50명 × 6개월
- Dify: $0
- 인프라: $145/월 × 6 = $870
- LLM 토큰 (동시 20~30명 피크, 월 5M 토큰 입력 + 2M 출력 가정):
  - Claude Sonnet 계열 기준: ($3×5 + $15×2)/월 = $45/월 × 6 = $270
- 임베딩 초기 인덱싱 (0.9GB ≈ 약 300M 토큰): Titan v2 $0.02×300 = $6 (1회성)
- **합계**: $870 + $270 + $6 ≈ **$1,146** (약 **₩1,719,000**)

### 시나리오 B: 소규모 초기 운영 10명 × 1개월
- Dify: $0
- 인프라: $145
- LLM 토큰 (월 1M 입력 + 0.3M 출력 가정):
  - Claude Sonnet 계열: $3 + $4.5 = $7.5
- 임베딩 (소규모 데이터셋 1회): $2
- **합계**: $145 + $7.5 + $2 ≈ **$155** (약 **₩232,000**)

## 데이터 처리 정책

- **Dify**: 셀프호스팅 시 모든 데이터가 MCNC 인프라에 머무름. 외부 서버 전송 없음 (LLM API 호출 제외)
- **Bedrock**: AWS 약관 - 고객 데이터는 모델 학습에 사용되지 않음. 입·출력 데이터 AWS 가 저장하지 않음

## 보안 및 규정 준수

- **암호화**: Bedrock KMS 지원, EBS 암호화
- **VPC**: 모든 컴포넌트를 Private Subnet 에 배치 가능. Bedrock 은 VPC Endpoint 지원
- **SSO**: Community Edition 은 기본 제공 없음 (Enterprise 필요) - **약점**
- **인증**: Bedrock (ISO 27001, SOC 1/2/3, HIPAA BAA)

## 강점 5가지

1. **사내 보관**: 셀프호스팅으로 모든 문서가 MCNC 인프라에 머무름. 고객사에 "외부 유출 없음" 증명 용이
2. **저비용**: 50명×6개월 기준 약 ₩170만~220만으로 4사 중 가장 저렴 (인프라 + LLM 토큰만 과금)
3. **MCNC 기존 노하우 높은 활용도**: mcnc-rag (Open WebUI, vLLM), Docker Compose, PostgreSQL, PGVector 경험이 그대로 이식됨
4. **커스터마이징 자유도**: UI 변경, 워크플로우 확장, 사내 시스템 연동 제약 없음. Bedrock 외 vLLM/Ollama 로 언제든 전환 가능
5. **LLM 선택 자유**: Claude Sonnet · Haiku · Opus 어떤 Bedrock 모델이든 교체 가능. 벤더 락인 없음

## 약점 5가지

1. **SSO 부재**: Community Edition 은 SAML/OIDC SSO 미지원. Enterprise Edition(유료) 필요
2. **문서 파싱 품질**: Gemini Enterprise 의 Document AI 대비 복잡 기획서/화면설계서 정확도 열세
3. **폴더 구조 제약**: 네이티브 폴더 트리 없이 태그·메타데이터 기반. 기존 125개 폴더 구조 그대로 보여주기 어려움
4. **운영 책임 전가**: 패치, 백업, 모니터링, 스케일링 모두 MCNC 책임. SM 이관 시 운영 매뉴얼 문서화 필수
5. **검색 품질 튜닝 공수**: 리랭커 · 청킹 전략 · 하이브리드 가중치 조정이 MCNC 책임. 관리형 제품 대비 수동 작업 많음

## MCNC 기존 노하우 활용도

- **높음**: mcnc-rag (Open WebUI + vLLM), Docker Compose, PostgreSQL, PGVector, Node.js, Python FastAPI, Spring Boot 경험 전부 활용
- Bedrock AWS CDK/CloudFormation 자동화 경험 그대로 투입
- bizMOB Xross 프론트 통합 시 Dify API 호출 구조 재사용 가능

## SI 적합도

- **반복 배포 용이성**: Docker Compose 템플릿 + Bedrock 계정 분리로 프로젝트별 인스턴스 스핀업 가능. Terraform/CDK 로 자동화 시 수 시간 내 셋업
- **SM 이관**: OSS 이므로 매뉴얼·Runbook 인계 가능. 단, MCNC 기술팀이 운영 지식 구축 필요
- **프로젝트 간 이식성**: 매우 높음. 구성 전체가 사내 자산

## 공식 문서 / 레퍼런스

- Dify 공식 문서: https://docs.dify.ai/
- Dify GitHub: https://github.com/langgenius/dify
- Amazon Bedrock Pricing: https://aws.amazon.com/bedrock/pricing/
- Amazon Bedrock Claude (Anthropic): https://aws.amazon.com/bedrock/anthropic/
