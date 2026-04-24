# 07. 예시 질의집 - MCNC 사내 규정 및 시스템 가이드

[05-openwebui-rag-tuning.md](./05-openwebui-rag-tuning.md) 에서 맞춘 RAG 튜닝값이 실제 MCNC 문서군에서 제대로 동작하는지 확인하기 위한 **시연/검증용 질의 모음** 입니다. Open WebUI 채팅창에서 `#` 으로 Knowledge 를 지정한 뒤 그대로 복붙해 쓰면 됩니다.

## 대상 Knowledge

`MCNC 사내 규정 및 시스템 가이드` Knowledge 에 업로드된 문서:

| 분류 | 문서 | 포맷 | 특징 |
|---|---|---|---|
| 규정 | 모빌씨앤씨 규정(2026_공지) | XLSX | 표 중심, 연도별 변경사항 |
| 시스템 가이드 (Flex) | 시스템 개요, 연차 신청, 휴가 결재, 잔여내역, 기타 휴가, 구성원 목록, 조직도 | Markdown | 표 + 한/영 혼용 용어 |
| 시스템 가이드 (Yuga) | 시스템 개요, 타임카드 입력, 초과근무·제출취소, 프로젝트 멤버, 타임카드 마감 | Markdown | 표 + 용어(`ACCUMULATED MM`, `ASSIGNED MM`) |
| RAG 활용 | MCP 도구 예시집, 마크다운 문서작성 가이드 | Markdown | 코드 블록 포함 |
| 제품 가이드 | MCP 개발자 가이드, RAG Portal 사용자 가이드, RAG 서비스 설치 가이드 | PPTX | 슬라이드 + 스크린샷 |
| 양식 | 2026년 프로젝트 손익분석 양식 | XLSX | 숫자 표, 수식 |

## 질의 카테고리 설계 근거

[05-openwebui-rag-tuning.md](./05-openwebui-rag-tuning.md) 의 시뮬레이션 섹션과 동일한 분류를 따릅니다. 각 카테고리는 튜닝 옵션 중 특정 조합을 자극해 **어느 설정이 실제로 기여하는지** 를 눈으로 볼 수 있게 설계했습니다.

| 카테고리 | 자극하는 설정 | 잘 나오지 않으면 조정할 곳 |
|---|---|---|
| 정확 매칭 (식별자·수치) | Hybrid Search, BM25 Weight | BM25 가중치 0.5 → 0.6, Enrich Hybrid Text ON |
| 서술/요약 | Vector, Chunk Size, Markdown Header Splitter | Chunk Size 800, Chunk Overlap 150 |
| 비교/대조 | Top K, Top K Reranker | Top K 8, Reranker ON |
| 나열/종합 | Top K 상향, Full Context 여부 | Top K 8 이상 |
| 복합·한영 혼용 | Enrich Hybrid Search Text, Reranker | Enrich ON, Reranker ON |
| 한계 확인 (no-answer) | RAG 템플릿, Relevance Threshold | 템플릿 "찾지 못했습니다" 규칙, Threshold 0.2 |

---

## 예시 질의 10종

각 질의는 **복붙용 프롬프트 → 기대 답변 요지 → 검증 포인트** 순서입니다. 기대 답변은 출처 문서의 핵심만 요약한 것이라 실제 LLM 답변 문장은 다를 수 있습니다. 검증 포인트가 모두 통과하면 OK.

### Q1. 정확 매칭 (표 hit)

```
Flex에서 연차 신청 시 고를 수 있는 기간 옵션 4가지와 각각의 시간은?
```

기대 답변 요지:
- All Day (8시간), Morning (4시간), Afternoon (4시간), Time (2시간)

검증 포인트:
- [ ] 4개 옵션이 모두 나열되는가
- [ ] 각 옵션의 시간 값이 정확한가
- [ ] `[출처: 플렉스-연차휴가-신청-절차.md]` 인용이 붙는가

### Q2. 정확 매칭 (엑셀 표)

```
2026년에 점심시간이 어떻게 변경됐나요?
```

기대 답변 요지:
- 변경 전: 오전 11시 30분 ~ 오후 12시 30분
- 변경 후: 오후 12시 ~ 오후 1시

검증 포인트:
- [ ] 시간 범위가 정확히 표시되는가
- [ ] `[출처: 모빌씨앤씨 규정(2026_공지).xlsx]` 인용이 붙는가
- [ ] XLSX 가 Tika 로 제대로 파싱됐는지 간접 확인 (엉뚱한 답 나오면 콘텐츠 추출 엔진 체크)

