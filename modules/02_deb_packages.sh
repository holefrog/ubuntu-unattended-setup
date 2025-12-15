#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

log "Installing DEB packages..."

if ! command -v dpkg &>/dev/null; then
    err "dpkg not installed"
    exit 1
fi

DEB_CONFIG=$(read_section "$CONFIG_FILE" "DEB_PACKAGES")

if [[ -z "$DEB_CONFIG" ]]; then
    log "No packages defined in [DEB_PACKAGES]"
    exit 0
fi

TEMP_FILE="$TEMP/temp_deb_pkg.deb"

while IFS='=' read -r pkg_name_line pkg_url_line; do
    pkg_name=$(echo "$pkg_name_line" | xargs)
    pkg_url=$(echo "$pkg_url_line" | xargs | sed 's/^"//; s/"$//')
    
    if [[ -z "$pkg_name" || -z "$pkg_url" ]]; then
        warn "Skipping invalid DEB package entry"
        continue
    fi

    log "Processing $pkg_name"
    
    # 下载
    if ! download "$pkg_url" "$TEMP_FILE"; then
        err "Download failed for $pkg_name"
        continue
    fi

    # 安装
    log "Installing $pkg_name..."
    if ! sudo dpkg -i "$TEMP_FILE"; then
        warn "Dependency error detected, attempting auto-fix..."
        
        if sudo apt-get install -f -y; then
            if dpkg -l "$pkg_name" 2>/dev/null | grep -q "^ii"; then
                ok "Dependencies fixed and $pkg_name configured"
            else
                warn "Re-attempting installation..."
                if ! sudo dpkg -i "$TEMP_FILE"; then
                    err "Failed to resolve dependencies for $pkg_name"
                    rm -f "$TEMP_FILE"
                    continue
                fi
                sudo apt-get install -f -y || {
                    err "Failed to configure $pkg_name"
                    rm -f "$TEMP_FILE"
                    continue
                }
                ok "Dependencies fixed and $pkg_name reconfigured"
            fi
        else
            err "Failed to fix dependencies for $pkg_name"
            rm -f "$TEMP_FILE"
            continue
        fi
    fi

    rm -f "$TEMP_FILE"
    ok "$pkg_name installed"
    
done <<< "$DEB_CONFIG"

ok "DEB packages installation complete"
