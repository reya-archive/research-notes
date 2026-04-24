# Dify + Bedrock 프로토타입 셋업

MCNC SI RAG 시스템 후보 비교([리서치 개요 페이지](../index.html)) 중 **Dify + Amazon Bedrock** 조합을 자체 리눅스 VM 위에 최소 설정으로 구축하기 위한 Docker Compose 번들. (2026-04-23 현재 웹 리서치 노트의 최종 비교 대상은 Open WebUI+Bedrock / Q Business / M365 Copilot 3개로 축소되어 이 번들은 참고 자료 성격으로 유지됩니다.)

## 이 프로토타입이 하는 일

```
[사용자 / 영업팀]
   │  (Dify Knowledge 에 드래그 & 드롭)
   ▼
[Dify] ── Knowledge Pipeline (OCR · 파싱 · 청킹 · 임베딩) ──▶ [Weaviate]
   │                                                             │
   └─────▶  Bedrock API  ──▶  [Amazon Bedrock]
                                   · Claude Sonnet 계열
                                   · Titan Embeddings v2
```

- **Dify** : 업로드 UI · 지식베이스 · 임베딩/검색 · 워크플로우 · 챗봇 UI
- **Bedrock** : LLM 추론 + 임베딩. 도쿄 리전, 학습 미사용 약관

## 빠른 시작 (10 ~ 20분)

```bash
# 1. 이 폴더를 VM 으로 가져간 뒤
cd oss-hosting

# 2. 환경변수 템플릿을 .env 로 복사 후 편집
cp .env.example .env
vi .env          # AWS 키 기입

# 3. 한 방에 기동
chmod +x setup.sh
./setup.sh
```

스크립트가 Dify 공식 리포 clone, 스택 기동, 헬스 체크까지 자동 수행.

이후 웹 UI 설정은 한 번:

- [03-post-install.md](./docs/03-post-install.md) - Dify 관리자 계정 + Bedrock provider 연결 + Knowledge 생성 · 파일 업로드

## 문서 가이드

| 문서 | 언제 |
|---|---|
| [01-prerequisites.md](./docs/01-prerequisites.md)  | 시작 전 VM / AWS 준비 체크리스트 |
| [02-install.md](./docs/02-install.md)              | 실제 설치 (위의 빠른 시작 상세판) |
| [03-post-install.md](./docs/03-post-install.md)    | Dify · Bedrock 초기 설정 + Knowledge + 파일 업로드 |
| [05-troubleshooting.md](./docs/05-troubleshooting.md) | 시연 중 막혔을 때 |
| [06-ollama.md](./docs/06-ollama.md)                | (선택) 사내 Ollama 도 Dify 에 연결해 Bedrock 과 비교 시연 |

## 추가 케이스: 사내 Ollama 연결 (선택)

사내 VM 에 이미 운영 중인 **Ollama** 를 Dify 에 추가 프로바이더로 붙여 Bedrock 과 비교 시연할 수 있습니다. LLM(`gemma4:26b`) + 임베딩(`bge-m3`) 모두 같은 Ollama 인스턴스에서 제공합니다.

```bash
# Bedrock + 사내 Ollama overlay 포함
./setup.sh --with-ollama
```

상세 절차는 [06-ollama.md](./docs/06-ollama.md). 시연 중 **Settings → System Model Settings** 드롭다운을 바꾸면 같은 Dify UI 안에서 두 케이스가 토글됩니다.

## 파일 구조

```
oss-hosting/
├── README.md                  ← 지금 이 파일
├── setup.sh                   ← 원샷 부트스트랩
├── .env.example               ← 환경변수 템플릿 (.env 로 복사해서 사용)
├── compose.ollama.yml         ← (선택) 사내 Ollama 연결용 overlay
├── docs/                      ← 단계별 세부 가이드
└── dify/                      ← setup.sh 가 clone (커밋 대상 아님)
```

## 설계 원칙

1. **Dify 공식 compose 를 fork 하지 않는다** - `./dify/` 는 shallow clone 하고, 우리 변경분은 환경변수 · overlay 만. 업그레이드 시 `cd dify && git pull` 한 번으로 끝.
2. **시크릿은 `.env` 한 곳**에만. `.gitignore` 에 `.env` 포함. 코드에 키를 박지 않음.
3. **사내 보관** - 모든 업로드 파일은 MCNC VM 내부 (Dify Weaviate) 에 저장. 외부로 나가는 것은 Bedrock API 호출 시의 프롬프트 뿐이며, Bedrock 은 고객 데이터를 학습에 사용하지 않음 (리서치 페이지 `data-policy` 섹션 참고).
4. **Dify 네이티브 업로드** - 파일 업로드 · 다중 파일 · 진행률 · 즉시 인제스트 모두 Dify UI 로 일원화. 별도 파일 서버/동기화 불필요.

## 프로토타입이 다루지 않는 것

이 번들은 "시연 가능한 상태까지 최단 경로"가 목표이므로 아래는 의도적으로 포함하지 않습니다.

- HTTPS / 리버스 프록시 (시연 이후 Caddy 추가 권장)
- Dify Enterprise Edition 기능 (SAML · SSO 등)
- 백업 · 모니터링 · 알람
- 고가용성 / 다중 노드

프로덕션 투입 시 고려사항은 리서치 페이지의 "강점과 약점" 섹션을 참조.

## 비용 힌트

- 이 스택 자체는 **모두 오픈소스 / 무료**. Dify Community.
- AWS 과금은 Bedrock LLM 호출 + (선택) VPC Endpoint 만. 리서치 페이지의 "LLM 토큰 사용 비용" 표 기준 50명 1개월 평균 약 $150.
- 시연 · 검증 단계에서는 $50 미만 예상 (리서치 페이지 "프로토타입 비용" 섹션).

## 참고

- Dify: <https://github.com/langgenius/dify>, <https://docs.dify.ai/>
- Bedrock: <https://aws.amazon.com/bedrock/pricing/>
- 상위 리서치: [../index.html](../index.html)
