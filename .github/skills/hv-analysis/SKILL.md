---
name: hv-analysis
description: "Use when the task needs 横纵分析法、系统性深度研究、发展史分析、竞品分析、生态位判断，或用户明确要一份 PDF 研究报告。适用于产品、公司、技术概念和协议研究。"
argument-hint: "研究对象；可选关注问题、时间范围、是否需要 PDF"
---

写作单元：section
章节路径：01
核心问题：这个 wrapper 在什么场景下触发，以及要读取哪份本地上游 skill
覆盖变量：触发词、来源路径、路由边界、交付约束
输入材料：khazix-skills upstream README；hv-analysis/SKILL.md；scripts/md_to_pdf.py
不处理项：简单名词解释、短内容写作

# Hv Analysis

先加载本地上游 skill，再按它的完整方法论执行。

## Load Order

1. 先读 `02_产品研发与技术线/external_projects/khazix-skills/upstream/hv-analysis/SKILL.md`
2. 需要确认仓库总览或安装背景时，再读 `02_产品研发与技术线/external_projects/khazix-skills/upstream/README.md`
3. 用户要求 PDF 成品，或报告已经写完准备交付时，再读 `02_产品研发与技术线/external_projects/khazix-skills/upstream/hv-analysis/scripts/md_to_pdf.py`

## Routing Rules

- 只在需要系统性研究时触发；简单名词解释不触发
- 公众号长文、素材改写、按作者风格出稿，不用这个 skill，改用 `khazix-writer`
- 用户显式要求“横纵分析”“深度研究”“竞品分析”“研究报告”“PDF 报告”时，优先用这个 skill

## Execution Contract

- 先证据，后判断
- 证据若依赖实时网页、搜索结果排序、登录后页面、JS 渲染内容或当前浏览器可见状态，先加载 `browser-human-navigation` 取证，再回到本 skill 和上游 skill 继续分析
- 先完成 Markdown 报告，再决定是否调用 PDF 转换脚本
- 环境缺少 PDF 依赖时，至少交付完整 Markdown 稿，并说明缺失项
