# 04. Admin Panel 최초 세팅 체크리스트

[03-post-install.md](./03-post-install.md) 에서 관리자 계정 생성과 기본 동작 확인까지 끝났다는 가정에서 시작합니다.

## 왜 문서로만 정리하는가

Open WebUI 의 많은 설정(Arena · RAG 청크/Top-K · 임베딩 모델 · Signup 등) 은 **PersistentConfig** 로 분류되어 있어, `docker-compose.yml` 의 env 는 **첫 부팅 시에만 DB 에 seed** 됩니다. 이후에는 DB 값이 우선이라 env 를 고쳐도 무시됩니다. 실제로 env 만으로 안정적으로 맞추기가 힘들어, **번들이 새로 기동된 뒤 Admin Panel 에서 한 번 정리하는 흐름**이 가장 단순합니다.

아래 순서대로 체크하면 10분 내외로 세팅이 끝납니다.

## 전제

- 번들이 기동되어 `http://<VM>:13000` 으로 로그인 가능한 상태
- 첫 signup 으로 만든 **관리자 계정**으로 접속 중

---

## 1. Arena Models 숨기기

기본값으로 Open WebUI 의 "Arena 샘플 모델" 들이 드롭다운에 섞여 보일 수 있습니다. 이 번들은 LiteLLM 전용이라 불필요.

**Admin Panel → Settings → Evaluations**

- **Arena Models** 토글 → **OFF**
- 저장

드롭다운 다시 열었을 때 `arena-model` 계열이 사라지면 성공.

---

## 2. 임베딩(Documents) 설정 확인

`docker-compose.yml` 의 `RAG_EMBEDDING_*` env 가 첫 부팅에 seed 되어 있어야 정상이지만, **UI 에서 한 번 눈으로 확인** 권장.

**Admin Panel → Settings → Documents**

| 필드 | 값 |
|---|---|
| Embedding Model Engine | `OpenAI` |
| OpenAI API Base URL | `http://litellm:4000/v1` |
| OpenAI API Key | `.env` 의 `LITELLM_MASTER_KEY` 값 |
| Embedding Model | `titan-embed-v2` |
| Hybrid Search | 필요 시 ON (한국어 단답 질의에는 ON 이 유리) |

값이 비어 있거나 다르면 위 표대로 직접 입력 후 **Save**.

---

## 3. 청크 · 검색 파라미터 (한국어 문서 기준 튜닝)

같은 **Settings → Documents** 하단의 "Chunk Params" 영역.

| 필드 | 기본값 | 권장값 | 이유 |
|---|---|---|---|
| **Chunk Size** | 1500 | **800** | 한국어 토큰이 영어보다 조금 짧아 1500 은 과대. 800 정도가 맥락 유지 + 검색 정확도 균형 |
| **Chunk Overlap** | 100 | **150** | 청크 경계에서 문맥이 끊기는 걸 완화 |
| **Top K** | 3 | **5** | 한국어 검색 recall 보완 |
| PDF Extract Images | Off | Off (그대로) | Titan 은 텍스트 전용이라 이미지 파싱 불필요 |

저장 후 **기존 Knowledge 가 있다면 재인덱싱 필요** — Knowledge 페이지에서 각 Knowledge → `Reindex` 버튼.

---

## 4. 모델 드롭다운 정리

채팅 UI 드롭다운에 임베딩 전용 모델(`titan-embed-v2`) 이 떠 있으면 사용자 혼란. 숨기기.

**Admin Panel → Workspace → Models** (또는 **Settings → Models**)

- `titan-embed-v2` 항목 → **Visibility** 또는 토글 → **OFF**
  - RAG 경로(`RAG_OPENAI_API_*`) 는 별개로 호출되므로 여기서 OFF 해도 Knowledge 임베딩은 정상 동작
- `claude-sonnet-4-6` 은 ON 유지

`litellm_config.yaml` 에서 Sonnet 4.5 · Haiku 4.5 를 주석 해제했다면 같은 화면에서 그 모델들도 관리.

---

## 5. 커스텀 Model (에이전트) 생성

사내 용도별 에이전트를 만들어 사용자가 항상 같은 시스템 프롬프트 · 같은 Knowledge 로 채팅하도록.

**Workspace → Models → + Create**

입력 필드:

| 필드 | 예시 |
|---|---|
| **Name** | `MCNC 지식봇` |
| **Base Model** | `claude-sonnet-4-6` |
| **System Prompt** | 한국어로 답변 · 출처 인용 · 특정 어조 등 지침 |
| **Knowledge** | (선택) 앞에서 만든 Knowledge 붙이면 이 에이전트는 항상 그 문서를 참고 |
| **Advanced Params** | (선택) temperature · max_tokens |

저장 후 상단 드롭다운에 새 항목으로 등장.

### 시스템 프롬프트 작성 팁

- "당신은 MCNC 내부 규정 전문 어시스턴트입니다" 같은 역할 선언
- "첨부된 Knowledge 에서 찾을 수 있는 내용만 답하고, 없으면 모른다고 명시" 같은 가드
- 출력 형식 지정 (예: "항상 한국어 존댓말", "답변 하단에 [출처: 파일명] 표기")

---

## 6. 백업 (매우 권장)

Model · Knowledge · 대화 등은 전부 `openwebui-hosting-data` 볼륨의 SQLite DB 에 들어 있습니다. `docker compose down -v` 하거나 번들을 재설치하면 사라집니다.

최소한 **커스텀 Model 은 JSON 으로 export** 해 두세요. 재설치 시 5번을 다시 하지 않아도 됩니다.

**Admin Panel → Workspace → Models → 각 Model 우측 메뉴 → Export**

- 파일을 로컬에 저장 (`my-agent.json` 등)
- 새 환경에서 같은 화면 → **Import** 로 복원

전체 백업이 필요하면 VM 에서:

```bash
docker compose exec open-webui tar czf - /app/backend/data > webui-backup.tar.gz
```

---

## 7. (선택) Signup 추가 차단

기본 상태는 `ENABLE_SIGNUP=true` + `DEFAULT_USER_ROLE=pending` 이라, 누구나 signup 시도는 가능하되 관리자 승인 없이는 로그인 불가. 더 확실히 잠그고 싶다면 env 말고 UI 에서 끌 수 있습니다.

**Admin Panel → Settings → General → User Permissions → Signup** → OFF

이후에는 Admin Panel → **Users** 에서 수동 초대 · 계정 생성만 가능.

---

## 체크리스트 요약

- [ ] 1. Evaluations → Arena Models OFF
- [ ] 2. Documents → Embedding Engine/Model/Base URL/API Key 확인
- [ ] 3. Documents → Chunk 800 · Overlap 150 · Top K 5
- [ ] 4. Workspace → Models → titan-embed-v2 숨김
- [ ] 5. Workspace → Models → 커스텀 에이전트 생성 + System Prompt
- [ ] 6. Workspace → Models → Export 로 백업
- [ ] 7. (선택) Signup 완전 차단

## 다음 단계

- 기동 · 설정이 꼬이면 → [05-troubleshooting.md](./05-troubleshooting.md)
- 외부 클라이언트(Python SDK · curl) 에서 직접 LiteLLM 호출 → [03-post-install.md](./03-post-install.md#e-외부-클라이언트-선택)
