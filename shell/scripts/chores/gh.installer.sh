#!/usr/bin/env bash
set -euo pipefail

url_keyring="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
path_keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
dir_sources_list="/etc/apt/sources.list.d"
url_github_packages="https://cli.github.com/packages"

if ! command -v wget >/dev/null; then
  sudo apt update && sudo apt install wget -y
fi

sudo mkdir -p -m 755 /etc/apt/keyrings

keyring_tmp="$(mktemp)"
wget -nv -O "$keyring_tmp" "$url_keyring"
sudo tee "$path_keyring" < "$keyring_tmp" > /dev/null
sudo chmod go+r "$path_keyring"
rm -f "$keyring_tmp"

sudo mkdir -p -m 755 "$dir_sources_list"
arch="$(dpkg --print-architecture)"
echo "deb [arch=$arch signed-by=$path_keyring] $url_github_packages stable main" \
  | sudo tee "$dir_sources_list/github-cli.list" > /dev/null

sudo apt update
sudo apt install gh -y
