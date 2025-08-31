# 使用Python 3.10作为基础镜像
FROM ronghuaxueleng/python-nodejs

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV TZ=Asia/Shanghai
ENV GIT_UPDATE_INTERVAL=3600
ENV GIT_REPO_URL=https://github.com/ronghuaxueleng/nianfo-backend.git
ENV GIT_BRANCH=main

RUN rm -rf /etc/apt/sources.list.d/*
RUN echo "deb http://mirrors.aliyun.com/debian/  bookworm main non-free contrib" > /etc/apt/sources.list  && \
    echo "deb http://mirrors.aliyun.com/debian/  bookworm-updates main non-free contrib" >> /etc/apt/sources.list  && \
    echo "deb http://mirrors.aliyun.com/debian/  bookworm-backports main non-free contrib" >> /etc/apt/sources.list  && \
    echo "deb http://mirrors.aliyun.com/debian-security/  bookworm-security main non-free contrib" >> /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        sqlite3 \
        ca-certificates \
        python3-dev \
        gcc \
        libpython3-dev \
        tzdata \
        python3-pip \
        procps \
        libgomp1 \
        libgl1 \
        libsm6 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        git \
        cron \
        openssh-client \
        libnspr4 \
        libnss3 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libatspi2.0-0 \
        libxcomposite1 \
        libxdamage1 \
        && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean
 
 # 设置时区
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone 

# 复制requirements文件
COPY requirements.txt .

RUN pip config set global.index-url  https://mirrors.aliyun.com/pypi/simple/
RUN pip install --upgrade pip
# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 克隆Git仓库到/app目录
RUN git clone -b ${GIT_BRANCH} ${GIT_REPO_URL} /tmp/repo && \
    cp -r /tmp/repo/* /app/ && \
    cp -r /tmp/repo/.git /app/ && \
    rm -rf /tmp/repo && \
    chmod +x /app/run.py 2>/dev/null || true

# 复制脚本文件
COPY git-update.sh /usr/local/bin/git-update.sh
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/git-update.sh /usr/local/bin/start.sh


# 创建数据目录和日志目录
RUN mkdir -p /app/data /var/log

# 打印构建时的目录结构
RUN echo "=== Build time /app directory ===" && ls -la /app

# 暴露端口
EXPOSE 5566

# 启动命令
ENTRYPOINT ["/usr/local/bin/start.sh"]
