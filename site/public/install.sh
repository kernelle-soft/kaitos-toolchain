#!/usr/bin/env sh
# Kaitos bootstrapper — curl -fsSL kaitos.dev/install.sh | sh
#
# Downloads the latest release tarball, extracts it, then hands off
# to the real installer. This script is a rarely-changed permalink.
#
# Dependencies (this bootstrapper): curl or wget, tar, uname, mktemp, find, grep, sed, head, awk, sha256sum or shasum
# Shells: runs under POSIX sh, then execs /usr/bin/env bash for the main installer.

set -eu

GITHUB_ORG="kernelle-soft"
GITHUB_REPO="kaitos-toolchain"
RELEASE_INDEX_URL="https://kaitos.dev/release-index.json"

_FLAG_PRERELEASE=false
_FLAG_TAG=""

# POSIX sh: functions can't modify the caller's $@, so
# parse_args tracks how many args it consumed and main
# shifts them off after the call.
_ARGS_CONSUMED=0

main() {
  parse_args "$@"
  shift "$_ARGS_CONSUMED"

  _os="$(detect_os)"
  _arch="$(detect_arch)"
  resolve_release

  _tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t kaitos)"
  trap 'rm -rf "$_tmp_dir"' EXIT

  info "Installing Kaitos ${_tag} for ${_os}/${_arch}"
  fetch_release
  verify_release
  extract_release
  run_installer "$@"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--prerelease)
        _FLAG_PRERELEASE=true
        _ARGS_CONSUMED=$((_ARGS_CONSUMED + 1))
        shift
        ;;
      -t|--tag)
        if [ $# -lt 2 ] || [ -z "${2-}" ]; then
          die "missing value for --tag"
        fi
        _FLAG_TAG="$2"
        _ARGS_CONSUMED=$((_ARGS_CONSUMED + 2))
        shift 2
        ;;
      --)
        _ARGS_CONSUMED=$((_ARGS_CONSUMED + 1))
        break
        ;;
      *)
        break
        ;;
    esac
  done
}

resolve_release() {
  if [ -n "$_FLAG_TAG" ]; then
    _tag="$_FLAG_TAG"
    _checksum=""
  else
    resolve_version
  fi

  _version="${_tag#v}"
  _tarball_name="kaitos-${_version}-${_os}-${_arch}.tar.gz"
  _tarball_url="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/${_tag}/${_tarball_name}"
}

fetch_release() {
  info "Downloading ${_tarball_url}..."
  download "$_tarball_url" "$_tmp_dir/kaitos.tar.gz"
}

verify_release() {
  info "Verifying checksum..."
  if [ -n "$_checksum" ]; then
    verify_checksum_direct "$_tmp_dir/kaitos.tar.gz" "$_checksum"
  else
    _sums_url="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/${_tag}/SHA256SUMS"
    download "$_sums_url" "$_tmp_dir/SHA256SUMS"
    verify_checksum "$_tmp_dir/kaitos.tar.gz" "$_tarball_name" "$_tmp_dir/SHA256SUMS"
  fi
}

extract_release() {
  info "Extracting..."
  tar -xzf "$_tmp_dir/kaitos.tar.gz" -C "$_tmp_dir"

  _extract_dir="$(find "$_tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [ -z "$_extract_dir" ]; then
    die "Failed to locate extracted tarball contents"
  fi
}

# Sets PROJ and hands off to the real installer with remaining args.
run_installer() {
  export PROJ="$_extract_dir"
  /usr/bin/env bash "$_extract_dir/scripts/install/install.sh" "$@"
}

detect_os() {
  case "$(uname -s)" in
    Linux)  echo "linux" ;;
    Darwin) echo "darwin" ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
  esac
}

detect_arch() {
  _uname_m="$(uname -m)"
  case "$_uname_m" in
    x86_64|aarch64|arm64)
      echo "$_uname_m"
      ;;
    *)
      die "Unsupported architecture: $_uname_m"
      ;;
  esac
}

# Fetches kaitos.dev/release-index.json and sets _tag and _checksum for
# the requested channel. _checksum may be empty when the index hasn't
# been populated for this platform yet; the caller falls back to
# SHA256SUMS from the release in that case.
resolve_version() {
  _vj="$(download_text "$RELEASE_INDEX_URL")" || die "Failed to fetch release index from ${RELEASE_INDEX_URL}"

  if [ "$_FLAG_PRERELEASE" = true ]; then
    _channel="prerelease"
  else
    _channel="stable"
  fi

  _tag="$(printf '%s' "$_vj" \
    | grep "\"${_channel}\"[[:space:]]*:" \
    | head -n 1 \
    | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/')"

  if [ -z "$_tag" ]; then
    die "No ${_channel} release available"
  fi

  _checksum_key="${_channel}_sha256_${_os}_${_arch}"
  _checksum="$(printf '%s' "$_vj" \
    | grep "\"${_checksum_key}\"[[:space:]]*:" \
    | head -n 1 \
    | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/')" || true
}

# Verifies a file's SHA-256 against an expected hash string.
verify_checksum_direct() {
  _vcd_file="$1"
  _vcd_expected="$2"

  if command -v sha256sum >/dev/null 2>&1; then
    _vcd_actual="$(sha256sum "$_vcd_file" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    _vcd_actual="$(shasum -a 256 "$_vcd_file" | awk '{print $1}')"
  else
    die "No SHA-256 utility found (tried sha256sum, shasum)"
  fi

  if [ "$_vcd_actual" != "$_vcd_expected" ]; then
    die "Checksum verification failed. Expected: ${_vcd_expected}, Got: ${_vcd_actual}"
  fi

  info "Checksum OK."
}

# Verifies a file's SHA-256 against an entry in a SHA256SUMS file.
verify_checksum() {
  _vc_file="$1"
  _vc_name="$2"
  _vc_sums="$3"

  _vc_expected="$(grep "  ${_vc_name}$" "$_vc_sums" | awk '{print $1}')"
  if [ -z "$_vc_expected" ]; then
    die "Checksum for ${_vc_name} not found in SHA256SUMS"
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    _vc_actual="$(sha256sum "$_vc_file" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    _vc_actual="$(shasum -a 256 "$_vc_file" | awk '{print $1}')"
  else
    die "No SHA-256 utility found (tried sha256sum, shasum)"
  fi

  if [ "$_vc_actual" != "$_vc_expected" ]; then
    die "Checksum verification failed for ${_vc_name}. Expected: ${_vc_expected}, Got: ${_vc_actual}"
  fi

  info "Checksum OK."
}

# Downloads a URL to a file on disk.
download() {
  if command -v curl >/dev/null 2>&1; then
    curl -fSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$2" "$1"
  else
    die "Neither curl nor wget found"
  fi
}

# Downloads a URL and writes the content to stdout.
download_text() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
  else
    die "Neither curl nor wget found"
  fi
}

info() {
  printf '[kaitos] %s\n' "$1" >&2
}

die() {
  printf '[kaitos] FATAL: %s\n' "$1" >&2
  exit 1
}

main "$@"
