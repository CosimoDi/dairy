#!/usr/bin/env bash
set -euo pipefail

event="${1:-}"

emit_continue() {
    cat <<'EOF'
{"continue":true}
EOF
}

emit_session_context() {
  local message="$1"
    local notice="${2:-}"
        /usr/bin/python3 -c 'import json, sys
notice = sys.argv[1]
message = sys.stdin.read()
payload = {
        "continue": True,
        "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": message,
        },
}
if notice:
        payload["systemMessage"] = notice
print(json.dumps(payload, ensure_ascii=False))' "$notice" <<<"$message"
}

emit_pretool_context() {
  local message="$1"
  /usr/bin/python3 -c 'import json, sys
message = sys.stdin.read()
print(json.dumps({
    "continue": True,
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "additionalContext": message,
    },
}, ensure_ascii=False))' <<<"$message"
}

emit_pretool_deny() {
  local reason="$1"
  /usr/bin/python3 -c 'import json, sys
reason = sys.stdin.read()
print(json.dumps({
    "continue": True,
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
        "additionalContext": reason,
    },
}, ensure_ascii=False))' <<<"$reason"
}

if [[ "$event" == "SessionStart" ]]; then
    emit_session_context "用户 instruction 按验收条件执行。对用户可见回复首句先给判断、答案或动作，只保留必要依据、验证结果和真实风险；不要输出寒暄、空转折、废话总结、收尾邀约，也不要输出自我修正草稿。默认直接执行，不先教步骤。改文件前先读上下文，做最小改动并验证。" "Hook 执行：SessionStart 已注入基础输出约束。"
  exit 0
fi

if [[ "$event" == "UserPromptSubmit" ]]; then
    hook_input="$(cat)"
    if userprompt_result="$(/usr/bin/python3 .github/hooks/semantic_userprompt_context.py <<<"$hook_input" 2>/dev/null)"; then
        if [[ -n "$userprompt_result" ]]; then
            printf '%s\n' "$userprompt_result"
        else
            emit_continue
        fi
    else
        emit_continue
    fi
  exit 0
fi

if [[ "$event" == "Stop" ]]; then
  cat >/dev/null
  emit_continue
  exit 0
fi

if [[ "$event" == "PreToolUse" ]]; then
  hook_input="$(cat)"
  pretool_python="$(cat <<'PY'
import json
import re
import sys

BANNED_PATTERNS = [
  ("不是…而是…", re.compile(r"不是[^。！？；：\n]{0,40}而是")),
  ("值得注意的是", re.compile(r"值得注意的是")),
  ("需要指出的是", re.compile(r"需要指出的是")),
  ("需要强调的是", re.compile(r"需要强调的是")),
  ("总的来说", re.compile(r"总的来说")),
  ("总而言之", re.compile(r"总而言之")),
  ("综上所述", re.compile(r"综上所述")),
  ("好的（句首）", re.compile(r"(^|[。！？；：\n]\s*)好的([！!，,。；;：:]|$)")),
  ("当然（句首）", re.compile(r"(^|[。！？；：\n]\s*)当然([！!，,。；;：:]|$)")),
  ("当然可以", re.compile(r"当然可以")),
  ("问得好", re.compile(r"问得好")),
  ("这是一个很好的问题", re.compile(r"(^|[。！？；：\n]\s*)这是一个很好的问题([！!，,。；;：:]|$)")),
  ("希望这对你有所帮助", re.compile(r"(^|[。！？；：\n]\s*)希望这对你有所帮助([！!，,。；;：:]|$)")),
  ("希望能帮到你", re.compile(r"(^|[。！？；：\n]\s*)希望能帮到你([！!，,。；;：:]|$)")),
  ("让我们来看看", re.compile(r"让我们来看看")),
  ("让我们深入探讨", re.compile(r"让我们深入探讨")),
  ("Great question", re.compile(r"(^|[.!?\n]\s*)great question\b", re.IGNORECASE)),
  ("I’d be happy to help", re.compile(r"(^|[.!?\n]\s*)i(?:\u2019|\x27)d be happy to help\b", re.IGNORECASE)),
  ("Let’s dive in", re.compile(r"(^|[.!?\n]\s*)let(?:\u2019|\x27)?s dive in\b", re.IGNORECASE)),
  ("Let’s delve into", re.compile(r"(^|[.!?\n]\s*)let(?:\u2019|\x27)?s delve into\b", re.IGNORECASE)),
  ("In conclusion", re.compile(r"(^|[.!?\n]\s*)in conclusion\b", re.IGNORECASE)),
  ("To summarize", re.compile(r"(^|[.!?\n]\s*)to summarize\b", re.IGNORECASE)),
  ("It’s important to note", re.compile(r"(^|[.!?\n]\s*)(?:it(?:\u2019|\x27)?s|it is) (?:important|worth) noting\b", re.IGNORECASE)),
]

