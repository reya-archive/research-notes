# research-notes

회사 내부 리서치 결과를 모아 정적 사이트(GitHub Pages)로 호스팅하기 위한 레포지토리입니다.

- 빌드 도구 없이 순수 HTML/CSS/JS만 사용합니다.
- `main` 브랜치의 `/docs` 폴더가 그대로 GitHub Pages에 배포됩니다.
- 디자인은 외부 의존성 없이 시스템 폰트 + 화이트/그레이 톤으로 통일합니다.

## 폴더 구조

```
docs/
├── .nojekyll
├── index.html                 루트(리서치 목록)
├── 404.html
├── assets/
│   ├── css/main.css           공통 스타일 (단일 파일)
│   ├── js/
│   │   ├── include.js         header/footer partial 주입
│   │   ├── index.js           manifest 읽어 카드 목록 렌더
│   │   └── research.js        다중 페이지 사이드바 활성 표시
│   └── partials/
│       ├── header.tpl
│       └── footer.tpl
├── data/manifest.json         리서치 목록 메타데이터
└── research/
    ├── _template/             새 리서치 시작용 템플릿
    └── 2026-04-example-topic/ 예시 리서치
        ├── index.html         화면 진입점
        ├── notes/             Markdown 원본 (1개 또는 N개)
        │   ├── 01-background.md
        │   └── 02-findings.md
        ├── pages/             다중 페이지일 때 사용 (선택)
        ├── assets/            리서치별 커스텀 CSS/JS/이미지
        │   ├── style.css
        │   ├── script.js
        │   └── img/
        └── files/             다운로드 첨부 파일
```

## 새 리서치 추가하기

1. `docs/research/_template/` 폴더를 통째로 복사하고 이름을 `YYYY-MM-slug` 형식으로 바꿉니다.
   예: `docs/research/2026-05-latency-analysis/`
2. `notes/` 안에 Markdown으로 조사 내용을 작성합니다. 문서가 여러 개라면 `01-background.md`, `02-method.md` 식으로 정렬용 prefix를 붙여 추가합니다.
3. `index.html`에 화면용 HTML을 작성합니다. 이 폴더의 모든 경로(예: `<link rel="stylesheet" href="research/2026-05-latency-analysis/assets/style.css">`)를 새 폴더명으로 바꿔주세요.
4. 다중 페이지로 나누고 싶다면 `pages/01-*.html` 같은 식으로 추가합니다.
5. 커스텀 스타일/스크립트는 `assets/style.css`, `assets/script.js`에 작성합니다. 공통 디자인 토큰(`var(--color-text)` 등)을 활용해 톤을 유지하세요.
6. 다운로드 파일은 `files/`에 두고 본문에서 `<a class="download-btn" href="research/<폴더>/files/<파일>" download>`로 링크합니다.
7. `docs/data/manifest.json`에 새 리서치 항목 하나를 추가합니다.

`docs/data/manifest.json` 항목 스키마:

```json
{
  "id": "2026-05-latency-analysis",
  "title": "지연 분석",
  "summary": "한 줄 요약",
  "date": "2026-05-01",
  "tags": ["perf"],
  "path": "research/2026-05-latency-analysis/index.html",
  "pages": 1
}
```

## 로컬 미리보기 (VS Code Live Server)

이 사이트의 모든 HTML은 `<base href="/research-notes/">`를 사용합니다. 따라서 로컬에서도 URL이 `/research-notes/`로 시작해야 절대경로(`/assets/...`, `/data/...`)가 깨지지 않습니다.

이를 위해 `.vscode/settings.json`에 Live Server의 mount 옵션이 미리 설정되어 있습니다. 가상 경로 `/research-notes`가 워크스페이스의 `./docs`에 매핑됩니다.

### 사용 방법

1. VS Code 확장에서 **Live Server** (`ritwickdey.LiveServer`) 를 설치합니다. 워크스페이스를 열면 자동으로 권장 확장으로 표시됩니다.
2. VS Code 우측 하단의 **[Go Live]** 버튼을 클릭합니다. (또는 명령 팔레트 > `Live Server: Open with Live Server`)
3. 자동으로 열린 브라우저에서 다음 URL로 이동합니다:
   ```
   http://127.0.0.1:5500/research-notes/
   ```
4. 예시 리서치 페이지는 다음 URL입니다:
   ```
   http://127.0.0.1:5500/research-notes/research/2026-04-example-topic/index.html
   ```

> ⚠ `docs/index.html`을 우클릭해서 "Open with Live Server"로 열면 `/docs/index.html` 경로로 열려서 `<base href>`가 깨집니다. 반드시 위의 `/research-notes/` 경로로 접근하세요.

### Live Server 없이 확인하려면

순수 Python으로도 동일한 효과를 낼 수 있습니다 (레포 한 단계 위에서):

```sh
cd ..
python -m http.server 8000
# 브라우저: http://localhost:8000/research-notes/docs/
```

다만 이 경우 URL에 `/docs/`가 한 단계 더 들어가므로 base href가 깨집니다. 가능하면 Live Server를 권장합니다.

## GitHub Pages 설정 (최초 1회)

1. 레포 **Settings → Pages**
2. **Source**: `Deploy from a branch`
3. **Branch**: `main` / **Folder**: `/docs` → Save
4. (Enterprise Cloud) 사이트 자체를 조직 멤버로만 제한하려면 **Access control: Private**으로 설정

> Private 레포에서 GitHub Pages를 사용하려면 GitHub Pro / Team / Enterprise Cloud 플랜이 필요합니다.
