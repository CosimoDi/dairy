#!/usr/bin/env bash
set -euo pipefail

event="${1:-}"

emit_silent_continue() {
  cat <<'EOF'
{"continue":true,"suppressOutput":true}
EOF
}

if [[ "$event" == "SessionStart" ]]; then
  printf 'Hook 执行：SessionStart 已装载会话级约束。\n'
  exit 0
fi

if [[ "$event" == "UserPromptSubmit" ]]; then
  cat >/dev/null
  printf 'Hook 执行：UserPromptSubmit 已触发本轮约束判定。\n'
  exit 0
fi

if [[ "$event" == "PreToolUse" ]]; then
  hook_input="$(cat)"
  visual_message="$(/usr/bin/python3 -c 'import json, sys

READ_ONLY_TOOLS = {
    "read_file",
    "list_dir",
    "grep_search",
    "file_search",
    "semantic_search",
    "search_subagent",
    "read_page",
    "fetch_webpage",
    "get_errors",
    "get_changed_files",
    "copilot_getNotebookSummary",
    "terminal_last_command",
    "terminal_selection",
    "get_terminal_output",
    "await_terminal",
    "view_image",
    "get_search_view_results",
}

WRITE_TOOLS = {
    "apply_patch",
    "create_file",
    "edit_notebook_file",
    "create_directory",
}

EXECUTION_TOOLS = {
    "run_in_terminal",
    "execution_subagent",
    "create_and_run_task",
    "runSubagent",
    "run_notebook_cell",
}

BROWSER_TOOLS = {
    "open_browser_page",
    "navigate_page",
    "click_element",
    "type_in_page",
    "hover_element",
    "drag_element",
    "run_playwright_code",
    "read_page",
    "screenshot_page",
}

try:
    payload = json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit(0)

tool_name = payload.get("tool_name") or ""
if not isinstance(tool_name, str) or not tool_name:
    print("")
    raise SystemExit(0)

short_name = tool_name.split(".")[-1]

if short_name in READ_ONLY_TOOLS:
    print("")
elif short_name in WRITE_TOOLS:
    print(f"Hook 执行：PreToolUse 将写入或改动文件，工具 {short_name}。")
elif short_name in EXECUTION_TOOLS:
    print(f"Hook 执行：PreToolUse 将执行命令或代理，工具 {short_name}。")
elif short_name in BROWSER_TOOLS:
    print(f"Hook 执行：PreToolUse 将操作浏览器，工具 {short_name}。")
else:
    print(f"Hook 执行：PreToolUse 将调用工具 {short_name}。")
' <<<"$hook_input")"

  if [[ -z "$visual_message" ]]; then
    emit_silent_continue
  else
    printf '%s\n' "$visual_message"
  fi
  exit 0
fi

emit_silent_continue