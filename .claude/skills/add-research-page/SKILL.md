---
name: add-research-page
description: Use when the user wants to add a new sub-page to an existing research in the research-notes repo, or convert a single-page research into a multi-page layout with sidebar navigation.
argument-hint: [folder-id] [page-slug]
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(ls:*)
---

# add-research-page

기존 리서치 폴더에 새 페이지(sub-page)를 추가한다. 두 가지 모드:

- **추가 모드**: 이미 `pages/` 안에 페이지가 있는 리서치 → 그냥 새 페이지 한 장 추가
- **전환 모드**: 단일 페이지 리서치 (`index.html`만 있는 상태) → 다중 페이지 레이아웃으로 전환하면서 새 페이지 추가

## 사전 점검

- 현재 디렉토리에 `docs/research/`가 있는지 확인
- 인자로 받은 `folder-id`가 실제 존재하는지 (`Glob "docs/research/<folder-id>/index.html"`)
- 없으면 사용자에게 알리고 중단. `_template`은 거부.

## 입력 수집

`argument-hint`로 받은 인자를 파싱:
- 첫 번째 인자: `folder-id`
- 두 번째 인자: `page-slug` (예: `02-method`)

부족하면 `AskUserQuestion`으로 보충:
- `folder-id`: 어떤 리서치에 페이지를 추가할지 (없으면 `Glob "docs/research/*"`로 후보 목록을 보여주고 선택)
- `page-slug`: `NN-slug` 형식 (예: `02-method`, `03-findings`). 두 자리 숫자 prefix 강제.
- `page-title`: 한국어 페이지 제목

## 모드 판별

`Glob "docs/research/<folder-id>/pages/*.html"` 결과:

- **결과가 0건**: 단일 페이지 리서치 → 전환 모드
- **결과가 1건 이상**: 이미 다중 페이지 → 추가 모드

전환 모드일 경우, 사용자에게 명시적으로 확인을 받는다 (`AskUserQuestion`):
> "이 리서치는 현재 단일 페이지입니다. 다중 페이지 레이아웃으로 전환하시겠습니까? 기존 index.html이 사이드바가 있는 진입 페이지로 재구성됩니다."

거부하면 중단.

## 전환 모드 작업

1. 기존 `index.html`을 읽어 `<article class="prose">` 내부 본문을 추출
2. 첫 페이지로 옮길 파일명 결정: 사용자에게 묻거나 기본값 `01-overview.html`
3. `docs/research/<folder-id>/pages/01-overview.html`을 새로 작성:
   - 기존 `index.html`의 head/header/footer 구조를 그대로 복제
   - 본문 영역에 추출한 prose 내용 삽입
   - `layout--with-sidebar` 클래스로 감싸고 사이드바 placeholder 추가
   - breadcrumb에 페이지 제목 추가
4. `index.html`을 사이드바 + 첫 페이지로 리디렉트 또는 개요 화면으로 재작성:
   - 가장 단순한 접근: `<meta http-equiv="refresh" content="0; url=pages/01-overview.html">` (정적이고 안전)
   - 또는 사이드바 + 짧은 안내 텍스트
5. 새 `notes/01-overview.md`가 이미 있으면 그대로, 없으면 골격 생성

## 추가 모드 작업

1. `docs/research/<folder-id>/pages/<slug>.html` 파일 생성
2. 기존 페이지 중 하나를 템플릿으로 삼아 복제 (head, sidebar, footer 구조 유지)
3. breadcrumb과 `<title>`, `.page-header__title`을 새 페이지 제목으로 교체
4. 본문(`<article class="prose">`)은 빈 골격으로

## 사이드바 업데이트

다중 페이지 리서치는 모든 페이지가 동일한 사이드바를 공유해야 한다. 사이드바 마크업 위치는 두 가지 패턴 중 하나를 선택할 수 있다:

### 패턴 A: 인라인 사이드바 (각 페이지에 직접 작성)
모든 페이지의 `<aside class="sidebar">` 안의 `<ul class="sidebar__list">`에 새 페이지 링크 `<li>`를 추가한다. `Glob`으로 모든 페이지를 찾아 `Edit`으로 한 줄씩 동기화.

### 패턴 B: 리서치별 partial (`docs/research/<folder-id>/sidebar.tpl`)
사이드바 마크업을 별도 `.tpl` 파일로 분리하고 각 페이지에서 `data-include`로 로드. 페이지가 5개 이상이면 이 패턴이 유지보수에 유리.

**기본은 패턴 A**로 한다. 페이지가 6개 이상인 시점에 사용자에게 패턴 B로 전환을 제안한다.

링크 항목 형식:
```html
<li><a href="research/<folder-id>/pages/<slug>.html"><번호> <제목></a></li>
```

`research.js` (이미 있음)가 현재 페이지에 `aria-current="page"`를 자동으로 부여한다.

## 대응되는 notes/.md 생성

`docs/research/<folder-id>/notes/<slug>.md` 파일이 없으면 다음 골격으로 생성:

```markdown
# <page-title>

> 작성일: <today>
> 상태: 초안

(본문 작성)
```

## manifest.json 업데이트

`docs/data/manifest.json`을 읽어 해당 리서치 항목의 `pages` 카운트를 갱신.

- 추가 모드: `pages` += 1
- 전환 모드: `pages` = 새 페이지 수 (기본 2 이상)

`Edit`으로 해당 항목의 `"pages": N` 값을 정확히 교체. JSON 유효성을 깨지 않도록 주의.

## 결과 출력

한국어 요약:

```
페이지를 추가했습니다.

리서치: <folder-id>
새 페이지: pages/<slug>.html
대응 notes: notes/<slug>.md
사이드바: <업데이트된 페이지 수>개

다음 단계:
1. notes/<slug>.md에 조사 내용 작성
2. pages/<slug>.html의 본문(<article class="prose">) 채우기
3. 로컬에서 사이드바 클릭이 정상 동작하는지 확인
```

## 절대 어기면 안 되는 원칙

- **해시 라우팅 / SPA 도입 금지**. 각 페이지는 독립된 정적 HTML이어야 한다.
- partial 추가 시 확장자는 반드시 `.tpl`
- `<base href="/research-notes/">` 유지
- 응답은 한국어
- destructive 작업 금지: 기존 페이지를 덮어쓰거나 삭제하지 마라. 이미 같은 slug 페이지가 있으면 중단하고 사용자에게 알린다.
