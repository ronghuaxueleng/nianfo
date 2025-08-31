#!/bin/bash

# 启动cron服务
echo "Starting cron service..."
service cron start

# 确保工作目录正确
cd /app
echo "Git repository ready"

# 创建定时任务
UPDATE_INTERVAL=${GIT_UPDATE_INTERVAL:-3600}
CRON_SCHEDULE="*/$((UPDATE_INTERVAL/60)) * * * *"

# 如果间隔大于60分钟，使用小时计划
if [ $UPDATE_INTERVAL -ge 3600 ]; then
    HOURS=$((UPDATE_INTERVAL/3600))
    CRON_SCHEDULE="0 */$HOURS * * *"
fi

echo "$CRON_SCHEDULE /usr/local/bin/git-update.sh >> /var/log/git-update.log 2>&1" | crontab -
echo "Git update cron job scheduled: $CRON_SCHEDULE (every $UPDATE_INTERVAL seconds)"

# 执行首次更新（可选）
if [ "$INITIAL_UPDATE" = "true" ]; then
    echo "Performing initial git update..."
    /usr/local/bin/git-update.sh
fi

# 启动应用
echo "Starting application..."
echo "Current directory: $(pwd)"
echo "Checking /app contents:"
ls -la /app
echo "Checking /app/backend directory:"
ls -la /app/
cd /app && python run.py