SELF_ANALYSIS_PATTERNS = [
  re.compile(r"(人物|性格|人格|画像)"),
  re.compile(r"(自省|内在冲突|成长评测|决策模式|决策系统|关系变量|机会判断|阶段目标函数|角色跃迁)"),
]

SELF_ANALYSIS_PATH_PATTERN = re.compile(r"(^|/)00_个人规划与复盘/")

REQUIRED_UNIT_FIELDS = [
  "写作单元：",
  "章节路径：",
  "核心问题：",
  "覆盖变量：",
  "输入材料：",
  "不处理项：",
]

CHAPTER_UNITS = {"chapter", "section"}
COMPLEX_UNITS = {"outline", "synthesis"}

def strip_non_prose(text):
    text = re.sub(r"```[\s\S]*?```", "", text)
    text = re.sub(r"\x60[^\x60\n]+\x60", "", text)
    text = re.sub(r"^\s*>.*$", "", text, flags=re.MULTILINE)
    return text

def count_cjk_chars(text):
    return len(re.findall(r"[\u4e00-\u9fff]", text))

def count_nonempty_lines(text):
    return len([line for line in text.splitlines() if line.strip()])

def count_headings(text, marker):
    return len(re.findall(rf"^\s*{marker}\s+", text, flags=re.MULTILINE))

def normalize_path(path):
    return str(path).replace("\\", "/")

def is_self_analysis_path(path):
    return bool(SELF_ANALYSIS_PATH_PATTERN.search(normalize_path(path)))

def looks_like_self_analysis(text):
    return any(pattern.search(text) for pattern in SELF_ANALYSIS_PATTERNS)

def needs_chapter_guard(text):
    if not looks_like_self_analysis(text):
        return False

    evidence_like_items = len(re.findall(r"^\s*(?:\d+\.|[-*])\s+", text, flags=re.MULTILINE))
    return (
        count_cjk_chars(text) >= 900
        or count_nonempty_lines(text) >= 35
        or count_headings(text, "##") >= 4
        or evidence_like_items >= 8
    )

def is_outline_doc(text):
    chapter_markers = re.findall(
        r"(?m)^\s*(?:[-*]|\d+\.)\s*(?:\d{2}(?:[._]\d{2})?|第[一二三四五六七八九十]+章|[0-9]{2}_[^\s]+|[一二三四五六七八九十]+、)",
        text,
    )
    return ("目录树" in text or "章节清单" in text) and len(chapter_markers) >= 3

def has_unit_metadata(text):
    return all(field in text for field in REQUIRED_UNIT_FIELDS)

def parse_unit_type(text):
    match = re.search(r"写作单元：([^\n]+)", text)
    if not match:
        return ""
    return match.group(1).strip().lower()

def parse_variable_count(text):
    match = re.search(r"覆盖变量：([^\n]+)", text)
    if not match:
        return None

    raw = match.group(1).strip()
    if not raw or raw in {"无", "-", "待补"}:
        return 0

    parts = [part.strip() for part in re.split(r"[、,，/；;|｜]+", raw) if part.strip()]
    return len(parts)

def collect_markdown_writes(payload):
    tool_name = payload.get("tool_name") or ""
    tool_input = payload.get("tool_input") or {}
    writes = []

    if tool_name.endswith("create_file"):
        file_path = tool_input.get("filePath") or ""
        content = tool_input.get("content") or ""
        if file_path.lower().endswith(".md"):
            writes.append((file_path, content))
        return writes

    if tool_name.endswith("edit_notebook_file"):
        language = (tool_input.get("language") or "").lower()
        if language != "markdown":
            return writes

        new_code = tool_input.get("newCode") or ""
        if isinstance(new_code, list):
            content = "\n".join(part for part in new_code if isinstance(part, str))
        elif isinstance(new_code, str):
            content = new_code
        else:
            content = ""

        writes.append((tool_input.get("filePath") or "markdown-notebook", content))
        return writes

    if not tool_name.endswith("apply_patch"):
        return writes

    patch_input = tool_input.get("input") or ""
    current_path = None
    added_lines = []

    def flush_current():
        if current_path and current_path.lower().endswith(".md"):
            writes.append((current_path, "\n".join(added_lines)))

    for raw_line in patch_input.splitlines():
        header = re.match(r"^\*\*\* (Add|Update|Delete) File: (.+)$", raw_line)
        if header:
            flush_current()
            action, path = header.groups()
            current_path = path.strip() if action != "Delete" else None
            added_lines = []
            continue

        if raw_line.startswith("*** End Patch"):
            break

        if raw_line.startswith("*** "):
            continue

        if current_path and raw_line.startswith("+") and not raw_line.startswith("+++"):
            added_lines.append(raw_line[1:])

    flush_current()
    return writes

