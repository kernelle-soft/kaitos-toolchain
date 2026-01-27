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
	[[ "$FLAG_MAJOR" && "$FLAG_MINOR" ]] && return 1
	[[ "$FLAG_MINOR" && "$FLAG_PATCH" ]] && return 1
	[[ "$FLAG_MAJOR" && "$FLAG_PATCH" ]] && return 1
	return 0
}

function prerelease_flags_valid() {
	[[ "$FLAG_DEV" && "$FLAG_ALPHA" ]] && return 1
	[[ "$FLAG_DEV" && "$FLAG_BETA" ]] && return 1
	[[ "$FLAG_DEV" && "$FLAG_RC" ]] && return 1
	[[ "$FLAG_ALPHA" && "$FLAG_BETA" ]] && return 1
	[[ "$FLAG_ALPHA" && "$FLAG_RC" ]] && return 1
	[[ "$FLAG_BETA" && "$FLAG_RC" ]] && return 1
	return 0
}

function plan_bump() {
	local semver_regex='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+(\.[0-9]+)?)?$'
	if [[ ! "$1" == "$semver_regex" ]]; then
		log "Invalid version string: $1"
		return 1
	fi

	local current_version="$1"
	local major="${current_version%%.*}"

	current_version="${current_version#*.}"
	local minor="${current_version%%.*}"

	current_version="${current_version#*.}"
	local patch="${current_version%%-*}"

	local prerelease=""
	local pre_type=""
	local pre_increment=""

	if [[ "$current_version" == *-* ]]; then
			prerelease="${current_version#*-}"
			pre_type="${prerelease%%.*}"
			pre_increment="${prerelease##*.}"
	fi

	local bumping_release

	bumping_release="$(is_bumping_release)"
	if is_bumping_prerelease; then
		local bump_type
		
		bump_type="$(compare_prerelease_types "$(get_prerelease_type)" "$pre_type")"
		if [[ "$bump_type" != "$pre_type" ]]; then
			pre_type="$bump_type"
			pre_increment=1

			if $bumping_release; then
				case "$(get_release_type)" in
					major) 
						major="$($major + 1)"
						minor=0
						patch=0
						;;
					minor) 
						minor="$($minor + 1)"
						patch=0
						;;
					patch) 
						patch="$($patch + 1)"
						;;
				esac
			fi
		else
			pre_increment="$($pre_increment + 1)"
		fi
	elif $bumping_release; then
		pre_type=""
		pre_increment=""
		case "$(get_release_type)" in
			major)
				major="$($major + 1)"
				minor=0
				patch=0
				;;
			minor)
				minor="$($minor + 1)"
				patch=0
				;;
			patch)
				patch="$($patch + 1)"
				;;
		esac
	fi

	return 0
}

function is_bumping_release() {
	if [[ "$FLAG_MAJOR" || "$FLAG_MINOR" || "$FLAG_PATCH" ]]; then
		return 0
	fi

	return 1
}

function is_bumping_prerelease() {
	if [[ "$FLAG_DEV" || "$FLAG_ALPHA" || "$FLAG_BETA" || "$FLAG_RC" ]]; then
		return 0
	fi

	return 1
}

function get_prerelease_type() {
	if [[ "$FLAG_DEV" ]]; then
		echo "dev"
	fi

	if [[ "$FLAG_ALPHA" ]]; then
		echo "alpha"
	fi

	if [[ "$FLAG_BETA" ]]; then
		echo "beta"
	fi

	if [[ "$FLAG_RC" ]]; then
		echo "rc"
	fi

	echo ""
	return 1
}

function get_release_type() {
	if [[ "$FLAG_MAJOR" ]]; then
		echo "major"
	fi

	if [[ "$FLAG_MINOR" ]]; then
		echo "minor"
	fi

	if [[ "$FLAG_PATCH" ]]; then
		echo "patch"
	fi

	echo ""
	return 1
}

function compare_prerelease_types() {
	if [[ "$1" == "$2" ]]; then
		echo "$1"
	fi

	local bump_type="$1"
	local cur_type="$2"

	local bump_precedence="$(get_prerelease_precedence $bump_type)"
	local cur_precedence="$(get_prerelease_precedence $cur_type)"

	if [[ "$bump_precedence" -gt "$cur_precedence" ]]; then
		echo "$bump_type"
	else
		echo "$cur_type"
	fi
}

get_prerelease_precedence() {
	local pre_type="$1"
	if [[ pre_type == "rc" ]]; then
		echo 4
	elif [[ pre_type == "beta" ]]; then
		echo 3
	elif [[ pre_type == "alpha" ]]; then
		echo 2
	elif [[ pre_type == "dev" ]]; then
		echo 1
	else
		echo 0
	fi
}

main "$@"