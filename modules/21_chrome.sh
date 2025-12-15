#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

log "Installing Google Chrome..."

# 添加 Google 签名密钥
if [ ! -d "/etc/apt/keyrings" ]; then
    log "Creating /etc/apt/keyrings directory..."
    sudo mkdir -p /etc/apt/keyrings
fi

KEYRING_FILE="/etc/apt/keyrings/google-chrome-archive-keyring.gpg"
log "Adding Google signing key..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o "${KEYRING_FILE}"

# 添加 APT 仓库
CHROME_LIST="/etc/apt/sources.list.d/google-chrome.list"
log "Adding Google Chrome APT repository..."
echo "deb [arch=amd64 signed-by=${KEYRING_FILE}] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee "$CHROME_LIST" >/dev/null

# 更新并安装
log "Updating APT package lists..."
sudo apt-get update >/dev/null

log "Installing google-chrome-stable..."
installs google-chrome-stable

ok "Google Chrome installed"
