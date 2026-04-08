---
name: new-research
description: Use when the user wants to start a new research topic in the research-notes repo. Creates a new research folder from _template, rewrites all internal paths to the new folder id, and appends a manifest.json entry.
argument-hint: [folder-id]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(cp:*), Bash(mv:*), Bash(ls:*), Bash(test:*), AskUserQuestion
---

# new-research

새 리서치 주제를 위한 폴더를 안전하게 생성한다. 이 skill 한 번으로 다음을 모두 수행한다:

1. `docs/research/_template/`를 새 폴더로 복사
2. 새 폴더 안의 모든 파일(HTML/CSS/JS/MD)에서 `research/_template/` → `research/<new-id>/` 일괄 치환
3. `notes/01-overview.md`의 헤더를 새 리서치 정보로 채움
4. `docs/data/manifest.json`에 새 항목 append

## 사전 점검 (반드시 실행)

이 skill을 시작하기 전에 다음을 확인:

- 현재 작업 디렉토리에 `docs/research/_template/` 폴더가 존재하는가? (`Glob` 으로 확인)
- `docs/data/manifest.json`이 존재하고 유효한 JSON인가? (`Read`로 읽어 검증)

둘 중 하나라도 실패하면 사용자에게 알리고 중단한다 - 이 skill은 research-notes 레포 안에서만 의미가 있다.

## 입력 수집

`argument-hint`로 받은 인자(있다면)를 `folder-id`로 사용한다. 인자가 없거나 형식이 맞지 않으면 `AskUserQuestion`으로 차례로 묻는다.

수집해야 하는 필드:

| 필드 | 형식 | 비고 |
|---|---|---|
| `folder-id` | `YYYY-MM-[a-z0-9-]+` | 정렬을 위해 두 자리 월. 예: `2026-05-latency-analysis` |
| `title` | 한국어 짧은 제목 | 카드와 페이지 제목에 표시됨 |
| `summary` | 한국어 한 줄 요약 | 카드 설명에 표시됨 (~80자) |
| `date` | `YYYY-MM-DD` | 기본값: 오늘 (`CLAUDE.md`의 currentDate, 없으면 사용자 OS 날짜) |
| `tags` | 콤마 구분 문자열 | 비워도 OK. 예: `infra,perf` |

`AskUserQuestion`으로 묻을 때는 한 번에 1~2개씩 묶어서 묻는다.

## folder-id 검증 (중단 사유)

다음 중 하나라도 해당되면 즉시 중단하고 사용자에게 사유를 한국어로 출력:

- 정규식 `^\d{4}-\d{2}-[a-z0-9][a-z0-9-]*$` 매치 실패
- `docs/research/<folder-id>/` 가 이미 존재 (`Glob`으로 확인)
- folder-id가 `_template`으로 시작

## 폴더 복사

```bash
cp -r docs/research/_template docs/research/<folder-id>
```

복사 직후 새 폴더의 파일 트리를 `Glob`으로 확인 (예상: `index.html`, `notes/01-overview.md`, `assets/style.css`, `assets/script.js`, `assets/img/.gitkeep`, `pages/.gitkeep`, `files/.gitkeep`).

## 경로 치환

새 폴더 안의 모든 파일에서 `research/_template/` 문자열을 `research/<folder-id>/`로 일괄 치환한다.

대상 파일을 `Glob`으로 식별: `docs/research/<folder-id>/**/*.{html,css,js,md}`

각 파일에 대해 `Grep`으로 `research/_template/` 매치를 찾고, `Edit`의 `replace_all: true`로 치환한다.

**주의**: `_template`이라는 문자열이 다른 맥락(예: 주석)에서 의도적으로 쓰일 수 있으므로 `research/_template/`라는 슬래시 포함 패턴만 치환한다. 단순히 `_template`만 바꾸지 마라.

## 헤더 채우기

`docs/research/<folder-id>/notes/01-overview.md` 파일의 헤더를 다음과 같이 수정:

```markdown
# <title>

> 작성일: <date>
> 상태: 초안

(본문은 사용자가 채울 수 있도록 빈 채로 둔다)
```

`docs/research/<folder-id>/index.html`의 `<title>`, `.page-header__title`, `.page-header__lede`, `.breadcrumb` 마지막 span도 새 정보로 교체한다. `.page-header__eyebrow`에는 `<date>` (YYYY.MM.DD 형식으로 변환)와 태그가 들어가도록 수정한다.

## manifest.json 업데이트

`docs/data/manifest.json`을 `Read`한 후, `researches` 배열에 다음 항목을 append:

```json
{
  "id": "<folder-id>",
  "title": "<title>",
  "summary": "<summary>",
  "date": "<date>",
  "tags": [<tags split by comma, trimmed>],
  "path": "research/<folder-id>/index.html",
  "pages": 1
}
```

`Edit`로 기존 마지막 항목 뒤에 콤마와 새 객체를 삽입한다. JSON 유효성을 깨지 않도록 주의: 마지막 객체 뒤의 닫는 `]` 위치, 줄바꿈, 들여쓰기(2 space)를 기존 스타일과 일치시킨다.

추가 후 다시 `Read`로 검증 - 파일이 여전히 유효한 JSON이어야 한다.

## 결과 출력

작업이 끝나면 한국어로 다음 형식의 요약을 출력:

```
새 리서치를 생성했습니다.

폴더: docs/research/<folder-id>/
포함된 파일:
  - index.html
  - notes/01-overview.md
  - assets/style.css, script.js
  - files/, pages/

manifest.json에 항목을 추가했습니다.

다음 단계:
1. notes/ 안에 .md 문서를 작성하세요 (필요시 02-, 03- 추가)
2. index.html의 본문(<article class="prose">)을 채우세요
3. 다운로드 파일은 files/에 두고 add-research-download skill로 추가
4. 다중 페이지가 필요하면 add-research-page skill 사용
5. 푸시 전 validate-research-site skill로 점검
6. 로컬 미리보기: http://127.0.0.1:5500/research-notes/
```

## 절대 어기면 안 되는 원칙

- **빌드 도구 추가 금지**. package.json, node_modules 등 만들지 말 것.
- **partial 파일 확장자는 `.tpl`**. `.html`로 만들면 Live Server hang.
- **`<base href="/research-notes/">` 유지**.
- **CSS 토큰 활용**. 새 폴더의 `assets/style.css`를 채울 때는 색상/간격을 직접 하드코딩하지 말고 `var(--color-...)` / `var(--space-...)` 를 사용.
- 사용자 글로벌 규칙: **응답은 한국어**, em dash 사용 금지, sentence case headers.

## 실패 처리

중간에 실패하면(파일 복사 실패, 치환 실패, JSON 손상 등):

1. 사용자에게 어느 단계에서 실패했는지 명확히 알린다
2. `manifest.json`을 손상시켰다면 즉시 원래 상태로 복원 (변경 전 내용을 미리 메모리에 보관해둘 것)
3. 새로 만든 폴더는 사용자 확인을 받고 정리하도록 안내 (자동 삭제는 destructive 작업이라 하지 않음)
