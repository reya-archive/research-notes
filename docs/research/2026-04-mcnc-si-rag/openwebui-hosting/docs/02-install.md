# 02. 설치

[01-prerequisites.md](./01-prerequisites.md) 를 통과했다는 가정에서 시작합니다.

## 1. 번들을 VM 으로 가져오기

레포 전체를 clone 하는 대신, **이 폴더(`openwebui-hosting/`) 만** 내려받아도 됩니다.

### 방법 A. git sparse-checkout

```bash
git clone --filter=blob:none --sparse --depth 1 \
  <이 레포 URL> research-notes
cd research-notes
git sparse-checkout set docs/research/2026-04-mcnc-si-rag/openwebui-hosting
cd docs/research/2026-04-mcnc-si-rag/openwebui-hosting
```

### 방법 B. scp · rsync · tar

로컬에서 VM 으로 직접 전송.

```bash
tar czf openwebui-hosting.tgz -C docs/research/2026-04-mcnc-si-rag openwebui-hosting
scp openwebui-hosting.tgz user@vm:/home/user/
ssh user@vm 'tar xzf openwebui-hosting.tgz && cd openwebui-hosting'
```

## 2. 환경변수 작성

```bash
cp .env.example .env
vi .env
```

채워야 할 값:

| 키 | 값 |
|---|---|
| `AWS_ACCESS_KEY_ID`     | IAM Programmatic access key |
| `AWS_SECRET_ACCESS_KEY` | 위 키의 시크릿 |
| `LITELLM_MASTER_KEY`    | `openssl rand -hex 32` |
| `WEBUI_SECRET_KEY`      | `openssl rand -hex 32` (세션 JWT 서명용) |

선택 조정:

| 키 | 기본값 | 비고 |
|---|---|---|
| `AWS_REGION`       | `ap-northeast-1` | 도쿄 고정 |
| `LITELLM_PORT`     | `14000`           | 외부 클라이언트용 |
| `OPENWEBUI_PORT`   | `13000`           | 브라우저 접속 |
| `WEBUI_NAME`       | `MCNC RAG Lab`    | 상단 표시 이름 |

## 3. 기동

```bash
chmod +x setup.sh
./setup.sh
```

스크립트가 아래를 순차 수행합니다.

1. docker / docker compose / curl 존재 확인
2. `.env` placeholder 남아 있으면 경고
3. 이미지 pull + 두 컨테이너 up (`openwebui-hosting-litellm`, `openwebui-hosting-webui`)
4. LiteLLM 헬스 체크 → Open WebUI 헬스 체크 (최대 각 2분)
5. Open WebUI 접속 URL · 최초 관리자 안내 · LiteLLM Bearer 토큰 출력

정상이면 종료 화면에 접속 URL 이 표시됩니다.

## 4. 로그 · 상태 확인

```bash
# 실시간 로그
docker compose logs -f litellm
docker compose logs -f open-webui

# 컨테이너 상태 (healthcheck 포함)
docker compose ps

# 재시작 (예: litellm_config.yaml 수정 후 반영)
docker compose restart litellm

# 중지 · 전체 정리 (볼륨은 유지됨 - 대화/사용자 보존)
docker compose down

# 볼륨까지 전부 삭제 (주의: 모든 데이터 손실)
docker compose down -v
```

## 5. 엔드포인트 확인

```bash
# LiteLLM 기동 여부 (포트는 .env 기준)
source .env
curl http://localhost:${LITELLM_PORT}/health/liveliness
# {"status":"healthy"}

# 등록된 모델 목록
curl http://localhost:${LITELLM_PORT}/v1/models \
  -H "Authorization: Bearer ${LITELLM_MASTER_KEY}"

# Open WebUI
curl -I http://localhost:${OPENWEBUI_PORT}/
# HTTP/1.1 200 OK 또는 리다이렉트
```

`/v1/models` 응답에 아래 2개가 보이면 성공.

- `claude-sonnet-4-6`
- `titan-embed-v2`

Sonnet 4.5 · Haiku 4.5 는 `litellm_config.yaml` 주석 블록에 있음 - 필요해지면 해당 블록 주석만 해제하고 `docker compose restart litellm`.

## 6. 설정 변경 시 반영 절차

| 바뀐 것 | 명령 |
|---|---|
| `litellm_config.yaml` (모델 · 타임아웃 등) | `docker compose restart litellm` |
| `.env` 의 환경변수 | `docker compose --env-file .env up -d` (컨테이너 재생성) |
| `.env` 의 포트 값 | 위와 동일 (호스트 포트 바인딩 재구성) |
| Open WebUI Admin Panel 에서 한 설정 | 재시작 불필요 (볼륨에 자동 저장) |

## 다음 단계

- 최초 관리자 계정 · RAG Knowledge 테스트 → [03-post-install.md](./03-post-install.md)
- Admin Panel 세팅 체크리스트 → [04-admin-settings.md](./04-admin-settings.md)
- 막혔다면 → [05-troubleshooting.md](./05-troubleshooting.md)
