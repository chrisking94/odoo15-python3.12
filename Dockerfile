# 使用 Python 3.12 官方镜像
FROM python:3.12-slim-bookworm

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    ODOO_VERSION=15.0 \
    PYTHONPATH=/opt/odoo

# 安装系统依赖
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
    # 安装 wkhtmltopdf
    && wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bookworm_amd64.deb \
    && apt-get install -y /tmp/wkhtmltox.deb \
    && rm /tmp/wkhtmltox.deb \
    # 清理缓存
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 克隆 Odoo 15.0 源码
RUN git clone --depth 1 --branch ${ODOO_VERSION} https://github.com/odoo/odoo.git /opt/odoo

# 设置工作目录
WORKDIR /opt/odoo

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 安装前端依赖
RUN npm install -g rtlcss

# 创建运行用户和必要的目录
RUN useradd -m -U -r -d /opt/odoo odoo \
    && mkdir -p /var/log/odoo /etc/odoo /mnt/data/odoo/addons \
    && chown -R odoo:odoo /opt/odoo /var/log/odoo /etc/odoo /mnt/data/odoo/addons

# 切换用户
USER odoo

# 创建启动脚本
COPY --chown=odoo:odoo entrypoint.sh /opt/odoo/entrypoint.sh
RUN chmod +x /opt/odoo/entrypoint.sh

# 暴露端口
EXPOSE 8069 8072

# 设置入口点
ENTRYPOINT ["/opt/odoo/entrypoint.sh"]
CMD ["--config=/etc/odoo/odoo.conf", "--logfile=/var/log/odoo/odoo.log"]