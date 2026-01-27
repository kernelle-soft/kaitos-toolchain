#!/bin/env bash
set -eo pipefail

source "scripts/shared/assert_exists.sh"

function main() {
	# Check if .orphan folder already exists
	if [[ -d "$HOME/.config/orphan" ]]; then
		echo "There's already an installation of orphan."
		read "Would you like to do a clean re-install (N/y)? " answer

		if [[ -z "$answer" || "$answer" == [Nn] ]]; then
			exit 0
		fi
	fi

	remove_install
	create_empty_install
	download_toolchain
	install_settings

	download_engine
	bind_engine
}

function remove_install() {
	rm -rf "$HOME/.config/orphan"
	rm -rf "$HOME/.local/share/orphan"
	rm -rf "$HOME/.local/bin/orphan"
	rm -rf "$HOME/.cache/orphan"
}

function create_empty_install() {
	mkdir -p "$HOME/.config/orphan"
	mkdir -p "$HOME/.local/share/orphan"
	mkdir -p "$HOME/.local/bin/orphan"
	mkdir -p "$HOME/.cache/orphan"
}

function download_toolchain() {
	# TODO
	# curl and download latest release to $HOME/.cache/orphan/{TOOLCHAIN_VERSION}/bundle.zip
	# extract $HOME/.cache/orphan/{TOOLCHAIN_VERSION}/bundle.zip to
	# $HOME/.local/share/orphan/{TOOLCHAIN_VERSION}/ and $HOME/.local/bin/orphan
	# - bin: the thin wrapper that coordinates godot and the transpiler
	# - share: the rest of the guts
}

function download_engine() {
	local engine_choice="$(get_user_engine_choice)"
	# TODO
	# Download the appropriate engine at the appropriate version
	# Download it to the cache at TOOLCHAIN_VERSION
	# Install it to .local/share/orphan/{TOOL_CHAIN_VERSION}/{ENGINE_NAME}
}

function get_user_engine_choice() {
	local options=("godot" "bevy")
	select choice in "${options[@]}"; do
		if [[ -n "$choice" ]]; then
			echo "$choice"
			return
		fi
	done
}

function install_settings() {
	sed -e "s/__TOOLCHAIN_VERSION__/$TOOLCHAIN_VERSION" \
		"scripts/toolchain/template_settings.yaml" "$HOME/.config/orphan/settings.yaml"
}

main