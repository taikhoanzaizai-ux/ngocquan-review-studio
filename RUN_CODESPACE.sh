#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "FFmpeg/FFprobe not found. Trying to install..."
  while IFS= read -r src; do
    [ -n "$src" ] || continue
    sudo mv "$src" "$src.disabled" 2>/dev/null || true
  done < <(grep -RIl "dl.yarnpkg.com" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null || true)
  if sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg; then
    echo "FFmpeg installed successfully."
  else
    echo "[WARN] Could not install FFmpeg. The web UI may open, but video processing may be unavailable."
  fi
fi

mkdir -p .local/logs

# Stop old prototype/uvicorn instances and anything currently holding port 8000.
pkill -f "uvicorn app:app" 2>/dev/null || true
pkill -f "python app.py" 2>/dev/null || true
if command -v fuser >/dev/null 2>&1; then
  fuser -k 8000/tcp >/dev/null 2>&1 || true
fi
sleep 1

echo "Starting Review Studio 0.40.0 with its native Python server..."
PORT=8000 nohup python app.py > .local/logs/review-studio.log 2>&1 &
echo $! > .local/review-studio.pid

for i in $(seq 1 25); do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
    echo "Review Studio is running on port 8000."
    echo "Log: .local/logs/review-studio.log"
    exit 0
  fi
  sleep 1
done

echo "Server did not become ready. Last log lines:"
tail -n 80 .local/logs/review-studio.log || true
exit 1
