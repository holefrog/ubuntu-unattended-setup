#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

log "Installing Double Commander..."

# 加载配置
declare -A cfg
load_config_section cfg "DoubleCommander"

# 构建下载 URL
local version="${cfg[dc_version]}"
local base_url="https://sourceforge.net/projects/doublecmd/files/DC%20for%20Linux%2064%20bit/Double%20Commander%20${version}"
local filename="doublecmd-${version}.gtk2.x86_64.tar.xz"
local url="${base_url}/${filename}"

# 准备应用配置
declare -A app
app[type]="archive"
app[name]="doublecmd"
app[url]="$url"
app[install_dir]="${cfg[dc_install_dir]}"
app[exec_name]="${cfg[dc_exec_name]}"
app[desktop_name]="Double Commander"
app[comment]="Dual-pane File Manager"
app[icon]="doublecmd"
app[categories]="${cfg[dc_categories]}"
app[strip]=1

# 执行安装
install_app app

ok "Double Commander ${version} installed successfully"