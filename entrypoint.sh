#!/bin/bash
set -e

# 通过环境变量设置 USER 和 HOME
export USER=$(id -u)
export HOME=/home/odoo

# 设置多进程启动方式。
# * 修复DeprecationWarning: This process (pid=12) is multi-threaded, use of fork() may lead to deadlocks in the child.
python -c "import multiprocessing; multiprocessing.set_start_method('spawn', force=True)"

# 加载环境变量文件（如果存在）
if [ -f "/home/odoo/.env" ]; then
    echo "Loading environment variables from /home/odoo/.env"
    export $(grep -v '^#' /home/odoo/.env | xargs)
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
    odoo --save --config=/etc/odoo/odoo.conf --stop-after-init
fi

# 启动 Odoo
echo "Starting Odoo..."
odoo "--update=$UPDATE" "$@"

# 阻塞进程，无限运行
echo "Odoo stopped unexpectedly."
tail -f /dev/null