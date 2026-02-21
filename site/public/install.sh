#!/usr/bin/env sh
# Kaitos bootstrapper — curl -fsSL kaitos.dev/install.sh | sh
#
# Downloads the latest stable release tarball, extracts it, and hands off
# to the real installer. This script is a rarely-changed permalink.
#
# Dependencies (this bootstrapper): curl or wget, tar, uname, mktemp, find, grep, sed, head
# Shells: runs under POSIX sh, then execs /usr/bin/env bash for the main installer.

set -eu

GITHUB_ORG="kernelle-soft"
GITHUB_REPO="kaitos-toolchain"
GITHUB_API="https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}"

_FLAG_PRERELEASE=false

main() {
  # Consume bootstrapper flags; $@ retains the rest for the installer
  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--prerelease) _FLAG_PRERELEASE=true; shift ;;
      --) shift; break ;;
      *)  break ;;
    esac
  done

  _os="$(detect_os)"
  _arch="$(detect_arch)"
  _tag="$(resolve_tag)"

  info "Installing Kaitos ${_tag} for ${_os}/${_arch}"

  _tarball_url="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/${_tag}/kaitos-${_tag}-${_os}-${_arch}.tar.gz"
  _tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t kaitos)"
  trap 'rm -rf "$_tmp_dir"' EXIT

  info "Downloading ${_tarball_url}..."
  download "$_tarball_url" "$_tmp_dir/kaitos.tar.gz"

  info "Extracting..."
  tar -xzf "$_tmp_dir/kaitos.tar.gz" -C "$_tmp_dir"

  # The tarball extracts to kaitos-<version>-<os>-<arch>/
  _extract_dir="$(find "$_tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

  if [ -z "$_extract_dir" ]; then
    die "Failed to locate extracted tarball contents"
  fi

  # Set KAITOSHOME so .envrc enters install context when the installer sources it
  export KAITOSHOME="$_extract_dir"

  # Hand off to the real installer with remaining args
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

resolve_tag() {
  if [ "$_FLAG_PRERELEASE" = true ]; then
    _url="${GITHUB_API}/releases?per_page=1"
  else
    _url="${GITHUB_API}/releases/latest"
  fi

  _response="$(download_text "$_url")" || die "Failed to fetch release info from GitHub API"

  _tag="$(printf '%s' "$_response" | grep '"tag_name"' | head -n 1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"

  if [ -z "$_tag" ]; then
    die "Could not determine release tag"
  fi

  printf '%s' "$_tag"
}

download() {
  if command -v curl >/dev/null 2>&1; then
    curl -fSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$2" "$1"
  else
    die "Neither curl nor wget found"
  fi
}

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
