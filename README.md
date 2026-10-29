# Ngọc Quân Review Studio

Bản v0.1 khởi tạo công cụ dựng video chạy bằng Python + FastAPI, có giao diện web, upload/preview media, timeline cơ bản và lớp Text/Audio/Voice.

## Chạy trên Windows

1. Cài Python 3.11 trở lên.
2. Khuyến nghị cài FFmpeg và thêm vào PATH.
3. Clone hoặc tải ZIP repo về máy.
4. Bấm đúp `START_WINDOWS.bat`.
5. Mở `http://127.0.0.1:8000` nếu trình duyệt chưa tự mở.

## Chạy bằng GitHub Codespaces

1. Trên GitHub bấm `Code` → `Codespaces` → `Create codespace on main`.
2. Dev Container sẽ tự cài Python dependencies và FFmpeg.
3. Server chạy ở cổng 8000 và GitHub sẽ forward cổng này.

## Tính năng v0.1

- Upload video/audio từ trình duyệt.
- Preview video trong giao diện.
- Play/Pause và hiển thị thời gian.
- Danh sách media đã upload.
- Timeline cơ bản với Video / Audio / Voice / Text.
- Thêm text overlay, đổi cỡ chữ và màu chữ.
- Kiểm tra trạng thái FFmpeg/FFprobe qua `/api/health`.

## Lộ trình tiếp theo

- Kéo thả clip trên timeline.
- Cắt/ghép video bằng FFmpeg.
- Điều chỉnh tốc độ video/audio.
- Upload audio riêng và waveform.
- TTS tiếng Việt và lưu danh sách voice.
- Voice clone và ghi nhớ voice đã clone.
- Text layer kéo/thả, resize, chỉnh font/màu/viền.
- Export video nhiều tỷ lệ.
