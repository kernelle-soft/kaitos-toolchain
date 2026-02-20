#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Automatic installer for 3rd party developer tools. This is useful for setting up a new machine or for CI/CD setup. Who wants to mess around manually installing all these tools with a crappy README, amiright?

Usage: install_tools.sh [flags...] [tools...]

Arguments:
  tools...          OPTIONAL. A list of tools to install. Must be one of
                    the tools listed in INSTALLERS. If no tools are
                    specified, all available tools will be installed

Flags:
  -c, --check       Do an install check without actually installing
  -f, --force       Force re-installation.
  -u, --uninstall   Uninstall specified tools.
  -h, --help        Show this help text.

Notes:
  To add another command to the installer, add the install and uninstall commands
  to the INSTALLERS and UNINSTALLERS array in the script.

EOF
)"

FLAG_CHECK=false
FLAG_FORCE=false
FLAG_UNINSTALL=false
ARG_TOOLS=()

declare -A INSTALLERS=(
  [gocover-cobertura]="go install github.com/boumenot/gocover-cobertura@v1.4.0"
  [govulncheck]="go install golang.org/x/vuln/cmd/govulncheck@v1.1.4"
  [gh]="gh_cli_installer"
  [cargo-binstall]="cargo install cargo-binstall --version 1.17.4"
  [tokei]="cargo binstall -y --locked --force tokei@14.0.0"
  [cargo-llvm-cov]="cargo binstall -y --locked --force cargo-llvm-cov@0.6.24"
  [cargo-audit]="cargo binstall -y --locked --force cargo-audit@0.22.0"
  [watchexec]="cargo binstall -y --locked --force watchexec-cli@2.3.3"
)

declare -A UNINSTALLERS=(
  [gocover-cobertura]="rm -f \$(command -v gocover-cobertura) || true"
  [govulncheck]="rm -f \$(command -v govulncheck) || true"
  [gh]="gh_cli_uninstaller"
  [tokei]="cargo uninstall -v tokei"
  [cargo-llvm-cov]="cargo uninstall -v cargo-llvm-cov"
  [cargo-audit]="cargo uninstall -v cargo-audit"
  [watchexec]="cargo uninstall -v watchexec-cli"
  [cargo-binstall]="cargo uninstall -v cargo-binstall"
)

function main() {
  parse_args "$@"
  validate_flags

  # If no tools were specified from args,
  # then install all available tools.
  if (( ${#ARG_TOOLS[@]} == 0 )); then
    ARG_TOOLS=("${!INSTALLERS[@]}")
  fi

  if is_check; then
    run_check
    exit 0
  fi

  if should_uninstall; then
    run_uninstallers
  fi

  if [[ $FLAG_UNINSTALL = false ]]; then
    run_installers
  fi

  log
  log "All tools installed successfully 🗹"
}

: <<'DOC'
  Parses CLI flags.
  See USAGE for flag descriptions.
DOC
function parse_args() {
  local trimmed
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--check)       FLAG_CHECK=true;;
      -f|--force)       FLAG_FORCE=true;;
      -u|--uninstall)   FLAG_UNINSTALL=true;;
      -h|--help)        log "$USAGE" && exit 0;;
      -*)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
      *)
        if ! has_installer_for "$1"; then
          log "No installer for tool '$1'"
          log "$USAGE"
          exit 1
        fi

        trimmed="$(echo "$1" | xargs)"
        ARG_TOOLS+=("$trimmed")
        ;;
    esac
    shift
  done
}

function has_installer_for() {
  local tool="$1"
  [[ -v "INSTALLERS[$tool]" ]]
}

function validate_flags() {
  if [[
    $FLAG_UNINSTALL = true &&
    ($FLAG_FORCE = true || $FLAG_CHECK = true)
  ]]; then
    log "ERROR: -u,--uninstall is not valid when paired with other flags."
    exit 1
  fi
}

function should_install_command() {
  local command="$1"

  if [[ $FLAG_UNINSTALL = true ]]; then
    return 1
  fi

  if [[ $FLAG_CHECK = true ]]; then
    return 1
  fi

  if [[ $FLAG_FORCE = true ]]; then
    return 0
  fi

  ! command_exists "$command"
}

function is_check() {
  [[ $FLAG_CHECK = true ]]
}

function should_uninstall() {
  [[ $FLAG_FORCE = true || $FLAG_UNINSTALL = true ]]
}

function run_check() {
  local line before after

  before="$(printf '%*s' 4 '')"
  after="$(printf '%*s' 8 '')"
  line="$(printf '%*s' 40 '' | tr ' ' '-')"

  log "Installed?   Command"
  log "$line"

  for cmd in "${ARG_TOOLS[@]}"; do
    local report=""
    if command_exists "$cmd"; then
      report="$before🗹$after$cmd"
    else
      report="$before𐄂$after$cmd"
    fi
    log "$report"
  done
}

function run_uninstallers() {
  for cmd in "${ARG_TOOLS[@]}"; do
    if command_exists "$cmd"; then
      log "Uninstalling $cmd..."
      eval "${UNINSTALLERS[$cmd]}"
    fi
  done
}

function run_installers() {
  for cmd in "${ARG_TOOLS[@]}"; do
    if should_install_command "$cmd"; then
      log "Installing $cmd..."
      eval "${INSTALLERS[$cmd]}"
    fi
  done
}

function command_exists() {
  command -v "$1" >/dev/null
}

function gh_cli_installer() {
  local url_keyring="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
  local path_keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
  local dir_sources_list="/etc/apt/sources.list.d"
  local url_github_packages="https://cli.github.com/packages"
  local arch keyring_tmp

  # Ensure wget is available
  if ! command_exists wget; then
    sudo apt update && sudo apt install wget -y
  fi

  # Setup keyrings directory
  sudo mkdir -p -m 755 /etc/apt/keyrings

  # Download and install GPG keyring
  keyring_tmp="$(mktemp)"
  wget -nv -O "$keyring_tmp" "$url_keyring"
  sudo tee "$path_keyring" < "$keyring_tmp" > /dev/null
  sudo chmod go+r "$path_keyring"
  rm -f "$keyring_tmp"

  # Add GitHub CLI apt repository
  sudo mkdir -p -m 755 "$dir_sources_list"
  arch="$(dpkg --print-architecture)"
  echo "deb [arch=$arch signed-by=$path_keyring] $url_github_packages stable main" \
    | sudo tee "$dir_sources_list/github-cli.list" > /dev/null

  # Install gh
  sudo apt update
  sudo apt install gh -y
}

function gh_cli_uninstaller() {
  local path_keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
  local path_sources_list="/etc/apt/sources.list.d/github-cli.list"

  # Remove gh package
  sudo apt remove gh -y
  sudo apt autoremove -y

  # Remove apt repository
  sudo rm -f "$path_sources_list"

  # Remove GPG keyring
  sudo rm -f "$path_keyring"

  # Refresh apt sources
  sudo apt update
}

main "$@"
