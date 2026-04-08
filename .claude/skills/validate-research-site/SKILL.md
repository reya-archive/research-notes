---
name: validate-research-site
description: Use when the user wants to verify the research-notes site is healthy before push, or after adding/editing a research. Checks manifest paths, base href, noindex meta, partial extensions, per-research path prefixes, download links, and CSS token usage.
allowed-tools: Read, Glob, Grep
---

# validate-research-site

`research-notes` 사이트의 무결성을 정적으로 검사한다. 빌드 단계가 없는 프로젝트이므로 push 전 손으로 점검해야 할 사항들을 자동화한다. **수정은 하지 않는다** - 발견된 문제만 보고한다.

## 실행 환경 확인

이 skill은 `docs/` 폴더가 있는 research-notes 레포 안에서만 의미가 있다. `Glob`으로 `docs/index.html`이 존재하는지 먼저 확인하고, 없으면 사용자에게 알리고 중단한다.

## 검사 항목

각 항목을 수행하면서 결과를 메모리에 누적한다. 각 발견은 `severity` (`OK | WARN | FAIL`), `category`, `location` (file:line 또는 file), `message`로 구성한다.

### 1. manifest 무결성

- `Read docs/data/manifest.json` → JSON 파싱 시도
  - 실패 시: `FAIL manifest invalid-json`
- `researches` 배열이 존재하는가
- 각 항목에 대해:
  - 필수 필드 (`id`, `title`, `summary`, `date`, `path`, `pages`)가 모두 있는가
  - `id`가 `^\d{4}-\d{2}-[a-z0-9][a-z0-9-]*$` 형식을 만족하는가
  - `date`가 `^\d{4}-\d{2}-\d{2}$` 형식을 만족하는가
  - `path`가 `research/<id>/...` 패턴이고 `id`와 폴더명이 일치하는가
  - `path`가 가리키는 파일이 실제 존재하는가 (`Glob`으로 확인)
  - `pages`가 양의 정수인가
- 전체 배열에서 `id` 중복 여부

### 2. HTML 페이지 점검

`Glob "docs/**/*.html"`로 모든 HTML 파일을 찾는다. 각 파일에 대해:

- **base href 검사**: `Grep`으로 `<base href="/research-notes/">` 매치 확인. 없으면 `FAIL base-href missing`.
- **noindex meta 검사**: `Grep`으로 `<meta name="robots" content="[^"]*noindex` 패턴 매치 확인. 없으면 `FAIL noindex-missing` - 회사 내부 자료라 검색엔진 인덱싱을 반드시 차단해야 한다. `_template/index.html`도 동일하게 검사한다 (새 리서치 생성 시 누락 방지).
- **data-include 확장자 검사**: `Grep`으로 `data-include="..."` 패턴을 찾고, 값이 `.html`로 끝나면 `FAIL include-extension` (반드시 `.tpl`이어야 함). 함정 1순위.
- **공통 자원 참조 검사**: `assets/css/main.css`, `assets/js/include.js`를 정상적으로 참조하는지 (루트 페이지와 리서치 페이지 모두 동일한 절대경로 패턴이어야 함).

### 3. 리서치별 경로 점검 (가장 중요)

`Glob "docs/research/*/index.html"`와 `docs/research/*/pages/*.html`로 리서치 폴더 안의 HTML을 모두 찾는다. (`_template`은 제외)

각 파일에 대해:

- 파일 경로에서 폴더 ID 추출 (예: `docs/research/2026-04-example-topic/index.html` → `2026-04-example-topic`)
- 그 파일 안의 `Grep "research/[^/\"' ]+/"` 매치를 모두 찾고, 매치된 폴더명이 자기 폴더 ID와 다르면 `FAIL path-prefix-mismatch`
  - 단, `research/_template/`는 템플릿 파일에서만 허용 (이미 `_template` 제외했으므로 매치 시 모두 FAIL)
- `<link rel="stylesheet" href="research/<id>/assets/style.css">`와 `<script src="research/<id>/assets/script.js">` 참조가 자기 폴더 ID를 가리키는지 명시적으로 확인

### 4. 다운로드 링크 무결성

각 리서치 HTML에서 `Grep "class=\"download-btn\""` 매치를 찾고, 각 매치 주변의 `href="..."` 값을 추출한다. (multiline grep이 필요할 수 있음)

추출한 href가 `research/<id>/files/<filename>` 형식인지 확인하고, 실제 그 파일이 존재하는지 `Glob`으로 검증. 없으면 `FAIL download-missing-file`.

### 5. CSS 토큰 사용 (warning 수준)

`Glob "docs/research/*/assets/style.css"`로 각 리서치의 커스텀 CSS를 읽는다.

`Grep "#[0-9a-fA-F]{3,8}\\b"`로 hex 색상 직접 사용을 찾는다. 매치가 있으면 `WARN css-token-bypass` (FAIL 아님 - 디자이너의 의도일 수도 있으니 권고만).

마찬가지로 `Grep`으로 픽셀 단위 직접 사용 (`\\b\\d+px`)을 찾을 수도 있지만, 노이즈가 많아 생략한다.

### 6. Live Server 호환성

`Glob "docs/assets/partials/*.html"`로 검색. 결과가 있으면 `FAIL partial-html-extension` - partial은 반드시 `.tpl` 확장자여야 한다.

### 7. .nojekyll 존재

`Glob "docs/.nojekyll"`. 없으면 `WARN nojekyll-missing` - GitHub Pages가 `_template` 폴더를 무시할 수 있다.

## 출력 형식

검사를 모두 끝낸 후 한국어로 결과를 보고. 다음과 같은 표 형식 사용:

```
## 검사 결과

| 카테고리                  | 상태  | 비고                       |
|---------------------------|-------|----------------------------|
| manifest 무결성            | OK    | 1개 항목 모두 정상         |
| HTML base href             | OK    | 5개 파일 모두 포함         |
| HTML noindex meta          | OK    | 5개 파일 모두 포함         |
| data-include 확장자        | OK    | 모두 .tpl                  |
| 리서치별 경로 prefix       | OK    |                            |
| 다운로드 링크 무결성       | OK    | 1개 링크, 파일 존재 확인   |
| CSS 토큰 사용              | WARN  | example/style.css에 hex 1개 |
| Live Server partials       | OK    | .html partial 없음         |
| .nojekyll                  | OK    |                            |

## 발견된 문제

(WARN/FAIL 항목만 자세히, 없으면 "없음" 표시)

### WARN [css-token-bypass]
docs/research/2026-04-example-topic/assets/style.css:5
  border-left: 3px solid #0b5fff;
  → var(--color-link) 사용을 권장합니다.
```

## 종합 결론

- 모든 항목 OK → "사이트는 정상입니다. push해도 안전합니다."
- WARN만 있고 FAIL 없음 → "치명적 문제는 없으나 권고 사항이 N개 있습니다. 검토 후 push하세요."
- FAIL이 하나라도 있음 → "FAIL 항목을 먼저 수정해야 합니다."

## 절대 어기면 안 되는 원칙

- **이 skill은 read-only**. `Edit`이나 `Write`를 호출하지 마라.
- 발견 사항은 거짓 양성이라도 보고하지 말 것 - 사용자가 신뢰할 수 있어야 한다. 확실하지 않으면 WARN으로.
- 응답은 한국어. em dash 사용 금지.
