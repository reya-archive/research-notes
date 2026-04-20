# 06. 사내 Ollama 연결 (선택)

Bedrock 기본 구성에 **사내 VM 의 Ollama** 를 추가 모델 프로바이더로 붙여, 같은 Dify 안에서 "Bedrock vs 사내 셀프호스팅" 을 토글하며 시연하기 위한 절차입니다.

시연 흐름:

| 케이스 | LLM | 임베딩 |
|---|---|---|
| **Bedrock** (관리형) | Claude Sonnet 계열 | Titan Embeddings v2 |
| **사내 Ollama** (셀프호스팅) | `gemma4:26b` | `bge-m3` |

LLM + 임베딩을 **Ollama 한 프로바이더에서 모두 제공**하므로 추가 컨테이너나 어댑터는 필요 없습니다.

> 임베딩 모델을 바꾸면 기존 색인이 의미를 잃습니다. 시연 때 지식베이스를 "Bedrock 임베딩 전용" · "Ollama 임베딩 전용" 두 개로 분리해 두면 드롭다운만 바꿔 비교 가능 (이 문서 4) 항목).

---

## 0) 선결 조건

VM 에서 다음 명령이 모두 응답해야 합니다.

```bash
# Ollama 리슨 중 + 필요 모델 보유
curl -fsS http://localhost:11434/api/tags | grep -E 'gemma4:26b|bge-m3'
```

Ollama 가 `127.0.0.1` 만 리슨 중이면 **컨테이너 안에서 접근 불가**합니다. systemd 기준 수정:

```bash
sudo systemctl edit ollama
#   [Service]
#   Environment="OLLAMA_HOST=0.0.0.0:11434"
sudo systemctl daemon-reload && sudo systemctl restart ollama

ss -lntp | grep 11434        # 0.0.0.0:11434 로 리슨 중인지 확인
```

모델 미설치 시:

```bash
ollama pull gemma4:26b
ollama pull bge-m3
```

두 모델을 미리 keep-alive 시켜 두면 시연 중 첫 응답이 빠릅니다:

```bash
curl -s http://localhost:11434/api/generate -d '{"model":"gemma4:26b","prompt":""}' >/dev/null &
curl -s http://localhost:11434/api/embed    -d '{"model":"bge-m3","input":""}'     >/dev/null &
wait
ollama ps
```

## 1) Ollama overlay 를 포함해 스택 기동

```bash
./setup.sh --with-ollama
```

이미 Bedrock 단독으로 떠 있더라도 재실행 안전합니다. 스크립트가 `compose.ollama.yml` 을 추가해 Dify `api` / `worker` 에 `host.docker.internal` DNS 매핑을 얹고 기동합니다.

확인:

```bash
docker compose \
  -f dify/docker/docker-compose.yaml \
  -f compose.ollama.yml \
  --env-file .env \
  exec api getent hosts host.docker.internal
# 172.x.x.x host.docker.internal
```

## 2) Dify 에 Ollama 프로바이더 추가 (LLM + 임베딩)

Dify → **Settings → Model Provider → Ollama → Setup**.

### LLM 추가

| 필드 | 값 |
|---|---|
| Model Name           | `gemma4:26b` |
| Base URL             | `http://host.docker.internal:11434` |
| Model Type           | LLM |
| Completion Mode      | Chat |
| Model Context Size   | 8192 |
| Maximum Token Limit  | 4096 |
| Support Vision       | (해제) |

**Save** → 녹색 체크 확인. 필요하면 `gemma4:31b` 도 같은 방식으로 하나 더 등록해 시연 중 드롭다운으로 바꿀 수 있습니다.

### 임베딩 추가

같은 Ollama 프로바이더 화면에서 **+ Add Model** 클릭.

| 필드 | 값 |
|---|---|
| Model Name      | `bge-m3` |
| Model Type      | Text Embedding |
| Base URL        | `http://host.docker.internal:11434` |
| Max Tokens      | 8192 |

**Save** → 녹색 체크 확인.

## 3) 시스템 모델 스위칭으로 케이스 토글

**Settings → Model Provider → System Model Settings**

| 케이스 | Reasoning Model | Embedding Model |
|---|---|---|
| Bedrock          | `Claude Sonnet 계열` (Bedrock) | `Titan Embeddings v2` (Bedrock) |
| 사내 Ollama      | `gemma4:26b` (Ollama)          | `bge-m3` (Ollama) |

**Save** 한 번으로 다음 질의부터 바로 적용됩니다.

## 4) (권장) 케이스별 지식베이스 분리

임베딩 모델이 다르면 같은 문서도 벡터가 완전히 다릅니다. 시연을 드라마틱하게 만들려면 두 지식베이스를 따로 만들어 두세요.

1. Dify → Knowledge → **Create Knowledge** → `rag-demo-bedrock` 생성 (System Model 을 Titan v2 로 둔 상태에서 파일 업로드)
2. System Model Settings 에서 Embedding Model 을 `bge-m3` (Ollama) 로 전환
3. Dify → Knowledge → **Create Knowledge** → `rag-demo-ollama` 생성 (같은 파일을 다시 업로드)

시연 중엔 Studio 챗봇 앱의 **Context** 에 연결된 지식베이스만 드롭다운으로 바꾸면 됩니다. 단순 비교만 보여주면 충분하다면 기존 지식베이스 하나에서 System Model 만 바꿔도 되지만 검색 품질이 엉킬 수 있습니다.

## 5) 트러블슈팅

| 증상 | 조치 |
|---|---|
| Dify 에서 Ollama 저장 시 `connection refused` | Ollama 가 `127.0.0.1` 만 리슨. `OLLAMA_HOST=0.0.0.0:11434` 로 재기동 |
| 저장 성공했지만 "model not found" | `ollama pull gemma4:26b` / `ollama pull bge-m3` 확인 |
| Dify 재기동 직후 `no such host` | `docker compose ... up -d --force-recreate api worker` 로 extra_hosts 반영 |
| 첫 추론이 너무 느림 | `ollama ps` 로 모델이 로드됐는지 확인. 위 0) 의 keep-alive 스크립트 실행 |
| GPU VRAM 부족 | 26B + bge-m3 동시 로드 시 16GB 카드는 빠듯. `OLLAMA_MAX_LOADED_MODELS=2` 설정하거나 gemma4:26b 대신 더 작은 모델 선택 |

---

시연 후 Ollama overlay 를 빼고 Bedrock 단독 구성으로 돌아가려면 옵션 없이 재기동:

```bash
./setup.sh
```

Ollama 쪽 등록은 Dify DB 에 남아 있으므로, Base URL 호출이 실패하는 동안 Dify UI 에서 해당 프로바이더에 "unreachable" 표시가 뜰 수 있습니다. 완전히 정리하려면 Dify Settings → Model Provider → Ollama → Remove 로 제거.
