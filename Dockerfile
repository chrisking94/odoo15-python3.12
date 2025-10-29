# 使用 Python 3.12 官方镜像
FROM python:3.12-slim-bookworm

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    ODOO_VERSION=15.0 \
    PYTHONPATH="$PYTHONPATH:/opt/odoo" \
    PATH="$PATH:/home/odoo/scripts"

# 合并系统操作到单层
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        git \
        libxslt-dev \
        libzip-dev \
        libldap2-dev \
        libsasl2-dev \
        libpq-dev \
        node-less \
        npm \
        gosu && \
    # 克隆 Odoo 源码
    git clone --depth 1 --branch ${ODOO_VERSION} https://github.com/odoo/odoo.git /opt/odoo && \
    cd /opt/odoo && \
    # 安装 Python 依赖
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir lxml_html_clean && \
    pip install --no-cache-dir . && \
    # 清理构建依赖和缓存
    apt-get purge -y --auto-remove build-essential git wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* ./.git

# 创建系统用户和目录结构
RUN groupadd -r odoo --gid=135 && \
    useradd -r -g odoo --uid=135 --gid=135 -d /opt/odoo odoo && \
    mkdir -p /var/lib/odoo /var/log/odoo /etc/odoo /mnt/data/odoo && \
    mkdir -p /home/odoo/addons /home/odoo/addons1 /home/odoo/addons2 && \
    chown -R odoo:odoo /opt/odoo /var/lib/odoo /var/log/odoo /etc/odoo /home/odoo /mnt/data/odoo

# 设置工作目录
WORKDIR /opt/odoo

# 复制脚本并设置权限
COPY --chown=odoo:odoo ./scripts /home/odoo/scripts/
COPY --chown=odoo:odoo entrypoint.sh /opt/odoo/entrypoint.sh
RUN chmod +x /home/odoo/scripts/* /opt/odoo/entrypoint.sh

# 暴露端口
EXPOSE 8069 8072

# 设置入口点
ENTRYPOINT ["/opt/odoo/entrypoint.sh"]
CMD ["--config=/etc/odoo/odoo.conf"]