### Q3. 서술/요약

```
Flex Team에서 연차를 신청하는 전체 절차를 단계별로 알려주세요.
```

기대 답변 요지:
1. 하단 메뉴 Time Off → Overview → Annual time off 카드 클릭
2. 달력에서 날짜 선택 (기간 또는 단일)
3. 단일 날짜면 기간 옵션(All Day/Morning/Afternoon/Time) 선택
4. 사유 입력
5. Select Reference 로 참조인 · 결재자 지정
6. Request Approval 제출

검증 포인트:
- [ ] 5~6 단계로 순서가 올바르게 나오는가
- [ ] 단계 번호가 섞이지 않고 재정렬되어 있는가
- [ ] Markdown Header Splitter 가 잘 동작했다면 "날짜 선택" · "사유 입력" 같은 섹션 제목이 드러나는가

### Q4. 비교/대조 (결재라인)

```
일반 휴가(5일 미만)와 장기 휴가(5일 이상)의 결재라인 차이를 비교해주세요.
```

기대 답변 요지:
- 일반 휴가 참조인: CEO, President, HR/Admin, 동료
- 장기 휴가 참조인: HR/Admin, 동료 (CEO/President 는 결재자로 이동)
- 일반 휴가 결재자: Owner - Leader Team - PM - Manager - Head of Division
- 장기 휴가 결재자: 위 + CEO - President

검증 포인트:
- [ ] 두 경우의 **참조인 차이** 가 명확히 언급되는가
- [ ] **결재자 순서** 가 올바르게 나열되는가
- [ ] 표로 답하면 가독성이 크게 향상되므로 RAG 템플릿에 "표 적절하면 표 사용" 규칙이 반영됐는지 확인

### Q5. 비교/대조 (시스템 내 용어)

```
Yuga 타임카드의 Save와 Submit은 어떻게 다른가요?
```

기대 답변 요지:
- Save: 임시 저장, 승인 워크플로우로 넘어가지 않음, 행 편집 가능 유지
- Submit: 제출, 승인 프로세스 진입, 이후 수정하려면 Request Unsubmit 필요

검증 포인트:
- [ ] "임시" 와 "제출" 의 구분이 명확히 설명되는가
- [ ] Submit 이후 수정 경로(제출 취소) 까지 교차 참조되면 가산점 (Reranker ON 시 더 잘 나옴)

### Q6. 나열/종합 (메뉴)

```
Flex Team의 하단 네비게이션 메뉴를 모두 나열해주세요.
```

기대 답변 요지:
- Home Feed, People, Work, Time Off, Workflow, Documents (총 6개)

검증 포인트:
- [ ] 6개 메뉴가 모두 나오는가 (Top K 가 충분한지 확인)
- [ ] 각 메뉴의 경로(`/home`, `/people` 등) 도 같이 언급되면 좋음
- [ ] 누락되는 메뉴가 있으면 Top K 8 이 충분하지 않거나 해당 표가 한 청크에 안 들어간 것

### Q7. 나열/종합 (시스템 기능)

```
Yuga에서 사용자가 직접 시작할 수 있는 요청 3가지는 무엇인가요?
```

기대 답변 요지:
- 프로젝트 멤버 추가 요청
- 타임카드 제출 취소 요청
- 초과근무 승인 요청

검증 포인트:
- [ ] 3가지 모두 언급되는가
- [ ] "접근 권한 부여" 같은 수동 배정 항목을 잘못 포함하지 않는가 (BM25 + 키워드 매칭 정확도)

### Q8. 복합·한영 혼용

```
Flex의 Time Off 대시보드에서 Details 탭과 History는 각각 무엇을 보여주나요?
```

기대 답변 요지:
- Details: 연도별 잔여 연차, 월별 내역 (Accrual/Expiration/Used/Adjustment/Balance)
- History: "Past time off" 목록, 승인/거절 상태, 거절 기록 토글

검증 포인트:
- [ ] 두 탭의 역할이 구분되어 설명되는가
- [ ] 영문 용어(Accrual, Balance 등) 와 한국어 설명이 함께 매칭되는가 (Enrich Hybrid Search Text ON 효과)

### Q9. 교차 문서 연동

```
ACCUMULATED MM이 ASSIGNED MM을 초과하면 어떻게 처리해야 하나요?
```

기대 답변 요지:
- 타임카드 제출 후 빨간색 경고 아이콘이 표시됨
- 경고 아이콘 클릭 → 초과근무 요청 양식 → 사유·상세 입력 → 제출
- PM 승인 후 녹색 체크 아이콘 표시

