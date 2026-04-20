#!/usr/bin/env bash
# ==============================================================================
# MCNC SI RAG - openwebui-hosting 부트스트랩
# ==============================================================================
# 이 스크립트는 다음을 수행합니다.
#   1. 필수 도구 확인 (docker, docker compose, curl)
#   2. 우리 .env 가 없으면 템플릿 복사 후 안내 후 종료
#   3. .env 안 placeholder 값이 남아 있으면 경고
#   4. docker compose up -d   (litellm + open-webui 동시 기동)
#   5. LiteLLM / Open WebUI 헬스 체크
#   6. 접근 URL · 테스트 curl · 최초 관리자 계정 생성 안내 출력
#
# 재실행 안전 (idempotent) : 이미 존재하는 항목은 건너뜁니다.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ------------------------------------------------------------------------------
# 0. 옵션 파싱 (현재는 해석만, 추후 확장 여지)
# ------------------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      cat <<EOF
Usage: $0

옵션:
  -h, --help   이 도움말 출력 후 종료
EOF
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_YELLOW=$'\033[0;33m'
COLOR_BLUE=$'\033[0;34m'
COLOR_RESET=$'\033[0m'

log()  { printf '%s[openwebui-hosting]%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$*"; }
ok()   { printf '%s[ ok ]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$*"; }
warn() { printf '%s[warn]%s %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$*"; }
err()  { printf '%s[ ERR]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2; }

die() {
  err "$1"
  if [[ -n "${2:-}" ]]; then
    printf '\n%s조치 방법%s\n  %s\n\n' "$COLOR_YELLOW" "$COLOR_RESET" "$2"
  fi
  exit 1
}

# ------------------------------------------------------------------------------
# 1. 필수 도구 확인
# ------------------------------------------------------------------------------
check_tool() {
  local tool="$1"
  local install_hint="$2"
  if ! command -v "$tool" >/dev/null; then
    die "$tool 명령을 찾을 수 없습니다." "$install_hint"
  fi
}

log "필수 도구 확인 중..."
check_tool docker "Docker 공식 설치 스크립트: curl -fsSL https://get.docker.com | sh"
check_tool curl   "sudo apt-get install -y curl   (Ubuntu) 또는 sudo dnf install -y curl"

if ! docker compose version >/dev/null 2>/dev/null; then
  die "docker compose (v2) 플러그인이 없습니다." \
      "sudo apt-get install -y docker-compose-plugin  또는  Docker Desktop 사용 시 자동 설치됨"
fi
ok "docker, docker compose, curl 확인 완료"

# ------------------------------------------------------------------------------
# 2. 우리 .env 확인
# ------------------------------------------------------------------------------
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    warn ".env 를 .env.example 로부터 생성했습니다."
    printf '\n%s▶ 다음 단계%s\n' "$COLOR_YELLOW" "$COLOR_RESET"
    printf '  1. vi %s/.env\n' "$SCRIPT_DIR"
    printf '     - AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY\n'
    printf '     - LITELLM_MASTER_KEY   (openssl rand -hex 32)\n'
    printf '     - WEBUI_SECRET_KEY     (openssl rand -hex 32)\n'
    printf '     - (선택) LITELLM_PORT / OPENWEBUI_PORT 조정\n'
    printf '  2. ./setup.sh 다시 실행\n\n'
    exit 0
  else
    die ".env 도 .env.example 도 없습니다." \
        "이 레포를 최신 상태로 다시 받아 주세요: git pull"
  fi
fi

# ------------------------------------------------------------------------------
# 3. .env placeholder 잔존 여부 경고
# ------------------------------------------------------------------------------
PLACEHOLDER_FOUND=0
if grep -qE '^AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX' "$SCRIPT_DIR/.env"; then
  warn ".env 에 기본 AWS_ACCESS_KEY_ID placeholder 가 남아 있습니다."
  PLACEHOLDER_FOUND=1
fi
if grep -qE '^LITELLM_MASTER_KEY=sk-change-me-' "$SCRIPT_DIR/.env"; then
  warn ".env 에 기본 LITELLM_MASTER_KEY placeholder 가 남아 있습니다."
  warn "  openssl rand -hex 32  결과로 바꿔 주세요."
  PLACEHOLDER_FOUND=1
fi
if grep -qE '^WEBUI_SECRET_KEY=change-me-' "$SCRIPT_DIR/.env"; then
  warn ".env 에 기본 WEBUI_SECRET_KEY placeholder 가 남아 있습니다."
  warn "  이대로 두면 컨테이너 재시작마다 세션이 만료되고 JWT 가 깨집니다."
  PLACEHOLDER_FOUND=1
fi
if [[ $PLACEHOLDER_FOUND -eq 1 ]]; then
  warn "그대로 기동하면 Bedrock 호출이 401/403 으로 실패하거나 로그인 상태가 불안정해집니다."
fi
ok ".env 확인 완료"

# .env 에서 포트 읽기 (없으면 기본값)
LITELLM_PORT_VALUE="$(grep -E '^LITELLM_PORT=' "$SCRIPT_DIR/.env" | head -n1 | cut -d'=' -f2- || echo '')"
OPENWEBUI_PORT_VALUE="$(grep -E '^OPENWEBUI_PORT=' "$SCRIPT_DIR/.env" | head -n1 | cut -d'=' -f2- || echo '')"
LITELLM_PORT_VALUE="${LITELLM_PORT_VALUE:-14000}"
OPENWEBUI_PORT_VALUE="${OPENWEBUI_PORT_VALUE:-13000}"

# ------------------------------------------------------------------------------
# 4. docker compose up
# ------------------------------------------------------------------------------
log "이미지 pull + 컨테이너 기동 중 (litellm + open-webui)..."
docker compose --env-file "$SCRIPT_DIR/.env" up -d

ok "컨테이너 기동 명령 완료. 초기 부팅이 완료될 때까지 대기합니다..."

# ------------------------------------------------------------------------------
# 5. 헬스 체크 (최대 2분, 5초 간격)
# ------------------------------------------------------------------------------
wait_http() {
  local name="$1"
  local url="$2"
  local service="$3"
  local attempts=24
  local i
  for (( i=1; i<=attempts; i++ )); do
    if curl -fsS -o /dev/null "$url"; then
      ok "$name 응답 OK - $url"
      return 0
    fi
    sleep 5
  done
  warn "$name 이 $((attempts * 5))초 내에 응답하지 않았습니다."
  warn "로그 확인: docker compose logs --tail 50 $service"
  return 1
}

log "LiteLLM 헬스 체크..."
wait_http "LiteLLM" "http://localhost:${LITELLM_PORT_VALUE}/health/liveliness" "litellm" || true

log "Open WebUI 헬스 체크..."
wait_http "Open WebUI" "http://localhost:${OPENWEBUI_PORT_VALUE}/health" "open-webui" || true

# ------------------------------------------------------------------------------
# 6. 접근 URL 및 다음 단계 출력
# ------------------------------------------------------------------------------
VM_HOSTNAME="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")"
if [[ -z "$VM_HOSTNAME" ]]; then VM_HOSTNAME="localhost"; fi

# .env 에서 MASTER_KEY 값 읽기
MASTER_KEY_VALUE="$(grep -E '^LITELLM_MASTER_KEY=' "$SCRIPT_DIR/.env" | head -n1 | cut -d'=' -f2-)"

cat <<EOF

${COLOR_GREEN}================================================================${COLOR_RESET}
  openwebui-hosting 기동 완료
${COLOR_GREEN}================================================================${COLOR_RESET}

  ${COLOR_YELLOW}▶ Open WebUI${COLOR_RESET}  (브라우저로 접속)
    http://${VM_HOSTNAME}:${OPENWEBUI_PORT_VALUE}

    첫 접속자가 자동으로 관리자 계정이 됩니다. 가입 직후 로그인 →
    모델 드롭다운에 claude-sonnet-4-6 과 titan-embed-v2 가 바로 보여야 정상.
    RAG 임베딩 모델은 titan-embed-v2 로 이미 프리셋되어 있습니다.
    추가 모델(Sonnet 4.5 · Haiku 4.5) 은 litellm_config.yaml 의 주석 블록에
    있으니 필요 시 주석만 해제하고 docker compose restart litellm.

  ${COLOR_YELLOW}▶ OpenAI 호환 엔드포인트${COLOR_RESET}  (외부 클라이언트용, 선택)
    Base URL :  http://${VM_HOSTNAME}:${LITELLM_PORT_VALUE}/v1
    API Key  :  ${MASTER_KEY_VALUE}

    동작 확인:
      curl http://localhost:${LITELLM_PORT_VALUE}/v1/models \\
        -H "Authorization: Bearer ${MASTER_KEY_VALUE}"

      curl http://localhost:${LITELLM_PORT_VALUE}/v1/chat/completions \\
        -H "Authorization: Bearer ${MASTER_KEY_VALUE}" \\
        -H "Content-Type: application/json" \\
        -d '{"model":"claude-sonnet-4-6","messages":[{"role":"user","content":"안녕"}]}'

  ${COLOR_YELLOW}▶ 기존 서비스와 충돌 없음${COLOR_RESET}
    이 스택은 컨테이너 이름 openwebui-hosting-* 과 볼륨 openwebui-hosting-data
    로 완전히 격리되어 있어 기존 mcnc-llm-webui(:3000) 에는 영향을 주지 않습니다.
EOF

printf '\n%s================================================================%s\n' "$COLOR_GREEN" "$COLOR_RESET"
