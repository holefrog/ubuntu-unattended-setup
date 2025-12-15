#!/bin/bash
# setup.sh - 主安装脚本（优化版）
set -euo pipefail

# 获取脚本目录
DIR="$(cd "$(dirname "$0")" && pwd)"

# ============================================
# 初始化环境
# ============================================
init() {
    source "$DIR/lib.sh"
    export DIR 
    
    CONFIG_FILE="$DIR/config.ini"
    
    log "Initializing environment..."
    
    # ============================================
    # 从 [Paths] 读取所有核心路径
    # ============================================
    PROGRAMS_DIR=$(read_config "$CONFIG_FILE" "Paths" "PROGRAMS_DIR")
    CONFIG_DIR=$(read_config "$CONFIG_FILE" "Paths" "CONFIG_DIR")
    DOWNLOADS_DIR=$(read_config "$CONFIG_FILE" "Paths" "DOWNLOADS_DIR")
    TEMP_DIR=$(read_config "$CONFIG_FILE" "Paths" "TEMP_DIR")
    
    # ============================================
    # 导出绝对路径变量（供模块使用）
    # ============================================
    export PROGRAMS="$HOME/$PROGRAMS_DIR"
    export CONFIG="$HOME/$CONFIG_DIR"
    export DOWNLOADS="$HOME/$DOWNLOADS_DIR"
    export TEMP="$HOME/$TEMP_DIR"
    export TEMPLATES_DIR="$DIR/templates"
    
    # ============================================
    # 创建所有核心目录
    # ============================================
    mkdir -p "$PROGRAMS" "$CONFIG" "$DOWNLOADS" "$TEMP"
    
    ok "Environment initialized"
    log "  PROGRAMS:  $PROGRAMS"
    log "  CONFIG:    $CONFIG"
    log "  DOWNLOADS: $DOWNLOADS"
    log "  TEMP:      $TEMP"
}

# ============================================
# 获取模块列表
# ============================================
list() {
    for m in "$DIR/modules/"*.sh; do
        [[ -f "$m" ]] && basename "$m"
    done | sort
}

# ============================================
# 执行安装模块
# ============================================
run() {
    local mod="$1"
    empty "=================================================="
    empty "$mod: start"
    empty "=================================================="
    
    CONFIG_FILE="$DIR/config.ini"
    HOSTS_FILE="$DIR/host.ini"
    
    if source "$DIR/modules/$mod" "$CONFIG_FILE" "$HOSTS_FILE"; then
        empty "=================================================="
        complete "$mod: complete"
        empty "==================================================\n\n"
        return 0
    else
        err "Module failed: $mod"
        return 1
    fi
}

# ============================================
# 交互式菜单
# ============================================
menu() {
    local mods=($(list))
    
    while true; do
        echo
        echo "====================================="
        echo "Ubuntu Setup - Module Installer"
        echo "====================================="
        echo
        echo "Available Modules:"
        for i in "${!mods[@]}"; do
            printf "  %2d) %s\n" "$((i+1))" "${mods[$i]}"
        done
        
        echo
        echo "  a) Install all modules"
        echo "  q) Quit"
        echo
        read -p "Your choice: " choice
        
        case "$choice" in
            a|A)
                echo
                log "Installing all modules..."
                for m in "${mods[@]}"; do 
                    run "$m" || {
                        err "Stopped at module: $m"
                        break
                    }
                done
                echo
                read -p "Press Enter to continue..."
                ;;
            q|Q)
                log "Exiting..."
                exit 0
                ;;
            [0-9]*)
                if [[ $choice -ge 1 && $choice -le ${#mods[@]} ]]; then
                    echo
                    run "${mods[$((choice-1))]}" || true
                    echo
                    read -p "Press Enter to continue..."
                else
                    err "Invalid choice: $choice"
                    sleep 2
                fi
                ;;
            *)
                err "Invalid input: $choice"
                sleep 1
                ;;
        esac
    done
}

# ============================================
# 主程序
# ============================================
main() {
	# Initialize
    init
    
	# ============================================
	# Forbid running as root (sudo setup.sh)
	# ============================================
	if [[ "$EUID" -eq 0 ]]; then
	    err "ERROR: Do NOT run this script with sudo or as root."
	    err "Please run it as a normal user:"
	    err "  ./setup.sh"
	    exit 1
	fi


# 检查 sudo 权限
    if ! sudo -v; then
        err "This script requires sudo privileges"
        exit 1
    fi
    
    case "${1:-menu}" in
        -a|--all)
            log "Installing all modules..."
            for m in $(list); do 
                run "$m"
            done
            ok "All modules installed successfully!"
            ;;
        menu|"")
            menu
            ;;
        -l|--list)
            echo "Available modules:"
            list
            ;;
        -h|--help)
            cat <<EOF
Usage: $0 [OPTION]

Options:
  -a, --all    Install all modules
  -l, --list   List available modules
  -h, --help   Show this help message
  menu         Interactive menu (default)

Examples:
  $0              # Interactive menu
  $0 --all        # Install all modules
  $0 --list       # List modules
EOF
            ;;
        *)
            err "Unknown option: $1"
            err "Use -h or --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
