#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

: <<'DOC'
Post-install verification for the kaitos install flow.

Asserts that all expected files exist, templates were expanded, shell rc
was patched, and re-runs are idempotent. Used by both simulated and live
CI test modes.

Usage: test_install.sh

Expects the installer to have already run. Needs GODOT_VERSION set
(from .envrc or the environment).
DOC

__test__PASS=0
__test__FAIL=0
__test__XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
__test__XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
__test__XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
__test__XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

function main() {
  log_banner "Install Verification"

  test_file_layout
  test_template_expansion
  test_shell_rc
  test_idempotency
  test_reset_configs

  log ""
  log_banner "Results: $__test__PASS passed, $__test__FAIL failed"

  if [[ "$__test__FAIL" -gt 0 ]]; then
    exit 1
  fi
}

function test_file_layout() {
  log ""
  log "--- File layout ---"

  log "  DEBUG: ls -la $__test__XDG_BIN_HOME/"
  ls -la "$__test__XDG_BIN_HOME/" 2>&1 | while IFS= read -r line; do log "  DEBUG: $line"; done || true

  assert_executable "$__test__XDG_BIN_HOME/kaitos" \
    "CLI binary"

  assert_exists "$__test__XDG_DATA_HOME/kaitos/lib/libgodot.so" \
    "Shared library"

  assert_executable "$__test__XDG_CACHE_HOME/kaitos/godot/$GODOT_VERSION/Godot_v${GODOT_VERSION}-stable_linux.x86_64" \
    "Godot binary"

  assert_exists "$__test__XDG_CONFIG_HOME/kaitos/settings.yaml" \
    "User config"

  assert_exists "$__test__XDG_DATA_HOME/kaitos/shell/env.sh" \
    "Shell env"
}

function test_template_expansion() {
  log ""
  log "--- Template expansion ---"

  assert_not_contains "$__test__XDG_CONFIG_HOME/kaitos/settings.yaml" \
    "__GODOT_VERSION__" \
    "settings.yaml has no unexpanded placeholders"

  assert_not_contains "$__test__XDG_DATA_HOME/kaitos/shell/env.sh" \
    "__KAITOS_VERSION__" \
    "env.sh has no unexpanded __KAITOS_VERSION__"

  assert_not_contains "$__test__XDG_DATA_HOME/kaitos/shell/env.sh" \
    "__GODOT_VERSION__" \
    "env.sh has no unexpanded __GODOT_VERSION__"
}

function test_shell_rc() {
  log ""
  log "--- Shell rc ---"

  local rc_file="$HOME/.bashrc"

  assert_contains "$rc_file" \
    "# kaitos" \
    "rc file contains kaitos source line"
}

function test_idempotency() {
  log ""
  log "--- Idempotency ---"

  local config="$__test__XDG_CONFIG_HOME/kaitos/settings.yaml"
  local rc_file="$HOME/.bashrc"

  if [[ ! -f "$config" ]]; then
    __test__fail "Config missing before idempotency check: $config"
    return
  fi

  local checksum_before
  checksum_before="$(md5sum "$config" | cut -d' ' -f1)"

  __test__run_installer

  if [[ ! -f "$config" ]]; then
    __test__fail "Config missing after re-install: $config"
    return
  fi

  local checksum_after
  checksum_after="$(md5sum "$config" | cut -d' ' -f1)"

  assert_equal "$checksum_before" "$checksum_after" \
    "Config unchanged after re-install"

  local kaitos_count
  kaitos_count="$(grep -c "# kaitos" "$rc_file" || true)"

  assert_equal "$kaitos_count" "1" \
    "rc file has exactly one kaitos block (got $kaitos_count)"
}

function test_reset_configs() {
  log ""
  log "--- Reset configs ---"

  local config="$__test__XDG_CONFIG_HOME/kaitos/settings.yaml"

  if [[ ! -f "$config" ]]; then
    __test__fail "Config missing before reset-configs check: $config"
    return
  fi

  echo "# test modification" >> "$config"
  local checksum_before
  checksum_before="$(md5sum "$config" | cut -d' ' -f1)"

  __test__run_installer --reset-configs

  local checksum_after
  checksum_after="$(md5sum "$config" | cut -d' ' -f1)"

  assert_not_equal "$checksum_before" "$checksum_after" \
    "Config was overwritten with --reset-configs"
}

function __test__run_installer() {
  if [[ "${TEST_INSTALL_USE_LIVE:-}" == "1" ]]; then
    curl -fsSL kaitos.dev/install.sh | sh -s -- --prerelease "$@"
  elif [[ -n "${KAITOSHOME:-}" && -f "$KAITOSHOME/scripts/install/install.sh" ]]; then
    bash "$KAITOSHOME/scripts/install/install.sh" "$@"
  else
    fatal "KAITOSHOME must point to a local installer (or set TEST_INSTALL_USE_LIVE=1)"
    return 1
  fi
}

# -- Assertion helpers --

function assert_exists() {
  local path="$1" label="$2"
  if [[ -f "$path" ]]; then
    __test__pass "$label"
  else
    __test__fail "$label — expected file: $path"
  fi
}

function assert_executable() {
  local path="$1" label="$2"
  if [[ -x "$path" ]]; then
    __test__pass "$label"
  else
    __test__fail "$label — expected executable: $path"
  fi
}

function assert_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -qF "$pattern" "$file" 2>/dev/null; then
    __test__pass "$label"
  else
    __test__fail "$label — '$pattern' not found in $file"
  fi
}

function assert_not_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -qF "$pattern" "$file" 2>/dev/null; then
    __test__fail "$label — '$pattern' still present in $file"
  else
    __test__pass "$label"
  fi
}

function assert_equal() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then
    __test__pass "$label"
  else
    __test__fail "$label — expected '$expected', got '$actual'"
  fi
}

function assert_not_equal() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" != "$expected" ]]; then
    __test__pass "$label"
  else
    __test__fail "$label — values should differ but both are '$actual'"
  fi
}

function __test__pass() {
  log "  PASS: $1"
  __test__PASS=$(( __test__PASS + 1 ))
}

function __test__fail() {
  error "  FAIL: $1"
  __test__FAIL=$(( __test__FAIL + 1 ))
}

main "$@"
