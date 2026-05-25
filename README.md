# Auto Fix GitHub Issues

自动化技能，通过 GitHub CLI (`gh`) 自动拉取 GitHub Issues，分析问题并生成修复代码，创建 PR 后暂停等待人工合并。

## 依赖要求

- **gh CLI**: GitHub 命令行工具，用于操作 Issues 和 PR
- **git**: 版本控制工具，用于创建分支和提交代码
- **jq**: JSON 处理工具，用于解析和格式化 JSON 数据

安装和认证方法：

```bash
# 安装 gh CLI (Linux/macOS)
brew install gh

# 安装 jq (Linux/macOS)
brew install jq

# 认证 GitHub
gh auth login
```

## 安装步骤

1. 将技能配置添加到 `~/.claude/settings.json`：

```json
{
  "autoFixGitHub": {
    "enabled": true,
    "repositories": [
      {
        "name": "my-repo",
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

2. 配置说明：
   - `enabled`: 技能总开关，设为 `true` 启用
   - `repositories`: 仓库列表，支持配置多个仓库
   - `repositories[].name`: 仓库别名（用于状态文件命名）
   - `repositories[].owner`: GitHub 用户名或组织名
   - `repositories[].repo`: 仓库名称
   - `repositories[].enabled`: 是否启用该仓库
   - `notification.email`: 通知邮箱（可选）
   - `notification.站内通知`: 是否发送站内通知

3. 验证配置：

```bash
# 检查 gh CLI 是否可用
gh issue list --state open --limit 1
```

## 使用方法

### 手动触发

在 Claude Code 中输入：

```
/auto-fix-github-issues
```

或使用斜杠命令：

```
/auto-fix-issues
```

### 定时任务设置

设置每小时自动执行：

```
/loop 1h /auto-fix-issues
```

设置每日自动执行：

```
/loop 24h /auto-fix-issues
```

查看当前定时任务：

```
/cron list
```

删除定时任务（需要任务ID）：

```
/cron delete {job-id}
```

## 工作流程

1. 加载 `settings.json` 中的仓库配置
2. 遍历每个 `enabled=true` 的仓库
3. 获取该仓库上次处理后的新 issues
4. 按 `createdAt` 升序逐个处理
5. AI 分析 issue 并生成修复代码
6. 创建 PR 后暂停，等待人工合并
7. 无法处理时暂停流程并通知

## 状态文件

状态文件位置：`~/.claude/state/auto-fix-github-issues/{repo-name}-state.json`

状态文件格式：

```json
{
  "lastProcessedIssueNumber": 42,
  "lastProcessedAt": "2026-05-25T10:30:00Z",
  "paused": false,
  "pauseReason": null
}
```

- `lastProcessedIssueNumber`: 最后处理的 Issue 编号
- `lastProcessedAt`: 最后处理时间
- `paused`: 是否暂停处理
- `pauseReason`: 暂停原因

## 注意事项

1. **启用仓库**: 在 `settings.json` 中添加仓库后，确保设置 `enabled: true`
2. **GitHub 认证**: 首次使用需运行 `gh auth login` 进行认证
3. **状态文件**: 不要删除状态文件，否则可能导致重复处理已处理过的 Issues
4. **分支命名**: 自动创建的分支格式为 `auto-fix/issue-{number}-{short-title}`
5. **PR 创建**: PR 创建时会设置 `Closes #{issue-number}` 自动关闭 Issue
6. **暂停机制**: 当无法处理某个 Issue 时，流程会暂停并发送通知，等待人工介入