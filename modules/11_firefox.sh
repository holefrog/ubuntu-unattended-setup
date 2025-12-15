#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

FIREFOX_PPA=$(read_config "$CONFIG_FILE" "Firefox" "FIREFOX_PPA")

# 添加 PPA
log "Adding Firefox PPA..."
if ! grep -qr "mozillateam" /etc/apt/sources.list.d/ 2>/dev/null; then
    sudo add-apt-repository -y --no-update "${FIREFOX_PPA}"
fi

# 配置优先级
log "Configuring APT priority..."
install_template "firefox.preferences" "/etc/apt/preferences.d/mozilla-firefox" "sudo"

# 安装
apt_update
install firefox

ok "Firefox installed"
