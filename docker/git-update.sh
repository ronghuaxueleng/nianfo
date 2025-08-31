#!/bin/bash
echo "$(date): Starting git update..."
cd /app || exit 1

# 检查是否是git仓库
if [ ! -d ".git" ]; then
    echo "$(date): Not a git repository, skipping update"
    exit 0
fi

# 获取当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo "$(date): Current branch: $CURRENT_BRANCH"

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo "$(date): Uncommitted changes detected, stashing..."
    git stash push -m "Auto-stash before update $(date)"
fi

# 拉取最新代码
echo "$(date): Pulling latest changes..."
if git pull origin "$CURRENT_BRANCH"; then
    echo "$(date): Git pull successful"
    
    # 检查是否需要重启应用（可选）
    if [ "$AUTO_RESTART" = "true" ]; then
        echo "$(date): Restarting application..."
        pkill -f "python.*run.py" || true
        sleep 2
        cd /app
        nohup python run.py > /dev/null 2>&1 &
    fi
else
    echo "$(date): Git pull failed"
    exit 1
fi

echo "$(date): Git update completed"