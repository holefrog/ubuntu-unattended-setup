#!/usr/bin/env bash
set -euo pipefail

git config --global user.name "holefrog"
git config --global user.email "liu_dong@outlook.com"

REPO_URL="https://github.com/holefrog/ubuntu-unattended-setup.git"
BRANCH="main"

# Ensure git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git init
fi

# Reset origin
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

# Create orphan branch (no history)
git checkout --orphan __temp_overwrite__

# ⚠️ 关键点：不要 git rm
# 直接 add 当前目录状态
git add -A

git commit -m "Full overwrite"

git branch -M "$BRANCH"

git push origin "$BRANCH" --force

