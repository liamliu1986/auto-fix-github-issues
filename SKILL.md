---
name: auto-fix-github-issues
description: Use when you need to automatically fetch GitHub issues, analyze problems, generate fix code, and create PRs for multiple repositories. Also use when setting up scheduled issue processing or handling issue automation.
---

# Auto Fix GitHub Issues

## Overview
无状态技能，通过 GitHub CLI (`gh`) 自动拉取 GitHub Issues，分析问题并生成修复代码，创建 PR 后暂停等待人工合并。

## When to Use
- 手动触发: `/auto-fix-issues`
- 定时触发: `/loop 1h /auto-fix-issues`
- 需要自动处理多个仓库的 GitHub Issues

## Quick Reference

### 配置格式 (settings.json)
```json
{
  "autoFixGitHub": {
    "enabled": true,
    "repositories": [
      {
        "name": "repo-alias",
        "owner": "github-username",
        "repo": "repository-name",
        "enabled": true
      }
    ],
    "notification": {
      "email": "your@email.com",
      "站内通知": true
    }
  }
}
```

### 状态文件位置
```
~/.claude/state/auto-fix-github-issues/{repo-name}-state.json
```

### 核心命令
```bash
# 获取新 issues（按创建时间排序）
gh issue list --state open --json number,title,body,createdAt --limit 50 | jq '. | sort_by(.createdAt)'

# 创建分支
git checkout -b auto-fix/issue-{number}-{short-title}

# 创建 PR
gh pr create --title "Fix: {issue title}" --body "Closes #{issue-number}" --base main
```

## Workflow

1. 加载 settings.json 中的仓库配置
2. 遍历每个 enabled=true 的仓库
3. 获取该仓库上次处理后的新 issues
4. 按 createdAt 升序逐个处理
5. AI 分析 issue 并生成修复代码
6. 创建 PR 后暂停，等待人工合并
7. 无法处理时暂停流程并通知

## Configuration

### settings.json 完整示例
在 settings.json 顶部添加：
```json
"autoFixGitHub": {
  "enabled": true,
  "repositories": [],
  "notification": {
    "email": "",
    "站内通知": true
  }
}
```

### 状态文件格式
```json
{
  "lastProcessedIssueNumber": 42,
  "lastProcessedAt": "2026-05-25T10:30:00Z",
  "paused": false,
  "pauseReason": null
}
```

## Common Mistakes
- 忘记在 settings.json 中启用仓库 (enabled: true)
- GitHub CLI 未认证 (运行 `gh auth login`)
- 状态文件被误删导致重复处理