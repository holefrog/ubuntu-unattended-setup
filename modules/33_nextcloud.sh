#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

log "Installing NextCloud..."

# 加载配置
declare -A cfg
load_config_section cfg "NextCloud"

# 构建 URL（变量替换）
local version="${cfg[nextcloud_version]}"
local filename="Nextcloud-${version}-x86_64.AppImage"
local url="https://github.com/nextcloud-releases/desktop/releases/download/v${version}/${filename}"

# 准备应用配置
declare -A app
app[type]="appimage"
app[name]="nextcloud"
app[url]="$url"
app[install_dir]="${cfg[nextcloud_install_dir]}"
app[desktop_name]="NextCloud"
app[comment]="NextCloud Desktop Sync Client"
app[icon]="nextcloud"
app[categories]="${cfg[nextcloud_categories]}"
app[autostart]="${cfg[nextcloud_autostart]:-false}"

# 执行安装
install_app app

# 配置提示
if [[ -n "${cfg[nextcloud_server]}" && "${cfg[nextcloud_server]}" != "YOUR_NEXTCLOUD_SERVER_HERE" ]]; then
    log "Server configured: ${cfg[nextcloud_server]}"
else
    warn "Please configure NEXTCLOUD_SERVER in config.ini"
fi

ok "NextCloud installed successfully"