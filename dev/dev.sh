#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEV_DIR="${SCRIPT_DIR}"
SERVER_PROJECT="${ROOT_DIR}/OrchardCore.Crest.Host.csproj"

export CREST_SERVER_URL="${CREST_SERVER_URL:-http://crest.localhost:5014}"
export CREST_SERVER_PORT="${CREST_SERVER_PORT:-5014}"
# Playwright isn't installed locally in this repo; reuse fruitful.orchard's install
# unless the caller already points NODE_PATH somewhere else.
export NODE_PATH="${NODE_PATH:-/workspaces/fruitful.orchard/node_modules}"

usage() {
  cat <<'EOF'
Usage:
  bash dev/dev.sh build     Rebuild OrchardCore.Crest.Host.csproj only (no server, no test run).
  bash dev/dev.sh server    Run the dev server in the foreground (dotnet run, Development launch profile).
  bash dev/dev.sh stop      Stop a locally running dev server.
  bash dev/dev.sh test      Rebuild, start the dev server if it isn't already up, run every Playwright script in the repo.
EOF
}

require_dotnet() {
  if ! command -v dotnet >/dev/null 2>&1; then
    echo ".NET SDK is not installed in this environment." >&2
    exit 1
  fi
}

url_is_up() {
  local url="$1"
  curl -fsS --max-time 2 -o /dev/null "$url" >/dev/null 2>&1
}

run_build() {
  require_dotnet
  dotnet build "${SERVER_PROJECT}"
}

run_server() {
  require_dotnet
  cd "${ROOT_DIR}"
  dotnet run --project "${SERVER_PROJECT}"
}

stop_server() {
  pkill -f "dotnet run --project .*OrchardCore.Crest.Host.csproj" >/dev/null 2>&1 || true
  pkill -f "${ROOT_DIR}/bin/.*/OrchardCore.Crest.Host$" >/dev/null 2>&1 || true
  if command -v lsof >/dev/null 2>&1; then
    lsof -ti :"${CREST_SERVER_PORT}" | xargs -r kill -9 >/dev/null 2>&1 || true
  fi
}

start_server_background() {
  mkdir -p "${DEV_DIR}/logs"
  (cd "${ROOT_DIR}" && nohup dotnet run --project "${SERVER_PROJECT}" > "${DEV_DIR}/logs/server.log" 2>&1 &)

  echo "Waiting for ${CREST_SERVER_URL} to come up..."
  for _ in $(seq 1 60); do
    if url_is_up "${CREST_SERVER_URL}"; then
      return 0
    fi
    sleep 5
  done

  echo "Timed out waiting for the dev server to start; check dev/logs/server.log" >&2
  return 1
}


# The legacy loop below discovers every *.js under a tests/playwright/ dir. That glob
# matches slashes, so without this exclusion it would also pick up checks/*.js and
# harness/*.js (not standalone-runnable — they just define a module.exports and no-op)
# and re-run run-admin-suite.js/run-client-suite.js a second time in full. Raw scripts
# that get converted should be deleted outright (git rm), not added here — this only
# excludes the harness/entrypoint machinery itself.
is_legacy_script() {
  case "$1" in
    */tests/playwright/checks/*|*/tests/playwright/harness/*) return 1 ;;
    */tests/playwright/run-admin-suite.js|*/tests/playwright/run-client-suite.js) return 1 ;;
    *) return 0 ;;
  esac
}

# This host supplies credentials/URLs (its own dev/.env, once it has one) and decides
# when to run tests, but does not know OrchardCore.Crest's internal subproject layout —
# that knowledge stays owned by the submodule itself, in its own tests/run-tests.sh,
# which takes BASE_URL as an input and holds no credentials of its own. Any other module
# this host later declares (currently only OrchardCore.Crest exists under modules/) gets
# walked directly here, same shape as fruitful.orchard/dev/dev.sh's module loop.
run_module_tests() {
  local module_dir="$1"
  local module_name
  module_name="$(basename "${module_dir}")"
  local tests_dir="${module_dir}/tests"

  if [ "${module_name}" = "OrchardCore.Crest" ]; then
    echo "=== ${module_name} (delegated to modules/OrchardCore.Crest/tests/run-tests.sh) ==="
    BASE_URL="${CREST_SERVER_URL}" bash "${tests_dir}/run-tests.sh"
    return $?
  fi

  local module_failed=0

  local csproj
  while IFS= read -r -d '' csproj; do
    echo "=== ${module_name} C# tests: $(basename "${csproj}") ==="
    dotnet test "${csproj}" || module_failed=1
  done < <(find "${tests_dir}" -mindepth 2 -maxdepth 2 -name "*.csproj" -print0 2>/dev/null | sort -z)

  if [ -d "${tests_dir}/playwright" ]; then
    echo "=== ${module_name} Playwright suite ==="
    local total=0
    local failures=0
    local failed_names=()
    while IFS= read -r -d '' test_file; do
      local relative="${test_file#${ROOT_DIR}/}"
      is_legacy_script "${relative}" || continue
      total=$((total + 1))
      echo "==> ${relative}"
      if ! BASE_URL="${CREST_SERVER_URL}" node "${test_file}"; then
        failures=$((failures + 1))
        failed_names+=("${relative}")
      fi
    done < <(find "${tests_dir}" -path "*/tests/playwright/*.js" -print0 2>/dev/null | sort -z)

    echo "${module_name} raw scripts: $((total - failures))/${total} passed"
    if ((failures > 0)); then
      echo "Failed:"
      printf '  %s\n' "${failed_names[@]}"
      module_failed=1
    fi
  fi

  return "${module_failed}"
}

run_tests() {
  require_dotnet
  run_build

  if ! url_is_up "${CREST_SERVER_URL}"; then
    start_server_background
  fi

  local overall_failed=0
  local module_dir
  while IFS= read -r -d '' module_dir; do
    [ -d "${module_dir}/tests" ] || continue
    echo
    run_module_tests "${module_dir}" || overall_failed=1
  done < <(find "${ROOT_DIR}/modules" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  return "${overall_failed}"
}

command="${1:-}"
case "${command}" in
  build)
    run_build
    ;;
  server)
    run_server
    ;;
  stop)
    stop_server
    ;;
  test)
    run_tests
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
