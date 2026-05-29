# Auto Fix GitHub Issues

自动化技能，通过 GitHub CLI (`gh`) 自动拉取 GitHub Issues，**严格遵循全局 CLAUDE.md 规范**（TDD、Worktree 隔离、代码审查）分析问题并生成修复代码，创建 PR 后暂停等待人工合并。

## 依赖要求

- **gh CLI**: GitHub 命令行工具，用于操作 Issues 和 PR
- **jq**: JSON 处理工具，用于解析和格式化 JSON 数据
- **git**: 版本控制工具，用于 worktree 和分支管理

### 检查依赖

```bash
# 检查 gh CLI
gh --version

# 检查 jq
jq --version

# 检查 git
git --version
```

### 安装 gh CLI

**Windows (使用 winget):**
```powershell
winget install --id GitHub.cli
```

**Windows (使用 scoop):**
```powershell
scoop install gh
```

**macOS (使用 Homebrew):**
```bash
brew install gh
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt install gh

# Fedora
sudo dnf install gh

# Arch
sudo pacman -S github-cli
```

### 认证 GitHub

```bash
gh auth login
```

按照提示选择：
- **Account**: GitHub.com
- **Protocol**: HTTPS
- **Authenticate**: Login with a web browser

### 安装 jq

**Windows (使用 winget):**
```powershell
winget install jqlang.jq
```

**macOS:**
```bash
brew install jq
```

**Linux:**
```bash
sudo apt install jq  # Ubuntu/Debian
```

## 安装步骤

1. 确保 skill 文件已放置在 `~/.claude/skills/auto-fix-github-issues/SKILL.md`

2. 将技能配置添加到 `~/.claude/settings.json`：

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

3. 配置说明：
   - `enabled`: 技能总开关，设为 `true` 启用
   - `repositories`: 仓库列表，支持配置多个仓库
   - `repositories[].name`: 仓库别名（用于状态文件命名）
   - `repositories[].owner`: GitHub 用户名或组织名
   - `repositories[].repo`: 仓库名称
   - `repositories[].enabled`: 是否启用该仓库
   - `notification.email`: 通知邮箱（可选）
   - `notification.站内通知`: 是否发送站内通知

4. 验证配置：

```bash
# 检查 gh CLI 是否可用
gh issue list --state open --limit 1

# 检查 jq 是否可用
echo '{"test": true}' | jq .
```

## 使用方法

### 手动触发

在 Claude Code 中输入：

```
/auto-fix-issues
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

## 工作流程（符合全局 CLAUDE.md 规范）

```
Phase 0: 加载配置，遍历仓库
    ↓
Phase 1: Issue 分析与设计（Brainstorming）
    - 阅读 issue，定位代码，分析根因
    - 编写设计文档：docs/superpowers/specs/YYYY-MM-DD-bugfix-issue-{number}-design.md
    ↓
Phase 2: 编写修复计划（Writing Plans）
    - 创建实施计划：docs/superpowers/plans/YYYY-MM-DD-bugfix-issue-{number}-plan.md
    - 包含 TDD 步骤（RED → GREEN → REFACTOR）
    ↓
Phase 3: 创建 Worktree（Setup Worktree）
    - 从 main 创建 bugfix 分支
    - 创建 worktree：.worktrees/bugfix-issue-{number}
    - 验证基线测试通过
    ↓
Phase 4: TDD 实施修复（Implementation）
    - RED：编写重现 issue 的测试 → 提交
    - Verify RED：运行测试确认失败（强制）
    - GREEN：编写最小修复 → 提交
    - Verify GREEN：运行测试确认通过（强制）
    - REFACTOR：清理代码 → 提交
    ↓
Phase 5: 验证（Verification）
    - 运行全量测试
    - 运行 linter
    - 回归测试（撤销修复应失败，恢复修复应通过）
    ↓
Phase 6: 代码审查（Code Review）
    - 派发 code-reviewer 子代理
    - 修复 Critical/Important 问题
    ↓
Phase 7: 完成分支（Finish Branch）
    - 推送分支
    - 创建 PR（包含设计文档和测试计划链接）
    - 清理 worktree
    - 暂停等待人工合并
```

## 分支命名规范

符合全局 CLAUDE.md Git Flow 规范：

```
bugfix/issue-{number}-{short-description}
```

示例：
```
bugfix/issue-42-gpu-list-duplication
bugfix/issue-123-memory-leak-in-parser
```

## Worktree 路径

```
.worktrees/bugfix-issue-{number}/
```

## 提交信息规范

```
test: add failing test for issue #42
fix: resolve GPU list duplication in issue #42
refactor: simplify GPU deduplication logic
```

## PR 模板

创建的 PR 自动包含：

```markdown
## Summary
- Fixes issue #{number}
- Root cause: {description}

## Test Plan
- [ ] Run `npm test` - all tests should pass
- [ ] Verify issue reproduction test fails before fix
- [ ] Verify issue reproduction test passes after fix

## Design Doc
- docs/superpowers/specs/YYYY-MM-DD-bugfix-issue-{number}-design.md

## Plan Doc
- docs/superpowers/plans/YYYY-MM-DD-bugfix-issue-{number}-plan.md

Closes #{number}
```

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
4. **分支命名**: 使用 `bugfix/issue-{number}-{short-description}` 格式
5. **PR 描述**: 包含 issue 链接、修复说明、测试建议、设计文档链接
6. **暂停机制**: 当无法处理某个 Issue 时，流程会暂停并发送通知，等待人工介入
7. **TDD 强制**: 每个修复必须先写测试，不允许先写修复代码
8. **Worktree 隔离**: 每个 issue 必须在独立 worktree 中处理
9. **代码审查**: 每批次修复后必须触发代码审查
10. **验证门控**: 无验证证据不得声称完成

## 与全局 CLAUDE.md 的合规性

本 skill 严格遵循全局 CLAUDE.md 的所有要求：

| 全局规范要求 | 本 skill 实现 |
|------------|-------------|
| Worktree 隔离 | ✅ 每个 issue 独立 worktree |
| TDD 强制 | ✅ RED → Verify RED → GREEN → Verify GREEN → REFACTOR |
| 设计文档 | ✅ 每个 issue 编写设计文档 |
| 实施计划 | ✅ 每个 issue 编写实施计划 |
| 代码审查 | ✅ 每批次后触发 code-reviewer |
| 验证门控 | ✅ 全量测试 + linter + 回归测试 |
| Karpathy Guidelines | ✅ 极简、精准修改 |
| Systematic Debugging | ✅ 根因分析 |
| Git Flow 规范 | ✅ bugfix/issue-{number}-{description} 命名 |
| 提交规范 | ✅ fix:/test:/refactor: 前缀 |

## 故障排除

### gh CLI 未安装

```bash
# Windows
winget install --id GitHub.cli

# macOS
brew install gh
```

### gh CLI 未认证

```bash
gh auth login
```

### 状态文件被误删

```bash
# 重新创建状态文件
mkdir -p ~/.claude/state/auto-fix-github-issues
echo '{"lastProcessedIssueNumber": 0, "lastProcessedAt": null, "paused": false}' > ~/.claude/state/auto-fix-github-issues/{repo-name}-state.json
```

### Worktree 目录冲突

```bash
# 检查现有 worktree
git worktree list

# 删除已完成的 worktree
git worktree remove .worktrees/bugfix-issue-{number}
```

### 测试失败

```bash
# 进入 worktree 目录
cd .worktrees/bugfix-issue-{number}

# 运行测试
npm test

# 查看详细错误
npm test -- --verbose
```
