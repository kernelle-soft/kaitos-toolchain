#!/usr/bin/env bash
set -euo pipefail

USAGE="$(cat <<EOF
Intelligently bump the VERSION file based on the project's current version.

Usage: "bump-version.sh [flags...]"

Flags:
	-M, --major		Bump the major release version (0.9.9 -> 1.0.0)
	-m, --minor		Bump the minor release version (0.0.9 -> 0.1.0)
	-p, --patch 	Bump the patch release version (0.0.9 -> 0.0.10)
	-d, --dev			Start (or increment) the pre-release dev version (1.0.0 -> 1.0.1-dev.1 -> 1.0.1-dev.2)
	-a, --alpha		Start (or increment) the pre-release alpha version (1.0.0 -> 1.0.1-alpha.1 -> 1.0.1-alpha.2)
	-b, --beta		Start (or increment) the pre-release beta version (1.0.0 -> 1.0.1-beta.1 -> 1.0.1-beta.2)
	-c, --rc			Start (or increment) the pre-release rc version (1.0.0 -> 1.0.1-rc.1 -> 1.0.1-rc.2)

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

FLAG_MAJOR=false
FLAG_MINOR=false
FLAG_PATCH=false
FLAG_DEV=false
FLAG_ALPHA=false
FLAG_BETA=false
FLAG_RC=false

function main() {
	local current_version
	
	current_version="$(cat ./VERSION)"

	parse_args "$@"
	if ! release_flags_valid; then
		log "Only one release flag may be specified at a time. Use --help for more information."
		exit 1
	fi

	if ! prerelease_flags_valid; then
		log "Only one pre-release flag may be specified at a time. Use --help for more information."
		exit 1
	fi

	if ! plan_bump "$current_version"; then
		exit 1
	fi

	exit 0
}

: <<'DOC'
	Parses CLI flags. 
	See USAGE for flag descriptions.
DOC
function parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-M|--major) FLAG_MAJOR=true;;
			-m|--minor) FLAG_MINOR=true;;
			-p|--patch) FLAG_PATCH=true;;
			-d|--dev)   FLAG_DEV=true;;
			-a|--alpha) FLAG_ALPHA=true;;
			-b|--beta)  FLAG_BETA=true;;
			-r|--rc) 		FLAG_RC=true;;
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
	local semver_regex='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+(\.[0-9]+)?)?$'
	if [[ "$1" =~ $semver_regex ]]; then
		log "Invalid version: $1"; 
		return 1;
	fi

	local major minor patch pre_type pre_inc
	parse_version "$1" major minor patch pre_type pre_inc

	if is_bumping_prerelease; then
		local target_type
		target_type="$(compare_prerelease_types "$(get_prerelease_type)" "$pre_type")"

		if [[ "$target_type" != "$pre_type" ]]; then
			# Changing pre-release type (or starting one)
			if [[ -z "$pre_type" ]] && ! is_bumping_release; then
				patch="$((patch + 1))"
			fi

			is_bumping_release && apply_release_bump major minor patch
			pre_type="$target_type"
			pre_inc=1
		else
			# Same pre-release type, just increment
			pre_inc="$((pre_inc + 1))"
		fi
	elif is_bumping_release; then
		apply_release_bump major minor patch
		pre_type=""
		pre_inc=""
	else
		# Auto-bump smallest unit
		[[ -n "$pre_type" ]] && pre_inc="$((pre_inc + 1))" || patch="$((patch + 1))"
	fi

	# Format and output
	if [[ -n "$pre_type" ]]; then
		echo "$major.$minor.$patch-$pre_type.$pre_inc"
	else
		echo "$major.$minor.$patch"
	fi
}

function plan_prerelease_bump() {

}

function plan_release_bump() {
	
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

function get_prerelease_type() {
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
	if [[ "$1" == "$2" ]]; then
		echo "$1"
		return 0
	fi

	local bump_type="$1"
	local cur_type="$2"

	local bump_precedence="$(get_prerelease_precedence "$bump_type")"
	local cur_precedence="$(get_prerelease_precedence "$cur_type")"

	if [[ "$bump_precedence" -gt "$cur_precedence" ]]; then
		echo "$bump_type"
	else
		echo "$cur_type"
	fi
}

get_prerelease_precedence() {
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

main "$@"