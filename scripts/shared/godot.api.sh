#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

: <<'DOC'
API for downloading and locating the Godot editor binary.

Manages Godot installations under XDG_CACHE_HOME, with version-namespaced
directories and platform-aware binary resolution (Linux binaries are bare
executables; macOS uses a .app bundle to preserve code signing).

Dependencies: curl, unzip
DOC

import "$KAITOSHOME/scripts/shared/manifest.api.sh"

__godot_api__XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
__godot_api__CACHE_DIR="$__godot_api__XDG_CACHE_HOME/kaitos/godot"

: <<'DOC'
  Maps uname values to the Godot release naming scheme.

  Returns the platform suffix used in Godot release filenames:
    - Linux:  linux.<arch>  (x86_64, arm64)
    - macOS:  macos.universal

  Usage:
    __godot_api__platform_suffix
    # => linux.x86_64
    # => macos.universal
DOC
function __godot_api__platform_suffix() {
  local os arch

  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin)
      echo "macos.universal"
      return
      ;;
    Linux) ;;
    *)
      fatal "Unsupported OS: $os"
      return 1
      ;;
  esac

  case "$arch" in
    x86_64)  echo "linux.x86_64" ;;
    aarch64) echo "linux.arm64" ;;
    *)
      fatal "Unsupported architecture: $arch"
      return 1
      ;;
  esac
}

: <<'DOC'
  Returns the platform-correct path to a cached Godot binary.

  On Linux, the binary is a bare executable named after the release artifact.
  On macOS, it lives inside the .app bundle to preserve notarization.

  Usage:
    godot_path              # uses version from manifest.json
    godot_path "4.5.1"      # explicit version

  Output:
    Prints the absolute path to the Godot binary to stdout.
DOC
function godot_path() {
  local version="${1:-$(manifest_get godot_version)}"
  local suffix cache_dir

  suffix="$(__godot_api__platform_suffix)" || return 1
  cache_dir="$__godot_api__CACHE_DIR/$version"

  case "$(uname -s)" in
    Darwin)
      echo "$cache_dir/Godot.app/Contents/MacOS/Godot"
      ;;
    *)
      echo "$cache_dir/Godot_v${version}-stable_${suffix}"
      ;;
  esac
}

: <<'DOC'
  Downloads and caches a Godot editor binary.

  Fetches the release zip from GitHub, extracts it to the XDG cache under a
  version-namespaced directory. Idempotent: skips download if the binary
  already exists at the expected path.

  Usage:
    godot_download              # uses version/url from manifest.json
    godot_download "4.5.1"      # explicit version

  Options (env):
    GODOT_URL: base URL for Godot releases (read from manifest if unset)

  Cache layout:
    $XDG_CACHE_HOME/kaitos/godot/<version>/
      Linux: Godot_v<version>-stable_linux.<arch>
      macOS: Godot.app/Contents/MacOS/Godot
DOC
function godot_download() {
  local version url_base suffix zip_name url cache_dir binary_path

  version="${1:-$(manifest_get godot_version)}"
  url_base="${GODOT_URL:-$(manifest_get godot_url)}"
  suffix="$(__godot_api__platform_suffix)" || return 1

  zip_name="Godot_v${version}-stable_${suffix}.zip"
  url="${url_base}/${version}-stable/${zip_name}"
  cache_dir="$__godot_api__CACHE_DIR/$version"
  binary_path="$(godot_path "$version")"

  if [[ -x "$binary_path" ]]; then
    log "Godot $version already cached at $cache_dir"
    return 0
  fi

  for cmd in curl unzip; do
    if ! command -v "$cmd" &>/dev/null; then
      fatal "Required command not found: $cmd"
      return 1
    fi
  done

  log "Downloading Godot $version for $(uname -s)/$(uname -m)..."

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  if ! curl -fSL "$url" -o "$tmp_dir/$zip_name"; then
    error "Failed to download $url"
    return 1
  fi

  mkdir -p "$cache_dir"

  if ! unzip -qo "$tmp_dir/$zip_name" -d "$cache_dir"; then
    error "Failed to extract $zip_name"
    rm -rf "$cache_dir"
    return 1
  fi

  if [[ ! -x "$binary_path" ]]; then
    chmod +x "$binary_path"
  fi

  log "Godot $version installed to $cache_dir"
}
