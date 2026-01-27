#!/bin/env bash
set -euo pipefail

source "scripts/shared/assert_exists.sh"

assert_exists "$GODOT_VERSION" "GODOT_VERSION is not set"
assert_exists "$GODOT_LOCAL_PATH" "GODOT_LOCAL_PATH is not set"
assert_exists "$GODOT_URL" "GODOT_URL is not set"

function main() {
	local version="$1"
	local url_base="$2"
	local bin_path="$3"
	local platform="linux.x86_64"
	local bin_name="Godot_v$version-stable_$platform"
	local zip_name="$bin_name.zip"
		
	# Get temp workspace
	local temp_dir="$(mktemp -d)"
	trap "rm -rf $temp_dir" EXIT

	# Download
	local url="$url_base/$version-stable/$zip_name"
	echo "Downloading $url..."
	curl -L "$url" -o "$temp_dir/$zip_name"

	# Extract
	mkdir -p "$bin_path"
	unzip -o "$temp_dir/$zip_name" -d "$bin_path"
  mv "$bin_path/$bin_name" "$bin_path/godot4"

	chmod +x "$bin_path/godot"
}


main "$GODOT_VERSION" "$GODOT_URL" "$GODOT_LOCAL_PATH"