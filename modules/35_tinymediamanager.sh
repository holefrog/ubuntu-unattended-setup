#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1}"

log "Installing tinyMediaManager..."

# 加载配置
declare -A cfg sys_cfg
load_config_section cfg "TinyMediaManager"
load_config_section sys_cfg "System"

# 检查 Java 依赖
if ! command -v java &>/dev/null; then
    log "Installing Java: ${sys_cfg[java_package]}"
    install "${sys_cfg[java_package]}"
fi

# 构建下载 URL
local version="${cfg[tmm_version]}"
local filename="tinyMediaManager-${version}-linux-amd64.tar.xz"
local url="https://release.tinymediamanager.org/v5/dist/${filename}"

# 准备应用配置
declare -A app
app[type]="archive"
app[name]="tinymediamanager"
app[url]="$url"
app[install_dir]="${cfg[tmm_install_dir]}"
app[exec_name]="${cfg[tmm_exec_name]}"
app[desktop_name]="tinyMediaManager"
app[comment]="Media Library Manager"
app[icon]="tmm"
app[categories]="${cfg[tmm_categories]}"
app[strip]=1

# 执行安装
install_app app

# 创建启动脚本
local launch_script="${cfg[tmm_install_dir]}/tmm.sh"
cat > "$launch_script" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
exec ./tinyMediaManager "$@"
EOF
chmod +x "$launch_script"

# 创建数据目录
mkdir -p "$HOME/.tinyMediaManager" \
         "$HOME/Videos/Movies" \
         "$HOME/Videos/TV Shows"

# 添加命令别名
append_line "" "$HOME/.bashrc" "no"
append_line "# tinyMediaManager launcher" "$HOME/.bashrc" "no"
append_line "alias tmm='${launch_script} &'" "$HOME/.bashrc" "no"

ok "tinyMediaManager ${version} installed successfully"
log "Launch with: tmm (after reloading bashrc)"