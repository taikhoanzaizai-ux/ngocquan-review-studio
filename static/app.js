const $ = (id) => document.getElementById(id);
const preview = $('preview');
const statusEl = $('status');
const mediaList = $('mediaList');
const fileInput = $('fileInput');
const textOverlay = $('textOverlay');
const videoClip = $('videoClip');
const textClip = $('textClip');

function fmt(sec) {
  if (!Number.isFinite(sec)) return '00:00';
  const m = Math.floor(sec / 60).toString().padStart(2, '0');
  const s = Math.floor(sec % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}

async function refreshHealth() {
  try {
    const r = await fetch('/api/health');
    const data = await r.json();
    const ff = data.ffmpeg?.ok ? 'FFmpeg OK' : 'Thiếu FFmpeg';
    statusEl.textContent = `${data.app} ${data.version} · ${ff}`;
    statusEl.style.color = data.ffmpeg?.ok ? '#9fe3b0' : '#ffd28a';
  } catch {
    statusEl.textContent = 'Không kết nối được backend';
    statusEl.style.color = '#ff9a9a';
  }
}

async function refreshMedia() {
  const r = await fetch('/api/media');
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
    use.onclick = () => loadPreview(item.url, item.name);
    row.append(name, use);
    mediaList.append(row);
  }
}

function loadPreview(url, name) {
  preview.src = url;
  preview.load();
  videoClip.textContent = name || 'Video';
}

$('pickBtn').onclick = () => fileInput.click();
fileInput.onchange = async () => {
  const files = [...fileInput.files];
  for (const file of files) {
    const form = new FormData();
    form.append('file', file);
    statusEl.textContent = `Đang tải ${file.name}…`;
    const r = await fetch('/api/upload', { method: 'POST', body: form });
    if (!r.ok) {
      statusEl.textContent = `Upload lỗi: ${file.name}`;
      continue;
    }
    const data = await r.json();
    loadPreview(data.url, data.name);
  }
  fileInput.value = '';
  await refreshMedia();
  await refreshHealth();
};

$('playBtn').onclick = () => preview.paused ? preview.play() : preview.pause();
preview.ontimeupdate = () => $('timeLabel').textContent = `${fmt(preview.currentTime)} / ${fmt(preview.duration)}`;
preview.onloadedmetadata = () => $('timeLabel').textContent = `${fmt(preview.currentTime)} / ${fmt(preview.duration)}`;

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
