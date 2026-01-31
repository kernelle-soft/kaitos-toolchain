#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

USAGE="$(cat <<EOF
Intelligently bump the git version based on the latest version tag.

Usage: "bump_git_version.sh [flags...]"

Flags:
  -h, --help       Show this help text
  -M, --major      Bump the major release version (0.9.9 -> 1.0.0)
  -m, --minor      Bump the minor release version (0.0.9 -> 0.1.0)
  -p, --patch      Bump the patch release version (0.0.9 -> 0.0.10)
  -d, --dev        Start (or increment) the pre-release dev version (1.0.0 -> 1.0.1-dev.1 -> 1.0.1-dev.2)
  -a, --alpha      Start (or increment) the pre-release alpha version (1.0.0 -> 1.0.1-alpha.1 -> 1.0.1-alpha.2)
  -b, --beta       Start (or increment) the pre-release beta version (1.0.0 -> 1.0.1-beta.1 -> 1.0.1-beta.2)
  -c, --rc         Start (or increment) the pre-release rc version (1.0.0 -> 1.0.1-rc.1 -> 1.0.1-rc.2)
  -r, --release    Transition from pre-release to release (1.0.0-rc.1 -> 1.0.0)
  --dry-run        Output the planned version bump without creating a tag

Notes:
  When using a pre-release flag on an existing release version, you can also pair it with --major or --minor for the version you're planning on targeting with the bump; otherwise, --patch is assumed. Pre-release versions always target a future release version.

  Running the script without any flags will automatically bump the version on the smallest existing granularity--the script will never graduate beyond that granularity until you graduate the version yourself.

  Or more simply, without flags, you get the predictable:
    - 1.0.0 --> 1.0.1
    - 1.0.0-dev.1 --> 1.0.0-dev.2
    - 1.0.0-rc.1 --> 1.0.0-rc.2
    - etc
EOF
)"

source "$REPO_ROOT/scripts/shared/log.func.sh"
source "$REPO_ROOT/scripts/shared/git/latest_version.func.sh"
source "$REPO_ROOT/scripts/shared/git/parse_version.func.sh"
source "$REPO_ROOT/scripts/shared/git/is_valid_semver.func.sh"

REGEX_SEMVER='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+(\.[0-9]+)?)?$'
REGEX_SEMVER_GIT_TAG="^v${REGEX_SEMVER#^}"  # ^v[0-9]+...

FLAG_MAJOR=false
FLAG_MINOR=false
FLAG_PATCH=false
FLAG_DEV=false
FLAG_ALPHA=false
FLAG_BETA=false
FLAG_RC=false
FLAG_RELEASE=false
FLAG_DRY_RUN=false

function main() {
  local current_version planned_version
  
  parse_args "$@"
  if ! release_flags_valid; then
    log "Only one release flag may be specified at a time. Use --help for more information."
    exit 1
  fi

  if ! prerelease_flags_valid; then
    log "Only one pre-release flag may be specified at a time. Use --help for more information."
    exit 1
  fi

  if ! needs_version_bump; then
    current_version="$(latest_version)"
    log "HEAD is already tagged with version '$current_version'"
    exit 1
  fi

  current_version="$(latest_version)"
  if ! planned_version="$(plan_bump "$current_version")"; then
    exit 1
  fi

  if [[ $FLAG_DRY_RUN = true ]]; then
    echo "$planned_version"
    exit 0
  fi

  perform_bump "$planned_version"

  exit 0
}

: <<'DOC'
  Parses CLI flags. 
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -M|--major)   FLAG_MAJOR=true;;
      -m|--minor)   FLAG_MINOR=true;;
      -p|--patch)   FLAG_PATCH=true;;
      -d|--dev)     FLAG_DEV=true;;
      -a|--alpha)   FLAG_ALPHA=true;;
      -b|--beta)    FLAG_BETA=true;;
      -c|--rc)       FLAG_RC=true;;
      -r|--release) FLAG_RELEASE=true;;
      --dry-run) FLAG_DRY_RUN=true;;
      -h|--help)  log "$USAGE" && exit 0;;
      *)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
    esac
    shift
  done
}


: <<'DOC'
  Checks if the repository should actually skip this attempt to bump.

  Returns false if there is already a valid semver tag at HEAD, OR if any flags are passed into the script, implying user intent beyond typical CI/CD flows. Returns true otherwise.
DOC
function needs_version_bump() {
  # Always bump when specific flags are provided.
  if is_bumping_prerelease || is_bumping_release; then
    return 0
  fi

  # If there's already a valid version tag
  if git tag --points-at HEAD | grep -qE "$REGEX_SEMVER_GIT_TAG"; then
    return 1
  fi

  return 0
}

function release_flags_valid() {
  $FLAG_MAJOR && $FLAG_MINOR && return 1
  $FLAG_MINOR && $FLAG_PATCH && return 1
  $FLAG_MAJOR && $FLAG_PATCH && return 1
  return 0
}

function prerelease_flags_valid() {
  $FLAG_DEV && $FLAG_ALPHA && return 1
  $FLAG_DEV && $FLAG_BETA && return 1
  $FLAG_DEV && $FLAG_RC && return 1
  $FLAG_ALPHA && $FLAG_BETA && return 1
  $FLAG_ALPHA && $FLAG_RC && return 1
  $FLAG_BETA && $FLAG_RC && return 1
  return 0
}

