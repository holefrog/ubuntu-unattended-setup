#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

log "Configuring OpenVPN..."

# 加载配置
declare -A cfg
load_config_section cfg "OpenVPN"

# 安装依赖
install openvpn
install network-manager-openvpn-gnome

# 创建配置目录
mkdir -p "${cfg[openvpn_config_dir]}"

# 部署配置文件
local profile_name="${cfg[openvpn_profile_name]}"
local src_ovpn="$DIR/data/openvpn/${profile_name}.ovpn"
local dest_ovpn="${cfg[openvpn_config_dir]}/${profile_name}.ovpn"

if [[ -f "$src_ovpn" ]]; then
    cp "$src_ovpn" "$dest_ovpn"
    chmod 600 "$dest_ovpn"
    ok "Config deployed: ${profile_name}.ovpn"
else
    # 尝试查找任意 .ovpn 文件
    local found_ovpn=$(find "$DIR/data/openvpn" -maxdepth 1 -name "*.ovpn" 2>/dev/null | head -n 1)
    if [[ -n "$found_ovpn" ]]; then
        warn "Profile ${profile_name}.ovpn not found, using: $(basename "$found_ovpn")"
        cp "$found_ovpn" "$dest_ovpn"
        chmod 600 "$dest_ovpn"
    else
        err "No .ovpn configuration file found in data/openvpn/"
        exit 1
    fi
fi

# 安装图标
local icon_source="${TEMPLATES_DIR}/openvpn.png"
local icon_dest="${cfg[openvpn_config_dir]}/openvpn.png"
[[ -f "$icon_source" ]] && cp "$icon_source" "$icon_dest"

# 创建桌面快捷方式
local desktop_file_name="${profile_name,,}.desktop"
local desktop_file="${cfg[openvpn_config_dir]}/$desktop_file_name"

cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=OpenVPN-${profile_name}
GenericName=OpenVPN
Comment=OpenVPN Connection: ${profile_name}
Exec=sudo openvpn ${dest_ovpn}
Icon=${icon_dest}
Type=Application
Terminal=true
Categories=Network;
EOF

sudo desktop-file-install "$desktop_file"

# 显示连接信息
log "Server: ${cfg[openvpn_server]}:${cfg[openvpn_port]}"
log "Profile: ${profile_name}"

ok "OpenVPN configured successfully"
