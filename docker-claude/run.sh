#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOKEN_FILE="$SCRIPT_DIR/token"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Token file not found at: $TOKEN_FILE"
  echo "Run 'claude setup-token' and save the output to that file."
  exit 1
fi

export CLAUDE_CODE_OAUTH_TOKEN=$(cat "$TOKEN_FILE")
docker compose run --rm claude
