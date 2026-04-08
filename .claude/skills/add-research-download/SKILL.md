---
name: add-research-download
description: Use when the user wants to attach a downloadable file (PDF, CSV, ZIP, image, etc.) to a research page in the research-notes repo and surface a styled download link in the body HTML.
argument-hint: [folder-id] [source-file-path]
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(cp:*), Bash(stat:*), Bash(ls:*)
---

# add-research-download

리서치에 다운로드 첨부 파일을 추가하고, 본문 HTML에 `.download-btn` 마크업을 자동 삽입한다.

## 사전 점검

- `docs/research/`가 있는 research-notes 레포 안에서만 동작
- 인자로 받은 `folder-id`가 실제 존재하는지 (`Glob "docs/research/<folder-id>/index.html"`)
- 인자로 받은 `source-file-path`가 실제 존재하는 파일인지 (`ls`로 확인)
- 둘 중 하나라도 실패하면 중단

## 입력 수집

`argument-hint`로 받은 인자:
- 첫 번째: `folder-id`
- 두 번째: `source-file-path` (절대경로 또는 상대경로)

부족하면 `AskUserQuestion`으로 보충:
- `folder-id`: 어떤 리서치에 첨부할지 (목록 제시)
- `source-file-path`: 원본 파일 경로
- (선택) `display-name`: 본문에 표시할 파일명. 기본값은 원본 파일명
- (선택) `target-page`: 다중 페이지 리서치라면 어느 페이지의 본문에 버튼을 넣을지. 기본은 `index.html`

## 파일 복사

대상 폴더: `docs/research/<folder-id>/files/`

```bash
cp "<source-file-path>" "docs/research/<folder-id>/files/<basename>"
```

복사 후 `ls -la`로 확인. 같은 이름 파일이 이미 존재하면 사용자에게 덮어쓰기 여부를 묻는다 (기본은 거부).

## 메타데이터 추출

복사된 파일에 대해:

- **확장자** → MIME 라벨 추정 (간단한 매핑):
  - `.pdf` → `PDF`
  - `.csv` → `CSV`
  - `.xlsx` → `XLSX`
  - `.zip` → `ZIP`
  - `.png` / `.jpg` → `IMG`
  - `.txt` / `.md` → `TXT`
  - 그 외 → 확장자 대문자
- **파일 크기** (`stat`):
  - Windows Git Bash: `stat -c %s "<file>"`
  - 결과 byte를 KB/MB로 변환 (소수점 1자리)
  - 1024 bytes 미만이면 `B` 단위, 1MB 미만이면 `KB`, 그 이상이면 `MB`

## 본문 HTML에 삽입

대상 HTML 파일: `docs/research/<folder-id>/<target-page>` (기본: `index.html`)

`Read`로 파일을 읽고 `<ul class="download-list">` 섹션을 찾는다.

### 케이스 A: 섹션이 이미 존재
`Grep`이나 위치 식별로 `</ul>` 닫기 직전에 새 항목을 `Edit`으로 삽입.

새 항목 마크업:
```html
      <li>
        <a class="download-btn" href="research/<folder-id>/files/<basename>" download>
          <svg class="download-btn__icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M8 2v9"/>
            <path d="M5 8l3 3 3-3"/>
            <path d="M3 13h10"/>
          </svg>
          <span class="download-btn__name"><display-name></span>
          <span class="download-btn__meta"><MIME-label> · <size></span>
        </a>
      </li>
```

들여쓰기는 기존 섹션의 들여쓰기와 정확히 일치시킨다.

### 케이스 B: 섹션이 없음
본문 끝(`</article>` 닫는 태그 다음, `</main>` 이전)에 새 섹션을 통째로 삽입:

```html
    <h3 class="section-title">첨부 파일</h3>
    <ul class="download-list">
      <li>
        <a class="download-btn" href="research/<folder-id>/files/<basename>" download>
          ... (위와 동일)
        </a>
      </li>
    </ul>
```

`</article>` 위치는 `Grep -n "</article>"`로 찾는다. 단일 페이지의 경우 본문 중에는 `</article>`이 보통 1개만 등장한다.

## 결과 출력

한국어 요약:

```
다운로드 파일을 추가했습니다.

리서치: <folder-id>
복사된 파일: docs/research/<folder-id>/files/<basename> (<size>)
HTML 변경: <target-page>의 첨부 파일 섹션에 항목 추가

링크 주소(GitHub Pages 기준):
  /research-notes/research/<folder-id>/files/<basename>

다음 단계:
1. 로컬에서 다운로드 버튼 클릭이 정상 동작하는지 확인
2. validate-research-site skill로 링크 무결성 점검
```

## 절대 어기면 안 되는 원칙

- 원본 파일을 **이동(mv)하지 마라**. 항상 **복사(cp)**. 사용자가 원본을 잃어버리면 안 된다.
- 같은 이름 파일이 이미 있으면 묻기 전에는 덮어쓰지 마라.
- HTML 수정 시 들여쓰기와 줄바꿈을 기존 스타일에 맞춰 깔끔하게 유지.
- `href` 경로는 `research/<folder-id>/files/<basename>` 형식으로 절대경로 prefix 사용 (페이지의 `<base href>`와 합쳐져 정상 동작).
- 응답은 한국어.
