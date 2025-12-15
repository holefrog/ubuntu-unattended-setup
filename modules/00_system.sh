#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"
HOSTS_FILE="${2}"

# 加载配置
declare -A cfg
load_config_section cfg "System"

# ============================================
# 系统升级
# ============================================
log "Upgrading system packages..."
sudo apt-get update
sudo apt-get upgrade -y

log "Installing essential tools..."
installs git curl wget net-tools

# ============================================
# 移除 Snap
# ============================================
if [[ "${cfg[remove_snap]}" == "True" ]] && command -v snap &>/dev/null; then
    log "Removing Snap..."
    
    # 停止服务
    sudo systemctl disable snapd.service snapd.socket 2>/dev/null || true
    
    # 移除所有 snap 包
    for snap_pkg in $(snap list 2>/dev/null | awk 'NR>1 {print $1}'); do
        sudo snap remove --purge "$snap_pkg" || true
    done
    
    # 卸载 snapd
    remove snapd
    sudo apt-mark hold snapd
    
    # 清理目录
    sudo rm -rf /snap /var/snap /var/lib/snapd ~/snap
    
    ok "Snap removed"
fi

# ============================================
# 配置 sudo 免密
# ============================================
if [[ "${cfg[configure_sudo_nopasswd]}" == "True" ]]; then
    log "Configuring passwordless sudo..."
    
    local sudoers_file="/etc/sudoers.d/$USER"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "$sudoers_file" >/dev/null
    sudo chmod 440 "$sudoers_file"
    
    ok "Sudo configured"
fi

# ============================================
# 配置 hosts 文件
# ============================================
if [[ "${cfg[configure_hosts_blocking]}" == "True" && -f "$HOSTS_FILE" ]]; then
    log "Configuring hosts blocking..."
    
    local hosts_target="/etc/hosts"
    backup "$hosts_target"
    
    # 添加标记
    append_line "" "$hosts_target" "sudo"
    append_line "# Custom Hosts - Start" "$hosts_target" "sudo"
    
    # 从 host.ini 读取并添加屏蔽规则
    awk -F'=' '/^\[BLOCKLIST\]/,/^\[/ {
        if (!/^\[/ && !/^[;#]/ && NF > 1) {
            host = $1; ip = $2
            gsub(/^[ \t]+|[ \t]+$/, "", host)
            gsub(/^[ \t]+|[ \t]+$/, "", ip)
            comment = ""
            if (match($0, /#.*$/)) {
                comment = substr($0, RSTART, RLENGTH)
            }
            print ip "\t" host " " comment
        }
    }' "$HOSTS_FILE" | while read -r line; do
        append_line "$line" "$hosts_target" "sudo"
    done
    
    append_line "# Custom Hosts - End" "$hosts_target" "sudo"
    
    ok "Hosts configured"
fi

# ============================================
# 配置 bashrc
# ============================================
if [[ "${cfg[configure_bashrc]}" == "True" ]]; then
    log "Configuring bashrc..."
    
    local bashrc="$HOME/.bashrc"
    backup "$bashrc"
    
    append_line "" "$bashrc" "no"
    append_line "# Custom Aliases" "$bashrc" "no"
    
    while IFS= read -r line; do
        [[ -n "$line" ]] && append_line "$line" "$bashrc" "no"
    done < "$TEMPLATES_DIR/bashrc_append.tpl"
    
    ok "Bashrc configured"
fi

# ============================================
# 时区和语言
# ============================================
log "Setting timezone: ${cfg[timezone]}"
sudo timedatectl set-timezone "${cfg[timezone]}"

log "Setting locale: ${cfg[locale]}"
sudo update-locale LANG="${cfg[locale]}"

ok "System configuration complete"