#!/bin/bash
# lib.sh - 核心工具函数库

# ============================================
# 颜色定义
# ============================================
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
BLUE='\033[38;5;21m'
NC='\033[0m'

# ============================================
# 日志函数
# ============================================
empty() { echo -e "${NC}$*"; }
log() { echo -e "${BLUE}▶  ${NC}$*"; }
ok() { echo -e "${GREEN}✓  ${NC}$*"; }
complete() { echo -e "${YELLOW}☑  $*${NC}"; }
err() { echo -e "${RED}✗  ${NC}$*" >&2; }
warn() { echo -e "${YELLOW}▲  ${NC}$*" >&2; }

# ============================================
# 系统包管理
# ============================================
apt_update() { 
    sudo apt update -qq
}

install() {
    local pkg="$1"
    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" && return 0
    apt_update
    sudo apt install -y "$pkg"
}

installs() {
    for pkg in "$@"; do
        pkg=$(echo "$pkg" | tr -d ',')
        log "Installing: $pkg"
        install "$pkg"
    done
}

remove() {
    local pkg="$1"
    if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        sudo apt purge -y "$pkg"
        sudo apt autoremove -y
    fi
}

# ============================================
# 文件操作
# ============================================
backup() { 
    [[ -f "$1" ]] && sudo cp -p "$1" "$1.backup.$(date +%s)"
}

download() {
    local url="$1" out="$2"
    [[ -f "$out" ]] && return 0
    mkdir -p "$(dirname "$out")"
    wget -q --show-progress -c -O "$out" "$url"
}

append_line() {
    local line="$1" file="$2" use_sudo="${3:-no}"
    if [[ "$use_sudo" == "sudo" ]]; then
        [[ ! -f "$file" ]] && sudo touch "$file"
        grep -qxF "$line" "$file" 2>/dev/null || echo "$line" | sudo tee -a "$file" >/dev/null
    else
        [[ ! -f "$file" ]] && touch "$file"
        grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
    fi
}

# ============================================
# 配置文件读取（支持空格）
# ============================================
read_config() {
    local config_file="$1" section="$2" key="$3" allow_empty="${4:-false}"
    [[ ! -f "$config_file" ]] && { err "Config not found: $config_file"; exit 1; }
    
    local result
    result=$(awk -F'=' -v sec="[$section]" -v k="$key" '
        /^[[].*[]]$/ { in_sec = ($0 == sec); next }
        in_sec && NF > 0 && !/^[;#]/ {
            # 提取键和值
            split($0, parts, "=")
            curr_key = parts[1]
            gsub(/^[ \t]+|[ \t]+$/, "", curr_key)
            
            if (curr_key == k) {
                # 提取等号后的所有内容
                idx = index($0, "=")
                value = substr($0, idx + 1)
                gsub(/^[ \t]+|[ \t]+$/, "", value)
                gsub(/^["'"'"']|["'"'"']$/, "", value)
                print value
                exit
            }
        }
    ' "$config_file")
    
    [[ -z "$result" && "$allow_empty" != "true" ]] && { 
        err "Missing required config: [$section] $key"
        exit 1
    }
    echo "$result"
}

read_section() {
    local config_file="$1" section="$2"
    [[ ! -f "$config_file" ]] && { err "Config not found: $config_file"; exit 1; }
    
    awk -F'=' -v sec="[$section]" '
        /^[[].*[]]$/ { in_sec = ($0 == sec); next }
        in_sec && NF > 0 && !/^[;#]/ {
            # 提取键
            split($0, parts, "=")
            k = parts[1]
            gsub(/^[ \t]+|[ \t]+$/, "", k)
            
            # 提取值（等号后的所有内容）
            idx = index($0, "=")
            if (idx > 0) {
                v = substr($0, idx + 1)
                gsub(/^[ \t]+|[ \t]+$/, "", v)
                gsub(/^["'"'"']|["'"'"']$/, "", v)
                print k "=\"" v "\""
            }
        }
    ' "$config_file"
}

# ============================================
# 配置加载（统一方法）
# ============================================
load_config_section() {
    local -n cfg_ref="$1"
    local section="$2"
    local auto_resolve="${3:-true}"
    
    while IFS='=' read -r key value; do
        key=$(echo "$key" | tr -d '"')
        value=$(echo "$value" | tr -d '"')
        
        local array_key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
        
        if [[ "$auto_resolve" == "true" && "$value" =~ \$\{ ]]; then
            value=$(resolve_var "$value")
        fi
        
        cfg_ref["$array_key"]="$value"
    done < <(read_section "$CONFIG_FILE" "$section")
}

# ============================================
# 变量解析（统一路径处理）
# ============================================
resolve_var() {
    local value="$1"
    value="${value//\$\{PROGRAMS_DIR\}/$PROGRAMS}"
    value="${value//\$\{CONFIG_DIR\}/$CONFIG}"
    value="${value//\$\{DOWNLOADS_DIR\}/$DOWNLOADS}"
    value="${value//\$\{TEMP_DIR\}/$TEMP}"
    echo "$value"
}

# ============================================
# 模板处理（统一模板引擎）
# ============================================
install_template() {
    local template="$1" output="$2" use_sudo="${3:-no}"
    shift 3
    local tpl_file="${TEMPLATES_DIR}/${template}"
    
    [[ ! -f "$tpl_file" ]] && { err "Template not found: $tpl_file"; exit 1; }
    
    local content=$(cat "$tpl_file")
    for kv in "$@"; do
        local key="${kv%%=*}" val="${kv#*=}"
        val=$(echo "$val" | sed 's/[\/&]/\\&/g')
        content=$(echo "$content" | sed "s|@${key}@|${val}|g")
    done
    
    if echo "$content" | grep -q '@.*@'; then
        err "Unresolved variables in $output:"
        echo "$content" | grep -o '@[^@]*@' | sort -u >&2
        exit 1
    fi
    
    mkdir -p "$(dirname "$output")"
    if [[ "$use_sudo" == "sudo" ]]; then
        echo "$content" | sudo tee "$output" >/dev/null
    else
        echo "$content" > "$output"
    fi
}

# ============================================
# 应用安装框架（统一安装流程）
# ============================================
install_app() {
    local -n app_cfg="$1"
    
    case "${app_cfg[type]}" in
        appimage)
            _install_appimage app_cfg
            ;;
        archive)
            _install_archive app_cfg
            ;;
        *)
            err "Unknown app type: ${app_cfg[type]}"
            return 1
            ;;
    esac
    
    # 统一创建桌面文件
    [[ -n "${app_cfg[desktop_name]:-}" ]] && _create_desktop app_cfg
    
    # 自动启动（检查键是否存在）
    if [[ -n "${app_cfg[autostart]:-}" && ( "${app_cfg[autostart]}" == "true" || "${app_cfg[autostart]}" == "True" ) ]]; then
        add_to_autostart "${app_cfg[desktop_file]}"
    fi
}

