@echo off
setlocal
cd /d %~dp0

echo ==========================================
echo   NGOC QUAN REVIEW STUDIO v0.1

echo ==========================================

where python >nul 2>nul
if errorlevel 1 (
  echo [LOI] Khong tim thay Python. Hay cai Python 3.11 tro len.
  pause
  exit /b 1
)

if not exist .venv (
  echo [1/4] Tao moi moi truong Python...
  python -m venv .venv
  if errorlevel 1 goto :fail
)

call .venv\Scripts\activate.bat

echo [2/4] Cai / cap nhat thu vien...
python -m pip install --upgrade pip >nul
pip install -r requirements.txt
if errorlevel 1 goto :fail

where ffmpeg >nul 2>nul
if errorlevel 1 (
  echo [CANH BAO] Chua tim thay FFmpeg trong PATH.
  echo Tool van mo duoc, nhung cac chuc nang xu ly video sau nay se can FFmpeg.
)

echo [3/4] Khoi dong server...
start "" http://127.0.0.1:8000

echo [4/4] Dang chay tai http://127.0.0.1:8000
python app.py
exit /b 0

:fail
echo.
echo [LOI] Cai dat / khoi dong that bai.
pause
exit /b 1
