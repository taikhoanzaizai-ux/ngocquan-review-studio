from __future__ import annotations

import shutil
import subprocess
from pathlib import Path
from typing import Any

from fastapi import FastAPI, File, UploadFile
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

BASE_DIR = Path(__file__).resolve().parent
STATIC_DIR = BASE_DIR / "static"
MEDIA_DIR = BASE_DIR / ".local" / "media"
MEDIA_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="Ngoc Quan Review Studio", version="0.1.0")
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
app.mount("/media", StaticFiles(directory=MEDIA_DIR), name="media")


def command_version(name: str) -> dict[str, Any]:
    path = shutil.which(name)
    if not path:
        return {"ok": False, "path": None, "version": None}
    try:
        result = subprocess.run([path, "-version"], capture_output=True, text=True, timeout=5)
        first_line = (result.stdout or result.stderr).splitlines()[0] if (result.stdout or result.stderr) else ""
        return {"ok": result.returncode == 0, "path": path, "version": first_line}
    except Exception as exc:
        return {"ok": False, "path": path, "version": str(exc)}


@app.get("/")
def index() -> FileResponse:
    return FileResponse(BASE_DIR / "index.html")


@app.get("/api/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "app": "Ngoc Quan Review Studio",
        "version": "0.1.0",
        "ffmpeg": command_version("ffmpeg"),
        "ffprobe": command_version("ffprobe"),
    }


@app.get("/api/media")
def list_media() -> dict[str, Any]:
    items = []
    for path in sorted(MEDIA_DIR.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True):
        if path.is_file():
            items.append({"name": path.name, "url": f"/media/{path.name}", "size": path.stat().st_size})
    return {"items": items}


@app.post("/api/upload")
async def upload(file: UploadFile = File(...)) -> dict[str, Any]:
    safe_name = Path(file.filename or "upload.bin").name
    target = MEDIA_DIR / safe_name
    counter = 1
    while target.exists():
        target = MEDIA_DIR / f"{Path(safe_name).stem}_{counter}{Path(safe_name).suffix}"
        counter += 1

    with target.open("wb") as out:
        while chunk := await file.read(1024 * 1024):
            out.write(chunk)

    return {"ok": True, "name": target.name, "url": f"/media/{target.name}", "size": target.stat().st_size}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app:app", host="127.0.0.1", port=8000, reload=False)
