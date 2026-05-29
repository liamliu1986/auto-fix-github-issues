---
name: auto-fix-github-issues
description: Use when you need to automatically fetch GitHub issues, analyze problems, generate fix code with TDD, and create PRs for multiple repositories. Also use when setting up scheduled issue processing or handling issue automation.
---

# Auto Fix GitHub Issues

## Overview

自动化技能，通过 GitHub CLI (`gh`) 自动拉取 GitHub Issues，严格遵循全局 CLAUDE.md 规范（TDD、Worktree 隔离、代码审查）分析问题并生成修复代码，创建 PR 后暂停等待人工合并。

**核心原则：**
- **TDD 强制**：先写测试，再写修复代码
- **Worktree 隔离**：每个 issue 在独立 worktree 中处理
- **代码审查**：每批次修复后触发代码审查
- **验证门控**：无验证证据不得声称完成

## When to Use

- 手动触发: `/auto-fix-issues`
- 定时触发: `/loop 1h /auto-fix-issues`
- 需要自动处理多个仓库的 GitHub Issues

## Prerequisites

- **gh CLI** 已安装并认证 (`gh auth login`)
- **jq** 已安装 (`jq --version`)
- **全局 CLAUDE.md** 已配置（强制 TDD + Worktree 流程）

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

# 创建 worktree（符合全局规范）
git worktree add .worktrees/bugfix-issue-{number} -b bugfix/issue-{number}-{short-title}

# 创建 PR（包含设计文档和测试计划链接）
gh pr create --title "fix: {issue title}" --body "$(cat <<'EOF'
## Summary
- Fixes issue #{number}
- Root cause: {description}

## Test Plan
- [ ] Run test command - all tests should pass
- [ ] Verify issue reproduction test fails before fix
- [ ] Verify issue reproduction test passes after fix

## Design Doc
- docs/superpowers/specs/YYYY-MM-DD-bugfix-issue-{number}-design.md

## Plan Doc
- docs/superpowers/plans/YYYY-MM-DD-bugfix-issue-{number}-plan.md

Closes #{number}
EOF
)"
```

## Workflow（符合全局 CLAUDE.md 规范）

### Phase 0: 配置加载与仓库遍历

1. 加载 `settings.json` 中的仓库配置
2. 遍历每个 `enabled=true` 的仓库
3. 获取该仓库上次处理后的新 issues（按 `createdAt` 升序）

### Phase 1: Issue 分析与设计（Brainstorming）

**对每个 issue：**
1. **阅读 issue 内容**（标题、描述、复现步骤）
2. **探索代码库**（定位相关文件）
3. **分析根因**（遵循 systematic-debugging 流程）
4. **编写简要设计文档**：
   ```
   docs/superpowers/specs/YYYY-MM-DD-bugfix-issue-{number}-design.md
   ```
   包含：
   - Issue 描述和根因分析
   - 影响范围
   - 修复方案（2-3 句话）
   - 测试策略

### Phase 2: 编写修复计划（Writing Plans）

**创建实施计划**：
```
docs/superpowers/plans/YYYY-MM-DD-bugfix-issue-{number}-plan.md
```

**计划必须包含：**
1. **Step 1: Write the failing test**（RED）
   - 编写重现 issue 的测试用例
   - 运行测试确认失败（Verify RED）
2. **Step 2: Implement the minimal fix**（GREEN）
   - 编写最小代码修复
   - 运行测试确认通过（Verify GREEN）
3. **Step 3: Refactor**（REFACTOR）
   - 清理代码
   - 确认测试仍通过
4. **Step 4: Run full test suite**
   - 确认无回归
5. **Step 5: Commit and create PR**

### Phase 3: 创建 Worktree（Setup Worktree）

```bash
# 从 main 创建 bugfix 分支
git checkout main
git pull origin main
git checkout -b bugfix/issue-{number}-{short-title}

# 创建 worktree（符合全局规范）
git worktree add .worktrees/bugfix-issue-{number} bugfix/issue-{number}-{short-title}
cd .worktrees/bugfix-issue-{number}

# 安装依赖
npm install  # 或 cargo build / pip install / go mod download

# 验证基线测试通过
npm test  # 或 cargo test / pytest / go test ./...
```

### Phase 4: TDD 实施修复（Implementation）

**严格遵循 TDD 循环：**

#### RED - 编写失败测试
```bash
# 编写重现 issue 的测试
git add tests/issue-{number}.test.js
git commit -m "test: add failing test for issue #{number}"

