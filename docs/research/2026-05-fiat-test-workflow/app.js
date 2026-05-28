/*
 * FIAT .claude 워크스페이스 소개 페이지 스크립트
 * - 데이터(에이전트/스킬/Hook)는 .claude 자산 frontmatter / settings.json 기준
 * - 외부 의존 없음 (file:// 직접 실행)
 */

// ===== 데이터 =====
const AGENTS = [
  { name: "@code-architect", role: "코치", desc: "도메인 무관 코드 작업 코치. 스펙 헤더 / cross-domain / Grep-first / base class 결정 트리 / 산출 자가 검증을 자동 강제. 호출 시 작업 도메인(fiat{XXXX}) 명시." },
  { name: "@test-planner", role: "계획 · read-only", desc: "TC 사양 작성, 라이프사이클 단계(L1~L4) 결정, 테스트 레벨 4지 선택, 11축 매핑, Edge 분리 결정. 어떤 파일도 작성하지 않음." },
  { name: "@test-generator", role: "작성 · write", desc: "Planner 결과를 입력으로 실제 *Test.java 작성 / TC row 발행 / 갭 보강 / 수정 적용. 테스트 파일 write 권한을 가진 유일한 에이전트." },
  { name: "@test-evaluator", role: "평가 · read-only", desc: "Generator 산출을 입력으로 11축 갭 분석 / 합격 기준 12항 체크 / 안티패턴 16항 검출 / 실패 5 카테고리 진단." },
  { name: "@test-reporter", role: "보고 · write", desc: "Evaluator 산출을 입력으로 cut 단위 결과 보고 파일을 도메인 reports 폴더에 자동 생성(80~250줄 담백 형식)." },
];

const SKILLS = {
  code: [
    { name: "/api-add", desc: "신규 REST API endpoint 추가. controller + 필요 시 filter / routing + 단위·통합 test 까지 한 단위로 생성." },
    { name: "/api-gateway-route-add", desc: "API gateway routing 추가. SCG filter + RouteResolver + Dynamic API Mapping 등록 + test (fiatgate 한정)." },
    { name: "/entity-add", desc: "신규 JPA Entity + Repository + Archive 페어 + Migration + 단위 test. base class 4지 / archive-then-purge 강제." },
    { name: "/event-add", desc: "Event publisher / listener 추가. FiatEvent + @FiatEventListener + Outbox + DLQ + idempotency + test." },
    { name: "/grpc-add", desc: "gRPC service / client 추가. .proto + GrpcService + GrpcClient + 테넌트 메타데이터 전파 + test." },
    { name: "/batch-add", desc: "Batch job 추가. FiatJobConfiguration + Step(Chunk/Tasklet) + Reader/Processor/Writer + Job Chain + concurrency guard." },
    { name: "/cache-add", desc: "캐시 적용. L1(in-process) / L2(Redis) / TTL / 키 정책 / 무효화 hook / 분산 락 + test." },
    { name: "/message-def-add", desc: "Message Definition 등재. 필드 정의 + 검증 / 암복호화 / 마스킹 / 버전 라이프사이클 + 사용처 매핑." },
  ],
  test: [
    { name: "/test-tc-spec-author", desc: "L1 Author. spec의 §Test Cases에 TC-{SUBSYSTEM}-{NNN} 발행 + 11축 매핑 + Input/Expected 표 작성." },
    { name: "/test-add", desc: "L2 Generate. 대응 test 파일이 없거나 부족한 production 코드에 누락 test 보강. 행동 11축 적용." },
    { name: "/test-coverage-improve", desc: "L3 Reinforce. *Test.java는 있으나 11축 중 누락 축(boundary/concurrency/serialization 등)을 보강." },
    { name: "/test-fix", desc: "L4 Repair. 실패 / Flaky / cut 어서션 / 빌드 깨진 테스트 복구. 어서션 약화 금지, systematic-debugging 기반." },
    { name: "/test-evaluate", desc: "평가 + 진단 통합. 11축 갭 / 합격 12항 / 안티패턴 16항 / 실패 5 카테고리 분류." },
    { name: "/test-domain-sweep", desc: "도메인(모듈) 전체를 배치 단위로 순차 테스트. 매니페스트로 세션 끊겨도 resume. /test-add의 상위 레이어." },
  ],
};

