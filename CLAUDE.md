# Research Notes 프로젝트 가이드

회사 내부 리서치 결과를 정적 사이트로 호스팅하는 레포입니다. `main` 브랜치의 `docs/` 폴더가 그대로 GitHub Pages로 배포되고, Private 레포 + Pages 조합으로 운영됩니다. 상급자 보고용이라 디자인은 화려함보다 깔끔함과 가독성을 우선합니다.

자세한 내용은 `README.md`를 먼저 참고하세요. 이 파일은 Claude가 작업할 때 절대 어기지 말아야 할 원칙과 자주 빠지는 함정만 정리합니다.

## 절대 원칙

- **빌드 도구 없음**. npm, webpack, vite, sass, postcss 등 어떤 빌드/번들 단계도 추가하지 않습니다. 사용자가 명시적으로 요구하지 않는 한 `package.json` 자체를 만들지 마세요.
- **외부 CDN 의존성 없음**. 모든 자원은 이 레포 안에서 해결합니다. Tailwind, Bootstrap, jQuery, 폰트 CDN 등 외부 링크를 추가하지 마세요.
- **모든 HTML 페이지는 `<base href="/research-notes/">`를 사용합니다.** 이 태그를 제거하면 절대경로가 모두 깨집니다.
- **partial 파일은 반드시 `.tpl` 확장자**입니다. `.html`로 만들면 VSCode Live Server가 partial HTML 응답에 라이브 리로드 스크립트를 주입하려다 hang하고, `include.js`의 fetch가 영원히 대기해 화면이 흰 채로 멈춥니다. 새 partial을 추가할 때도 반드시 `.tpl`을 사용하세요.
- **vanilla JS만 사용**. 프레임워크, 빌드러너, transpiler 모두 금지.

## 디렉토리 구조 한 줄 요약

```
docs/
├── index.html / 404.html         루트 페이지
├── assets/{css,js,partials}/     공통 자원 (단일 main.css, include.js, index.js, research.js, *.tpl)
├── data/manifest.json            리서치 목록 단일 진실 소스
└── research/
    ├── _template/                새 리서치 시작용
    └── YYYY-MM-slug/             각 리서치 (notes/, pages/, assets/, files/)
```

## 새 리서치 추가 절차 (요약)

1. `docs/research/_template/` 통째로 복사 → `docs/research/YYYY-MM-slug/`로 rename
2. `notes/`에 Markdown 원본 작성 (1개 또는 N개, `01-`, `02-` prefix)
3. `index.html`에 화면용 HTML 작성. 다중 페이지면 `pages/NN-*.html` 추가
4. 커스텀 스타일/스크립트가 필요하면 `assets/style.css`, `assets/script.js`에 작성
5. 다운로드 파일은 `files/`에 두고 본문에 `<a class="download-btn" href="research/<폴더>/files/<파일>" download>`
6. `docs/data/manifest.json`에 항목 하나 append

새 리서치 폴더 안의 모든 HTML에서, 폴더 이름이 들어가는 경로(`<link rel="stylesheet" href="research/.../assets/style.css">`)를 새 폴더명으로 빠짐없이 바꿔야 합니다.

## 코딩 규칙

- **들여쓰기**: 2 space
- **인코딩**: UTF-8, LF 줄바꿈
- **언어**: UI 텍스트와 본문은 한국어가 기본. 폰트 스택에 `Apple SD Gothic Neo`/`Noto Sans KR`이 포함되어 있어 별도 처리 불필요
- **CSS**: 공통 디자인 토큰(`var(--color-text)`, `var(--space-4)` 등)을 우선 활용. 색상/간격을 직접 하드코딩하지 마세요. 리서치별 커스텀 클래스에는 폴더 ID prefix를 권장합니다 (예: `.r-2026-04-example-topic__chart`)
- **JS**: vanilla, ES2017+ 문법 OK. 모듈 시스템 사용하지 않습니다 (단순 `<script>` 태그)
- **HTML**: 시맨틱 태그 우선 (`<header>`, `<main>`, `<article>`, `<nav>`, `<footer>`)

## 디자인 톤

- 미니멀, 회사 보고용
- 화이트/그레이 톤 + 링크 색 한 가지(`--color-link`)
- 그림자/애니메이션 거의 없음. hover transition은 150ms 배경색 정도만
- 본문 가독성 우선 (`max-width: 760px`)
- 8px 그리드 spacing
- 시스템 폰트 스택만 사용

## 라우팅 / 페이지 분할

- 다중 페이지 리서치는 **별도 HTML 파일 + 사이드바 링크** 방식만 사용합니다
- **해시 라우팅, History API SPA 방식 모두 사용하지 마세요**. GitHub Pages는 SPA fallback을 제공하지 않아 새로고침 시 404가 발생합니다. 정적 파일 직접 링크 공유가 핵심 UX입니다

## 로컬 검증

VSCode Live Server를 사용합니다. 워크스페이스 `.vscode/settings.json`에 `liveServer.settings.mount`로 `/research-notes` → `./docs` 매핑이 미리 설정되어 있습니다.

- 시작: 우측 하단 [Go Live] 클릭
- 접근 URL: `http://127.0.0.1:5500/research-notes/`
- ⚠ `docs/index.html`을 우클릭 "Open with Live Server"로 열면 base href와 어긋나니 사용하지 마세요

## 자주 빠지는 함정

- partial을 `.html`로 만들면 Live Server에서 hang → 항상 `.tpl`
- `manifest.json`의 `path` 값은 `docs/` 기준 상대경로 (`research/<폴더>/index.html`)
- 새 리서치 폴더 안의 HTML에서 `<link href="research/<폴더>/...">` 같은 폴더명 포함 경로를 복사 후 바꾸지 않으면 다른 리서치의 자원이 로드됩니다
- `base href` 절대경로(`/assets/...`, `/data/...`)와 리서치 폴더 내부 자원 상대경로(`./files/...`)를 혼동하지 마세요

## 프로젝트 로컬 skills

이 레포에는 반복 작업을 표준화하는 project-local skills가 `.claude/skills/` 아래에 있습니다. 사용자가 자연어로 같은 의도를 표현하면 자동 발동되며, 슬래시 명령으로도 호출할 수 있습니다.

| skill | 슬래시 | 역할 |
|---|---|---|
| `new-research` | `/new-research [folder-id]` | _template 복사 + 경로 치환 + manifest 항목 추가로 새 리서치 폴더를 안전하게 셋업 |
| `add-research-page` | `/add-research-page [folder-id] [page-slug]` | 기존 리서치에 sub-page 추가, 단일→다중 페이지 전환 포함 |
| `add-research-download` | `/add-research-download [folder-id] [source-file]` | 파일을 files/에 복사하고 본문에 download-btn 삽입 |
| `validate-research-site` | `/validate-research-site` | 사이트 무결성 정적 검사 (manifest, base href, .tpl, 경로 prefix, 다운로드 링크) |

새 리서치를 시작하거나 push 전 점검할 때는 위 skills를 우선 활용하세요. 직접 파일을 수정하는 것보다 함정(`.html` partial, 경로 prefix 누락 등)을 피할 수 있습니다.

## Git / 커밋

- 사용자가 명시적으로 요청하지 않는 한 커밋하지 마세요
- 커밋이 필요한 시점에 사용자에게 확인 받고 진행
