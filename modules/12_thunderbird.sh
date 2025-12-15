#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

# 读取配置
THUNDERBIRD_PPA=$(read_config "$CONFIG_FILE" "Thunderbird" "THUNDERBIRD_PPA")

# 添加 PPA
log "Adding Thunderbird PPA..."
if ! grep -qr "mozillateam" /etc/apt/sources.list.d/ 2>/dev/null; then
    sudo add-apt-repository -y --no-update "${THUNDERBIRD_PPA}"
fi

# 配置优先级
log "Configuring APT priority..."
install_template "thunderbird.preferences" "/etc/apt/preferences.d/mozilla-thunderbird" "sudo"

# 更新并安装
apt_update
install thunderbird

ok "Thunderbird installed"