def make_result(mode, message):
    return {
        "mode": mode,
        "message": message,
    }

try:
    payload = json.load(sys.stdin)
except Exception:
    print(json.dumps(make_result("allow", ""), ensure_ascii=False))
    raise SystemExit(0)

markdown_writes = collect_markdown_writes(payload)

if not markdown_writes:
    print(json.dumps(make_result("allow", ""), ensure_ascii=False))
    raise SystemExit(0)

violations = []
structure_violations = []
for path, raw_content in markdown_writes:
    content = strip_non_prose(raw_content)
    if not content.strip():
        continue

    for label, pattern in BANNED_PATTERNS:
        if pattern.search(content):
            violations.append(f"{path} 命中 {label}")

    if not is_self_analysis_path(path):
        continue

    has_metadata = has_unit_metadata(content)

    if not has_metadata and not looks_like_self_analysis(content):
        continue

    if not has_metadata and not needs_chapter_guard(content):
        continue

    if is_outline_doc(content):
        continue

    if not has_metadata:
        structure_violations.append(f"{path} 缺少章节化写作元信息")
        continue

    unit_type = parse_unit_type(content)
    variable_count = parse_variable_count(content)
    second_level_headings = count_headings(content, "##")
    cjk_chars = count_cjk_chars(content)

    if unit_type not in CHAPTER_UNITS and unit_type not in COMPLEX_UNITS:
        structure_violations.append(f"{path} 写作单元取值无效：{unit_type or '空'}")

    if variable_count is None:
        structure_violations.append(f"{path} 缺少覆盖变量")
    elif variable_count > 5:
        structure_violations.append(f"{path} 覆盖变量 {variable_count} 个，超过 5 个上限")

    if unit_type in CHAPTER_UNITS and second_level_headings > 3:
        structure_violations.append(f"{path} 二级标题 {second_level_headings} 个，像多章节混写")

    if unit_type in CHAPTER_UNITS and cjk_chars > 1800:
        structure_violations.append(f"{path} 正文过长，超过单章节建议上限")

deny_messages = []
if violations:
    deny_messages.append(
        "Markdown 写入被拒绝：检测到高风险套话或禁用句式。"
        + "；".join(violations)
        + "。请改成直接判断句、证据句或动作句后再提交。"
    )

if structure_violations:
    advisory_message = (
        "Markdown 写入提示：详尽人物分析、性格分析、自省分析建议先补目录树或章节边界。"
        + "；".join(structure_violations)
        + "。目录树、章节元信息和分文件用于控遗漏，不再作为长文写入的硬门槛。"
    )
else:
    advisory_message = ""

if deny_messages:
    print(json.dumps(make_result(
        "deny",
        " ".join(deny_messages),
    ), ensure_ascii=False))
else:
    allow_message = "即将写入 Markdown 文档。写入文件正文时继续遵守语言规范。"
    if advisory_message:
        allow_message += " " + advisory_message

    print(json.dumps(make_result(
        "allow",
        allow_message,
    ), ensure_ascii=False))
PY
)"
  pretool_result="$(/usr/bin/python3 -c "$pretool_python" <<<"$hook_input")"

  pretool_mode="$(/usr/bin/python3 -c 'import json, sys
payload = json.load(sys.stdin)
print(payload.get("mode", "allow"))' <<<"$pretool_result")"
  pretool_message="$(/usr/bin/python3 -c 'import json, sys
payload = json.load(sys.stdin)
print(payload.get("message", ""))' <<<"$pretool_result")"

  if [[ "$pretool_mode" == "deny" ]]; then
    emit_pretool_deny "$pretool_message"
  elif [[ -n "$pretool_message" ]]; then
    emit_pretool_context "$pretool_message"
    else
        emit_continue
  fi
  exit 0
fi

emit_continue