const HOOK_GROUPS = [
  {
    event: "UserPromptSubmit", desc: "사용자 입력 시점",
    hooks: [
      { name: "detect-test-work.mjs", desc: "테스트 모드 진입 시 모드별 절차 안내를 inject (미결정 시 침묵 + session_id만 silent 기록)." },
    ],
  },
  {
    event: "PreToolUse", desc: "Write/Edit 직전",
    hooks: [
      { name: "check-test-write-workflow.mjs", desc: "*Test.java 직접 작성 시도 시 모드별 분기 경고 / 차단." },
    ],
  },
  {
    event: "PostToolUse", desc: "Write/Edit 직후 · 7종",
    hooks: [
      { name: "check-spec-header.mjs", desc: "구현물 최상단 스펙 헤더 주석 누락 검출." },
      { name: "check-test-exists.mjs", desc: "production 코드의 대응 test 존재 여부 검증." },
      { name: "check-tc-id-mapping.mjs", desc: "@Requirement TC ID 매핑 누락 검출." },
      { name: "check-axis-marker.mjs", desc: "javadoc의 [Axis N] 행동 축 마커 누락 검출." },
      { name: "check-banned-test-patterns.mjs", desc: "isNotNull 단독 / @Disabled / Thread.sleep 등 안티패턴 검출." },
      { name: "check-fixture-naming.mjs", desc: "테스트 fixture 명명 규칙 검증." },
      { name: "check-report-format.mjs", desc: "보고 파일 5 § 골든 템플릿 형식 검증." },
    ],
  },
  {
    event: "Stop", desc: "cut 종료 시점",
    hooks: [
      { name: "audit-test-workflow.mjs", desc: "transcript 분석으로 모드 vs 행동 정합 + 보고 파일 존재 검증." },
    ],
  },
];

// ===== 렌더링 =====
function renderAgents() {
  const el = document.getElementById("agentGrid");
  el.innerHTML = AGENTS.map(a => `
    <article class="item-card">
      <div class="item-head">
        <span class="item-name">${a.name}</span>
        <span class="item-role">${a.role}</span>
      </div>
      <p>${a.desc}</p>
    </article>`).join("");
}

function renderSkills(tab) {
  const el = document.getElementById("skillGrid");
  el.innerHTML = SKILLS[tab].map(s => `
    <article class="item-card">
      <div class="item-head"><span class="item-name">${s.name}</span></div>
      <p>${s.desc}</p>
    </article>`).join("");
}

function renderHooks() {
  const el = document.getElementById("hookGroups");
  el.innerHTML = HOOK_GROUPS.map(g => `
    <div class="hook-group">
      <div class="hook-event">
        <span class="hook-event-name">${g.event}</span>
        <span class="hook-event-desc">${g.desc}</span>
      </div>
      <div class="hook-list">
        ${g.hooks.map(h => `<div class="hook-item"><code>${h.name}</code><p>${h.desc}</p></div>`).join("")}
      </div>
    </div>`).join("");
}

// ===== 탭 =====
function initTabs() {
  const tabs = document.querySelectorAll(".tab");
  tabs.forEach(t => t.addEventListener("click", () => {
    tabs.forEach(x => x.classList.remove("active"));
    t.classList.add("active");
    renderSkills(t.dataset.tab);
    observeReveal();
  }));
}

// ===== 테마 토글 =====
function initTheme() {
  const btn = document.getElementById("themeToggle");
  btn.addEventListener("click", () => {
    const cur = document.documentElement.getAttribute("data-theme");
    document.documentElement.setAttribute("data-theme", cur === "light" ? "dark" : "light");
  });
}

// ===== 카운트업 =====
function countUp() {
  document.querySelectorAll(".stat-num").forEach(el => {
    const target = +el.dataset.count;
    let cur = 0;
    const step = Math.max(1, Math.ceil(target / 28));
    const tick = () => {
      cur = Math.min(target, cur + step);
      el.textContent = cur;
      if (cur < target) requestAnimationFrame(tick);
    };
    tick();
  });
}

// ===== 스크롤 등장 =====
let revealObserver;
function observeReveal() {
  document.querySelectorAll(".card, .item-card, .pipe-step, .mode-card, .mini-card, .axis, .hook-group")
    .forEach(el => { if (!el.classList.contains("reveal")) { el.classList.add("reveal"); revealObserver.observe(el); } });
}

function initReveal() {
  revealObserver = new IntersectionObserver(entries => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add("in"); revealObserver.unobserve(e.target); } });
  }, { threshold: 0.12 });
  observeReveal();
}

// ===== 부트 =====
document.addEventListener("DOMContentLoaded", () => {
  renderAgents();
  renderSkills("code");
  renderHooks();
  initTabs();
  initTheme();
  countUp();
  initReveal();
});
