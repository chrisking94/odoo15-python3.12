#!/bin/bash
set -e

# 动态用户设置
if [ -n "$HOST_UID" ] && [ -n "$HOST_GID" ]; then
    echo "检测到自定义用户ID: UID=$HOST_UID, GID=$HOST_GID"

    # 检查是否需要修改用户
    CURRENT_UID=$(id -u odoo)
    CURRENT_GID=$(id -g odoo)

    if [ "$CURRENT_UID" != "$HOST_UID" ] || [ "$CURRENT_GID" != "$HOST_GID" ]; then
        echo "修改容器用户ID以匹配宿主机..."

        # 修改组ID
        if ! getent group $HOST_GID > /dev/null; then
            groupmod -g $HOST_GID odoo
        fi

        # 修改用户ID
        usermod -u $HOST_UID -g $HOST_GID odoo

        # 更改文件所有权
        chown -R $HOST_UID:$HOST_GID /opt/odoo
        chown -R $HOST_UID:$HOST_GID /var/log/odoo
        chown -R $HOST_UID:$HOST_GID /etc/odoo
        chown -R $HOST_UID:$HOST_GID /home/odoo

        echo "用户ID修改完成"
    else
        echo "用户ID已匹配，无需修改"
    fi
fi

# 设置 PYTHONPATH 包含额外的包目录
if [ -n "$EXTRA_PACKAGE_PATHS" ]; then
    IFS=':' read -ra PATHS <<< "$EXTRA_PACKAGE_PATHS"
    for path in "${PATHS[@]}"; do
        if [ -d "$path" ]; then
            export PYTHONPATH="${PYTHONPATH}:${path}"
            echo "添加包路径: $path"
        else
            echo "警告: 包路径不存在: $path"
        fi
    done
fi

# 检查配置文件是否存在
if [ ! -f "/etc/odoo/odoo.conf" ]; then
    echo "警告: 配置文件 /etc/odoo/odoo.conf 不存在"
    echo "创建默认配置文件..."
    gosu odoo python odoo-bin --save --config=/etc/odoo/odoo.conf --stop-after-init
fi

# 切换到odoo用户并启动Odoo
echo "启动Odoo服务..."
exec gosu odoo python odoo-bin "$@"