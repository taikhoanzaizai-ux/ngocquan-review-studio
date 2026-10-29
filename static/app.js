const $ = (id) => document.getElementById(id);
const preview = $('preview');
const statusEl = $('status');
const mediaList = $('mediaList');
const fileInput = $('fileInput');
const textOverlay = $('textOverlay');
const videoClip = $('videoClip');
const textClip = $('textClip');

let localObjectUrl = null;

function fmt(sec) {
  if (!Number.isFinite(sec)) return '00:00';
  const m = Math.floor(sec / 60).toString().padStart(2, '0');
  const s = Math.floor(sec % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}

function setStatus(text, ok = true) {
  statusEl.textContent = text;
  statusEl.style.color = ok ? '#9fe3b0' : '#ff9a9a';
}

async function refreshHealth() {
  try {
    const r = await fetch('/api/health', { cache: 'no-store' });
    const data = await r.json();
    const ff = data.ffmpeg?.ok ? 'FFmpeg OK' : 'Thiếu FFmpeg';
    statusEl.textContent = `${data.app} ${data.version} · ${ff}`;
    statusEl.style.color = data.ffmpeg?.ok ? '#9fe3b0' : '#ffd28a';
  } catch {
    setStatus('Không kết nối được backend', false);
  }
}

async function refreshMedia() {
  try {
    const r = await fetch('/api/media', { cache: 'no-store' });
    const data = await r.json();
    mediaList.innerHTML = '';
    for (const item of data.items || []) {
      const row = document.createElement('div');
      row.className = 'media-item';
      const name = document.createElement('span');
      name.textContent = item.name;
      name.title = item.name;
      const use = document.createElement('button');
      use.textContent = 'Preview';
      use.onclick = () => loadPreview(item.url, item.name, false);
      row.append(name, use);
      mediaList.append(row);
    }
  } catch (err) {
    setStatus(`Không tải được danh sách media: ${err.message}`, false);
  }
}

function loadPreview(url, name, isLocal = false) {
  if (!isLocal && localObjectUrl) {
    URL.revokeObjectURL(localObjectUrl);
    localObjectUrl = null;
  }
  preview.pause();
  preview.removeAttribute('src');
  preview.src = url;
  preview.load();
  videoClip.textContent = name || 'Video';
}

$('pickBtn').onclick = () => fileInput.click();

fileInput.onchange = async () => {
  const files = [...fileInput.files];
  if (!files.length) return;

  const firstVideo = files.find(file => file.type.startsWith('video/'));
  if (firstVideo) {
    if (localObjectUrl) URL.revokeObjectURL(localObjectUrl);
    localObjectUrl = URL.createObjectURL(firstVideo);
    loadPreview(localObjectUrl, firstVideo.name, true);
    setStatus(`Đã chọn ${firstVideo.name} · đang tải lên server…`);
    preview.play().catch(() => {});
  } else {
    setStatus('Bạn chưa chọn file video. Audio sẽ không hiện hình trong khung preview.', false);
  }

  for (const file of files) {
    try {
      const form = new FormData();
      form.append('file', file);
      const r = await fetch('/api/upload', { method: 'POST', body: form });
      if (!r.ok) {
        const detail = await r.text();
        throw new Error(detail || `HTTP ${r.status}`);
      }
      const data = await r.json();
      if (file === firstVideo) {
        loadPreview(data.url, data.name, false);
      }
    } catch (err) {
      setStatus(`Upload lỗi ${file.name}: ${err.message}`, false);
    }
  }

  fileInput.value = '';
  await refreshMedia();
  await refreshHealth();
};

$('playBtn').onclick = () => preview.paused ? preview.play() : preview.pause();
preview.ontimeupdate = () => $('timeLabel').textContent = `${fmt(preview.currentTime)} / ${fmt(preview.duration)}`;
preview.onloadedmetadata = () => {
  $('timeLabel').textContent = `${fmt(preview.currentTime)} / ${fmt(preview.duration)}`;
  setStatus(`Video đã sẵn sàng · ${fmt(preview.duration)}`);
};
preview.onerror = () => {
  const code = preview.error?.code;
  const messages = {
    1: 'Video bị hủy khi đang tải.',
    2: 'Lỗi mạng khi tải video.',
    3: 'Trình duyệt không giải mã được video.',
    4: 'Định dạng/codec video không được trình duyệt hỗ trợ.'
  };
  setStatus(messages[code] || 'Không thể phát video đã chọn.', false);
};

$('addText').onclick = () => {
  const value = $('textValue').value.trim();
  textOverlay.textContent = value;
  textOverlay.style.fontSize = `${$('fontSize').value}px`;
  textOverlay.style.color = $('fontColor').value;
  textClip.textContent = value || 'Text layer';
};
$('fontSize').oninput = () => textOverlay.style.fontSize = `${$('fontSize').value}px`;
$('fontColor').oninput = () => textOverlay.style.color = $('fontColor').value;

for (const button of document.querySelectorAll('[data-layer]')) {
  button.onclick = () => {
    const type = button.dataset.layer;
    const row = document.createElement('div');
    row.className = 'track';
    row.innerHTML = `<span>${type.toUpperCase()}</span><div class="clip">${type} layer mới</div>`;
    $('timeline').append(row);
  };
}

refreshHealth();
refreshMedia();
