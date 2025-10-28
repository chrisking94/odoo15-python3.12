#!/bin/bash
set -e

# 获取当前用户ID和组ID
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

# 确保/etc/passwd中有当前用户的记录
if ! whoami > /dev/null 2>&1; then
    echo "用户记录不存在，创建用户记录: UID=$CURRENT_UID, GID=$CURRENT_GID"

    # 创建用户记录
    echo "odoo:x:$CURRENT_UID:$CURRENT_GID::/opt/odoo:/bin/bash" >> /etc/passwd
    echo "odoo:x:$CURRENT_GID:" >> /etc/group

    # 确保必要的目录存在并有正确的权限
    mkdir -p /opt/odoo /var/log/odoo /etc/odoo /home/odoo
    chown $CURRENT_UID:$CURRENT_GID /opt/odoo /var/log/odoo /etc/odoo /home/odoo
fi

# 设置 PYTHONPATH 包含额外的包目录
if [ -n "$EXTRA_PACKAGE_PATHS" ]; then
    IFS=':' read -ra PATHS <<< "$EXTRA_PACKAGE_PATHS"
    for path in "${PATHS[@]}"; do
        if [ -d "$path" ]; then
            export PYTHONPATH="${PYTHONPATH}:${path}"
            echo "Added package path: $path"
        else
            echo "Warning: Package path does not exist: $path"
        fi
    done
fi

# 检查配置文件是否存在
if [ ! -f "/etc/odoo/odoo.conf" ]; then
    echo "Warning: Config file /etc/odoo/odoo.conf not found"
    echo "Creating default config file..."
    python odoo-bin --save --config=/etc/odoo/odoo.conf --stop-after-init
fi

# 启动 Odoo
echo "Starting Odoo..."
exec python odoo-bin "$@"