#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

log "Installing Aria2..."

# 加载配置
declare -A cfg
load_config_section cfg "Aria2"

# 安装软件包
install aria2

# 创建目录
mkdir -p "${cfg[aria2_config_dir]}" "${cfg[aria2_download_dir]}"

# 生成密钥（如果未设置）
if [[ -z "${cfg[aria2_rpc_secret]}" || "${cfg[aria2_rpc_secret]}" == "YOUR_RPC_SECRET_HERE" ]]; then
    cfg[aria2_rpc_secret]=$(openssl rand -base64 32)
    warn "Generated RPC secret: ${cfg[aria2_rpc_secret]}"
    warn "Please update config.ini with this secret"
fi

# 配置文件路径
local session_file="${cfg[aria2_config_dir]}/aria2.session"
local log_file="${cfg[aria2_config_dir]}/aria2.log"
local conf_file="${cfg[aria2_config_dir]}/aria2.conf"

# 创建会话文件
touch "$session_file"

# 生成配置
install_template "aria2.conf.tpl" "$conf_file" "no" \
    "A2_DOWN=${cfg[aria2_download_dir]}" \
    "A2_INPUT_FILE=$session_file" \
    "A2_SAVE_SESSION=$session_file" \
    "A2_SAVE_SESSION_INTERVAL=${cfg[a2_save_session_interval]}" \
    "A2_LOG_FILE=$log_file" \
    "A2_LOG_LEVEL=${cfg[a2_log_level]}" \
    "A2_SECRET=${cfg[aria2_rpc_secret]}" \
    "A2_RPC_PORT=${cfg[aria2_rpc_port]}" \
    "A2_MAX_DOWNLOADS=${cfg[aria2_max_concurrent_downloads]}" \
    "HTTP_USER=${cfg[http_user]}" \
    "HTTP_PASSWD=${cfg[http_passwd]}"

# 更新 BT trackers
log "Updating BT trackers..."
local trackers=$(wget -qO- "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt" | tr '\n' ',' || echo "")
[[ -n "$trackers" ]] && echo "bt-tracker=$trackers" >> "$conf_file"

# 创建 systemd 服务
mkdir -p "$CONFIG/systemd/user"
install_template "aria2c.service.tpl" "$CONFIG/systemd/user/aria2c.service" "no" \
    "A2_CONF=$conf_file"

# 启用服务
enable_service aria2c.service

# 验证服务
sleep 2
if check_service aria2c.service; then
    ok "Aria2 service running"
else
    err "Aria2 failed to start"
    journalctl --user -xeu aria2c.service --no-pager | tail -20
    exit 1
fi

ok "Aria2 installed successfully"
log "RPC Port: ${cfg[aria2_rpc_port]}"
log "RPC Secret: ${cfg[aria2_rpc_secret]}"