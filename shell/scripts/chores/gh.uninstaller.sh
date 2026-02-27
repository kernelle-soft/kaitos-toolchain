#!/usr/bin/env bash
set -euo pipefail

sudo apt remove gh -y
sudo apt autoremove -y
sudo rm -f /etc/apt/sources.list.d/github-cli.list
sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg
sudo apt update
