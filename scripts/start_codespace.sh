#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

export REVIEW_STUDIO_HOST=0.0.0.0
export PORT=${PORT:-8000}

mkdir -p .local

# Stop an older instance if this Codespace was restarted.
pkill -f "python app.py" 2>/dev/null || true

nohup python app.py > .local/codespace.log 2>&1 &

sleep 2
if curl -fsS "http://127.0.0.1:${PORT}/api/health" >/dev/null; then
  echo "Ngoc Quan Review Studio is running on port ${PORT}."
else
  echo "Server failed to start. Recent log:"
  tail -n 50 .local/codespace.log || true
  exit 1
fi