# 运行测试确认失败（Verify RED - 强制）
npm test -- tests/issue-{number}.test.js
# 必须亲眼看到失败信息
```

#### GREEN - 最小修复
```bash
# 编写最小修复代码
git add src/xxx.js
git commit -m "fix: resolve issue #{number} - {brief description}"

# 运行测试确认通过（Verify GREEN - 强制）
npm test -- tests/issue-{number}.test.js
# 必须亲眼看到通过
```

#### REFACTOR - 清理
```bash
# 重构代码（如有需要）
git add src/xxx.js
git commit -m "refactor: simplify fix for issue #{number}"

# 确认所有测试仍通过
npm test
```

**禁止：**
- 先写修复代码再补测试
- 跳过 Verify RED 或 Verify GREEN
- 一次修改多个行为

### Phase 5: 验证（Verification）

**验证门控（强制）：**
```bash
# 1. 运行全量测试
npm test
# Expected: All tests pass, 0 failures

# 2. 运行 linter
npm run lint
# Expected: 0 errors, 0 warnings

# 3. 运行类型检查（如适用）
npm run typecheck
# Expected: 0 errors

# 4. 回归测试（Red-Green 验证）
# 撤销修复 → 测试应失败 → 恢复修复 → 测试应通过
git stash
npm test -- tests/issue-{number}.test.js
# Expected: FAIL
git stash pop
npm test -- tests/issue-{number}.test.js
# Expected: PASS
```

**无验证证据不得声称完成。**

### Phase 6: 代码审查（Code Review）

**请求审查流程：**
1. 获取 git SHA（BASE_SHA 和 HEAD_SHA）
2. 派发 code-reviewer 子代理
3. 根据反馈行动：
   - Critical 问题：立即修复
   - Important 问题：继续前修复
   - Minor 问题：记录待后续处理

**审查检查清单：**
- [ ] 测试覆盖了 issue 描述的场景
- [ ] 修复是最小化的（无多余修改）
- [ ] 无 TBD/TODO/FIXME 遗留
- [ ] 提交信息符合规范（`fix:` 或 `test:` 前缀）
- [ ] 无相邻代码的"顺便改进"

### Phase 7: 完成分支（Finish Branch）

```bash
# 推送 bugfix 分支
git push -u origin bugfix/issue-{number}-{short-title}

# 创建 Pull Request（使用模板）
gh pr create --title "fix: {issue title}" --body "$(cat <<'EOF'
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
EOF
)"

# 清理 worktree
git checkout main
git worktree remove .worktrees/bugfix-issue-{number}

# 可选：删除本地分支（PR 合并后）
git branch -d bugfix/issue-{number}-{short-title}
```

**暂停等待人工合并。**

## Configuration

### settings.json 完整示例

在 `settings.json` 顶部添加：
```json
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

## Red Flags（立即停止）

- 直接修改代码而不写测试（TDD 违规）
- 跳过 Verify RED 或 Verify GREEN
- 未创建 worktree 直接修改 main 分支
- 先写修复再补测试
- 使用 "should work now" 等未验证用语
- 一次处理多个 issues（必须逐个处理）
- 未运行全量测试就声称完成
- 跳过代码审查直接创建 PR

## Common Mistakes

- 忘记在 `settings.json` 中启用仓库 (`enabled: true`)
- GitHub CLI 未认证 (运行 `gh auth login`)
- 状态文件被误删导致重复处理
- 跳过 TDD 流程直接修复
- 未创建 worktree 直接修改代码
- 测试未亲眼看到失败就继续
- 未运行回归测试

## Integration with Global CLAUDE.md

本 skill **严格遵循**全局 CLAUDE.md 的所有要求：
- ✅ 使用 worktree 隔离（Phase 3）
- ✅ 强制 TDD（Phase 4）
- ✅ 验证门控（Phase 5）
- ✅ 代码审查（Phase 6）
- ✅ 设计文档（Phase 1）
- ✅ 实施计划（Phase 2）
- ✅ 完成分支清理（Phase 7）
- ✅ 遵循 Karpathy Guidelines（极简、精准修改）
- ✅ 遵循 Systematic Debugging（根因分析）
