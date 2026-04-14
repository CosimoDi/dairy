---
name: khazix-writer
description: "Use when the task is 公众号长文写作、基于素材出稿、续写文章、扩写成文、按作者风格改写，或需要对长文做风格自检。适用于长篇内容创作，不适用于短帖和深度研究报告。"
argument-hint: "素材或主题；可选目标读者、核心观点、篇幅、是否要做风格自检"
---

写作单元：section
章节路径：02
核心问题：这个 wrapper 在什么场景下触发，以及要读取哪份本地上游 skill 和参考资料
覆盖变量：触发词、来源路径、路由边界、自检要求
输入材料：khazix-skills upstream khazix-writer/SKILL.md；references/style_examples.md；references/content_methodology.md
不处理项：短帖、研究报告、名词解释

# Khazix Writer

先加载本地上游 skill 和参考资料，再按它的写作边界与自检体系执行。

## Load Order

1. 先读 `02_产品研发与技术线/external_projects/khazix-skills/upstream/khazix-writer/SKILL.md`
2. 需要具体风格样本时，再读 `02_产品研发与技术线/external_projects/khazix-skills/upstream/khazix-writer/references/style_examples.md`
3. 需要看选题、方法论和案例框架时，再读 `02_产品研发与技术线/external_projects/khazix-skills/upstream/khazix-writer/references/content_methodology.md`

## Routing Rules

- 只用于长文写作和长文改稿；短内容不触发
- 用户只要研究报告、竞品分析、发展史分析，不用这个 skill，改用 `hv-analysis`
- 用户明确说“按这个风格写”“公众号文章”“把素材写成文章”“续写/扩写成长文”时，优先用这个 skill

## Execution Contract

- 先吃透素材，再判断选题和结构
- 把 AI 当成扩写、补证据和自检工具，不替代第一手观察和核心观点
- 交付前按上游 skill 里的四层自检体系做一次检查
