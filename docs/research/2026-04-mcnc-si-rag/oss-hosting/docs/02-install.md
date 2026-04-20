# 02. 설치 (원샷 부트스트랩)

선결 조건([01-prerequisites.md](./01-prerequisites.md))이 모두 충족된 VM 에서 진행합니다.

## 1) 코드 배치

이 `oss-hosting/` 폴더만 VM 으로 가져가면 됩니다.

### 방법 A - git clone (private 레포 액세스 있음)

```bash
git clone https://github.com/<org>/reya-archive.git
cd reya-archive/research-notes/docs/research/2026-04-mcnc-si-rag/oss-hosting
```

### 방법 B - 폴더만 scp

로컬에서:

```bash
scp -r ./oss-hosting ubuntu@<VM_IP>:~/rag-prototype
```

VM 에서:

```bash
ssh ubuntu@<VM_IP>
cd ~/rag-prototype
```

## 2) `.env` 작성

```bash
cp .env.example .env
vi .env
```

필수 수정 항목:

| 항목 | 값 |
|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | 01 장에서 발급한 IAM 키 |

나머지 값 (`COMPOSE_PROFILES`, `BEDROCK_*`, `OLLAMA_*`) 은 기본값 그대로 두시면 됩니다.

## 3) 부트스트랩 실행

```bash
chmod +x setup.sh
./setup.sh
```

스크립트가 하는 일:

1. docker / docker compose / git 확인
2. `./dify/` 에 Dify 공식 리포 shallow clone
3. `dify/docker/.env` 생성 (수정 없이 기본값)
4. Dify 공식 compose 로 `up -d`
5. 포트 80 응답 대기 (최대 3분)
6. 접근 URL 과 다음 단계 출력

최초 실행은 이미지 pull + 초기 DB 마이그레이션 때문에 **5 ~ 10 분** 정도 걸립니다.

## 4) 성공 판단

스크립트 말미에 녹색 박스가 나오면 기동 완료입니다. 브라우저에서:

- `http://<VM_IP>/` → Dify 초기 설정 화면

`docker compose ps` 로 전체 컨테이너 상태를 볼 수도 있습니다.

```bash
docker compose \
  -f dify/docker/docker-compose.yaml \
  --env-file .env \
  ps
```

모두 `running` 또는 `healthy` 상태여야 합니다.

## 5) 자주 묻는 초기 실패

| 증상 | 원인 | 조치 |
|---|---|---|
| `setup.sh: Permission denied` | 실행 비트 없음 | `chmod +x setup.sh` |
| `docker: command not found` | Docker 미설치 | 01 장 1) 항목 |
| `cannot start service nginx: Bind for 0.0.0.0:80 failed` | 호스트 포트 80 점유 | `sudo ss -lntp | grep :80` 으로 점유 프로세스 확인 후 중단 |
| 브라우저에 `502 Bad Gateway` 가 뜸 | `api` 가 `db_postgres` 를 못 찾음 (COMPOSE_PROFILES 누락) | `.env` 에 `COMPOSE_PROFILES=weaviate,postgresql` 확인 |

더 많은 케이스는 [05-troubleshooting.md](./05-troubleshooting.md).

---

기동이 확인되면 [03-post-install.md](./03-post-install.md) 로 진행.
