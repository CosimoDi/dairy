---
description: "用于研究、deep research、竞品分析、发展史、生态位判断、技术商业研究与研究报告；这是工作区 research 的统一入口，内部按任务类型路由到 deep-research、hv-analysis 与 browser-human-navigation"
argument-hint: "研究对象；可选关注问题、时间范围、输出形式、是否需要 PDF、是否需要落盘"
agent: "agent"
---
# Research

这是工作区 research 的统一入口。先判断研究任务类型，再只加载一条主工作流。

1. 先定义问题：写清研究对象、核心问题、时间范围、输出形式和验收条件。用户没给全时，按最小默认值推进：研究对象从起源到当前，输出语言跟随用户语言。
2. 先做路由：用户显式要求“横纵分析”“竞品分析”“研究报告”或“PDF 报告”，优先加载 [hv-analysis](../skills/hv-analysis/SKILL.md)。其他产品、公司、技术概念、协议或赛道的系统研究，加载 [deep-research](../skills/deep-research/SKILL.md)。证据依赖实时网页、搜索结果排序、登录态、JS 渲染内容或当前浏览器可见状态时，先加载用户级 skill browser-human-navigation 取证，再回到研究主线。
3. 控制输出：先证据，后判断，明确区分事实、推断和未确认项。不并行展开多套研究框架，只保留最能回答当前问题的一条主线。用户如果只要简短解释，不要强行扩成研究报告。
4. 处理交付：用户要求沉淀到仓库时，默认落到 [AI技术体系手册](../../02_产品研发与技术线/AI技术体系手册/README.md) 的相关章节。需要 PDF 成品时，先完成 Markdown，再按 [hv-analysis](../skills/hv-analysis/SKILL.md) 的 PDF 路由处理。
5. 汇报标准：先给总判断，再给关键证据和主要分歧。交代信息边界、未验证项和真实风险。
