#!/bin/bash
set -e

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