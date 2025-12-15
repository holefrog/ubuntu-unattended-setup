[Unit]
Description=Aria2c
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/aria2c --conf-path=@A2_CONF@
Restart=on-failure

[Install]
WantedBy=default.target
