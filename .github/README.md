# 外挂能力入口

这份 README 用来定位工作区里的 skill、hooks、prompts、harness 和外部参考外挂。先从这里进，再进具体目录。

## Copilot 定制层

- [copilot-instructions.md](copilot-instructions.md)
  - 工作区级总规则。这里定义全局行为、git 规则、外部项目落位和执行协议。
- [instructions/](instructions/)
  - 文件级或主题级规则。当前主要包括语言风格、Markdown 写法、git 管理、问题求解和长篇自省写作约束。
- [instructions/problem-solving.instructions.md](instructions/problem-solving.instructions.md)
  - 问题求解闭环规则。和
    [prompts/problem-solving.prompt.md](prompts/problem-solving.prompt.md)
    配套，约束执行型任务的证据、修改和验证闭环。
- [instructions/git-management.instructions.md](instructions/git-management.instructions.md)
  - git 管理细则。这里定义“更新 git / 上传 git / 同步仓库”时的默认检查顺序。
- [instructions/language-style.instructions.md](instructions/language-style.instructions.md)
  - 中文输出风格约束。控制禁用句式、首句结构和收口方式。
- [instructions/markdown-doc-writing.instructions.md](instructions/markdown-doc-writing.instructions.md)
  - Markdown 写作约束。控制文档结构、兼容性和落盘风格。
- [instructions/chaptered-self-analysis.instructions.md](instructions/chaptered-self-analysis.instructions.md)
  - `00_个人规划与复盘/` 下详尽自省类长文的结构约束。
- [hooks/instruction-gate.json](hooks/instruction-gate.json)
  - Hook 注册入口。当前把 SessionStart、UserPromptSubmit 和
    PreToolUse 拆成“可见提示 hook + 约束 gate hook”两层并行执行。
- [hooks/instruction_gate.sh](hooks/instruction_gate.sh)
  - Hook 主控制脚本。负责注入额外上下文、拦截不合规写入和执行前校验。
- [hooks/hook_visualizer.sh](hooks/hook_visualizer.sh)
  - Hook 可视化脚本。负责把 SessionStart、UserPromptSubmit 和关键 PreToolUse 事件转换成交互里可见的成功提示。
- [hooks/semantic_userprompt_context.py](hooks/semantic_userprompt_context.py)
  - UserPromptSubmit 的语义补充脚本。用于把本地小模型的判定结果注回主会话。
- [../runtime/bootstrap_git_tools.sh](../runtime/bootstrap_git_tools.sh)
  - 本地 git 工具 bootstrap。统一写入工作区扩展推荐、校准 `core.hooksPath`，并确保 `.githooks/` 具备执行权限。
- [prompts/research.prompt.md](prompts/research.prompt.md)
  - 当前 research 单入口。先判断研究类型，再路由到 deep-research、hv-analysis 和 browser-human-navigation。
- [prompts/problem-solving.prompt.md](prompts/problem-solving.prompt.md)
  - 当前可直接调用的问题求解 prompt。
- [skills/](skills/)
  - 按主题封装的可调用工作流。每个 skill 自己维护 `SKILL.md` 和 `assets/`；这里不复制 skill 细节，避免和目录内的真实内容漂移。
- [skills/deep-research/](skills/deep-research/)
  - 工作区 research skill，处理通用深度研究。
- [skills/hv-analysis/](skills/hv-analysis/)
  - 横纵分析与报告导向 research skill。
- [skills/khazix-writer/](skills/khazix-writer/)
  - 公众号长文和研究写作 skill wrapper。

## Harness 与运行入口

- [../02_产品研发与技术线/v2_evals驱动/README.md](../02_产品研发与技术线/v2_evals驱动/README.md)
  - 当前主 harness。这里放可执行的对话系统、评测入口、测试集和回归链路。
- [../02_产品研发与技术线/github_models_longrun/README.md](../02_产品研发与技术线/github_models_longrun/README.md)
  - 官方 GitHub Models 长时调用脚本。适合长任务、自动续跑和会话恢复。
- [../02_产品研发与技术线/AI技术体系手册/README.md](../02_产品研发与技术线/AI技术体系手册/README.md)
  - 理论入口。第 04 部分专门讲 Harness 与 Eval 的边界和作用。

## 外部参考外挂

- [../02_产品研发与技术线/external_projects/README.md](../02_产品研发与技术线/external_projects/README.md)
  - 第三方参考项目总入口。这里集中放上游源码包装层、本地 runtime、脚本和学习文档。

## 新东西放哪

- 对所有对话都生效的总规则，放 [copilot-instructions.md](copilot-instructions.md)。
- 只在特定文件或主题触发的规则，放 [instructions/](instructions/)。
- 需要强制拦截、注入或写入前校验的逻辑，放 [hooks/](hooks/)。
- 一次性 prompt 或轻量 slash 入口，放 [prompts/](prompts/)。
- 可复用的多步工作流，放 [skills/](skills/)。
- 可执行的评测、回归、运行态实验，默认放在
  [../02_产品研发与技术线/v2_evals驱动/README.md](../02_产品研发与技术线/v2_evals驱动/README.md)
  或
  [../02_产品研发与技术线/github_models_longrun/README.md](../02_产品研发与技术线/github_models_longrun/README.md)。
- 外部开源项目、对标项目和隔离部署包装层，放 [../02_产品研发与技术线/external_projects/README.md](../02_产品研发与技术线/external_projects/README.md)。

## 当前整理原则

- `.github/` 负责 Copilot 定制层，不承载外部项目源码和运行态目录。
- harness 是可执行系统，skill 是调用工作流，这两层不要混写到同一个目录。
- 外部参考项目统一放在 `02_产品研发与技术线/external_projects/`，不要混进 `.github/`。
- 新增、删除或重构这几类外挂后，同时更新这份 README 和根目录 `CHANGELOG.md`。

