# 05. 트러블슈팅

시연 당일 마주칠 확률이 높은 것부터 정리. 대부분 `.env` 수정 + 해당 서비스 재기동으로 해결됩니다.

## 공통 - 로그 빠르게 보기

```bash
# 반복 사용하는 compose 명령은 alias 를 두는 편이 편합니다.
alias rag-compose='docker compose \
  -f dify/docker/docker-compose.yaml \
  --env-file .env'

rag-compose ps
rag-compose logs --tail 100 nginx
rag-compose logs --tail 100 api
rag-compose logs --tail 100 db_postgres
rag-compose logs --tail 100 weaviate
```

---

## Dify 관련

### `db_postgres` 가 안 뜸 + api 가 "could not translate host name db_postgres" 로 재시작 루프 + 502

원인: Dify 1.x 의 compose 는 `db_postgres`, `weaviate` 를 profile 뒤에 숨겨두었는데, `COMPOSE_PROFILES` 가 비어 있으면 해당 서비스가 아예 기동되지 않습니다. `--env-file` 을 지정하면 Dify 의 `dify/docker/.env` 에 설정된 기본 프로필도 무시됩니다.

조치: `oss-hosting/.env` 에 아래 한 줄이 있어야 합니다 (`.env.example` 최신본에는 포함됨).

```bash
echo 'COMPOSE_PROFILES=weaviate,postgresql' >> .env
rag-compose down
rag-compose up -d
```

`setup.sh` 는 .env 에 이 값이 없으면 자동으로 `weaviate,postgresql` 을 export 해 보정하지만, **이미 쓴 옛 .env 를 재사용할 땐 수동으로 추가**하세요.

### 80 포트가 이미 점유됨

```
Error starting userland proxy: listen tcp4 0.0.0.0:80: bind: address already in use
```

원인: VM 에 다른 웹 서버(nginx, apache, Caddy 등) 가 구동 중.

조치:

```bash
sudo ss -lntp | grep :80    # 점유 프로세스 확인
# (A) 중단 가능하면 중단
# (B) 불가하면 Dify 포트를 바꿈:
vi dify/docker/.env
#   EXPOSE_NGINX_PORT=8000   으로 변경
rag-compose up -d nginx
```

### `http://VM_IP/install` 이 404 를 줌

Dify 가 이미 설치된 상태. `/signin` 으로 로그인하세요.

### Model Provider 저장 시 "Credentials validated" 안 뜸

| 메시지 | 원인 | 조치 |
|---|---|---|
| `AccessDenied`         | 해당 모델이 리전에서 미활성 | [01-prerequisites.md](./01-prerequisites.md) 3) CLI 호출 테스트로 확인 후 콘솔에서 Enable |
| `on-demand throughput isn't supported` | Claude 4.x 를 직접 model ID 로 입력함 | `jp.anthropic.claude-sonnet-4-6` 같은 inference profile ID 로 교체 (03-post-install 3) |
| `Too many tokens per day` | 단기 API 키 일일 토큰 쿼터 소진 | Long-term API 키 재발급 또는 IAM AKID/SAK 로 전환 |
| `SignatureDoesNotMatch`| Access Key 오타           | IAM 콘솔에서 키 확인 / 재발급 |
| `Unable to locate credentials` | 필드 공백 | 세 필드 모두 입력되었는지 재확인 |
| `ConnectTimeout`       | 네트워크 경로 문제         | VM 에서 `curl -I https://bedrock.ap-northeast-1.amazonaws.com` |

### 지식베이스 문서가 "Error" 상태로 뜸

문서 종류별 파싱 한도/제약이 걸렸을 수 있습니다. Dify 지식베이스 문서 상세 화면의 에러 메시지를 먼저 확인. 드물게 모델 비용/쿼터 부족이 원인일 수도 있으니 AWS Billing 도 확인하세요.

---

## Ollama 연결 (`--with-ollama` 사용 시)

전용 트러블슈팅은 [06-ollama.md](./06-ollama.md) 5) 항목에 모았습니다. 빈도 높은 것만 여기 요약:

| 증상 | 조치 |
|---|---|
| Dify 에서 Ollama 저장 시 `connection refused` | Ollama 가 `127.0.0.1` 만 리슨. `OLLAMA_HOST=0.0.0.0:11434` 로 재기동 |
| Ollama 는 뜨는데 `no such host` | Dify api/worker 재시작 필요: `rag-compose up -d --force-recreate api worker` |
| "model not found" | `ollama pull gemma4:26b` / `ollama pull bge-m3` 로 모델 다운로드 |
| 첫 응답이 매우 느림 | 모델 로드 시간. `ollama ps` 로 keep-alive 상태 확인 |

---

## 자주 묻는 운영 명령

```bash
# 전체 스택 중단
rag-compose stop

# 전체 스택 재기동 (이미지 재pull 없음)
rag-compose up -d

# 이미지 최신 업데이트
rag-compose pull
rag-compose up -d

# 모든 것을 완전 리셋 (볼륨 포함 - 데이터 사라집니다!)
rag-compose down -v

# Dify 버전 업그레이드
(cd dify && git pull)
rag-compose up -d
```

---

## 완전히 막히면

1. 이 폴더의 `rag-compose logs` 출력 + `.env` (민감정보 삭제) 를 캡처
2. 리서치 페이지의 Dify 자세히 보기 (`pages/01-dify-bedrock.html`) 참고 링크 중 Dify GitHub Issues 에서 유사 사례 검색
3. 필요하면 사내 Slack 의 #rag-prototype 채널에 로그 공유
