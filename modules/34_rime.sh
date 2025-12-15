#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

# 读取配置
RIME_INSTALL=$(read_config "$CONFIG_FILE" "RimeInputMethod" "RIME_INSTALL")

if [[ "${RIME_INSTALL}" != "True" ]]; then
    log "Rime installation skipped"
    exit 0
fi

log "Installing Rime..."

RIME_CONFIG_SUBDIR=$(read_config "$CONFIG_FILE" "RimeInputMethod" "RIME_CONFIG_SUBDIR")
RIME_PACKAGES_STR=$(read_config "$CONFIG_FILE" "RimeInputMethod" "RIME_PACKAGES")

# 解析包列表
IFS=',' read -r -a RIME_PACKAGES <<< "$RIME_PACKAGES_STR"

# 安装软件包
installs "${RIME_PACKAGES[@]}"

# 重启 IBus
ibus restart || true

# 部署配置文件
RIME_DIR="$CONFIG/$RIME_CONFIG_SUBDIR"
RIME_DATA="$DIR/data/ibus/rime"

if [[ -d "$RIME_DATA" ]]; then
    log "Deploying Rime config..."
    mkdir -p "$RIME_DIR"
    cp -r "$RIME_DATA/"* "$RIME_DIR/"
    ok "Config deployed"
fi

ok "Rime installed"
log "Reboot required to use Rime"
log "Add input: Settings > Region & Language > Input Sources > Chinese (Rime)"
