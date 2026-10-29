#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

python -m pip install -r requirements.txt

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "FFmpeg/FFprobe not found. Installing..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg
fi

echo "Starting Ngoc Quan Review Studio on port 8000..."
exec uvicorn app:app --host 0.0.0.0 --port 8000
