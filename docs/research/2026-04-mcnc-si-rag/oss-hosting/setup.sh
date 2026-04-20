#!/usr/bin/env bash
# ==============================================================================
# MCNC SI RAG - Dify + Bedrock 프로토타입 부트스트랩
# ==============================================================================
# 이 스크립트는 다음을 수행합니다.
#   1. 필수 도구 확인 (docker, docker compose, git)
#   2. Dify 공식 리포 shallow clone (./dify/)
#   3. Dify 의 docker/.env 템플릿 자동 복사 (수정 없음)
#   4. 우리 .env 가 없으면 템플릿 복사 후 안내 후 종료
#   5. 전체 스택 up -d
#   6. Dify 웹 헬스 체크
#   7. 접근 URL 및 다음 단계 출력
#
# 옵션:
#   --with-ollama   호스트의 Ollama(11434) 를 Dify 에 연결하는
#                   overlay(compose.ollama.yml) 를 포함합니다.
#
# 재실행 안전 (idempotent) : 이미 존재하는 항목은 건너뜁니다.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ------------------------------------------------------------------------------
# 0. 옵션 파싱
# ------------------------------------------------------------------------------
WITH_OLLAMA=0
for arg in "$@"; do
  case "$arg" in
    --with-ollama) WITH_OLLAMA=1 ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--with-ollama]

옵션:
  --with-ollama   호스트의 Ollama(11434) 를 Dify 에 연결하는
                  compose.ollama.yml 을 함께 사용합니다.
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

