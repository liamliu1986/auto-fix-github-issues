# Auto Fix GitHub Issues - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建一个全局技能 `auto-fix-github-issues`，实现自动拉取 GitHub Issues、分析问题、生成修复代码并创建 PR 的完整流程。

**Architecture:** 无状态技能 + 配置驱动模式。技能本身通过 GitHub CLI (`gh`) 与 GitHub API 交互，配置存储在 `settings.json`，状态存储在 `~/.claude/state/auto-fix-github-issues/` 目录。

**Tech Stack:** GitHub CLI (`gh`), Bash, JSON configuration

---

## File Structure

```
~/.claude/
├── skills/                                    # 全局 skills 目录
│   └── auto-fix-github-issues/
│       └── SKILL.md                           # 主技能文档
├── state/                                     # 状态目录
│   └── auto-fix-github-issues/
│       └── {repo-name}-state.json             # 每个仓库的处理状态
└── settings.json                             # 全局配置（追加 autoFixGitHub 配置）
```

---

## Task 1: 创建目录结构

**Files:**
- Create: `~/.claude/skills/auto-fix-github-issues/`
- Create: `~/.claude/state/auto-fix-github-issues/`

- [ ] **Step 1: 创建 skills 目录**

```bash
mkdir -p ~/.claude/skills/auto-fix-github-issues
```

- [ ] **Step 2: 创建 state 目录**

```bash
mkdir -p ~/.claude/state/auto-fix-github-issues
```

- [ ] **Step 3: 验证目录创建成功**

```bash
ls -la ~/.claude/skills/ && ls -la ~/.claude/state/
```

Expected output: 目录已创建

---

## Task 2: 编写主技能 SKILL.md

**Files:**
- Create: `~/.claude/skills/auto-fix-github-issues/SKILL.md`

- [ ] **Step 1: 创建 SKILL.md 文件**

写入完整的技能文档，包含：
- YAML frontmatter (name, description)
- Overview (核心原理)
- When to Use (触发条件)
- Quick Reference (配置格式、命令)
- Workflow (完整工作流程)
- Configuration (settings.json 格式说明)
- State Management (状态文件格式)
- Common Mistakes

**关键内容：**

```markdown
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
```

- [ ] **Step 2: 验证文件语法**

确认 markdown 格式正确，YAML frontmatter 有效。

---

## Task 3: 更新 settings.json 添加配置

**Files:**
- Modify: `~/.claude/settings.json` (追加 autoFixGitHub 配置)

- [ ] **Step 1: 读取当前 settings.json 尾部**

确认 JSON 结构，确定如何追加配置。

- [ ] **Step 2: 追加 autoFixGitHub 配置**

在 settings.json 顶部添加 `autoFixGitHub` 配置块，初始为空配置：
```json
"autoFixGitHub": {
  "enabled": false,
  "repositories": [],
  "notification": {
    "email": "",
    "站内通知": true
  }
}
```

- [ ] **Step 3: 验证 JSON 格式有效**

```bash
cat ~/.claude/settings.json | jq empty && echo "Valid JSON"
```

Expected output: `Valid JSON`

---

## Task 4: 创建示例状态文件

**Files:**
- Create: `~/.claude/state/auto-fix-github-issues/example-repo-state.json`

- [ ] **Step 1: 创建示例状态文件**

```json
{
  "lastProcessedIssueNumber": 0,
  "lastProcessedAt": null,
  "paused": false,
  "pauseReason": null
}
```

- [ ] **Step 2: 验证 JSON 格式**

```bash
cat ~/.claude/state/auto-fix-github-issues/example-repo-state.json | jq .
```

Expected output: JSON 被格式化输出

---

## Task 5: 测试 GitHub CLI 环境

**Files:**
- 无文件变更（仅验证环境）

- [ ] **Step 1: 检查 gh 是否安装**

```bash
gh --version
```

Expected output: `gh version x.x.x`

- [ ] **Step 2: 检查 gh 是否已认证**

```bash
gh auth status
```

Expected output: 显示已登录的账户信息

- [ ] **Step 3: 如果未认证，输出认证指令**

如果未认证，输出：
```bash
gh auth login
```

---

## Task 6: 创建 README 说明文档

**Files:**
- Create: `~/.claude/skills/auto-fix-github-issues/README.md`

- [ ] **Step 1: 创建 README.md**

简单说明如何使用该技能，包括：
- 安装后的初始配置步骤
- 手动触发命令
- 定时任务设置方法
- 依赖要求 (gh CLI, git)

---

## 自检清单

完成所有 Task 后，执行以下自检：

1. **Spec Coverage**: 检查设计文档中的每个需求是否有对应的 Task 实现
2. **Placeholder Scan**: 确认没有 "TBD"、"TODO"、"实现后续" 等占位符
3. **类型一致性**: 确认所有文件路径、命令、JSON 结构在整个 Plan 中一致
4. **可执行性**: 每个 Step 都有具体的命令和期望输出

---

## 执行选项

**Plan complete and saved to `docs/superpowers/plans/2026-05-25-auto-fix-github-issues-design.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**