#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

log "Installing APT packages..."

APT_PACKAGES=$(read_section "$CONFIG_FILE" "APT_PACKAGES")

if [[ -z "$APT_PACKAGES" ]]; then
    log "No packages defined in [APT_PACKAGES]"
    exit 0
fi

PACKAGES=()
while IFS="=" read -r key value; do
    [[ "$key" =~ ^[a-zA-Z0-9_-]+$ ]] && PACKAGES+=("$key")
done <<< "$APT_PACKAGES"

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    log "No valid packages found"
    exit 0
fi

log "Packages to install: ${PACKAGES[*]}"
installs "${PACKAGES[@]}"

ok "APT packages installed"
