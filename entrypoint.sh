#!/bin/bash
set -e
source /home/odoo/scripts/profile

# 设置多进程启动方式。
# * 修复DeprecationWarning: This process (pid=12) is multi-threaded, use of fork() may lead to deadlocks in the child.
python -c "import multiprocessing; multiprocessing.set_start_method('spawn', force=True)"

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