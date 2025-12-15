# Aria2 Configuration

# 基础设置
dir=@A2_DOWN@
continue=true
input-file=@A2_INPUT_FILE@
save-session=@A2_SAVE_SESSION@
save-session-interval=@A2_SAVE_SESSION_INTERVAL@

# 日志
log=@A2_LOG_FILE@
log-level=@A2_LOG_LEVEL@

# RPC 配置
enable-rpc=true
rpc-listen-port=@A2_RPC_PORT@
rpc-secret=@A2_SECRET@
rpc-listen-all=false
rpc-allow-origin-all=true

# HTTP 认证（可选）
http-user=@HTTP_USER@
http-passwd=@HTTP_PASSWD@

# 下载设置
max-concurrent-downloads=@A2_MAX_DOWNLOADS@
max-connection-per-server=16
min-split-size=10M
split=16

# BitTorrent
enable-dht=true
bt-enable-lpd=true
bt-max-peers=55

# 性能优化
file-allocation=none
disk-cache=32M