검증 포인트:
- [ ] "빨간색 경고 아이콘" 이 정확히 언급되는가
- [ ] 두 문서(타임카드 입력 · 초과근무 요청) 의 내용이 자연스럽게 이어지는가 (Reranker 가 관련 청크를 잘 뽑았는지)

### Q10. 한계 확인 (no-answer)

```
MCNC의 4대 보험 요율은 어떻게 되나요?
```

기대 답변 요지:
- "첨부된 문서에서 해당 내용을 찾지 못했습니다." (RAG 템플릿 규칙 그대로)

검증 포인트:
- [ ] 모른다고 명시하는가 (**추측으로 만들어내지 않는가**)
- [ ] `[출처: ...]` 가 붙지 않거나 "해당 없음" 으로 표기되는가
- [ ] 만약 엉뚱한 답이 나오면 RAG 템플릿이 기본(영문) 상태라는 뜻 - 05 문서의 한국어 커스텀 템플릿으로 교체

---

## 시연 순서 권장

데모 타이밍에 따라 아래 순서로 가면 깔끔하게 이어집니다 (각 질의 사이 10~20초).

1. **Q6** (메뉴 나열) - 짧고 명료, 답이 잘 나오면 바로 시청자 신뢰 확보
2. **Q1** (연차 기간 옵션) - 표 hit 의 힘을 보여줌
3. **Q3** (연차 신청 절차) - 서술형, Markdown Header Splitter 효과
4. **Q4** (결재라인 비교) - 표 + 비교, 가장 "답변이 똑똑해 보이는" 질의
5. **Q9** (ACCUMULATED MM 처리) - 교차 문서 종합, Reranker 효과 체감
6. **Q2** (점심시간 변경) - XLSX 파싱 확인, 규정 단문서 hit
7. **Q8** (Details/History) - 한영 혼용 + 복합
8. **Q10** (4대 보험) - "없는 정보는 없다고 말한다" 로 깔끔하게 마무리

Q5, Q7 은 Q&A 가 길어지면 생략 가능.

## 통과 못 할 때 조정 가이드

증상별로 [05-openwebui-rag-tuning.md](./05-openwebui-rag-tuning.md) 의 어느 옵션을 손볼지 직결시킵니다.

| 증상 | 먼저 조정할 것 |
|---|---|
| 식별자·수치 질의(Q1, Q2, Q7) 가 엉뚱함 | BM25 가중치 0.5 → 0.6, Enrich Hybrid Text ON 확인 |
| 서술 질의(Q3) 에서 단계 순서가 뒤섞임 | Chunk Size 800, Chunk Overlap 150, Markdown Header Splitter ON |
| 비교 질의(Q4, Q5) 에서 한쪽만 나옴 | Top K 8, Reranker External+cohere-rerank ON |
| 나열 질의(Q6, Q7) 에서 항목 누락 | Top K 10~12 로 상향, Top K Reranker 4~6 |
| 교차 질의(Q9) 에서 문서 하나만 인용 | Reranker 필수 ON, Relevance Threshold 0.0 유지 |
| no-answer 질의(Q10) 에서 허언 생성 | RAG 템플릿이 영문 기본값인지 확인, 한국어 커스텀으로 교체 |

## 로그로 품질 확인

질의 한 건을 쏠 때 LiteLLM 로그는 대략 이렇게 찍힙니다:

```bash
docker compose logs -f litellm | grep -iE "embed|rerank|completion"
```

기대 패턴:

```
POST /v1/embeddings      200 OK    (질의를 벡터화)
POST /rerank             200 OK    (Reranker 사용 시만)
POST /v1/chat/completions 200 OK   (최종 답변 생성)
```

세 줄이 순서대로 찍히면 RAG 파이프라인 전체가 정상. `embeddings` 만 있고 `completions` 가 없으면 Open WebUI → LiteLLM 연결 이슈, `completions` 만 있고 `embeddings` 가 없으면 Knowledge 가 채팅에 첨부되지 않은 상태 (`#` 미지정).

## 참고

- 질의 추가 기준: 같은 카테고리에 너무 많이 겹치지 말 것. 새 문서군이 추가되면 해당 문서의 **가장 특징적인 고유 용어** 를 포함하는 질의를 하나 추가하는 것으로 충분합니다.
- 기대 답변 요지는 문서 원본 기준. 문서가 개정되면 이 파일도 함께 갱신 필요.
