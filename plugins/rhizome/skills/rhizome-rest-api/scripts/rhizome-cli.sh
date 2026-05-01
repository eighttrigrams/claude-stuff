#!/usr/bin/env bash
set -euo pipefail

# Thin wrapper around Rhizome's REST API on 127.0.0.1.
# Usage:
#   rhizome-cli.sh <port> <path>                        # GET
#   rhizome-cli.sh <port> <method> <path> [json-body]   # any method, optional body
#
# <path> is everything after /rest, including the leading slash,
# e.g. "/contexts?q=Books".

if [ $# -lt 2 ]; then
  echo "usage: rhizome-cli.sh <port> <path> | <port> <method> <path> [json-body]" >&2
  exit 1
fi

port="$1"; shift
base="http://127.0.0.1:${port}/rest"

if [ $# -eq 1 ]; then
  curl -sf "${base}$1"
else
  method="$1"; path="$2"; body="${3:-}"
  if [ -n "$body" ]; then
    curl -sf -X "$method" -H 'Content-Type: application/json' -d "$body" "${base}${path}"
  else
    curl -sf -X "$method" "${base}${path}"
  fi
fi
