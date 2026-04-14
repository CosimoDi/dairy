---
description: "Use when handling git status, checkpoint, commit, push, branch, worktree, PR review, issue start-work, or GitLens/GitKraken workflows."
---

# Git 管理执行规则

用户请求涉及 git、分支、commit、push、PR、review、issue 关联开发或 GitLens 工作流时，按下面规则执行。

## 路由原则

- 能用 GitKraken / GitLens / GitHub 一等工具时，优先用它们，不先退回 git CLI。
- 本地仓库状态、分支、worktree、stash、push 优先 GitKraken；提交组织、PR 排队、issue 开工、review 优先 GitLens；GitHub 上的 PR / issue 详情、checks、评论、通知优先 GitHub 工具。
- 已暴露的 GitKraken / GitLens / GitHub 显式工具直接使用；只有 history、PR 详情、评论、assigned work、GitHub issue / notification 这类依赖工具组暴露的能力，才先激活对应工具组。
- 只有缺少等价能力、需要组合命令，或当前一等工具没有暴露该动作时，才使用非交互 git 命令。
- 不使用交互式 git 流程。

## 需要显式激活的工具组

- commit 历史、blame、revision diff：先 `activate_git_history_inspection_tools`
- GitHub PR 详情、当前 checkout 的 PR、status checks：先 `activate_github_pull_request_management`
- PR / issue 评论：先 `activate_git_issue_and_pr_comment_tools`
- 自己待处理的 issue / PR：先 `activate_git_assigned_tasks_tools`
- GitHub issue、notification、labels：先 `activate_github_issue_and_notification_tools`

## 默认映射

- 查看工作树状态：`mcp_gitkraken_git_status`；需要文件级 diff 时再补 `get_changed_files`
- 创建或列出分支：`mcp_gitkraken_git_branch`
- 切换分支：`mcp_gitkraken_git_checkout`
- worktree 管理：`mcp_gitkraken_git_worktree`
- stash：`mcp_gitkraken_git_stash`
- push：`mcp_gitkraken_git_push`
- 组织提交、拆分 commit、生成 message：`mcp_gitkraken_gitlens_commit_composer`
- 真正执行 add / commit：`mcp_gitkraken_git_add_or_commit`
- 查看待处理 PR、判断先处理哪个：`mcp_gitkraken_gitlens_launchpad`
- 从 issue 开工并创建关联分支：`mcp_gitkraken_gitlens_start_work`
- 针对 PR 建立 review worktree：`mcp_gitkraken_gitlens_start_review`
- 查看 commit 历史、blame、revision diff：`activate_git_history_inspection_tools`，再用激活后的 history 工具；只有缺口仍在时才退回 CLI
- GitHub 仓库创建 PR：`activate_github_pull_request_management` -> `github-pull-request_create_pull_request`
- 非 GitHub provider 或需要显式指定 provider 的 PR 创建：`mcp_gitkraken_pull_request_create`
- 查看当前 checkout 的 PR、打开中的 PR、status checks、review requirement：`activate_github_pull_request_management`
- 读取或回复 PR / issue 评论：`activate_git_issue_and_pr_comment_tools`
- 查自己待处理 issue / PR：`activate_git_assigned_tasks_tools`
- 看 GitHub issue、notification 或 labels：`activate_github_issue_and_notification_tools`

## 执行规则

- 开始高风险或多文件改动前，先看工作树状态。若需要 checkpoint，优先在本次任务的改动范围内创建本地 commit；不要为混有用户未确认改动的工作树自动 stash 或提交无关文件。
- 用户要求“更新 git”“上传 git”“同步仓库”“提交远程”时，默认顺序是：`mcp_gitkraken_git_status` -> 如果本次改动涉及当前仓库的 `00_个人规划与复盘/`，先对照 `/Users/cosimo/Documents/WORKSPACE/00_个人规划与复盘/`，把与本次主题直接相关的工作复盘增量整合进当前仓库，并默认以摘要方式沉淀到现有文档 -> 检查本次改动涉及目录及其上层导航 README 是否仍与当前文件结构、入口命令和关键脚本一致 -> 如有漂移先更新 README 与 `CHANGELOG.md` -> `mcp_gitkraken_gitlens_commit_composer`（如需要）-> `mcp_gitkraken_git_add_or_commit` -> `mcp_gitkraken_git_push`。
- 如果本次 git 前置动作包含从 `/Users/cosimo/Documents/WORKSPACE/` 同步 `.github/` 配置，先保留当前 `Diary` 仓库关于仓库定位、关系分析用途和 git 更新整合规则的本地约束；默认只同步通用规则文件，`Diary` 专属文件手工增量合并，不要直接用上游 `.github/` 覆盖当前仓库。
- 如果 git push 成功，基于本次改动和执行过程中暴露出的规则空缺，向用户补问 1 到 2 个高信息量问题，用来完善当前仓库总配置。
- 用户明确要求按某种 commit 结构组织改动时，先把要求传给 `mcp_gitkraken_gitlens_commit_composer`，再执行 add / commit。
- 用户要求“review”“看一下 PR”“我该先处理哪个 PR”时，优先走 GitLens 的 `mcp_gitkraken_gitlens_start_review` 或 `mcp_gitkraken_gitlens_launchpad`；如果需求落在 PR 描述、checks、评论线程，再补 GitHub PR / comment 工具。
- 用户要求“谁改了这段”“这个提交什么时候进来的”“比较两个 revision”时，优先激活 history 工具组，不直接退回 CLI。