: <<'DOC'
  Applies a release bump (major/minor/patch) based on flags.
  Usage: apply_release_bump version_array
DOC
function apply_release_bump() {
  local -n _version=$1
  case "$(get_release_type)" in
    major) 
      _version[major]="$((_version[major] + 1))"; 
      _version[minor]=0; 
      _version[patch]=0
      ;;
    minor) _version[minor]="$((_version[minor] + 1))"; _version[patch]=0 ;;
    patch) _version[patch]="$((_version[patch] + 1))" ;;
  esac
}

: <<'DOC'
  Plans the version bump based on current version and flags.
  Outputs the new version string.
DOC
function plan_bump() {
  local -A version
  local major minor patch pre_type pre_inc

  if ! is_valid_semver "$1"; then
    log "Invalid version: $1"
    return 1
  fi

  parse_version "$1" version

  if is_bumping_prerelease; then
    plan_prerelease_bump version
  elif is_bumping_release || is_releasing_prerelease "${version[pre_type]}"; then
    apply_release_bump version
    version[pre_type]=""
    version[pre_inc]=""
  else
    # Auto-bump smallest unit
    plan_auto_bump version
  fi

  # Assign to temp vars for better readability
  # of the final format strings.
  major="${version[major]}"
  minor="${version[minor]}"
  patch="${version[patch]}"
  pre_type="${version[pre_type]}"
  pre_inc="${version[pre_inc]}"

  # Format and output
  if [[ -n "$pre_type" ]]; then
    echo "$major.$minor.$patch-$pre_type.$pre_inc"
  else
    echo "$major.$minor.$patch"
  fi
}

: <<'DOC'
Helper function that plans the pre-release bump based on current version and flags.
Uses nameref to modify the version array.

Usage: plan_prerelease_bump version_array
DOC
function plan_prerelease_bump() {
  local target_type
  local -n _version="$1"
  target_type="$(compare_prerelease_types "$(get_target_prerelease_type)" "${_version[pre_type]}")"

  if [[ "$target_type" != "${_version[pre_type]}" ]]; then
    if [[ -z "${_version[pre_type]}" ]] && ! is_bumping_release; then
      _version[patch]="$((_version[patch] + 1))"
    fi

    if is_bumping_release; then
      apply_release_bump "$1"
    fi

    _version[pre_type]="$target_type"
    _version[pre_inc]=1
  else
    # Same pre-release type, just increment
    _version[pre_inc]="$((_version[pre_inc] + 1))"
  fi
}

function plan_auto_bump() {
  local -n _version="$1"

  if [[ -n "${_version[pre_type]}" ]]; then
    _version[pre_inc]="$((_version[pre_inc] + 1))"
  else
    _version[patch]="$((_version[patch] + 1))"
  fi
}

function is_bumping_release() {
  [[ 
    $FLAG_MAJOR = true || 
    $FLAG_MINOR = true || 
    $FLAG_PATCH = true
  ]]
}

function is_bumping_prerelease() {
  [[ 
    $FLAG_DEV = true || 
    $FLAG_ALPHA = true || 
    $FLAG_BETA = true || 
    $FLAG_RC = true
  ]]
}

function is_releasing_prerelease() {
  local prerelease_type

  prerelease_type="$1"
  [[ -n "$prerelease_type" && $FLAG_RELEASE = true ]]
}

function get_target_prerelease_type() {
  if $FLAG_DEV; then
    echo "dev"
    return 0
  elif $FLAG_ALPHA; then
    echo "alpha"
    return 0
  elif $FLAG_BETA; then
    echo "beta"
    return 0
  elif $FLAG_RC; then
    echo "rc"
    return 0
  fi

  echo ""
  return 1
}

function get_release_type() {
  if $FLAG_MAJOR; then
    echo "major"
    return 0
  elif $FLAG_MINOR; then
    echo "minor"
    return 0
  elif $FLAG_PATCH; then
    echo "patch"
    return 0
  fi

  echo ""
  return 1
}

function compare_prerelease_types() {
  local bump_type cur_type
  local bump_precedence cur_precedence

  if [[ "$1" == "$2" ]]; then
    echo "$1"
    return 0
  fi

  bump_type="$1"
  cur_type="$2"

  bump_precedence="$(get_prerelease_precedence "$bump_type")"
  cur_precedence="$(get_prerelease_precedence "$cur_type")"

  if [[ "$bump_precedence" -gt "$cur_precedence" ]]; then
    echo "$bump_type"
  else
    echo "$cur_type"
  fi
}

function get_prerelease_precedence() {
  local pre_type="$1"
  if [[ "$pre_type" == "rc" ]]; then
    echo 4
  elif [[ "$pre_type" == "beta" ]]; then
    echo 3
  elif [[ "$pre_type" == "alpha" ]]; then
    echo 2
  elif [[ "$pre_type" == "dev" ]]; then
    echo 1
  else
    echo 0
  fi
}

: <<'DOC'
Executes the planned version bump, creating a new git tag.
DOC
function perform_bump() {
  local version

  version="v$1"
  git tag -a "$version" -m "$version"
  echo "Bumped to version '$version'"
}

main "$@"