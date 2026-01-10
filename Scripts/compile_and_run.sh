#!/usr/bin/env bash
# Reset BreakTime: kill running instances, build, package, relaunch, verify.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="BreakTime"
APP_BUNDLE="${ROOT_DIR}/${APP_NAME}.app"
APP_PROCESS_PATTERN="${APP_NAME}.app/Contents/MacOS/${APP_NAME}"
DEBUG_PROCESS_PATTERN="${ROOT_DIR}/.build/debug/${APP_NAME}"
RELEASE_PROCESS_PATTERN="${ROOT_DIR}/.build/release/${APP_NAME}"
LOCK_KEY="$(printf '%s' "${ROOT_DIR}" | shasum -a 256 | cut -c1-8)"
LOCK_DIR="${TMPDIR:-/tmp}/breaktime-compile-and-run-${LOCK_KEY}"
LOCK_PID_FILE="${LOCK_DIR}/pid"
WAIT_FOR_LOCK=0
RUN_TESTS=0
DEBUG_LLDB=0
RELEASE_ARCHES=""

log()  { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

run_step() {
  local label="$1"; shift
  log "==> ${label}"
  if ! "$@"; then
    fail "${label} failed"
  fi
}

cleanup() {
  if [[ -d "${LOCK_DIR}" ]]; then
    rm -rf "${LOCK_DIR}"
  fi
}

acquire_lock() {
  while true; do
    if mkdir "${LOCK_DIR}" 2>/dev/null; then
      echo "$$" > "${LOCK_PID_FILE}"
      return 0
    fi

    local existing_pid=""
    if [[ -f "${LOCK_PID_FILE}" ]]; then
      existing_pid="$(cat "${LOCK_PID_FILE}" 2>/dev/null || true)"
    fi

    if [[ -n "${existing_pid}" ]] && kill -0 "${existing_pid}" 2>/dev/null; then
      if [[ "${WAIT_FOR_LOCK}" == "1" ]]; then
        log "==> Another agent is compiling (pid ${existing_pid}); waiting..."
        while kill -0 "${existing_pid}" 2>/dev/null; do
          sleep 1
        done
        continue
      fi
      log "==> Another agent is compiling (pid ${existing_pid}); re-run with --wait."
      exit 0
    fi

    rm -rf "${LOCK_DIR}"
  done
}

trap cleanup EXIT INT TERM

kill_all_breaktime() {
  is_running() {
    pgrep -f "${APP_PROCESS_PATTERN}" >/dev/null 2>&1 \
      || pgrep -f "${DEBUG_PROCESS_PATTERN}" >/dev/null 2>&1 \
      || pgrep -f "${RELEASE_PROCESS_PATTERN}" >/dev/null 2>&1 \
      || pgrep -x "${APP_NAME}" >/dev/null 2>&1
  }

  for _ in {1..25}; do
    pkill -f "${APP_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -f "${DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -f "${RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -x "${APP_NAME}" 2>/dev/null || true
    if ! is_running; then
      return 0
    fi
    sleep 0.2
  done

  pkill -9 -f "${APP_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -f "${DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -f "${RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -x "${APP_NAME}" 2>/dev/null || true

  for _ in {1..25}; do
    if ! is_running; then
      return 0
    fi
    sleep 0.2
  done

  fail "Failed to kill all BreakTime instances."
}

for arg in "$@"; do
  case "${arg}" in
    --wait|-w) WAIT_FOR_LOCK=1 ;;
    --test|-t) RUN_TESTS=1 ;;
    --debug-lldb) DEBUG_LLDB=1 ;;
    --release-universal) RELEASE_ARCHES="arm64 x86_64" ;;
    --release-arches=*) RELEASE_ARCHES="${arg#*=}" ;;
    --help|-h)
      log "Usage: $(basename "$0") [--wait] [--test] [--debug-lldb] [--release-universal] [--release-arches=\"arm64 x86_64\"]"
      exit 0
      ;;
    *)
      ;;
  esac
done

acquire_lock

log "==> Killing existing BreakTime instances"
kill_all_breaktime

if [[ "${RUN_TESTS}" == "1" ]]; then
  run_step "swift test" swift test -q
fi
if [[ "${DEBUG_LLDB}" == "1" && -n "${RELEASE_ARCHES}" ]]; then
  fail "--release-arches is only supported for release packaging"
fi
HOST_ARCH="$(uname -m)"
ARCHES_VALUE="${HOST_ARCH}"
if [[ -n "${RELEASE_ARCHES}" ]]; then
  ARCHES_VALUE="${RELEASE_ARCHES}"
fi

if [[ "${DEBUG_LLDB}" == "1" ]]; then
  run_step "package app" env BREAKTIME_ALLOW_LLDB=1 ARCHES="${ARCHES_VALUE}" "${ROOT_DIR}/Scripts/package_app.sh" debug
else
  run_step "package app" env BREAKTIME_SIGNING=adhoc ARCHES="${ARCHES_VALUE}" "${ROOT_DIR}/Scripts/package_app.sh"
fi

log "==> launch app"
if ! open "${APP_BUNDLE}"; then
  log "WARN: launch app returned non-zero; falling back to direct binary launch."
  "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" >/dev/null 2>&1 &
  disown
fi

for _ in {1..10}; do
  if pgrep -f "${APP_PROCESS_PATTERN}" >/dev/null 2>&1; then
    log "OK: BreakTime is running."
    exit 0
  fi
  sleep 0.4
done
fail "App exited immediately. Check crash logs in Console.app (User Reports)."