log()  { printf '%s[oss-hosting]%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$*"; }
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
check_tool git    "sudo apt-get install -y git   (Ubuntu) 또는 sudo dnf install -y git"
check_tool docker "Docker 공식 설치 스크립트: curl -fsSL https://get.docker.com | sh"

if ! docker compose version >/dev/null 2>/dev/null; then
  die "docker compose (v2) 플러그인이 없습니다." \
      "sudo apt-get install -y docker-compose-plugin  또는  Docker Desktop 사용 시 자동 설치됨"
fi
ok "docker, docker compose, git 확인 완료"

# ------------------------------------------------------------------------------
# 2. Dify 공식 리포 clone (없을 때만)
# ------------------------------------------------------------------------------
DIFY_REPO_URL="https://github.com/langgenius/dify.git"
DIFY_DIR="$SCRIPT_DIR/dify"

if [[ ! -d "$DIFY_DIR/.git" ]]; then
  log "Dify 공식 리포 clone 중... ($DIFY_REPO_URL)"
  git clone --depth 1 "$DIFY_REPO_URL" "$DIFY_DIR"
  ok "Dify clone 완료"
else
  ok "Dify 폴더 이미 존재 - clone 건너뜀"
fi

# ------------------------------------------------------------------------------
# 3. Dify docker/.env 생성 (없을 때만)
# ------------------------------------------------------------------------------
DIFY_COMPOSE_DIR="$DIFY_DIR/docker"

if [[ ! -f "$DIFY_COMPOSE_DIR/docker-compose.yaml" ]]; then
  die "Dify 리포에서 docker/docker-compose.yaml 을 찾지 못했습니다." \
      "rm -rf dify && ./setup.sh 로 재시도하거나, Dify main 브랜치 구조가 변경됐는지 확인하세요."
fi

if [[ ! -f "$DIFY_COMPOSE_DIR/.env" ]]; then
  if [[ -f "$DIFY_COMPOSE_DIR/.env.example" ]]; then
    cp "$DIFY_COMPOSE_DIR/.env.example" "$DIFY_COMPOSE_DIR/.env"
    ok "Dify 기본 .env 생성 (수정 없이 기본값 사용)"
  else
    die "Dify 의 docker/.env.example 을 찾을 수 없습니다." \
        "Dify 버전이 맞는지 확인: cd dify && git log -1 --oneline"
  fi
fi

# ------------------------------------------------------------------------------
# 4. 우리 .env 확인
# ------------------------------------------------------------------------------
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    warn ".env 를 .env.example 로부터 생성했습니다."
    printf '\n%s▶ 다음 단계%s\n' "$COLOR_YELLOW" "$COLOR_RESET"
    printf '  1. vi %s/.env   (AWS 키 편집)\n' "$SCRIPT_DIR"
    printf '  2. ./setup.sh 다시 실행\n\n'
    exit 0
  else
    die ".env 도 .env.example 도 없습니다." \
        "이 레포를 최신 상태로 다시 받아 주세요: git pull"
  fi
fi

# .env 안에 placeholder 그대로 남아 있으면 경고
if grep -qE '^AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX' "$SCRIPT_DIR/.env"; then
  warn ".env 에 기본 placeholder 값이 남아 있습니다. 실제 값으로 꼭 바꿔 주세요."
fi
ok ".env 확인 완료"

# ------------------------------------------------------------------------------
# 5. docker compose up
# ------------------------------------------------------------------------------
COMPOSE_ARGS=(
  --env-file "$SCRIPT_DIR/.env"
  -f "$DIFY_COMPOSE_DIR/docker-compose.yaml"
)
if [[ $WITH_OLLAMA -eq 1 ]]; then
  COMPOSE_ARGS+=(-f "$SCRIPT_DIR/compose.ollama.yml")
  log "--with-ollama: 호스트 Ollama(11434) 연결용 overlay 포함"
  # 호스트에서 Ollama 리슨 여부 사전 점검 (실패해도 진행만 하고 경고)
  if ! curl -fsS -o /dev/null http://localhost:11434/api/tags; then
    warn "호스트의 http://localhost:11434 에서 Ollama 가 응답하지 않습니다."
    warn "Dify 는 나중에도 UI 에서 추가할 수 있으니 계속 진행합니다."
    warn "Ollama 가 127.0.0.1 만 바인딩 중이라면 OLLAMA_HOST=0.0.0.0:11434 로 재시작 필요."
  fi
fi

log "컨테이너 이미지 pull + 전체 스택 기동 중..."
export OSS_HOSTING_DIR="$SCRIPT_DIR"

# Dify 1.x 는 db_postgres / weaviate 를 profile 뒤에 숨겨두어, 이 값이 비면
# api 가 DB 를 찾지 못해 502 가 발생합니다. .env 에 없으면 안전한 기본값 주입.
if ! grep -q '^COMPOSE_PROFILES=' "$SCRIPT_DIR/.env" 2>/dev/null; then
  export COMPOSE_PROFILES="weaviate,postgresql"
  warn ".env 에 COMPOSE_PROFILES 가 없어 'weaviate,postgresql' 로 자동 설정"
fi

docker compose "${COMPOSE_ARGS[@]}" up -d

ok "컨테이너 기동 명령 완료. 초기 부팅이 완료될 때까지 대기합니다..."

# ------------------------------------------------------------------------------
# 6. 헬스 체크 (최대 3분, 10초 간격)
# ------------------------------------------------------------------------------
wait_http() {
  local name="$1"
  local url="$2"
  local attempts=18
  local i
  for (( i=1; i<=attempts; i++ )); do
    if curl -fsS -o /dev/null "$url"; then
      ok "$name 응답 OK - $url"
      return 0
    fi
    sleep 10
  done
  warn "$name 이 $((attempts * 10))초 내에 응답하지 않았습니다."
  warn "로그 확인: docker compose --env-file .env -f dify/docker/docker-compose.yaml logs --tail 50 $3"
  return 1
}

log "Dify 웹 (http://localhost/) 헬스 체크..."
wait_http "Dify" "http://localhost/" "nginx" || true

# ------------------------------------------------------------------------------
# 7. 접근 URL 및 다음 단계 출력
# ------------------------------------------------------------------------------
VM_HOSTNAME="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")"
if [[ -z "$VM_HOSTNAME" ]]; then VM_HOSTNAME="localhost"; fi

cat <<EOF

${COLOR_GREEN}================================================================${COLOR_RESET}
  프로토타입 기동 완료
${COLOR_GREEN}================================================================${COLOR_RESET}

  Dify       http://${VM_HOSTNAME}/

  ${COLOR_YELLOW}▶ 다음 단계${COLOR_RESET} (docs/03-post-install.md 참고)
    1. Dify 로 접속해 관리자 계정 생성
    2. 설정 → Model Provider 에서 Amazon Bedrock 추가 (도쿄 리전 + AWS 키)
    3. Knowledge → Create Knowledge → 준비해 둔 파일 드래그&드롭 업로드
    4. Studio 에서 챗봇 앱 만들고 지식베이스 연결 → 질의 응답 확인
EOF

if [[ $WITH_OLLAMA -eq 1 ]]; then
  cat <<EOF

  ${COLOR_YELLOW}▶ Ollama 추가 설정${COLOR_RESET} (docs/06-ollama.md 참고)
    Dify Model Provider 에서 Ollama 를 추가한 뒤
      Base URL:     http://host.docker.internal:11434
      LLM 모델:     gemma4:26b
      임베딩 모델:  bge-m3
    를 등록하면 Bedrock 과 같은 Dify 안에서 번갈아 시연 가능합니다.
EOF
fi

printf '\n%s================================================================%s\n' "$COLOR_GREEN" "$COLOR_RESET"
