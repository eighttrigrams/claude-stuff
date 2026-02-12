#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name' 2>/dev/null)
TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)

if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command' 2>/dev/null)
  DESC=$(echo "$INPUT" | jq -r '.tool_input.description // empty' 2>/dev/null)
  if [ -n "$DESC" ]; then
    echo "$TIMESTAMP - PreToolUse - Bash($CMD) - $DESC" >> "$LOG_FILE"
  else
    echo "$TIMESTAMP - PreToolUse - Bash($CMD)" >> "$LOG_FILE"
  fi
elif [ "$TOOL_NAME" = "Task" ]; then
  SUBAGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null)
  DESC=$(echo "$INPUT" | jq -r '.tool_input.description // empty' 2>/dev/null)
  PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null)
  echo "$TIMESTAMP - PreToolUse - Task($SUBAGENT) - $DESC" >> "$LOG_FILE"
  echo "  prompt: $PROMPT" >> "$LOG_FILE"
elif [ "$TOOL_NAME" = "Skill" ]; then
  SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
  ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // empty' 2>/dev/null)
  if [ -n "$ARGS" ]; then
    echo "$TIMESTAMP - PreToolUse - Skill($SKILL) - $ARGS" >> "$LOG_FILE"
  else
    echo "$TIMESTAMP - PreToolUse - Skill($SKILL)" >> "$LOG_FILE"
  fi
elif [ "$TOOL_NAME" = "Read" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  REL_PATH="${FILE_PATH#$PROJECT_DIR/}"
  echo "$TIMESTAMP - PreToolUse - Read($REL_PATH)" >> "$LOG_FILE"
elif [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  REL_PATH="${FILE_PATH#$PROJECT_DIR/}"
  echo "$TIMESTAMP - PreToolUse - Write($REL_PATH)" >> "$LOG_FILE"
elif [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  REL_PATH="${FILE_PATH#$PROJECT_DIR/}"
  echo "$TIMESTAMP - PreToolUse - Edit($REL_PATH)" >> "$LOG_FILE"
elif [ "$TOOL_NAME" = "WebFetch" ]; then
  URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty' 2>/dev/null)
  PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null)
  echo "$TIMESTAMP - PreToolUse - WebFetch($URL) - $PROMPT" >> "$LOG_FILE"
elif [ "$TOOL_NAME" = "WebSearch" ]; then
  QUERY=$(echo "$INPUT" | jq -r '.tool_input.query // empty' 2>/dev/null)
  echo "$TIMESTAMP - PreToolUse - WebSearch($QUERY)" >> "$LOG_FILE"
elif [ "$TOOL_NAME" = "Grep" ]; then
  PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // empty' 2>/dev/null)
  PATH_ARG=$(echo "$INPUT" | jq -r '.tool_input.path // empty' 2>/dev/null)
  GLOB=$(echo "$INPUT" | jq -r '.tool_input.glob // empty' 2>/dev/null)
  REL_PATH="${PATH_ARG#$PROJECT_DIR/}"
  LOG_MSG="$TIMESTAMP - PreToolUse - Grep($PATTERN)"
  [ -n "$REL_PATH" ] && LOG_MSG="$LOG_MSG path=$REL_PATH"
  [ -n "$GLOB" ] && LOG_MSG="$LOG_MSG glob=$GLOB"
  echo "$LOG_MSG" >> "$LOG_FILE"
elif [ "$TOOL_NAME" = "Glob" ]; then
  PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // empty' 2>/dev/null)
  PATH_ARG=$(echo "$INPUT" | jq -r '.tool_input.path // empty' 2>/dev/null)
  REL_PATH="${PATH_ARG#$PROJECT_DIR/}"
  LOG_MSG="$TIMESTAMP - PreToolUse - Glob($PATTERN)"
  [ -n "$REL_PATH" ] && LOG_MSG="$LOG_MSG path=$REL_PATH"
  echo "$LOG_MSG" >> "$LOG_FILE"
elif [ "$TOOL_NAME" = "TodoWrite" ]; then
  echo "$TIMESTAMP - PreToolUse - TodoWrite" >> "$LOG_FILE"
  echo "  todos:" >> "$LOG_FILE"
  echo "$INPUT" | jq -r '
    .tool_input.todos // [] | .[] |
    "  - " + (to_entries | map("\(.key): \(.value | tostring)") | join("\n    "))
  ' 2>/dev/null >> "$LOG_FILE"
else
  echo "$TIMESTAMP - PreToolUse - $TOOL_NAME" >> "$LOG_FILE"
fi
