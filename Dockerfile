# 使用 Python 3.12 官方镜像
FROM python:3.12-slim-bookworm

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    ODOO_VERSION=15.0 \
    PYTHONPATH=/opt/odoo

# 安装系统依赖（包括gosu用于用户切换）
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    gosu \
    # 清理缓存
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 克隆 Odoo 15.0 源码
RUN git clone --depth 1 --branch ${ODOO_VERSION} https://github.com/odoo/odoo.git /opt/odoo

# 设置工作目录
WORKDIR /opt/odoo

# 安装 Odoo 15
RUN pip install --no-cache-dir .

# 创建odoo用户和组（使用高UID避免冲突）
RUN groupadd -r -g 10001 odoo && \
    useradd -r -u 10001 -g odoo -d /opt/odoo odoo

# 创建必要的目录
RUN mkdir -p /var/log/odoo /etc/odoo /home/odoo/addons /home/odoo/addons1 /home/odoo/addons2 && \
    chown -R odoo:odoo /opt/odoo /var/log/odoo /etc/odoo /home/odoo

# 创建启动脚本
COPY --chown=odoo:odoo entrypoint.sh /opt/odoo/entrypoint.sh
RUN chmod +x /opt/odoo/entrypoint.sh

# 暴露端口
EXPOSE 8069 8072

# 设置入口点
ENTRYPOINT ["/opt/odoo/entrypoint.sh"]
CMD ["--config=/etc/odoo/odoo.conf", "--logfile=/var/log/odoo/odoo.log"]