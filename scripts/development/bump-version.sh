#!/usr/bin/env bash
set -euo pipefail

USAGE="$(cat <<EOF
Intelligently bump the VERSION file based on the project's current version.

Usage: "bump-version.sh [flags...]"

Flags:
	-M, --major			Bump the major release version (0.9.9 -> 1.0.0)
	-m, --minor			Bump the minor release version (0.0.9 -> 0.1.0)
	-p, --patch 		Bump the patch release version (0.0.9 -> 0.0.10)
	-d, --dev				Start (or increment) the pre-release dev version (1.0.0 -> 1.0.1-dev.1 -> 1.0.1-dev.2)
	-a, --alpha			Start (or increment) the pre-release alpha version (1.0.0 -> 1.0.1-alpha.1 -> 1.0.1-alpha.2)
	-b, --beta			Start (or increment) the pre-release beta version (1.0.0 -> 1.0.1-beta.1 -> 1.0.1-beta.2)
	-c, --rc				Start (or increment) the pre-release rc version (1.0.0 -> 1.0.1-rc.1 -> 1.0.1-rc.2)
	-r, --release 	Transition from pre-release to release (1.0.0-rc.1 -> 1.0.0)

Notes:
	When using a pre-release flag on an existing release version, you can also specify which release version you're planning on targeting with the bump. Pre-release versions always target a future release version.

	Running the script without any flags will automatically bump the version on the smallest existing granularity--the script will never graduate beyond that granularity until you graduate the version yourself.

	Or more simply, without flags, you get the predictable:
		- 1.0.0 --> 1.0.1
		- 1.0.0-dev.1 --> 1.0.0-dev.2
		- 1.0.0-rc.1 --> 1.0.0-rc.2
		- etc
EOF
)"

source "scripts/shared/log.sh"

SEMVER_REGEX='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+(\.[0-9]+)?)?$'
FLAG_MAJOR=false
FLAG_MINOR=false
FLAG_PATCH=false
FLAG_DEV=false
FLAG_ALPHA=false
FLAG_BETA=false
FLAG_RC=false
FLAG_RELEASE=false # TODO - implement transition from 1.0.0-rc.1 --> 1.0.0

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

	current_version="$(get_current_version)"
	planned_version="$(plan_bump "$current_version")"

	echo "current: $current_version, next: $planned_version"
	if ! plan_bump "$current_version"; then
		exit 1
	fi

	exit 0
}

: <<'DOC'
	Gets the latest tagged version from git. This can be either a pre-release or full release.

	If there is no previous tag, this returns "0.0.0". Otherwise, it will get the current tag
	with the leading 'v' stripped.
DOC
function get_current_version() {
	local latest_tag semver

	latest_tag="$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")"

	# Strip leading 'v' if there is one
	semver="${latest_tag#v}"
	echo "$semver"
}

: <<'DOC'
	Parses CLI flags. 
	See USAGE for flag descriptions.
DOC
function parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-M|--major) 	FLAG_MAJOR=true;;
			-m|--minor) 	FLAG_MINOR=true;;
			-p|--patch) 	FLAG_PATCH=true;;
			-d|--dev)   	FLAG_DEV=true;;
			-a|--alpha) 	FLAG_ALPHA=true;;
			-b|--beta)  	FLAG_BETA=true;;
			-c|--rc) 			FLAG_RC=true;;
			-r|--release) FLAG_RELEASE=true;;
			-h|--help)	log "$USAGE" && exit 0;;
			*)
				log "Unknown option: $1"
				log "$USAGE"
				exit 1
				;;
		esac
		shift
	done
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
	Parses a semver string into its components using namerefs.
	Usage: parse_version "1.2.3-alpha.4" major minor patch pre_type pre_inc
DOC
function parse_version() {
	local ver="$1"
	local -n _major=$2 _minor=$3 _patch=$4 _pre_type=$5 _pre_inc=$6

	_major="${ver%%.*}"; ver="${ver#*.}"
	_minor="${ver%%.*}"; ver="${ver#*.}"
	_patch="${ver%%-*}"
	_pre_type=""
	_pre_inc=""

	if [[ "$ver" == *-* ]]; then
		local pre="${ver#*-}"
		_pre_type="${pre%%.*}"
		_pre_inc="${pre##*.}"
	fi
}

: <<'DOC'
	Applies a release bump (major/minor/patch) based on flags.
	Usage: apply_release_bump major minor patch
DOC
function apply_release_bump() {
	local -n _major=$1 _minor=$2 _patch=$3
	case "$(get_release_type)" in
		major) _major="$((_major + 1))"; _minor=0; _patch=0 ;;
		minor) _minor="$((_minor + 1))"; _patch=0 ;;
		patch) _patch="$((_patch + 1))" ;;
	esac
}

: <<'DOC'
	Plans the version bump based on current version and flags.
	Outputs the new version string.
DOC
function plan_bump() {
	local major minor patch pre_type pre_inc

	if [[ ! "$1" =~ $SEMVER_REGEX ]]; then
		log "Invalid version: $1"
		return 1
	fi

	parse_version "$1" major minor patch pre_type pre_inc

	if is_bumping_prerelease; then
		plan_prerelease_bump major minor patch pre_type pre_inc
	elif is_bumping_release; then
		apply_release_bump major minor patch
		pre_type=""
		pre_inc=""
	else
		# Auto-bump smallest unit
		plan_auto_bump pre_type pre_inc patch
	fi

	# Format and output
	if [[ -n "$pre_type" ]]; then
		echo "$major.$minor.$patch-$pre_type.$pre_inc"
	else
		echo "$major.$minor.$patch"
	fi
}

: <<'DOC'
Helper function that plans the pre-release bump based on current version and flags.
Uses namerefs to modify the input variables 1-5.

Usage: plan_prerelease_bump major minor patch pre_type pre_inc
	major - The major version number
	minor - The minor version number
	patch - The patch version number
	pre_type - The pre-release type (dev, alpha, beta, rc)
	pre_inc - The pre-release increment (1, 2, 3, etc)
DOC
function plan_prerelease_bump() {
	local target_type
	local -n _major="$1" _minor="$2" _patch="$3" _pre_type="$4" _pre_inc="$5"
	target_type="$(compare_prerelease_types "$(get_target_prerelease_type)" "$_pre_type")"

	if [[ "$target_type" != "$_pre_type" ]]; then
		if [[ -z "$_pre_type" ]] && ! is_bumping_release; then
			_patch="$((_patch + 1))"
		fi

		if is_bumping_release; then
			apply_release_bump "$1" "$2" "$3"
		fi

		_pre_type="$target_type"
		_pre_inc=1
	else
		# Same pre-release type, just increment
		_pre_inc="$((_pre_inc + 1))"
	fi
}

function plan_auto_bump() {
	local -n _pre_type="$1" _pre_inc="$2" _patch="$3"

	if [[ -n "$_pre_type" ]]; then
		_pre_inc="$((_pre_inc + 1))"
	else
		_patch="$((_patch + 1))"
	fi
}

function is_bumping_release() {
	if $FLAG_MAJOR || $FLAG_MINOR || $FLAG_PATCH; then
		return 0
	fi

	return 1
}

function is_bumping_prerelease() {
	if $FLAG_DEV || $FLAG_ALPHA || $FLAG_BETA || $FLAG_RC; then
		return 0
	fi

	return 1
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
Executes the planned version bump, applying it to the VERSION file and Cargo workspace.

If both are successful, it then tags the current ref in git.
DOC
function perform_bump() {
	echo "TODO: perform_bump"
}

main "$@"