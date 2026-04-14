#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import socket
import sys
import urllib.error
import urllib.request
from typing import Any


MODEL_NAME = os.getenv("HOOK_SEMANTIC_MODEL", "qwen3.5:9b")
OLLAMA_URL = os.getenv("HOOK_OLLAMA_URL", "http://127.0.0.1:11434/api/generate")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("HOOK_SEMANTIC_TIMEOUT_SECONDS", "7.5"))
MAX_PROMPT_CHARS = int(os.getenv("HOOK_SEMANTIC_MAX_PROMPT_CHARS", "6000"))
MAX_CONTRACT_CHARS = 90

BASE_REPLY_CONTEXT_LINES = [
    "用户 instruction 按验收条件执行。",
    "对用户可见回复首句先给判断、答案或动作。",
    "只保留必要依据、验证结果和真实风险。",
    "不要输出寒暄、空转折、废话总结、收尾邀约，也不要输出自我修正草稿。",
    "默认直接执行，不先教步骤。",
    "改文件前先读上下文，做最小改动并验证。",
]
USERPROMPT_NOTICE = "Hook 执行：UserPromptSubmit 已注入语义与输出约束。"
USERPROMPT_FALLBACK_NOTICE = "Hook 执行：UserPromptSubmit 已注入基础输出约束。"

TASK_MODES = {
    "direct_action",
    "explanation",
    "review",
    "brainstorm",
    "planning",
    "analysis",
    "other",
}


def emit_continue() -> None:
    print(json.dumps({"continue": True}, ensure_ascii=False))


def emit_context(message: str, system_message: str) -> None:
    print(
        json.dumps(
            {
                "continue": True,
                "systemMessage": system_message,
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": message,
                },
            },
            ensure_ascii=False,
        )
    )


def load_payload() -> dict[str, Any]:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return {}
    return payload if isinstance(payload, dict) else {}


def truncate_text(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    return text[:limit] + "\n...[truncated]"


def build_model_prompt(user_prompt: str) -> str:
        return f"""你是 coding assistant 的语义判定器。只分析用户最新请求，不回答问题。
只输出 JSON，不要多余文字：
{{
    "task_mode": "direct_action|explanation|review|brainstorm|planning|analysis|other",
    "wants_steps": false,
    "keep_brief": true,
    "allow_extra_suggestions": false,
    "answer_contract": "不超过24字的中文回答契约"
}}
规则：
- 明确要修复、修改、实现、运行、执行，task_mode=direct_action。
- 明确要解释、比较、分析影响，task_mode=explanation 或 analysis。
- 明确要 review，task_mode=review。
- 明确要 brainstorm、发散想法，task_mode=brainstorm。
- 明确要计划、路线、清单、步骤，task_mode=planning，且 wants_steps=true。
- 除非用户明确要选项、下一步、继续展开，否则 allow_extra_suggestions=false。
- 除非用户明确要详细展开，否则 keep_brief=true。
- answer_contract 只描述回答方式，不能提判定器、JSON、模型。
用户请求：{truncate_text(user_prompt, MAX_PROMPT_CHARS)}
"""


def call_ollama(user_prompt: str) -> dict[str, Any] | None:
    request_payload = {
        "model": MODEL_NAME,
        "prompt": build_model_prompt(user_prompt),
        "stream": False,
        "format": "json",
        "think": False,
        "options": {
            "temperature": 0,
            "top_p": 0.2,
            "top_k": 20,
            "num_predict": 96,
            "num_ctx": 4096,
        },
        "keep_alive": "15m",
    }
    data = json.dumps(request_payload).encode("utf-8")
    request = urllib.request.Request(
        OLLAMA_URL,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            envelope = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, socket.timeout, json.JSONDecodeError, ValueError):
        return None

    raw_response = envelope.get("response") or envelope.get("thinking") or ""
    if not isinstance(raw_response, str) or not raw_response.strip():
        return None

    try:
        parsed = json.loads(raw_response)
    except json.JSONDecodeError:
        return None
    return parsed if isinstance(parsed, dict) else None


def normalize_bool(value: Any, default: bool = False) -> bool:
    if isinstance(value, bool):
        return value
    return default


def normalize_result(result: dict[str, Any]) -> dict[str, Any]:
    task_mode = result.get("task_mode")
    if task_mode not in TASK_MODES:
        task_mode = "other"

    answer_contract = result.get("answer_contract")
    if not isinstance(answer_contract, str):
        answer_contract = "先按用户当前目标直接回答，不额外扩题。"
    answer_contract = " ".join(answer_contract.split())[:MAX_CONTRACT_CHARS]

    normalized = {
        "task_mode": task_mode,
        "wants_steps": normalize_bool(result.get("wants_steps")),
        "keep_brief": normalize_bool(result.get("keep_brief"), default=True),
        "allow_extra_suggestions": normalize_bool(result.get("allow_extra_suggestions")),
        "answer_contract": answer_contract,
    }

    return normalized


def build_fallback_context() -> str:
    lines = list(BASE_REPLY_CONTEXT_LINES)
    lines.extend(
        [
            "本轮语义分类未返回有效结果，按用户当前目标直接回答。",
            "不要主动展开教程、路线图或大段步骤。",
            "不要主动追加下一步推销、额外选项或扩展话题。",
            "表达保持紧凑，避免复读用户问题。",
        ]
    )
    return "\n".join(lines)


def build_context(result: dict[str, Any]) -> str:
    lines: list[str] = list(BASE_REPLY_CONTEXT_LINES)
    lines.extend(
        [
        "当前用户请求的语义约束由本地小模型判定。",
        f"回答契约：{result['answer_contract']}",
        ]
    )

    task_mode = result["task_mode"]
    if task_mode == "review":
        lines.append("本轮按 review 心智输出：先列 findings、风险、回归点，再给简短总结。")
    elif task_mode == "brainstorm":
        lines.append("本轮是发散探索，允许列选项，但不要伪装成已定结论。")
    elif task_mode == "planning":
        lines.append("本轮用户接受步骤或计划，给最小必要计划，不要把简单事写成大纲。")
    elif task_mode == "direct_action":
        lines.append("本轮优先直接执行、直接修改或直接给判断，不先讲教程。")
    elif task_mode in {"explanation", "analysis"}:
        lines.append("本轮需要解释或权衡，先给判断，再展开依据和取舍。")

    if result["wants_steps"]:
        lines.append("用户明确接受步骤、方案或清单，可以给步骤。")
    else:
        lines.append("不要主动展开教程、路线图或大段步骤。")

    if result["allow_extra_suggestions"]:
        lines.append("可以给有限下一步或备选项，但保持主线收敛。")
    else:
        lines.append("不要主动追加下一步推销、额外选项或扩展话题。")

    if result["keep_brief"]:
        lines.append("表达保持紧凑，避免复读用户问题。")
    else:
        lines.append("在必要处展开，但只展开与当前问题直接相关的部分。")

    return "\n".join(lines)


def main() -> None:
    payload = load_payload()
    prompt = payload.get("prompt")
    if not isinstance(prompt, str) or not prompt.strip():
        emit_continue()
        return

    raw_result = call_ollama(prompt)
    if raw_result is None:
        emit_context(build_fallback_context(), USERPROMPT_FALLBACK_NOTICE)
        return

    emit_context(build_context(normalize_result(raw_result)), USERPROMPT_NOTICE)


if __name__ == "__main__":
    main()