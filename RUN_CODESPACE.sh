#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

python -m pip install -r requirements.txt

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "FFmpeg/FFprobe not found. Installing..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg
fi

mkdir -p .local/logs

if [ -f .local/uvicorn.pid ]; then
  OLD_PID="$(cat .local/uvicorn.pid 2>/dev/null || true)"
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" || true
    sleep 1
  fi
fi

if command -v fuser >/dev/null 2>&1; then
  fuser -k 8000/tcp >/dev/null 2>&1 || true
fi

echo "Starting Ngoc Quan Review Studio in background on port 8000..."
nohup uvicorn app:app --host 0.0.0.0 --port 8000 > .local/logs/uvicorn.log 2>&1 &
echo $! > .local/uvicorn.pid

for i in $(seq 1 20); do
  if curl -fsS http://127.0.0.1:8000/api/health >/dev/null 2>&1; then
    echo "Review Studio is running on port 8000."
    echo "Log: .local/logs/uvicorn.log"
    exit 0
  fi
  sleep 1
done

echo "Server did not become ready. Last log lines:"
tail -n 40 .local/logs/uvicorn.log || true
exit 1