_install_appimage() {
    local -n cfg="$1"
    local filename=$(basename "${cfg[url]}")
    local temp_file="$TEMP/$filename"
    
    log "Installing ${cfg[name]}..."
    download "${cfg[url]}" "$temp_file" || return 1
    
    mkdir -p "${cfg[install_dir]}"
    mv "$temp_file" "${cfg[install_dir]}/$filename"
    chmod +x "${cfg[install_dir]}/$filename"
    
    cfg[exec]="${cfg[install_dir]}/$filename"
    ok "${cfg[name]} installed"
}

_install_archive() {
    local -n cfg="$1"
    local filename=$(basename "${cfg[url]}")
    local temp_file="$TEMP/$filename"
    
    log "Installing ${cfg[name]}..."
    download "${cfg[url]}" "$temp_file" || return 1
    
    mkdir -p "${cfg[install_dir]}"
    
    case "$filename" in
        *.tar.gz|*.tgz) tar xzf "$temp_file" -C "${cfg[install_dir]}" --strip-components="${cfg[strip]:-1}" ;;
        *.tar.xz) tar xJf "$temp_file" -C "${cfg[install_dir]}" --strip-components="${cfg[strip]:-1}" ;;
        *.tar.bz2) tar xjf "$temp_file" -C "${cfg[install_dir]}" --strip-components="${cfg[strip]:-1}" ;;
        *.zip) unzip -q "$temp_file" -d "${cfg[install_dir]}" ;;
        *) err "Unsupported format: $filename"; return 1 ;;
    esac
    
    rm -f "$temp_file"
    
    cfg[exec]="${cfg[install_dir]}/${cfg[exec_name]}"
    [[ -f "${cfg[exec]}" ]] && chmod +x "${cfg[exec]}"
    
    ok "${cfg[name]} installed"
}

_create_desktop() {
    local -n cfg="$1"
    local desktop_file="/tmp/${cfg[name],,}.desktop"
    
    # 安装图标
    local icon_path="${cfg[install_dir]}/${cfg[icon]:-${cfg[name]}}.png"
    if [[ -f "${TEMPLATES_DIR}/${cfg[icon]:-${cfg[name]}}.png" ]]; then
        cp "${TEMPLATES_DIR}/${cfg[icon]:-${cfg[name]}}.png" "$icon_path"
    fi
    
    # 创建桌面文件
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=${cfg[desktop_name]:-${cfg[name]}}
Comment=${cfg[comment]:-${cfg[name]}}
Exec=${cfg[exec]}
Icon=$icon_path
Terminal=${cfg[terminal]:-false}
Type=Application
Categories=${cfg[categories]:-Utility};
EOF
    
    desktop-file-validate "$desktop_file" 2>/dev/null || warn "Desktop validation warning"
    sudo desktop-file-install "$desktop_file"
    sudo update-desktop-database
    rm -f "$desktop_file"
    
    cfg[desktop_file]="${cfg[name],,}.desktop"
}

add_to_autostart() {
    local desktop_file="$1"
    mkdir -p "$CONFIG/autostart"
    cp "/usr/share/applications/$desktop_file" "$CONFIG/autostart/" 2>/dev/null || \
    cp "$HOME/.local/share/applications/$desktop_file" "$CONFIG/autostart/" 2>/dev/null
}

# ============================================
# Systemd 服务管理
# ============================================
enable_service() {
    local name="$1"
    systemctl --user daemon-reload
    systemctl --user enable "$name"
    systemctl --user restart "$name"
}

check_service() { 
    systemctl --user is-active --quiet "$1"
}

# ============================================
# 导出所有函数
# ============================================
export -f log ok err warn empty complete
export -f apt_update install installs remove
export -f download backup append_line
export -f read_config read_section load_config_section resolve_var
export -f install_template install_app
export -f add_to_autostart enable_service check_service
