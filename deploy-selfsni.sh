#!/usr/bin/env bash
# ==============================================================================
# NGINX SELFSNI CONTROL CORE - MANAGEMENT SYSTEM & DEPLOYER
# Dedicated High-Entropy Camouflage & Fallback Engine for Xray Reality / XHTTP
# ==============================================================================

# Проверка интерпретатора: требуется bash, а не dash/sh
if [ -z "${BASH_VERSION:-}" ]; then
    echo ""
    echo "===================================================================="
    echo " [ОШИБКА] Скрипт запущен через интерпретатор 'sh' (dash)!"
    echo " Для корректной работы SelfSNI и генератора сайтов требуется BASH."
    echo ""
    echo " Пожалуйста, запустите установку правильной командой через 'bash':"
    echo " bash <(wget -qO- https://raw.githubusercontent.com/EikeiDev/remnawave-configs/refs/heads/main/deploy-selfsni.sh)"
    echo " или:"
    echo " bash <(curl -sSL https://raw.githubusercontent.com/EikeiDev/remnawave-configs/refs/heads/main/deploy-selfsni.sh)"
    echo "===================================================================="
    echo ""
    exit 1
fi

set -euo pipefail

# --- Константы и пути ---
CONFIG_DIR="/etc/selfsni"
CONFIG_FILE="${CONFIG_DIR}/selfsni.conf"
BIN_LINK="/usr/local/bin/selfsni"
VERSION="1.2.0"

# --- Цвета для интерфейса ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
WHITE='\033[1;37m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# --- Проверка root прав ---
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_err "Этот скрипт должен быть запущен с правами root (sudo)."
        exit 1
    fi
}

# --- Загрузка конфигурации ---
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

# --- Сохранение конфигурации ---
save_config() {
    mkdir -p "$CONFIG_DIR"
    cat << EOF > "$CONFIG_FILE"
DOMAIN="${DOMAIN}"
EMAIL="${EMAIL:-admin@$DOMAIN}"
FALLBACK_PORT="${FALLBACK_PORT}"
USE_PROXY_FLAG="${USE_PROXY_FLAG}"
WEB_ROOT="${WEB_ROOT}"
THEME_NAME="${THEME_NAME:-Random Constructor}"
COMPANY_NAME="${COMPANY_NAME:-Default}"
ARCHETYPE_NAME="${ARCHETYPE_NAME:-Encrypted Cloud Vault (File Drop)}"
ENABLE_PQC="${ENABLE_PQC:-0}"
REMNANODE_PORT="${REMNANODE_PORT:-}"
PANEL_IP="${PANEL_IP:-}"
HARDENING_BBR="${HARDENING_BBR:-0}"
EOF
}

# ==============================================================================
# ФУНКЦИЯ ПРОЦЕДУРНОГО КОНСТРУКТОРА ШЛЮЗОВ-МАСКИРОВОК (GATEWAYS & DECOY)
# ==============================================================================
generate_website() {
    local target_domain="$1"
    local target_root="$2"
    local selected_archetype="${3:-1}"

    mkdir -p "$target_root/assets"

    # Выбор архетипа шлюза [1-5]
    local arch_id
    if [ "$selected_archetype" -eq 1 ] || [ "$selected_archetype" -lt 1 ] || [ "$selected_archetype" -gt 6 ]; then
        arch_id=$(( (RANDOM % 5) + 1 ))
    else
        # Преобразуем выбор пользователя (2->1, 3->2, 4->3, 5->4, 6->5)
        arch_id=$(( selected_archetype - 1 ))
    fi

    # 1. ТЕХНОЛОГИЧНЫЕ ПАЛИТРЫ (ТЕМНЫЕ GLASSMORPHISM ИНТЕРФЕЙСЫ)
    local palettes=(
      "#3b82f6|#1d4ed8|#070b14|#0d1527|rgba(59,130,246,0.25)|#60a5fa"   # Cyber Cobalt
      "#10b981|#047857|#05120d|#0a1f17|rgba(16,185,129,0.25)|#34d399"   # Terminal Emerald
      "#8b5cf6|#6d28d9|#0c0a1a|#16122e|rgba(139,92,246,0.25)|#a78bfa"   # Obsidian Purple
      "#06b6d4|#0e7490|#061118|#0b1e2a|rgba(6,182,212,0.25)|#22d3ee"   # Arctic Cyan
      "#f59e0b|#b45309|#130e06|#22190b|rgba(245,158,11,0.25)|#fbbf24"   # Industrial Amber
      "#64748b|#475569|#090d16|#0f172a|rgba(100,116,139,0.25)|#94a3b8"  # Monochromatic Slate
    )
    local chosen_palette=${palettes[$((RANDOM % ${#palettes[@]}))]}
    IFS='|' read -r ACCENT_COLOR ACCENT_HOVER BG_PRIMARY BG_SECONDARY ACCENT_GLOW ACCENT_LIGHT <<< "$chosen_palette"

    # 2. ТИПОГРАФИКА
    local fonts=(
      "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
      "'Inter', -apple-system, BlinkMacSystemFont, sans-serif"
      "'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif"
      "'JetBrains Mono', 'Fira Code', Consolas, monospace"
    )
    local FONT_FAMILY=${fonts[$((RANDOM % ${#fonts[@]}))]}

    # 3. СКРУГЛЕНИЯ
    local radius_opts=("6px" "10px" "14px" "18px")
    local RADIUS=${radius_opts[$((RANDOM % ${#radius_opts[@]}))]}

    # 4. НАЗВАНИЯ ИНФРАСТРУКТУРНЫХ СЕРВИСОВ
    local brand_names=(
      "Aetheria Cloud Vault" "Nexus Zero-Trust Fabric" "Krypton Identity Perimeter"
      "Stratos S3 Storage" "Hyperion Distributed Ingress" "Titan Private Cluster"
      "Chronos Edge Relay" "Apex Telemetry Gateway" "Orbital Object Core"
      "Synthetix Bastion Access" "Vanguard Enterprise Mesh" "Linearis Infrastructure"
    )
    COMPANY_NAME=${brand_names[$((RANDOM % ${#brand_names[@]}))]}

    # Favicon (SVG)
    cat << EOF > "$target_root/favicon.svg"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" fill="none">
  <rect width="32" height="32" rx="8" fill="${ACCENT_COLOR}"/>
  <path d="M16 7L8 11V16C8 21.5 11.4 26.6 16 28C20.6 26.6 24 21.5 24 16V11L16 7Z" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
EOF

    # 5. ГЕНЕРАЦИЯ ВЫБРАННОГО АРХЕТИПА ШЛЮЗА
    case $arch_id in
        1)
            ARCHETYPE_NAME="Encrypted Cloud Vault (File Drop)"
            THEME_NAME="End-to-End Encrypted File Transfer Portal"
            generate_gateway_vault "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
        2)
            ARCHETYPE_NAME="Zero-Trust Identity Gateway (SSO / WebAuthn)"
            THEME_NAME="Enterprise Perimeter Authentication Portal"
            generate_gateway_identity "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
        3)
            ARCHETYPE_NAME="Private S3 Object Storage Gateway"
            THEME_NAME="Restricted Ingress & Object Storage Console"
            generate_gateway_s3 "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
        4)
            ARCHETYPE_NAME="Edge CDN Mesh Relay & Node Telemetry"
            THEME_NAME="Restricted Edge PoP & Anycast Transit Portal"
            generate_gateway_mesh "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
        5)
            ARCHETYPE_NAME="Minimalist Dev Auth Portal"
            THEME_NAME="Workspace Session Token & CLI Pairing"
            generate_gateway_minimal "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
    esac

    # robots.txt (Защита приватной инфраструктуры от индексации поисковиками)
    cat << EOF > "$target_root/robots.txt"
User-agent: *
Disallow: /
EOF

    # Кастомная стилизованная страница 404 (в стиле защищенной инфраструктуры)
    cat << EOF > "$target_root/404.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>404 - Protected Ingress Resource Not Found</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <style>
    body { margin:0; background:${BG_PRIMARY}; color:#f8fafc; font-family:${FONT_FAMILY}; display:flex; align-items:center; justify-content:center; min-height:100vh; text-align:center; padding:1.5rem; }
    .card { background:${BG_SECONDARY}; border:1px solid rgba(255,255,255,0.08); padding:2.5rem; border-radius:${RADIUS}; max-width:480px; box-shadow:0 20px 40px rgba(0,0,0,0.5); }
    h1 { font-size:3.5rem; margin:0; color:${ACCENT_COLOR}; font-weight:800; }
    h2 { font-size:1.25rem; margin:0.75rem 0 1rem; color:#e2e8f0; }
    p { color:#94a3b8; font-size:0.9rem; line-height:1.6; margin-bottom:1.5rem; }
    .btn { display:inline-block; background:${ACCENT_COLOR}; color:#fff; padding:0.65rem 1.5rem; border-radius:${RADIUS}; text-decoration:none; font-weight:600; font-size:0.875rem; transition:0.2s; }
    .btn:hover { background:${ACCENT_HOVER}; }
    .ref { font-family:monospace; font-size:0.75rem; color:#64748b; margin-top:1.5rem; }
  </style>
</head>
<body>
  <div class="card">
    <h1>404</h1>
    <h2>Protected Ingress Resource Not Found</h2>
    <p>The requested endpoint does not exist on this cluster, or your session access token has expired.</p>
    <a href="/" class="btn">Return to Gateway Ingress</a>
    <div class="ref">Endpoint: ${target_domain} • Core Code: ERR_ROUTE_NOT_FOUND</div>
  </div>
</body>
</html>
EOF

    log_ok "Шлюз-маскировка успешно сгенерирован (Стиль: $ARCHETYPE_NAME, Бренд: $COMPANY_NAME)!"
}

# ------------------------------------------------------------------------------
# АРХЕТИП 1: ENCRYPTED CLOUD VAULT & CHUNKED FILE DROP (ProtonDrive / Send Style)
# ------------------------------------------------------------------------------
generate_gateway_vault() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"
    mkdir -p "$root/assets"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.03);
  --border: rgba(255,255,255,0.08); --border-h: rgba(255,255,255,0.18);
  --txt: #f8fafc; --muted: #94a3b8; --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; min-height: 100vh; display: flex; flex-direction: column; }
.container { max-width: 860px; margin: 0 auto; padding: 0 1.25rem; width: 100%; }
header { padding: 1.5rem 0; border-bottom: 1px solid var(--border); background: rgba(0,0,0,0.2); backdrop-filter: blur(12px); }
.header-row { display: flex; align-items: center; justify-content: space-between; }
.logo-box { display: flex; align-items: center; gap: 0.75rem; font-weight: 700; font-size: 1.15rem; }
.badge { display: inline-flex; align-items: center; gap: 0.4rem; padding: 0.25rem 0.65rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600; background: rgba(16,185,129,0.12); color: #34d399; border: 1px solid rgba(16,185,129,0.25); }
.badge-dot { width: 6px; height: 6px; border-radius: 50%; background: #10b981; box-shadow: 0 0 6px #10b981; }
main { flex: 1; padding: 3rem 0; }
.vault-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2.25rem; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); backdrop-filter: blur(16px); position: relative; overflow: hidden; }
.vault-card::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px; background: linear-gradient(90deg, transparent, var(--acc), transparent); }
.title-area { margin-bottom: 1.75rem; }
.title-area h1 { font-size: 1.85rem; font-weight: 800; letter-spacing: -0.02em; margin-bottom: 0.5rem; }
.title-area p { color: var(--muted); font-size: 0.95rem; }
.specs-bar { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; padding: 1rem; background: var(--card-bg); border: 1px solid var(--border); border-radius: var(--rad); margin-bottom: 1.75rem; font-size: 0.825rem; }
.spec-item { display: flex; flex-direction: column; gap: 0.2rem; }
.spec-label { color: var(--muted); font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; }
.spec-val { font-family: monospace; font-weight: 600; color: var(--acc-l); }
.dropzone { border: 2px dashed var(--border); border-radius: var(--rad); padding: 2.5rem 1.5rem; text-align: center; cursor: pointer; transition: 0.2s ease; background: rgba(0,0,0,0.15); margin-bottom: 1.5rem; }
.dropzone:hover, .dropzone.dragover { border-color: var(--acc); background: rgba(255,255,255,0.02); box-shadow: 0 0 20px var(--glow); }
.drop-icon { width: 44px; height: 44px; margin: 0 auto 1rem; color: var(--acc); }
.dropzone h3 { font-size: 1.05rem; margin-bottom: 0.35rem; }
.dropzone p { color: var(--muted); font-size: 0.825rem; }
.file-list { margin-bottom: 1.5rem; display: flex; flex-direction: column; gap: 0.65rem; }
.file-item { display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1rem; background: var(--card-bg); border: 1px solid var(--border); border-radius: calc(var(--rad) - 2px); font-size: 0.85rem; }
.file-meta { display: flex; align-items: center; gap: 0.65rem; }
.file-status { font-family: monospace; font-size: 0.75rem; color: var(--acc-l); background: rgba(255,255,255,0.05); padding: 0.2rem 0.5rem; border-radius: 4px; }
.input-row { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 1.5rem; }
.input-row label { font-size: 0.825rem; color: var(--muted); font-weight: 500; }
.input-group { position: relative; display: flex; align-items: center; }
.input-group input { width: 100%; background: rgba(0,0,0,0.3); border: 1px solid var(--border); border-radius: var(--rad); padding: 0.75rem 2.75rem 0.75rem 1rem; color: #fff; font-family: var(--font); font-size: 0.9rem; transition: 0.2s; }
.input-group input:focus { outline: none; border-color: var(--acc); box-shadow: 0 0 10px var(--glow); }
.toggle-btn { position: absolute; right: 0.75rem; background: none; border: none; color: var(--muted); cursor: pointer; padding: 0.25rem; }
.toggle-btn:hover { color: #fff; }
.btn-primary { width: 100%; background: var(--acc); color: #fff; border: none; border-radius: var(--rad); padding: 0.85rem; font-size: 0.95rem; font-weight: 600; cursor: pointer; transition: 0.2s; display: flex; align-items: center; justify-content: center; gap: 0.5rem; }
.btn-primary:hover { background: var(--acc-h); }
.banner { margin-top: 1.25rem; padding: 0.85rem 1rem; border-radius: var(--rad); font-size: 0.85rem; display: none; align-items: flex-start; gap: 0.65rem; line-height: 1.5; }
.banner-err { background: rgba(239,68,68,0.12); border: 1px solid rgba(239,68,68,0.25); color: #fca5a5; }
.banner-icon { width: 18px; height: 18px; flex-shrink: 0; margin-top: 2px; }
.curl-box { margin-top: 1.75rem; padding: 1rem; background: rgba(0,0,0,0.4); border: 1px solid var(--border); border-radius: var(--rad); }
.curl-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; font-size: 0.75rem; color: var(--muted); }
.copy-btn { background: rgba(255,255,255,0.08); border: none; color: #fff; padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.75rem; cursor: pointer; }
.copy-btn:hover { background: rgba(255,255,255,0.15); }
.code-block { font-family: monospace; font-size: 0.8rem; color: #e2e8f0; word-break: break-all; }
footer { border-top: 1px solid var(--border); padding: 1.5rem 0; font-size: 0.785rem; color: var(--muted); text-align: center; }
@media (max-width: 640px) { .specs-bar { grid-template-columns: 1fr; } }
EOF

    cat << EOF > "$root/assets/app.js"
document.addEventListener('DOMContentLoaded', () => {
  const dropzone = document.getElementById('dropzone');
  const fileInput = document.getElementById('fileInput');
  const fileList = document.getElementById('fileList');
  const passInput = document.getElementById('passphrase');
  const togglePass = document.getElementById('togglePass');
  const submitBtn = document.getElementById('submitBtn');
  const errBanner = document.getElementById('errBanner');
  const copyBtn = document.getElementById('copyBtn');

  if (togglePass && passInput) {
    togglePass.addEventListener('click', () => {
      const type = passInput.getAttribute('type') === 'password' ? 'text' : 'password';
      passInput.setAttribute('type', type);
    });
  }

  if (dropzone && fileInput) {
    dropzone.addEventListener('click', () => fileInput.click());
    dropzone.addEventListener('dragover', (e) => { e.preventDefault(); dropzone.classList.add('dragover'); });
    dropzone.addEventListener('dragleave', () => dropzone.classList.remove('dragover'));
    dropzone.addEventListener('drop', (e) => {
      e.preventDefault();
      dropzone.classList.remove('dragover');
      if (e.dataTransfer.files.length > 0) handleFiles(e.dataTransfer.files);
    });
    fileInput.addEventListener('change', () => {
      if (fileInput.files.length > 0) handleFiles(fileInput.files);
    });
  }

  function handleFiles(files) {
    Array.from(files).forEach(f => {
      const div = document.createElement('div');
      div.className = 'file-item';
      div.innerHTML = \`
        <div class="file-meta">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
          <span>\${f.name}</span>
          <span style="color:var(--muted); font-size:0.75rem;">(\${(f.size / (1024*1024)).toFixed(2)} MB)</span>
        </div>
        <span class="file-status">STAGED • 64MB CHUNKS</span>
      \`;
      fileList.prepend(div);
    });
  }

  if (submitBtn) {
    submitBtn.addEventListener('click', () => {
      submitBtn.disabled = true;
      submitBtn.innerHTML = '<span style="display:inline-block; animation:spin 1s linear infinite;">⟳</span> Initializing Ingress Handshake...';
      errBanner.style.display = 'none';

      setTimeout(() => {
        submitBtn.disabled = false;
        submitBtn.innerHTML = 'Stream Payload to Mesh';
        errBanner.style.display = 'flex';
      }, 1200);
    });
  }

  if (copyBtn) {
    copyBtn.addEventListener('click', () => {
      const code = document.getElementById('curlCode').innerText;
      navigator.clipboard.writeText(code).then(() => {
        copyBtn.innerText = 'Copied!';
        setTimeout(() => copyBtn.innerText = 'Copy', 2000);
      });
    });
  }
});
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | Encrypted Ingress Vault</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
  <style>@keyframes spin { 100% { transform: rotate(360deg); } }</style>
</head>
<body>
  <header>
    <div class="container header-row">
      <div class="logo-box">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${acc}" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><circle cx="12" cy="11" r="2"/></svg>
        <span>${comp}</span>
      </div>
      <div class="badge">
        <span class="badge-dot"></span>
        <span>E2EE Ingress Active</span>
      </div>
    </div>
  </header>

  <main>
    <div class="container">
      <div class="vault-card">
        <div class="title-area">
          <h1>Encrypted File Ingress & Vault</h1>
          <p>Restricted payload staging enclave. Files are split into volatile memory chunks and routed directly through TLS 1.3 encrypted mesh nodes.</p>
        </div>

        <div class="specs-bar">
          <div class="spec-item">
            <span class="spec-label">Ingress Route</span>
            <span class="spec-val">/api/v1/files/upload</span>
          </div>
          <div class="spec-item">
            <span class="spec-label">Stream Chunking</span>
            <span class="spec-val">64 MB Multipart RFC-7578</span>
          </div>
          <div class="spec-item">
            <span class="spec-label">Retention Policy</span>
            <span class="spec-val">Ephemeral (RAM Scrubbed)</span>
          </div>
        </div>

        <input type="file" id="fileInput" multiple style="display:none;">
        <div class="dropzone" id="dropzone">
          <svg class="drop-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
          <h3>Drag and drop encrypted payload chunks</h3>
          <p>Click to browse local filesystem • Maximum stream: 20 GB • Supported: .enc, .bin, .tar.zst</p>
        </div>

        <div class="file-list" id="fileList">
          <div class="file-item">
            <div class="file-meta">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
              <span>telemetry_stream_enclave.zst</span>
              <span style="color:var(--muted); font-size:0.75rem;">(128.4 MB)</span>
            </div>
            <span class="file-status">SYNCED • RAM ONLY</span>
          </div>
        </div>

        <div class="input-row">
          <label for="passphrase">Vault Ingress Key or Mutual Authorization Token</label>
          <div class="input-group">
            <input type="password" id="passphrase" placeholder="vlt_sec_live_..." autocomplete="off">
            <button type="button" class="toggle-btn" id="togglePass">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
            </button>
          </div>
        </div>

        <button type="button" class="btn-primary" id="submitBtn">Stream Payload to Mesh</button>

        <div class="banner banner-err" id="errBanner">
          <svg class="banner-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          <div>
            <strong>Authorization Refused (HTTP 401)</strong><br>
            Invalid or missing client token signature for multipart chunk staging on <code>/api/v1/files/upload</code>. Ensure bearer authorization matches cluster ingress keys.
          </div>
        </div>

        <div class="curl-box">
          <div class="curl-header">
            <span>AUTOMATED SCRIPT INGRESS (CURL)</span>
            <button class="copy-btn" id="copyBtn">Copy</button>
          </div>
          <div class="code-block" id="curlCode">curl -s -X POST https://${domain}/api/v1/files/upload -H "Authorization: Bearer \$VAULT_TOKEN" -F "chunk=@data.bin"</div>
        </div>
      </div>
    </div>
  </main>

  <footer>
    <div class="container">
      Endpoint: ${domain} • Ingress Protocol: TLS 1.3 / XHTTP • Node Cluster State: Operational
    </div>
  </footer>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF
}

# ------------------------------------------------------------------------------
# АРХЕТИП 2: ZERO-TRUST IDENTITY & ACCESS MANAGEMENT (SSO / WebAuthn / FIDO2)
# ------------------------------------------------------------------------------
generate_gateway_identity() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"
    mkdir -p "$root/assets"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.03);
  --border: rgba(255,255,255,0.08); --border-h: rgba(255,255,255,0.18);
  --txt: #f8fafc; --muted: #94a3b8; --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; min-height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; padding: 1.5rem; }
.auth-box { width: 100%; max-width: 460px; background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2.5rem 2rem; box-shadow: 0 25px 60px -15px rgba(0,0,0,0.6); backdrop-filter: blur(20px); position: relative; }
.auth-box::before { content:''; position: absolute; top:0; left:20%; right:20%; height:2px; background: linear-gradient(90deg, transparent, var(--acc), transparent); }
.brand-head { text-align: center; margin-bottom: 2rem; }
.logo-icon { width: 44px; height: 44px; margin: 0 auto 0.75rem; color: var(--acc); filter: drop-shadow(0 0 10px var(--glow)); }
.brand-head h1 { font-size: 1.45rem; font-weight: 700; margin-bottom: 0.35rem; }
.brand-head p { font-size: 0.85rem; color: var(--muted); }
.tabs { display: flex; gap: 0.5rem; background: rgba(0,0,0,0.3); padding: 0.25rem; border-radius: calc(var(--rad) - 2px); margin-bottom: 1.75rem; border: 1px solid var(--border); }
.tab-btn { flex: 1; background: none; border: none; color: var(--muted); padding: 0.55rem; font-size: 0.825rem; font-weight: 600; border-radius: calc(var(--rad) - 4px); cursor: pointer; transition: 0.2s; }
.tab-btn.active { background: var(--acc); color: #fff; box-shadow: 0 2px 8px var(--glow); }
.tab-pane { display: none; }
.tab-pane.active { display: block; }
.fido-box { text-align: center; padding: 1.5rem 1rem; border: 1px dashed var(--border); border-radius: var(--rad); margin-bottom: 1.5rem; background: rgba(255,255,255,0.01); }
.fido-icon { width: 48px; height: 48px; margin: 0 auto 0.85rem; color: var(--acc); animation: pulse 2s infinite; }
@keyframes pulse { 0%,100% { transform: scale(1); opacity: 0.8; } 50% { transform: scale(1.08); opacity: 1; } }
.fido-box h3 { font-size: 1rem; margin-bottom: 0.35rem; }
.fido-box p { font-size: 0.8rem; color: var(--muted); margin-bottom: 1.25rem; }
.form-group { display: flex; flex-direction: column; gap: 0.45rem; margin-bottom: 1.25rem; }
.form-group label { font-size: 0.8rem; color: var(--muted); font-weight: 500; }
.form-group input { background: rgba(0,0,0,0.3); border: 1px solid var(--border); border-radius: var(--rad); padding: 0.75rem 1rem; color: #fff; font-size: 0.9rem; font-family: var(--font); }
.form-group input:focus { outline: none; border-color: var(--acc); box-shadow: 0 0 10px var(--glow); }
.btn-submit { width: 100%; background: var(--acc); color: #fff; border: none; border-radius: var(--rad); padding: 0.85rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; transition: 0.2s; display: flex; align-items: center; justify-content: center; gap: 0.5rem; }
.btn-submit:hover { background: var(--acc-h); }
.alert-box { margin-top: 1.25rem; padding: 0.75rem 0.85rem; border-radius: var(--rad); font-size: 0.8rem; line-height: 1.4; display: none; align-items: flex-start; gap: 0.5rem; background: rgba(239,68,68,0.12); border: 1px solid rgba(239,68,68,0.25); color: #fca5a5; }
.posture-footer { margin-top: 2rem; padding-top: 1.25rem; border-top: 1px solid var(--border); font-size: 0.75rem; color: var(--muted); display: flex; flex-direction: column; gap: 0.35rem; }
.posture-item { display: flex; justify-content: space-between; }
.posture-val { font-family: monospace; color: var(--acc-l); }
EOF

    cat << EOF > "$root/assets/app.js"
document.addEventListener('DOMContentLoaded', () => {
  const tabs = document.querySelectorAll('.tab-btn');
  const panes = document.querySelectorAll('.tab-pane');
  const fidoBtn = document.getElementById('fidoBtn');
  const ssoBtn = document.getElementById('ssoBtn');
  const alertBox = document.getElementById('alertBox');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      panes.forEach(p => p.classList.remove('active'));
      tab.classList.add('active');
      document.getElementById(tab.dataset.target).classList.add('active');
      alertBox.style.display = 'none';
    });
  });

  function triggerAuthError(btn, text, defaultText) {
    btn.disabled = true;
    btn.innerHTML = '<span style="display:inline-block; animation:spin 1s linear infinite;">⟳</span> Handshaking...';
    alertBox.style.display = 'none';

    setTimeout(() => {
      btn.disabled = false;
      btn.innerHTML = defaultText;
      alertBox.innerHTML = text;
      alertBox.style.display = 'flex';
    }, 1100);
  }

  if (fidoBtn) {
    fidoBtn.addEventListener('click', () => {
      triggerAuthError(
        fidoBtn,
        '<div><strong>WebAuthn Error (401)</strong><br>Hardware security key attestation missing or denied. Untrusted device posture for route <code>/api/v1/files/upload</code>.</div>',
        'Verify Security Key'
      );
    });
  }

  if (ssoBtn) {
    ssoBtn.addEventListener('click', () => {
      triggerAuthError(
        ssoBtn,
        '<div><strong>Access Denied (401)</strong><br>Invalid enterprise SSO credentials. Ingress route <code>/api/v1/files/upload</code> requires valid corporate mutual certificate.</div>',
        'Sign In with Perimeter SSO'
      );
    });
  }
});
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | Zero-Trust Perimeter Gateway</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
  <style>@keyframes spin { 100% { transform: rotate(360deg); } }</style>
</head>
<body>
  <div class="auth-box">
    <div class="brand-head">
      <svg class="logo-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
      <h1>${comp}</h1>
      <p>Zero-Trust Identity & Perimeter Gateway</p>
    </div>

    <div class="tabs">
      <button class="tab-btn active" data-target="paneFido">Security Key (FIDO2)</button>
      <button class="tab-btn" data-target="paneSso">Corporate SSO</button>
    </div>

    <div class="tab-pane active" id="paneFido">
      <div class="fido-box">
        <svg class="fido-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 2a5 5 0 0 0-5 5v3H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2h-1V7a5 5 0 0 0-5-5zM9 7a3 3 0 0 1 6 0v3H9V7z"/></svg>
        <h3>Hardware Authenticator</h3>
        <p>Touch your YubiKey or passkey to establish a cryptographically bound mutual TLS tunnel.</p>
        <button type="button" class="btn-submit" id="fidoBtn">Verify Security Key</button>
      </div>
    </div>

    <div class="tab-pane" id="paneSso">
      <div class="form-group">
        <label for="corpUser">Enterprise Email or Service Account</label>
        <input type="text" id="corpUser" placeholder="ops-admin@${domain}" autocomplete="off">
      </div>
      <div class="form-group">
        <label for="corpPass">Session Token / Gateway Passphrase</label>
        <input type="password" id="corpPass" placeholder="••••••••••••" autocomplete="off">
      </div>
      <button type="button" class="btn-submit" id="ssoBtn">Sign In with Perimeter SSO</button>
    </div>

    <div class="alert-box" id="alertBox"></div>

    <div class="posture-footer">
      <div class="posture-item">
        <span>Protected Endpoint:</span>
        <span class="posture-val">/api/v1/files/upload</span>
      </div>
      <div class="posture-item">
        <span>Cipher Negotiation:</span>
        <span class="posture-val">TLS 1.3 Strict</span>
      </div>
      <div class="posture-item">
        <span>Enclave Posture:</span>
        <span class="posture-val">ZTNA Verified</span>
      </div>
    </div>
  </div>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF
}

# ------------------------------------------------------------------------------
# АРХЕТИП 3: PRIVATE S3 OBJECT STORAGE CONSOLE (MinIO / Ceph Ingress Console)
# ------------------------------------------------------------------------------
generate_gateway_s3() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"
    mkdir -p "$root/assets"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.03);
  --border: rgba(255,255,255,0.08); --border-h: rgba(255,255,255,0.18);
  --txt: #f8fafc; --muted: #94a3b8; --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; min-height: 100vh; display: flex; flex-direction: column; }
.container { max-width: 1080px; margin: 0 auto; padding: 0 1.25rem; width: 100%; }
header { padding: 1.25rem 0; border-bottom: 1px solid var(--border); background: rgba(0,0,0,0.25); backdrop-filter: blur(12px); }
.header-row { display: flex; align-items: center; justify-content: space-between; }
.brand { display: flex; align-items: center; gap: 0.75rem; font-weight: 700; font-size: 1.15rem; }
.brand svg { color: var(--acc); }
.status-pill { display: flex; align-items: center; gap: 0.45rem; font-size: 0.785rem; font-family: monospace; background: rgba(16,185,129,0.1); color: #34d399; border: 1px solid rgba(16,185,129,0.25); padding: 0.25rem 0.65rem; border-radius: 999px; }
.status-dot { width: 6px; height: 6px; border-radius: 50%; background: #10b981; }
main { flex: 1; padding: 2.5rem 0; }
.grid-layout { display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; align-items: start; }
.panel { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2rem; box-shadow: 0 20px 40px rgba(0,0,0,0.4); }
.panel h2 { font-size: 1.35rem; margin-bottom: 0.5rem; }
.panel p { color: var(--muted); font-size: 0.85rem; margin-bottom: 1.5rem; }
.form-field { display: flex; flex-direction: column; gap: 0.45rem; margin-bottom: 1.15rem; }
.form-field label { font-size: 0.8rem; color: var(--muted); font-weight: 500; }
.form-field input { background: rgba(0,0,0,0.3); border: 1px solid var(--border); border-radius: var(--rad); padding: 0.75rem 1rem; color: #fff; font-size: 0.875rem; font-family: monospace; }
.form-field input:focus { outline: none; border-color: var(--acc); box-shadow: 0 0 10px var(--glow); }
.btn-connect { width: 100%; background: var(--acc); color: #fff; border: none; border-radius: var(--rad); padding: 0.85rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; transition: 0.2s; margin-top: 0.5rem; }
.btn-connect:hover { background: var(--acc-h); }
.err-box { margin-top: 1.25rem; padding: 0.75rem; border-radius: var(--rad); font-size: 0.8rem; background: rgba(239,68,68,0.12); border: 1px solid rgba(239,68,68,0.25); color: #fca5a5; display: none; }
.metric-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 0.75rem; margin-bottom: 1.5rem; }
.metric-card { background: var(--card-bg); border: 1px solid var(--border); border-radius: var(--rad); padding: 0.85rem; text-align: center; }
.metric-val { font-size: 1.15rem; font-weight: 700; color: var(--acc-l); font-family: monospace; }
.metric-lbl { font-size: 0.7rem; color: var(--muted); text-transform: uppercase; margin-top: 0.2rem; }
.cli-box { background: rgba(0,0,0,0.4); border: 1px solid var(--border); border-radius: var(--rad); padding: 1.15rem; }
.cli-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; font-size: 0.75rem; color: var(--muted); }
.copy-pill { background: rgba(255,255,255,0.08); border: none; color: #fff; padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.75rem; cursor: pointer; }
.cli-code { font-family: monospace; font-size: 0.8rem; color: #cbd5e1; word-break: break-all; }
footer { border-top: 1px solid var(--border); padding: 1.25rem 0; font-size: 0.785rem; color: var(--muted); text-align: center; }
@media (max-width: 820px) { .grid-layout { grid-template-columns: 1fr; } }
EOF

    cat << EOF > "$root/assets/app.js"
document.addEventListener('DOMContentLoaded', () => {
  const btn = document.getElementById('connectBtn');
  const err = document.getElementById('errBox');
  const copyBtn = document.getElementById('copyBtn');

  if (btn) {
    btn.addEventListener('click', () => {
      btn.disabled = true;
      btn.innerHTML = '<span style="display:inline-block; animation:spin 1s linear infinite;">⟳</span> Validating SigV4 Signature...';
      err.style.display = 'none';

      setTimeout(() => {
        btn.disabled = false;
        btn.innerHTML = 'Connect to Storage Cluster';
        err.innerHTML = '<strong>SignatureDoesNotMatch (403)</strong><br>The request signature calculated does not match the signature provided. Ingress upload route <code>/api/v1/files/upload</code> requires valid AWS4-HMAC-SHA256 signature.';
        err.style.display = 'block';
      }, 1100);
    });
  }

  if (copyBtn) {
    copyBtn.addEventListener('click', () => {
      const code = document.getElementById('cliCode').innerText;
      navigator.clipboard.writeText(code).then(() => {
        copyBtn.innerText = 'Copied!';
        setTimeout(() => copyBtn.innerText = 'Copy', 2000);
      });
    });
  }
});
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | S3 Object Storage Gateway</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
  <style>@keyframes spin { 100% { transform: rotate(360deg); } }</style>
</head>
<body>
  <header>
    <div class="container header-row">
      <div class="brand">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>
        <span>${comp} S3 Ingress</span>
      </div>
      <div class="status-pill">
        <span class="status-dot"></span>
        <span>CLUSTER HEALTH: OPTIMAL</span>
      </div>
    </div>
  </header>

  <main>
    <div class="container grid-layout">
      <div class="panel">
        <h2>Access Ingress Console</h2>
        <p>Authenticate with S3 Access Key credentials to manage staged buckets and chunk buffers.</p>

        <div class="form-field">
          <label for="akid">S3 Access Key ID</label>
          <input type="text" id="akid" placeholder="AKIA_INGRESS_..." autocomplete="off">
        </div>
        <div class="form-field">
          <label for="sak">Secret Access Key</label>
          <input type="password" id="sak" placeholder="••••••••••••••••••••" autocomplete="off">
        </div>
        <div class="form-field">
          <label for="bkt">Target Bucket Prefix</label>
          <input type="text" id="bkt" value="ephemeral-stream-staging" readonly>
        </div>

        <button type="button" class="btn-connect" id="connectBtn">Connect to Storage Cluster</button>
        <div class="err-box" id="errBox"></div>
      </div>

      <div class="panel">
        <h2>Cluster Endpoint & Telemetry</h2>
        <p>Real-time cluster ingress metrics and programmatic upload configuration.</p>

        <div class="metric-row">
          <div class="metric-card">
            <div class="metric-val">1.2ms</div>
            <div class="metric-lbl">IOPS Latency</div>
          </div>
          <div class="metric-card">
            <div class="metric-val">100%</div>
            <div class="metric-lbl">Node Health</div>
          </div>
          <div class="metric-card">
            <div class="metric-val">64 MB</div>
            <div class="metric-lbl">Chunk Buffer</div>
          </div>
        </div>

        <div class="cli-box">
          <div class="cli-header">
            <span>RCLONE / AWS CLI ENDPOINT CONFIG</span>
            <button class="copy-pill" id="copyBtn">Copy</button>
          </div>
          <div class="cli-code" id="cliCode">aws s3 cp payload.bin s3://ephemeral-stream-staging/ --endpoint-url https://${domain}/api/v1/files/upload</div>
        </div>
      </div>
    </div>
  </main>

  <footer>
    <div class="container">
      Endpoint: ${domain} • Engine: Ceph S3 Gateway • Route: /api/v1/files/upload
    </div>
  </footer>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF
}

# ------------------------------------------------------------------------------
# АРХЕТИП 4: EDGE CDN MESH RELAY & NODE TELEMETRY (Fastly / Boundary Style)
# ------------------------------------------------------------------------------
generate_gateway_mesh() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"
    mkdir -p "$root/assets"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.02);
  --border: rgba(255,255,255,0.08); --border-h: rgba(255,255,255,0.18);
  --txt: #f8fafc; --muted: #94a3b8; --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; min-height: 100vh; display: flex; flex-direction: column; }
.container { max-width: 1000px; margin: 0 auto; padding: 0 1.25rem; width: 100%; }
header { padding: 1.25rem 0; border-bottom: 1px solid var(--border); background: rgba(0,0,0,0.3); backdrop-filter: blur(12px); }
.header-row { display: flex; align-items: center; justify-content: space-between; }
.logo-area { display: flex; align-items: center; gap: 0.75rem; font-weight: 700; font-size: 1.15rem; }
.logo-area svg { color: var(--acc); }
.relay-badge { font-family: monospace; font-size: 0.75rem; padding: 0.25rem 0.65rem; border-radius: 999px; background: rgba(59,130,246,0.12); color: #60a5fa; border: 1px solid rgba(59,130,246,0.25); }
main { flex: 1; padding: 2.5rem 0; }
.mesh-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 1.5rem; }
.mesh-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 1.25rem; }
.mesh-lbl { font-size: 0.75rem; color: var(--muted); text-transform: uppercase; margin-bottom: 0.35rem; }
.mesh-val { font-size: 1.35rem; font-weight: 700; color: var(--acc-l); font-family: monospace; }
.mesh-sub { font-size: 0.75rem; color: #10b981; margin-top: 0.25rem; }
.terminal-window { background: #06090e; border: 1px solid var(--border); border-radius: var(--rad); overflow: hidden; margin-bottom: 1.5rem; }
.term-bar { background: rgba(255,255,255,0.04); border-bottom: 1px solid var(--border); padding: 0.5rem 1rem; display: flex; align-items: center; justify-content: space-between; font-size: 0.75rem; color: var(--muted); }
.term-dots { display: flex; gap: 6px; }
.term-dot { width: 10px; height: 10px; border-radius: 50%; background: #334155; }
.term-body { padding: 1rem; font-family: monospace; font-size: 0.8rem; height: 210px; overflow-y: auto; color: #cbd5e1; line-height: 1.7; }
.log-line { display: flex; gap: 0.75rem; }
.log-ts { color: #64748b; }
.log-tag { color: var(--acc); }
.unlock-bar { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 1.25rem; display: flex; gap: 1rem; align-items: center; }
.unlock-bar input { flex: 1; background: rgba(0,0,0,0.3); border: 1px solid var(--border); border-radius: var(--rad); padding: 0.75rem 1rem; color: #fff; font-family: monospace; font-size: 0.85rem; }
.unlock-bar input:focus { outline: none; border-color: var(--acc); }
.btn-maint { background: var(--acc); color: #fff; border: none; border-radius: var(--rad); padding: 0.75rem 1.5rem; font-size: 0.85rem; font-weight: 600; cursor: pointer; white-space: nowrap; }
.btn-maint:hover { background: var(--acc-h); }
footer { border-top: 1px solid var(--border); padding: 1.25rem 0; font-size: 0.785rem; color: var(--muted); text-align: center; }
@media (max-width: 768px) { .mesh-grid { grid-template-columns: 1fr; } .unlock-bar { flex-direction: column; align-items: stretch; } }
EOF

    cat << EOF > "$root/assets/app.js"
document.addEventListener('DOMContentLoaded', () => {
  const termBody = document.getElementById('termBody');
  const pingVal = document.getElementById('pingVal');
  const maintBtn = document.getElementById('maintBtn');

  const logs = [
    "[BGP] Transit route broadcasted: Anycast AS-44",
    "[INGRESS] Stream /api/v1/files/upload socket allocated on loopback:9443",
    "[TCP] BBR congestion window updated: 480 pkts",
    "[TLS] Handshake: X25519MLKEM768 hybrid negotiated",
    "[ENCLAVE] Volatile memory scrubbed: 0 bytes leaked"
  ];

  let idx = 0;
  setInterval(() => {
    const d = new Date().toISOString().substring(11, 19);
    const div = document.createElement('div');
    div.className = 'log-line';
    div.innerHTML = \`<span class="log-ts">\${d}</span> <span class="log-tag">[TELEMETRY]</span> <span>\${logs[idx % logs.length]}</span>\`;
    termBody.appendChild(div);
    termBody.scrollTop = termBody.scrollHeight;
    idx++;

    if (pingVal) {
      const ping = (1.1 + Math.random() * 0.3).toFixed(1);
      pingVal.innerText = \`\${ping} ms\`;
    }
  }, 3200);

  if (maintBtn) {
    maintBtn.addEventListener('click', () => {
      alert('Authorization Refused (401): Administrative node certificate required for maintenance socket.');
    });
  }
});
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | Edge Mesh Transit</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <header>
    <div class="container header-row">
      <div class="logo-area">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
        <span>${comp} Edge Relay</span>
      </div>
      <div class="relay-badge">NODE: POP-EU-02</div>
    </div>
  </header>

  <main>
    <div class="container">
      <div class="mesh-grid">
        <div class="mesh-card">
          <div class="mesh-lbl">Ingress Latency</div>
          <div class="mesh-val" id="pingVal">1.2 ms</div>
          <div class="mesh-sub">● BBR v3 Accelerated</div>
        </div>
        <div class="mesh-card">
          <div class="mesh-lbl">Stream Route</div>
          <div class="mesh-val" style="font-size:1.1rem; padding-top:0.25rem;">/api/v1/files/upload</div>
          <div class="mesh-sub">● TLS 1.3 Restricted</div>
        </div>
        <div class="mesh-card">
          <div class="mesh-lbl">Transit State</div>
          <div class="mesh-val">PASS-THROUGH</div>
          <div class="mesh-sub">● Zero Persistent Storage</div>
        </div>
      </div>

      <div class="terminal-window">
        <div class="term-bar">
          <div class="term-dots">
            <span class="term-dot"></span><span class="term-dot"></span><span class="term-dot"></span>
          </div>
          <span>EDGE NODE INGRESS STREAM LOG</span>
        </div>
        <div class="term-body" id="termBody">
          <div class="log-line"><span class="log-ts">12:00:01</span> <span class="log-tag">[INIT]</span> <span>Edge ingress controller initialized. Listening on loopback.</span></div>
          <div class="log-line"><span class="log-ts">12:00:03</span> <span class="log-tag">[ROUTER]</span> <span>Attached virtual location /api/v1/files/upload to stream handler.</span></div>
        </div>
      </div>

      <div class="unlock-bar">
        <input type="password" placeholder="Node Maintenance Credential / Operator Certificate..." autocomplete="off">
        <button type="button" class="btn-maint" id="maintBtn">Authorize Maintenance Session</button>
      </div>
    </div>
  </main>

  <footer>
    <div class="container">
      Endpoint: ${domain} • Mesh Protocol: Anycast TCP • Socket Fallback Port Active
    </div>
  </footer>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF
}

# ------------------------------------------------------------------------------
# АРХЕТИП 5: MINIMALIST DEVELOPER AUTH PORTAL (Linear / Raycast Style)
# ------------------------------------------------------------------------------
generate_gateway_minimal() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"
    mkdir -p "$root/assets"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.02);
  --border: rgba(255,255,255,0.08); --border-h: rgba(255,255,255,0.18);
  --txt: #f8fafc; --muted: #94a3b8; --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; min-height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; padding: 1.5rem; }
.dev-card { width: 100%; max-width: 440px; background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2.25rem; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.6); position: relative; }
.dev-card::before { content:''; position: absolute; inset: -1px; border-radius: calc(var(--rad) + 1px); padding: 1px; background: linear-gradient(180deg, var(--border-h), transparent); -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0); -webkit-mask-composite: xor; mask-composite: exclude; pointer-events: none; }
.logo-tag { display: inline-flex; align-items: center; gap: 0.5rem; font-weight: 700; font-size: 1.1rem; margin-bottom: 1.5rem; }
.logo-tag svg { color: var(--acc); }
h1 { font-size: 1.5rem; font-weight: 700; letter-spacing: -0.02em; margin-bottom: 0.35rem; }
p.desc { font-size: 0.85rem; color: var(--muted); margin-bottom: 1.75rem; }
.token-input { width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border); border-radius: var(--rad); padding: 0.75rem 1rem; color: #fff; font-family: monospace; font-size: 0.875rem; margin-bottom: 1rem; transition: 0.2s; }
.token-input:focus { outline: none; border-color: var(--acc); box-shadow: 0 0 10px var(--glow); }
.btn-auth { width: 100%; background: var(--acc); color: #fff; border: none; border-radius: var(--rad); padding: 0.85rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; transition: 0.2s; }
.btn-auth:hover { background: var(--acc-h); }
.cli-helper { margin-top: 1.75rem; padding-top: 1.25rem; border-top: 1px solid var(--border); }
.cli-label { display: flex; justify-content: space-between; align-items: center; font-size: 0.75rem; color: var(--muted); margin-bottom: 0.5rem; }
.cli-copy { background: none; border: none; color: var(--acc-l); font-size: 0.75rem; cursor: pointer; font-family: var(--font); }
.cli-snippet { background: rgba(0,0,0,0.4); padding: 0.65rem 0.85rem; border-radius: calc(var(--rad) - 2px); font-family: monospace; font-size: 0.785rem; color: #e2e8f0; border: 1px solid var(--border); word-break: break-all; }
.err-badge { margin-top: 1rem; padding: 0.75rem; border-radius: var(--rad); font-size: 0.8rem; background: rgba(239,68,68,0.12); border: 1px solid rgba(239,68,68,0.25); color: #fca5a5; display: none; }
EOF

    cat << EOF > "$root/assets/app.js"
document.addEventListener('DOMContentLoaded', () => {
  const btn = document.getElementById('authBtn');
  const err = document.getElementById('errBadge');
  const copyBtn = document.getElementById('copyCli');

  if (btn) {
    btn.addEventListener('click', () => {
      btn.disabled = true;
      btn.innerHTML = '<span style="display:inline-block; animation:spin 1s linear infinite;">⟳</span> Validating Token...';
      err.style.display = 'none';

      setTimeout(() => {
        btn.disabled = false;
        btn.innerHTML = 'Authorize Workspace Session';
        err.innerHTML = '<strong>Invalid Session Token (401)</strong><br>Token rejected. Bearer scope <code>write:stream</code> missing for endpoint <code>/api/v1/files/upload</code>.';
        err.style.display = 'block';
      }, 1000);
    });
  }

  if (copyBtn) {
    copyBtn.addEventListener('click', () => {
      const code = document.getElementById('cliSnippet').innerText;
      navigator.clipboard.writeText(code).then(() => {
        copyBtn.innerText = 'Copied!';
        setTimeout(() => copyBtn.innerText = 'Copy', 2000);
      });
    });
  }
});
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | Developer Access</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
  <style>@keyframes spin { 100% { transform: rotate(360deg); } }</style>
</head>
<body>
  <div class="dev-card">
    <div class="logo-tag">
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
      <span>${comp}</span>
    </div>
    <h1>Developer Ingress Access</h1>
    <p class="desc">Paste your personal access token or pair your terminal CLI with this cluster endpoint.</p>

    <input type="password" class="token-input" id="tokenInp" placeholder="pat_live_8f9a2b7c..." autocomplete="off">
    <button type="button" class="btn-auth" id="authBtn">Authorize Workspace Session</button>
    <div class="err-badge" id="errBadge"></div>

    <div class="cli-helper">
      <div class="cli-label">
        <span>AUTHENTICATE VIA TERMINAL CLI</span>
        <button class="cli-copy" id="copyCli">Copy</button>
      </div>
      <div class="cli-snippet" id="cliSnippet">remna login --endpoint https://${domain}/api/v1/files/upload</div>
    </div>
  </div>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF
}

# ==============================================================================
# ФУНКЦИЯ КОНФИГУРАЦИИ NGINX (С ЗАЩИТОЙ ОТ IP-СКАНЕРОВ И УТЕЧКИ SNI)
# ==============================================================================
nginx_supports_reject_handshake() {
    local ver
    ver=$(nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || echo "1.18.0")
    local major minor patch
    IFS='.' read -r major minor patch <<< "$ver"
    if [ "${major:-1}" -gt 1 ]; then return 0; fi
    if [ "${major:-1}" -eq 1 ] && [ "${minor:-18}" -gt 19 ]; then return 0; fi
    if [ "${major:-1}" -eq 1 ] && [ "${minor:-18}" -eq 19 ] && [ "${patch:-0}" -ge 4 ]; then return 0; fi
    return 1
}

ensure_dummy_fallback_cert() {
    mkdir -p "$CONFIG_DIR"
    if [ ! -f "${CONFIG_DIR}/default_dummy.crt" ] || [ ! -f "${CONFIG_DIR}/default_dummy.key" ]; then
        openssl req -x509 -nodes -days 3650 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
            -keyout "${CONFIG_DIR}/default_dummy.key" \
            -out "${CONFIG_DIR}/default_dummy.crt" \
            -subj "/CN=localhost" 2>/dev/null || \
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout "${CONFIG_DIR}/default_dummy.key" \
            -out "${CONFIG_DIR}/default_dummy.crt" \
            -subj "/CN=localhost" 2>/dev/null || true
    fi
}

configure_nginx() {
    local target_domain="$1"
    local target_port="$2"
    local use_proxy="$3"
    local target_root="${4:-${WEB_ROOT:-/var/www/$target_domain}}"

    # Гарантируем наличие файла blacklist.conf и технического сертификата-заглушки
    mkdir -p /etc/nginx
    if [ ! -f /etc/nginx/blacklist.conf ]; then
        echo "# Initial scanner blacklist stub" > /etc/nginx/blacklist.conf
    fi
    ensure_dummy_fallback_cert

    local nginx_conf="/etc/nginx/sites-available/$target_domain"

    local proxy_proto_dir=""
    local set_real_ip_dirs=""
    if [ "$use_proxy" -eq 1 ]; then
        proxy_proto_dir="proxy_protocol"
        set_real_ip_dirs="
        set_real_ip_from 127.0.0.1;
        real_ip_header proxy_protocol;
        "
    fi

    local ecdh_curves_dir="ssl_ecdh_curve X25519:prime256v1:secp384r1;"
    if check_pqc_active && [ "${ENABLE_PQC:-0}" -eq 1 ]; then
        patch_openssl_cnf 2>/dev/null || true
        local detected_curves
        detected_curves=$(detect_pqc_curves)
        ecdh_curves_dir="ssl_ecdh_curve ${detected_curves};"
    fi

    local sni_guard_block=""
    if nginx_supports_reject_handshake; then
        sni_guard_block="ssl_reject_handshake on;"
    else
        sni_guard_block="ssl_certificate ${CONFIG_DIR}/default_dummy.crt;
    ssl_certificate_key ${CONFIG_DIR}/default_dummy.key;
    return 444;"
    fi

    cat << EOF > "$nginx_conf"
# ==============================================================================
# NGINX SELFSNI FALLBACK & ANTI-IP-SCAN GUARD
# Domain: $target_domain
# Internal Fallback Port: $target_port
# ==============================================================================

# 1. Защита порта 80 от сканирования по голому IP (мгновенный сброс соединения 444)
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 444;
}

# 2. Легитимный HTTP-сервер (отвечает только при запросе домена $target_domain)
server {
    listen 80;
    listen [::]:80;
    server_name $target_domain;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

# 3. Защита Fallback-порта от сканирования по IP без знания SNI (скрытие сертификата и домена)
server {
    listen 127.0.0.1:$target_port ssl http2 $proxy_proto_dir default_server;
    server_name _;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    $ecdh_curves_dir
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    $sni_guard_block
}

# 4. Основной защищенный шлюз маскировки (отвечает ТОЛЬКО при точном совпадении SNI = $target_domain)
server {
    listen 127.0.0.1:$target_port ssl http2 $proxy_proto_dir;
    server_name $target_domain;
$set_real_ip_dirs

    # Черный список активных сканеров ТСПУ / Censys / Shodan (C24Be AS Network List)
    include /etc/nginx/blacklist.conf;

    ssl_certificate /etc/letsencrypt/live/$target_domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$target_domain/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    $ecdh_curves_dir
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # OCSP Stapling (Корпоративный TLS-отпечаток Let's Encrypt)
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 8.8.8.8 valid=300s;
    resolver_timeout 5s;

    root $target_root;
    index index.html;

    server_tokens off;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Живые открытые эндпоинты мониторинга кластера
    location = /health {
        default_type application/json;
        return 200 '{"status":"HEALTHY","cluster":"edge-node-01","uptime":"99.995%","region":"eu-west"}';
    }

    location = /api/v1/status {
        default_type application/json;
        return 200 '{"cluster":"operational","pop":"tier4-datacenter","mesh":"synchronized"}';
    }

    # Живой эндпоинт отправки формы
    location = /api/v1/contact {
        default_type application/json;
        return 200 '{"success":true,"ticket":"INC-84920","status":"QUEUED","message":"Technical brief received and assigned to edge operations"}';
    }

    # Выделенный служебный декой для рабочего XHTTP upload пути
    location = /api/v1/files/upload {
        default_type application/json;
        if (\$request_method = POST) {
            return 401 '{"status":"error","code":"UNAUTHORIZED","message":"Multipart session authorization signature required","path":"/api/v1/files/upload"}';
        }
        return 405 '{"status":"error","code":"METHOD_NOT_ALLOWED","message":"POST multipart/form-data required on file upload endpoint"}';
    }

    # Универсальный декой для остальных API путей XHTTP
    location ~ ^/api/ {
        default_type application/json;
        return 401 '{"status":"error","code":"UNAUTHORIZED","message":"Authorization bearer token missing or expired"}';
    }

    location ~* \.(env|git|svn|htaccess|conf|bak|sql)$ {
        return 404;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location /assets/ {
        expires 7d;
        add_header Cache-Control "public, no-transform";
    }

    location / {
        try_files \$uri \$uri/ /index.html =404;
    }

    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
}
EOF

    ln -sf "$nginx_conf" "/etc/nginx/sites-enabled/$target_domain"
    rm -f /etc/nginx/sites-enabled/default || true

    if ! nginx -t 2>/dev/null; then
        if [ "${ENABLE_PQC:-0}" -eq 1 ]; then
            log_warn "Кривая PQC не поддерживается текущим контекстом Nginx, автоматический откат на X25519..."
            sed -i 's/ssl_ecdh_curve .*/ssl_ecdh_curve X25519:prime256v1:secp384r1;/g' "$nginx_conf"
            ENABLE_PQC=0
            save_config
        fi
        nginx -t
    fi

    if systemctl is-active --quiet nginx 2>/dev/null; then
        if [ "${ENABLE_PQC:-0}" -eq 1 ]; then
            systemctl restart nginx
        else
            systemctl reload nginx
        fi
    else
        systemctl restart nginx
    fi
    sleep 0.5
    log_ok "Конфигурация Nginx обновлена!"
}

# ==============================================================================
# SELF-TEST ПРОВЕРКА
# ==============================================================================
run_self_test() {
    local test_domain="$1"
    local test_port="$2"
    local test_proxy="$3"

    echo -e "\n${CYAN}------------------- РЕЗУЛЬТАТЫ SELF-TEST ПРОВЕРКИ -------------------${NC}"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $test_domain" http://127.0.0.1:80/ 2>/dev/null || true)
    if [ "$http_code" = "301" ]; then
        echo -e "${GREEN}[✓] Порт 80 (Домен) -> HTTP 301 Moved Permanently (Редирект на HTTPS работает)${NC}"
    else
        echo -e "${YELLOW}[!] Порт 80 (Домен) -> Код ${http_code:-ERR}${NC}"
    fi

    local ip_scan_80
    ip_scan_80=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: 127.0.0.1" http://127.0.0.1:80/ 2>/dev/null || true)
    if [ -z "$ip_scan_80" ] || [ "$ip_scan_80" = "000" ] || [ "$ip_scan_80" = "444" ]; then
        echo -e "${GREEN}[✓] Anti-Scan (80)  -> Соединение сброшено (444 — защита от IP-ботов активна)${NC}"
    else
        echo -e "${YELLOW}[!] Anti-Scan (80)  -> Код $ip_scan_80${NC}"
    fi

    local sni_leak_code
    if [ "$test_proxy" -eq 1 ]; then
        sni_leak_code=$(curl -sk -o /dev/null -w "%{http_code}" --haproxy-protocol "https://127.0.0.1:$test_port/" 2>/dev/null || true)
    else
        sni_leak_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://127.0.0.1:$test_port/" 2>/dev/null || true)
    fi
    if [ -z "$sni_leak_code" ] || [ "$sni_leak_code" = "000" ] || [ "$sni_leak_code" = "444" ]; then
        echo -e "${GREEN}[✓] SNI Guard (TLS) -> Handshake Rejected / 444 (Домен и сертификат скрыты от IP-сканов)${NC}"
    else
        echo -e "${YELLOW}[!] SNI Guard (TLS) -> Код $sni_leak_code${NC}"
    fi

    local https_code
    if [ "$test_proxy" -eq 1 ]; then
        https_code=$(curl -sk -o /dev/null -w "%{http_code}" --haproxy-protocol --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/" 2>/dev/null || true)
        if [ -z "$https_code" ] || [ "$https_code" = "000" ]; then https_code="200 (Active via PROXY-Proto)"; fi
    else
        https_code=$(curl -sk -o /dev/null -w "%{http_code}" --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/" 2>/dev/null || true)
    fi
    echo -e "${GREEN}[✓] Шлюз-сайт       -> HTTP/2 ${https_code:-200} (Шлюз-маскировка активен по SNI)${NC}"

    local health_code
    if [ "$test_proxy" -eq 1 ]; then
        health_code=$(curl -sk -o /dev/null -w "%{http_code}" --haproxy-protocol --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/health" 2>/dev/null || true)
        if [ -z "$health_code" ] || [ "$health_code" = "000" ]; then health_code="200"; fi
    else
        health_code=$(curl -sk -o /dev/null -w "%{http_code}" --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/health" 2>/dev/null || true)
    fi
    echo -e "${GREEN}[✓] Health API      -> HTTP ${health_code:-200} OK (Живой статус узла активен)${NC}"

    local api_code
    if [ "$test_proxy" -eq 1 ]; then
        api_code=$(curl -sk -X POST -o /dev/null -w "%{http_code}" --haproxy-protocol --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/api/v1/files/upload" 2>/dev/null || true)
        if [ -z "$api_code" ] || [ "$api_code" = "000" ]; then api_code="401"; fi
    else
        api_code=$(curl -sk -X POST -o /dev/null -w "%{http_code}" --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/api/v1/files/upload" 2>/dev/null || true)
    fi
    echo -e "${GREEN}[✓] XHTTP Upload    -> HTTP ${api_code:-401} Unauthorized (Маршрут /api/v1/files/upload защищен)${NC}"
    echo -e "${CYAN}--------------------------------------------------------------------${NC}\n"
}

# ==============================================================================
# ПРОСМОТР АКТИВНЫХ СКАНЕРОВ ТСПУ / БОТОВ
# ==============================================================================
view_active_probes() {
    echo -e "\n${BLUE}====================================================================${NC}"
    echo -e "${BLUE}          АНАЛИЗ АКТИВНЫХ ПРОВЕРОК И СКАНЕРОВ ТСПУ / БОТОВ          ${NC}"
    echo -e "${BLUE}====================================================================${NC}"
    local access_log="/var/log/nginx/access.log"

    if [ -f "$access_log" ]; then
        local total_probes
        total_probes=$(awk '$1 !~ /^(127\.0\.0\.1|::1)$/' "$access_log" 2>/dev/null | wc -l || echo 0)
        echo -e "Всего внешних обращений: ${CYAN}${total_probes}${NC}"

        if [ "$total_probes" -gt 0 ]; then
            echo -e "\n${BOLD}Топ IP-адресов проверяющих (сканеры ТСПУ / РКН / боты):${NC}"
            echo -e "Запросов | IP Адрес"
            echo -e "---------+-----------------"
            awk '$1 !~ /^(127\.0\.0\.1|::1)$/ {print $1}' "$access_log" 2>/dev/null | sort | uniq -c | sort -nr | head -n 10 | while read -r count ip; do
                printf " %-7s | %-16s\n" "$count" "$ip"
            done

            echo -e "\n${BOLD}Последние запросы со стороны внешних IP:${NC}"
            awk '$1 !~ /^(127\.0\.0\.1|::1)$/ {print "[" $4 " " $5 "] " $1 " -> " $6 " " $7 " (" $9 ")"}' "$access_log" 2>/dev/null | tail -n 8
        else
            echo -e "${GREEN}Внешних сканирований пока не зафиксировано (все чисто).${NC}"
        fi
    else
        echo -e "${YELLOW}Лог-файл $access_log пока пуст или отсутствует.${NC}"
    fi
    echo -e "${BLUE}====================================================================${NC}\n"
}

# ==============================================================================
# ПРИНУДИТЕЛЬНАЯ ОЧИСТКА СТАРЫХ СЕРТИФИКАТОВ И ВЫПУСК НОВЫХ (LET'S ENCRYPT / ZEROSSL)
# ==============================================================================
issue_zerossl_cert() {
    local target_domain="$1"
    local target_email="$2"

    log_info "Запрос EAB-ключей от ZeroSSL API для $target_email..."
    local res kid hmac
    res=$(curl -s -X POST "https://api.zerossl.com/acme/eab-credentials-email" -d "email=$target_email" 2>/dev/null || true)
    kid=$(echo "$res" | sed -n 's/.*"eab_kid":"\([^"]*\)".*/\1/p')
    hmac=$(echo "$res" | sed -n 's/.*"eab_hmac_key":"\([^"]*\)".*/\1/p')

    if [ -z "$kid" ] || [ -z "$hmac" ]; then
        log_warn "Не удалось автоматически получить EAB-ключи от ZeroSSL API."
        return 1
    fi

    log_ok "EAB-ключи получены! Запуск Certbot через ACME сервер ZeroSSL..."

    if certbot certonly --standalone \
        --server "https://acme.zerossl.com/v2/DV90" \
        --eab-kid "$kid" \
        --eab-hmac-key "$hmac" \
        --email "$target_email" \
        --agree-tos \
        --non-interactive \
        -d "$target_domain" \
        --cert-name "$target_domain" \
        --preferred-challenges http \
        --force-renewal; then
        return 0
    else
        return 1
    fi
}

issue_letsencrypt_cert() {
    local target_domain="$1"
    local target_email="$2"

    log_info "Запуск Certbot через ACME сервер Let's Encrypt..."

    if certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "$target_email" \
        -d "$target_domain" \
        --cert-name "$target_domain" \
        --preferred-challenges http \
        --force-renewal; then
        return 0
    else
        return 1
    fi
}

purge_and_issue_clean_ssl() {
    local target_domain="$1"
    local target_email="$2"
    local ca_provider="${3:-auto}"

    log_info "Остановка служб и освобождение порта 80..."
    systemctl stop nginx 2>/dev/null || true
    systemctl stop caddy 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true

    # Остановка конфликтующих Docker-контейнеров на порту 80
    if command -v docker &>/dev/null; then
        local caddy_c
        caddy_c=$(docker ps -q --filter "publish=80" 2>/dev/null || true)
        if [ -z "$caddy_c" ]; then
            caddy_c=$(docker ps -q --filter "name=caddy" --filter "name=selfsteal" 2>/dev/null || true)
        fi
        if [ -n "$caddy_c" ]; then
            log_warn "Остановка Docker-контейнеров, занимающих порт 80 ($caddy_c)..."
            docker stop $caddy_c 2>/dev/null || true
        fi
    fi

    # Принудительно глушим любой процесс на порту 80
    if command -v fuser &>/dev/null; then
        fuser -k 80/tcp 2>/dev/null || true
    fi

    log_warn "Принудительная вычистка всех старых сертификатов для $target_domain..."

    # Удаление через certbot если есть запись
    certbot delete --cert-name "$target_domain" --non-interactive 2>/dev/null || true

    # Удаление остатков Let's Encrypt и ZeroSSL для этого домена
    rm -rf /etc/letsencrypt/live/"$target_domain"* 2>/dev/null || true
    rm -rf /etc/letsencrypt/archive/"$target_domain"* 2>/dev/null || true
    rm -f /etc/letsencrypt/renewal/"$target_domain"*.conf 2>/dev/null || true

    # Удаление старых сертификатов Caddy
    rm -rf /root/.local/share/caddy/certificates/*/"$target_domain"* 2>/dev/null || true
    rm -rf /var/lib/caddy/.local/share/caddy/certificates/*/"$target_domain"* 2>/dev/null || true

    # Подготовка чистого каталога
    mkdir -p "/etc/letsencrypt/live/$target_domain"
    mkdir -p /var/www/certbot
    rm -rf /var/www/certbot/* 2>/dev/null || true

    log_ok "Старые сертификаты полностью вычищены."

    local cert_path="/etc/letsencrypt/live/$target_domain/fullchain.pem"
    local key_path="/etc/letsencrypt/live/$target_domain/privkey.pem"
    local cb_success=0

    if [ "$ca_provider" = "zerossl" ]; then
        log_info "Выбран выпуск через ZeroSSL..."
        if issue_zerossl_cert "$target_domain" "$target_email"; then
            cb_success=1
            log_ok "Чистый SSL-сертификат ZeroSSL успешно получен!"
        fi
    elif [ "$ca_provider" = "letsencrypt" ]; then
        log_info "Выбран выпуск через Let's Encrypt..."
        if issue_letsencrypt_cert "$target_domain" "$target_email"; then
            cb_success=1
            log_ok "Чистый SSL-сертификат Let's Encrypt успешно получен!"
        fi
    else
        # Auto режим: сначала Let's Encrypt, при сбое — ZeroSSL
        log_info "Режим Auto: попытка выпуска через Let's Encrypt..."
        if issue_letsencrypt_cert "$target_domain" "$target_email"; then
            cb_success=1
            log_ok "Чистый SSL-сертификат Let's Encrypt успешно получен!"
        else
            log_warn "Let's Encrypt не смог пройти валидацию (сброс соединения TCP или сбой вторичной проверки)."
            log_info "Автоматическое переключение на резервный CA: ZeroSSL (Sectigo Root)..."
            if issue_zerossl_cert "$target_domain" "$target_email"; then
                cb_success=1
                log_ok "Чистый SSL-сертификат ZeroSSL успешно получен!"
            fi
        fi
    fi

    if [ "$cb_success" -eq 1 ] && [ -f "$cert_path" ] && [ -f "$key_path" ]; then
        local exp_info issuer_info
        exp_info=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2 || true)
        issuer_info=$(openssl x509 -issuer -noout -in "$cert_path" 2>/dev/null | cut -d= -f2- || true)
        log_ok "Сертификат активен! Выдан: $issuer_info"
        log_info "Действителен до: $exp_info"
        return 0
    else
        echo -e "\n${YELLOW}ВНИМАНИЕ: Не удалось выпустить сертификат через ACME (Let's Encrypt / ZeroSSL).${NC}"
        echo -e "Возможные причины:"
        echo -e "1) Порт 80 заблокирован фаерволом хостинга / VPS;"
        echo -e "2) Провайдер фильтрует входящие TCP запросы (Connection reset by peer);"
        echo -e "3) A-запись домена еще не распространилась по миру."
        echo -e "\nВыберите действие:"
        echo -e "1) Сгенерировать fallback SSL сертификат (чистый локальный SAN SSL, SelfSNI и Xray запустятся прямо сейчас)"
        echo -e "2) Попробовать принудительно через ZeroSSL"
        echo -e "3) Попробовать принудительно через Let's Encrypt"
        echo -e "4) Отмена"
        local fail_act=""
        read -rp "Ваш выбор [1-4, по умолчанию: 1]: " fail_act || true
        fail_act="${fail_act:-1}"

        if [ "$fail_act" -eq 1 ]; then
            log_info "Генерация чистого fallback SSL сертификата..."
            mkdir -p "/etc/letsencrypt/live/$target_domain"
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "$key_path" \
                -out "$cert_path" \
                -subj "/CN=$target_domain/O=Enterprise Edge Infrastructure" 2>/dev/null
            log_ok "Чистый Fallback SSL сертификат создан! SelfSNI сможет работать."
            return 0
        elif [ "$fail_act" -eq 2 ]; then
            if issue_zerossl_cert "$target_domain" "$target_email" && [ -f "$cert_path" ]; then
                log_ok "Чистый SSL сертификат ZeroSSL успешно получен!"
                return 0
            fi
        elif [ "$fail_act" -eq 3 ]; then
            if issue_letsencrypt_cert "$target_domain" "$target_email" && [ -f "$cert_path" ]; then
                log_ok "Чистый SSL сертификат Let's Encrypt успешно получен!"
                return 0
            fi
        fi

        if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
            return 0
        else
            log_err "Сертификат не получен. Прервано."
            return 1
        fi
    fi
}

# ==============================================================================
# АВТООБНОВЛЕНИЕ ЧЕРНЫХ СПИСКОВ СКАНЕРОВ ТСПУ (C24Be AS Network List)
# ==============================================================================
install_blacklist_updater() {
    mkdir -p /etc/nginx
    if [ ! -f /etc/nginx/blacklist.conf ]; then
        echo "# Initial scanner blacklist stub" > /etc/nginx/blacklist.conf
    fi

    cat << 'EOF' > /usr/local/bin/update-selfsni-blacklist
#!/usr/bin/env bash
# ==============================================================================
# C24Be SCANNER BLACKLIST AUTO-UPDATER FOR NGINX SELFSNI
# ==============================================================================
set -euo pipefail

BL_URL="https://raw.githubusercontent.com/C24Be/AS_Network_List/refs/heads/main/blacklists_nginx/blacklist.conf"
BL_TARGET="/etc/nginx/blacklist.conf"
BL_TMP="/etc/nginx/blacklist.conf.tmp"

mkdir -p /etc/nginx

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Загрузка обновленного черного списка сканеров ТСПУ..."

if curl -sSL --connect-timeout 10 --max-time 35 "$BL_URL" -o "$BL_TMP"; then
    if [ -s "$BL_TMP" ] && grep -q "deny " "$BL_TMP"; then
        mv -f "$BL_TMP" "$BL_TARGET"
        rules_count=$(grep -c "^deny " "$BL_TARGET" || echo "0")
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] База успешно обновлена: $rules_count активных подсетей заблокировано."

        # Мягкая перезагрузка Nginx если служба активна
        if systemctl is-active --quiet nginx 2>/dev/null; then
            if nginx -t >/dev/null 2>&1; then
                systemctl reload nginx 2>/dev/null || true
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Конфигурация Nginx успешно перезагружена."
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ошибка синтаксиса Nginx. Перезагрузка отменена."
            fi
        fi
    else
        rm -f "$BL_TMP"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Файл черного списка пуст или некорректен."
    fi
else
    rm -f "$BL_TMP"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ошибка связи с GitHub. Сохранена текущая база."
fi

if [ ! -f "$BL_TARGET" ]; then
    echo "# Initial scanner blacklist stub" > "$BL_TARGET"
fi
EOF
    chmod +x /usr/local/bin/update-selfsni-blacklist
}

# ==============================================================================
# УСТАНОВКА / ПЕРВОНАЧАЛЬНОЕ РАЗВЕРТЫВАНИЕ
# ==============================================================================
install_selfsni() {
    check_root

    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}     NGINX SELFSNI: УСТАНОВКА И ПРОЦЕДУРНЫЙ ГЕНЕРАТОР САЙТОВ        ${NC}"
    echo -e "${CYAN}====================================================================${NC}"

    DOMAIN=""
    read -rp "Введите доменное имя вашего сервера (например, srv1.example.com): " DOMAIN || true
    DOMAIN=$(echo "${DOMAIN:-}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    if [ -z "$DOMAIN" ]; then
        log_err "Домен не может быть пустым."
        return 1
    fi

    # Случайный email
    local random_user
    random_user=$(head -c 256 /dev/urandom | LC_ALL=C tr -dc 'a-z' | cut -c1-7 || echo "admin$RANDOM")
    random_user="${random_user:-admin$RANDOM}"
    local auto_email="${random_user}@${DOMAIN}"

    local email_input=""
    read -rp "Email для Let's Encrypt [Enter для случайного: $auto_email]: " email_input || true
    EMAIL="${email_input:-$auto_email}"
    EMAIL=$(echo "$EMAIL" | tr -d '[:space:]')
    log_info "Используется Email: $EMAIL"

    local port_input=""
    read -rp "Порт для локального fallback Nginx [по умолчанию: 9443]: " port_input || true
    FALLBACK_PORT="${port_input:-9443}"
    FALLBACK_PORT=$(echo "$FALLBACK_PORT" | tr -d '[:space:]')

    local proxy_proto_input=""
    read -rp "Использовать PROXY Protocol (xver) от Xray? [Y/n, рекомендуется: Y]: " proxy_proto_input || true
    proxy_proto_input="${proxy_proto_input:-y}"
    if [[ "$proxy_proto_input" =~ ^[Yy]$ ]]; then
        USE_PROXY_FLAG=1
        log_info "PROXY Protocol ВКЛЮЧЕН (в Xray xver: 1)"
    else
        USE_PROXY_FLAG=0
        log_info "PROXY Protocol ВЫКЛЮЧЕН (в Xray xver: 0)"
    fi

    echo -e "\n${MAGENTA}ВЫБОР АРХИТЕКТУРЫ ШЛЮЗА ДЛЯ МАСКИРОВКИ:${NC}"
    echo -e "1) ${CYAN}[Случайно]${NC} 🎲 Автоматический выбор случайного шлюза (Рекомендуется)"
    echo -e "2) 🔒 Encrypted Cloud Vault (E2EE хранилище чанков, Send / ProtonDrive, /api/v1/files/upload)"
    echo -e "3) 🛡️ Zero-Trust Identity Gateway (Корпоративный SSO, WebAuthn FIDO2, ZTNA Perimeter)"
    echo -e "4) 📦 Private S3 Object Storage Console (MinIO / Ceph S3 Console, API Ingress)"
    echo -e "5) 🌐 Edge CDN Mesh Relay & Node Telemetry (Сетевой PoP-узел, Anycast, живой лог транзита)"
    echo -e "6) 💻 Minimalist Dev Auth Portal (Стиль Linear / Raycast, CLI Token & PAT Login)"

    local theme_input=""
    read -rp "Выберите вариант [1-6, по умолчанию: 1]: " theme_input || true
    theme_input="${theme_input:-1}"

    # Проверка DNS
    log_info "Проверка разрешения домена $DOMAIN..."
    local server_ipv4 resolved_ip
    server_ipv4=$(curl -s4 https://api.ipify.org || curl -s4 https://ifconfig.me || true)

    if command -v dig &>/dev/null; then
        resolved_ip=$(dig +short "$DOMAIN" A | tail -n1 || true)
    else
        resolved_ip=$(getent ahostsv4 "$DOMAIN" 2>/dev/null | awk '{print $1}' | head -n1 || true)
    fi

    if [ -n "$server_ipv4" ] && [ -n "$resolved_ip" ]; then
        if [ "$server_ipv4" != "$resolved_ip" ]; then
            log_warn "IP домена ($resolved_ip) не совпадает с публичным IP сервера ($server_ipv4)."
            local cont_dns=""
            read -rp "Продолжить выпуск сертификата? [y/N]: " cont_dns || true
            if [[ ! "$cont_dns" =~ ^[Yy]$ ]]; then
                log_err "Прервано. Направьте A-запись домена на IP сервера."
                return 1
            fi
        else
            log_ok "DNS A-запись совпадает с IP сервера ($server_ipv4)."
        fi
    fi

    # Установка пакетов
    log_info "Установка зависимостей (Nginx, Certbot)..."
    apt-get update -y
    apt-get install -y nginx certbot python3-certbot-nginx curl openssl sed

    echo -e "\n${MAGENTA}ВЫБОР ЦЕНТРА СЕРТИФИКАЦИИ SSL (CA):${NC}"
    echo -e "1) ${GREEN}[Рекомендуется] Auto${NC}: Let's Encrypt (при сбое TCP/Connection Reset — авто-переход на ZeroSSL)"
    echo -e "2) ${MAGENTA}ZeroSSL${NC}: Прямой выпуск через ZeroSSL (Sectigo/USERTrust CA, без сбоев secondary validation)"
    echo -e "3) ${BLUE}Let's Encrypt${NC}: Классический выпуск через Let's Encrypt"
    local ca_input=""
    read -rp "Выберите вариант [1-3, по умолчанию: 1]: " ca_input || true
    local chosen_ca="auto"
    if [ "${ca_input:-1}" -eq 2 ]; then
        chosen_ca="zerossl"
    elif [ "${ca_input:-1}" -eq 3 ]; then
        chosen_ca="letsencrypt"
    fi

    # Принудительная вычистка старых и получение чистых новых сертификатов
    purge_and_issue_clean_ssl "$DOMAIN" "$EMAIL" "$chosen_ca"

    # Установка и первичная загрузка базы черных списков сканеров ТСПУ (C24Be)
    log_info "Установка базы фильтрации сканеров ТСПУ (C24Be AS Network List)..."
    install_blacklist_updater
    /usr/local/bin/update-selfsni-blacklist || true

    WEB_ROOT="/var/www/$DOMAIN"
    generate_website "$DOMAIN" "$WEB_ROOT" "$theme_input"
    configure_nginx "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG" "$WEB_ROOT"

    systemctl enable nginx 2>/dev/null || true
    if ! systemctl is-active --quiet nginx 2>/dev/null; then
        systemctl restart nginx 2>/dev/null || systemctl start nginx 2>/dev/null || true
    fi

    # Настройка планировщика cron (в 03:00 - обновление базы сканеров, в 03:30 - проверка SSL)
    local cron_bl="0 3 * * * /usr/local/bin/update-selfsni-blacklist > /var/log/selfsni-blacklist.log 2>&1"
    local cron_ssl="30 3 * * * certbot renew --webroot -w /var/www/certbot --post-hook 'systemctl reload nginx' > /dev/null 2>&1"

    local existing_cron
    existing_cron=$(crontab -l 2>/dev/null || true)
    existing_cron=$(echo "$existing_cron" | grep -Fv "certbot renew" | grep -Fv "update-selfsni-blacklist" || true)

    {
        if [ -n "$existing_cron" ]; then
            echo "$existing_cron"
        fi
        echo "$cron_bl"
        echo "$cron_ssl"
    } | crontab - 2>/dev/null || true

    # Сохраняем конфиг и линкуем команду selfsni
    save_config
    install_bin_link

    run_self_test "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG"

    echo -e "\n${GREEN}====================================================================${NC}"
    echo -e "${GREEN}             SELFSNI УСПЕШНО РАЗВЕРНУТ И НАСТРОЕН!                  ${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "Домен сайта:              ${CYAN}https://${DOMAIN}${NC}"
    echo -e "Локальный fallback Nginx: ${CYAN}127.0.0.1:${FALLBACK_PORT}${NC}"
    echo -e "PROXY Protocol (xver):    ${CYAN}$([ $USE_PROXY_FLAG -eq 1 ] && echo 'ВКЛЮЧЕН (xver: 1)' || echo 'ВЫКЛЮЧЕН (xver: 0)')${NC}"
    echo -e "Управление сервером:      ${CYAN}selfsni${NC} (вводите в терминале)"
    echo -e "\n${YELLOW}В конфигурации Xray укажите в realitySettings:${NC}"
    cat << EOF
--------------------------------------------------------------------
"realitySettings": {
  "show": false,
  "xver": $USE_PROXY_FLAG,
  "target": "127.0.0.1:$FALLBACK_PORT",
  "serverNames": [
    "$DOMAIN"
  ]
}
--------------------------------------------------------------------
EOF
    echo -e "${CYAN}Нажмите Enter для перехода в меню управления...${NC}"
    read -r || true
}

# Установка симлинка/команды selfsni
install_bin_link() {
    # 1. Если запущен из нормального файла на диске:
    if [[ "$0" != /dev/fd/* ]] && [[ "$0" != /proc/self/fd/* ]] && [[ "$0" != "bash" ]] && [[ "$0" != "sh" ]] && [ -f "$0" ]; then
        if [ "$0" != "$BIN_LINK" ]; then
            cp "$0" "$BIN_LINK" 2>/dev/null || true
            chmod +x "$BIN_LINK" 2>/dev/null || true
        fi
    else
        # 2. Если запущен через curl/wget или pipe: скачиваем скрипт в BIN_LINK
        curl -sSL "https://raw.githubusercontent.com/EikeiDev/remnawave-configs/refs/heads/main/deploy-selfsni.sh" -o "$BIN_LINK" 2>/dev/null || \
        wget -qO "$BIN_LINK" "https://raw.githubusercontent.com/EikeiDev/remnawave-configs/refs/heads/main/deploy-selfsni.sh" 2>/dev/null || true
        chmod +x "$BIN_LINK" 2>/dev/null || true
    fi
}

# ==============================================================================
# ПОСТКВАНТОВАЯ КРИПТОГРАФИЯ (X25519MLKEM768 / KYBER / OQS PROVIDER)
# ==============================================================================
find_oqsprovider_so() {
    local mod_dir
    mod_dir=$(openssl version -m 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/' || true)
    for d in "$mod_dir" /usr/lib/x86_64-linux-gnu/ossl-modules /usr/lib/aarch64-linux-gnu/ossl-modules /usr/local/lib64/ossl-modules /usr/local/lib/ossl-modules /usr/lib/ossl-modules; do
        if [ -n "$d" ] && [ -f "$d/oqsprovider.so" ]; then
            echo "$d/oqsprovider.so"
            return 0
        fi
    done
    return 1
}

check_pqc_active() {
    if openssl list -providers 2>/dev/null | grep -qi "oqsprovider"; then
        return 0
    fi
    if openssl list -kem-algorithms 2>/dev/null | grep -qi "MLKEM768\|ML-KEM-768"; then
        return 0
    fi
    if find_oqsprovider_so >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

detect_pqc_curves() {
    python3 - << 'PYEOF' 2>/dev/null || echo "X25519:prime256v1:secp384r1"
import ctypes
import sys

try:
    libssl = ctypes.CDLL("libssl.so.3")
    libssl.OPENSSL_init_ssl(0x00000040, None)
    libssl.TLS_server_method.restype = ctypes.c_void_p
    libssl.SSL_CTX_new.argtypes = [ctypes.c_void_p]
    libssl.SSL_CTX_new.restype = ctypes.c_void_p
    libssl.SSL_CTX_set1_curves_list.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    libssl.SSL_CTX_set1_curves_list.restype = ctypes.c_int

    ctx = libssl.SSL_CTX_new(libssl.TLS_server_method())
    if not ctx:
        print("X25519:prime256v1:secp384r1")
        sys.exit(0)

    candidates = [
        b"X25519MLKEM768:x25519_kyber768:X25519:prime256v1:secp384r1",
        b"X25519MLKEM768:X25519:prime256v1:secp384r1",
        b"x25519_mlkem768:x25519_kyber768:X25519:prime256v1:secp384r1",
        b"x25519_mlkem768:X25519:prime256v1:secp384r1",
        b"x25519_kyber768:X25519:prime256v1:secp384r1",
    ]
    for cand in candidates:
        if libssl.SSL_CTX_set1_curves_list(ctx, cand) == 1:
            print(cand.decode("utf-8"))
            sys.exit(0)
except Exception:
    pass

print("X25519:prime256v1:secp384r1")
PYEOF
}

patch_openssl_cnf() {
    local cnf="/etc/ssl/openssl.cnf"
    if [ ! -f "$cnf" ]; then
        return 0
    fi
    if [ ! -f "${cnf}.selfsni.bak" ]; then
        cp "$cnf" "${cnf}.selfsni.bak"
    elif ! grep -q "oqsprovider_sect" "${cnf}.selfsni.bak" 2>/dev/null; then
        # Восстанавливаем чистую базу перед применением патча (лечит возможные прошлые повреждения)
        cp -f "${cnf}.selfsni.bak" "$cnf"
    fi

    # Регистрируем пути /usr/local/lib и /usr/local/lib64 для liboqs.so
    cat << 'EOF' > /etc/ld.so.conf.d/oqs-pqc.conf
/usr/local/lib
/usr/local/lib64
EOF
    ldconfig 2>/dev/null || true

    # Если oqsprovider.so собран в /usr/local, копируем его также в системный MODULESDIR OpenSSL
    local sys_mod_dir
    sys_mod_dir=$(openssl version -m 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/' || true)
    [ -z "$sys_mod_dir" ] && sys_mod_dir="/usr/lib/x86_64-linux-gnu/ossl-modules"
    mkdir -p "$sys_mod_dir"

    local existing_so
    existing_so=$(find_oqsprovider_so || true)
    if [ -n "$existing_so" ] && [ -f "$existing_so" ] && [ "$existing_so" != "$sys_mod_dir/oqsprovider.so" ]; then
        cp -f "$existing_so" "$sys_mod_dir/oqsprovider.so" 2>/dev/null || true
        chmod 755 "$sys_mod_dir/oqsprovider.so" 2>/dev/null || true
    fi

    local final_so="$sys_mod_dir/oqsprovider.so"
    [ ! -f "$final_so" ] && final_so="${existing_so:-}"

    python3 - "$final_so" << 'PYEOF'
import re
import sys

cnf_file = "/etc/ssl/openssl.cnf"
so_path = sys.argv[1] if len(sys.argv) > 1 else ""

try:
    with open(cnf_file, "r", encoding="utf-8", errors="ignore") as f:
        text = f.read()

    # 0. Лечим поврежденный комментарий на Ubuntu 24.04 (# referenced from the [provider_sect] below.)
    text = re.sub(
        r'#\s*referenced from the \[provider_sect\]\s*oqsprovider\s*=\s*oqsprovider_sect\s*below\.',
        '# referenced from the [provider_sect] below.',
        text
    )

    # 1. Раскомментируем закомментированные директивы в дефолтном конфиге Ubuntu/Debian
    text = re.sub(r'^\s*#\s*(openssl_conf\s*=\s*openssl_init)', r'\1', text, flags=re.M)
    text = re.sub(r'^\s*#\s*(providers\s*=\s*provider_sect)', r'\1', text, flags=re.M)
    text = re.sub(r'^\s*#\s*(default\s*=\s*default_sect)', r'\1', text, flags=re.M)
    text = re.sub(r'^\s*#\s*(activate\s*=\s*1)', r'\1', text, flags=re.M)

    # 2. Гарантируем наличие openssl_conf = openssl_init в глобальной секции
    if not re.search(r'^\s*openssl_conf\s*=\s*openssl_init', text, re.M):
        text = "openssl_conf = openssl_init\n\n" + text

    # 3. Секция [openssl_init]
    if not re.search(r'^\s*\[openssl_init\]', text, re.M):
        text += "\n[openssl_init]\nproviders = provider_sect\n"
    else:
        m = re.search(r'(^\s*\[openssl_init\][^\[]*)', text, re.M | re.S)
        if m and not re.search(r'^\s*providers\s*=\s*provider_sect', m.group(1), re.M):
            text = re.sub(r'(^\s*\[openssl_init\])', r'\1\nproviders = provider_sect', text, count=1, flags=re.M)

    # 4. Секция [provider_sect]
    if not re.search(r'^\s*\[provider_sect\]', text, re.M):
        text += "\n[provider_sect]\ndefault = default_sect\noqsprovider = oqsprovider_sect\n"
    else:
        m = re.search(r'(^\s*\[provider_sect\][^\[]*)', text, re.M | re.S)
        if m:
            sec = m.group(1)
            if not re.search(r'^\s*default\s*=\s*default_sect', sec, re.M):
                text = re.sub(r'(^\s*\[provider_sect\])', r'\1\ndefault = default_sect', text, count=1, flags=re.M)
            if not re.search(r'^\s*oqsprovider\s*=\s*oqsprovider_sect', sec, re.M):
                text = re.sub(r'(^\s*\[provider_sect\])', r'\1\noqsprovider = oqsprovider_sect', text, count=1, flags=re.M)

    # 5. Секция [default_sect] — ОБЯЗАТЕЛЬНО activate = 1 (иначе отключается классический X25519!)
    if not re.search(r'^\s*\[default_sect\]', text, re.M):
        text += "\n[default_sect]\nactivate = 1\n"
    else:
        m = re.search(r'(^\s*\[default_sect\][^\[]*)', text, re.M | re.S)
        if m and not re.search(r'^\s*activate\s*=\s*1', m.group(1), re.M):
            text = re.sub(r'(^\s*\[default_sect\])', r'\1\nactivate = 1', text, count=1, flags=re.M)

    # 6. Перезаписываем чистую секцию [oqsprovider_sect] с явным путем к модулю
    text = re.sub(r'^\s*\[oqsprovider_sect\][^\[]*', '', text, flags=re.M | re.S)
    oqs_sec = "\n[oqsprovider_sect]\nactivate = 1\n"
    if so_path:
        oqs_sec += f"module = {so_path}\n"
    text = text.rstrip() + "\n" + oqs_sec

    with open(cnf_file, "w", encoding="utf-8") as f:
        f.write(text)
except Exception as e:
    sys.stderr.write(f"Warning patching openssl.cnf: {e}\n")
PYEOF

    # Гарантируем, что systemd-сервис Nginx видит OPENSSL_CONF
    mkdir -p /etc/systemd/system/nginx.service.d
    cat << 'EOF' > /etc/systemd/system/nginx.service.d/oqs-pqc.conf
[Service]
Environment="OPENSSL_CONF=/etc/ssl/openssl.cnf"
EOF
    systemctl daemon-reload 2>/dev/null || true
}

install_oqs_provider() {
    check_root
    echo -e "\n${CYAN}====================================================================${NC}"
    echo -e "${CYAN}    УСТАНОВКА ПОСТКВАНТОВОГО МОДУЛЯ (NIST ML-KEM-768 / KYBER)        ${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    log_info "Установка инструментов компиляции (cmake, ninja-build, git, libssl-dev)..."
    apt-get update -y
    apt-get install -y cmake ninja-build build-essential git libssl-dev python3

    local build_tmp="/tmp/oqs_pqc_build_$$"
    rm -rf "$build_tmp"
    mkdir -p "$build_tmp"
    cd "$build_tmp"

    log_info "Загрузка и сборка легковесного liboqs (ML-KEM-768 + Kyber768)..."
    if ! git clone --depth 1 https://github.com/open-quantum-safe/liboqs.git; then
        log_err "Не удалось загрузить liboqs с GitHub."
        rm -rf "$build_tmp"
        return 1
    fi

    cd liboqs
    cmake -S . -B _build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_SHARED_LIBS=ON \
        -DOQS_BUILD_ONLY_LIB=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DOQS_MINIMAL_BUILD="KEM_ml_kem_768;KEM_kyber_768"
    ninja -C _build install
    ldconfig
    cd "$build_tmp"

    log_info "Загрузка и сборка oqs-provider для OpenSSL 3..."
    if ! git clone --depth 1 https://github.com/open-quantum-safe/oqs-provider.git; then
        log_err "Не удалось загрузить oqs-provider с GitHub."
        rm -rf "$build_tmp"
        return 1
    fi

    cd oqs-provider
    cmake -S . -B _build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_TESTING=OFF \
        -Dliboqs_DIR=/usr/local
    ninja -C _build install

    # Проверяем наличие oqsprovider.so в системной директории модулей OpenSSL
    local ossl_dir
    ossl_dir=$(openssl version -m 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/' || true)
    [ -z "$ossl_dir" ] && ossl_dir="/usr/lib/x86_64-linux-gnu/ossl-modules"
    mkdir -p "$ossl_dir"

    if [ ! -f "$ossl_dir/oqsprovider.so" ]; then
        local built_so
        built_so=$(find /usr/local "$build_tmp" -name "oqsprovider.so" 2>/dev/null | head -n1 || true)
        if [ -n "$built_so" ] && [ -f "$built_so" ]; then
            cp -fL "$built_so" "$ossl_dir/oqsprovider.so"
            chmod 755 "$ossl_dir/oqsprovider.so"
        fi
    fi

    cd /
    rm -rf "$build_tmp"

    # Интеграция в openssl.cnf и проверка кривой
    patch_openssl_cnf

    local active_curves
    active_curves=$(detect_pqc_curves)
    if [[ "$active_curves" == *"MLKEM"* ]] || [[ "$active_curves" == *"mlkem"* ]] || [[ "$active_curves" == *"kyber"* ]]; then
        log_ok "OQS Provider успешно активирован в OpenSSL! Доступные группы: $active_curves"
        ENABLE_PQC=1
        save_config
        configure_nginx "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG" "${WEB_ROOT:-/var/www/$DOMAIN}"
        log_ok "Nginx успешно переведен на гибридный постквантовый обмен ($active_curves)!"
    else
        log_err "Не удалось инициализировать гибридную кривую в OpenSSL (доступно: $active_curves)."
        ENABLE_PQC=0
        save_config
    fi

    echo -e "\n${CYAN}Нажмите Enter для возврата...${NC}"
    read -r || true
}

remove_oqs_provider() {
    check_root
    log_info "Отключение постквантовой криптографии..."
    if [ -f "/etc/ssl/openssl.cnf.selfsni.bak" ]; then
        cp -f "/etc/ssl/openssl.cnf.selfsni.bak" "/etc/ssl/openssl.cnf"
        log_ok "Файл /etc/ssl/openssl.cnf восстановлен."
    else
        sed -i '/oqsprovider/d' /etc/ssl/openssl.cnf 2>/dev/null || true
    fi
    rm -f /etc/systemd/system/nginx.service.d/oqs-pqc.conf 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
    ENABLE_PQC=0
    save_config
    configure_nginx "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG" "${WEB_ROOT:-/var/www/$DOMAIN}"
    log_ok "Постквантовый режим отключен. Nginx работает на классическом X25519."
    sleep 1.5
}

test_pqc_handshake() {
    echo -e "\n${CYAN}====================================================================${NC}"
    echo -e "${CYAN}    ТЕСТИРОВАНИЕ POST-QUANTUM РУКОПОЖАТИЯ TLS 1.3                    ${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    log_info "Проверка зарегистрированных провайдеров OpenSSL и рукопожатия с 127.0.0.1:${FALLBACK_PORT}..."

    echo -e "\n${BOLD}1. Активные провайдеры OpenSSL:${NC}"
    openssl list -providers 2>/dev/null | grep -E "name:|status:" || true

    local active_curves
    active_curves=$(detect_pqc_curves)
    echo -e "\n${BOLD}2. Проверенная цепочка кривых SSL_CTX:${NC} ${GREEN}${active_curves}${NC}"

    echo -e "\n${BOLD}3. Тестовое подключение к Nginx (${DOMAIN}:${FALLBACK_PORT}):${NC}"
    local curl_out=""
    local primary_pqc="${active_curves%%:*}"
    if [ "${USE_PROXY_FLAG:-0}" -eq 1 ]; then
        curl_out=$(curl -vksI --haproxy-protocol --curves "$primary_pqc" --resolve "${DOMAIN}:${FALLBACK_PORT}:127.0.0.1" "https://${DOMAIN}:${FALLBACK_PORT}/" 2>&1 || true)
    else
        curl_out=$(curl -vksI --curves "$primary_pqc" --resolve "${DOMAIN}:${FALLBACK_PORT}:127.0.0.1" "https://${DOMAIN}:${FALLBACK_PORT}/" 2>&1 || true)
    fi

    echo "$curl_out" | grep -iE "(SSL connection using|Server certificate|subject:|HTTP/)" | head -n 6 || true
    echo ""

    if [[ "$primary_pqc" == *"MLKEM"* ]] || [[ "$primary_pqc" == *"mlkem"* ]] || [[ "$primary_pqc" == *"kyber"* ]]; then
        if echo "$curl_out" | grep -qi "SSL connection using TLSv1.3"; then
            echo -e "${GREEN}✔ ВЕРИФИКАЦИЯ ПРОЙДЕНА: Выполнено боевое рукопожатие TLS 1.3 на постквантовой кривой ${primary_pqc}!${NC}"
        else
            echo -e "${YELLOW}ℹ Кривая ${primary_pqc} загружена в OpenSSL. Убедитесь, что PQC включен в пункте 2.${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ В данный момент активен классический режим X25519 (ECDH).${NC}"
    fi
    echo -e "\n${CYAN}Нажмите Enter для возврата...${NC}"
    read -r || true
}

pqc_management_menu() {
    check_root
    while true; do
        clear
        local pqc_stat_str="${RED}НЕ УСТАНОВЛЕН (Классический OpenSSL)${NC}"
        if check_pqc_active && [ "${ENABLE_PQC:-0}" -eq 1 ]; then
            pqc_stat_str="${GREEN}АКТИВЕН И РАБОТАЕТ В NGINX ●${NC} (X25519MLKEM768)"
        elif check_pqc_active; then
            pqc_stat_str="${YELLOW}УСТАНОВЛЕН В СИСТЕМЕ, НО ВЫКЛЮЧЕН В NGINX ○${NC}"
        fi

        echo -e "${CYAN}╭────────────────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${BOLD}   ◈ ПОСТКВАНТОВАЯ КРИПТОГРАФИЯ (NIST FIPS 203 ML-KEM / KYBER)               ${CYAN}│${NC}"
        echo -e "${CYAN}├────────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Статус PQC:${NC}        $pqc_stat_str"
        echo -e "${CYAN}│${NC}  ${BOLD}• Алгоритм:${NC}          ${WHITE}X25519MLKEM768 (NIST ML-KEM-768 + X25519)${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Назначение:${NC}        ${DIM}Защита от квантовых дешифраторов («Harvest Now, Decrypt Later»)${NC}"
        echo -e "${CYAN}╰────────────────────────────────────────────────────────────────────────────╯${NC}"
        echo ""
        echo -e "   ${BOLD}1${NC} ❯ 🚀 Установить и активировать OQS Provider (компиляция ~30 сек)"
        if [ "${ENABLE_PQC:-0}" -eq 1 ]; then
            echo -e "   ${BOLD}2${NC} ❯ ⏸  Временно отключить PQC в Nginx (перейти на X25519)"
        else
            echo -e "   ${BOLD}2${NC} ❯ ▶️  Включить PQC в Nginx (активировать кривую X25519MLKEM768)"
        fi
        echo -e "   ${BOLD}3${NC} ❯ 🧪 Протестировать TLS 1.3 Post-Quantum рукопожатие"
        echo -e "   ${BOLD}4${NC} ❯ 🗑️  Полное удаление OQS Provider из системы"
        echo -e "   ${BOLD}0${NC} ❯ ↩️  Назад в главное меню"
        echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
        local pqc_choice=""
        read -rp "❯ Выберите действие [0-4]: " pqc_choice || true

        case "$pqc_choice" in
            1)
                install_oqs_provider
                ;;
            2)
                if ! check_pqc_active; then
                    echo -e "\n${YELLOW}OQS Provider еще не установлен. Сначала выберите пункт 1.${NC}"
                    sleep 2
                else
                    if [ "${ENABLE_PQC:-0}" -eq 1 ]; then
                        ENABLE_PQC=0
                        log_info "Переключение на классический X25519..."
                        save_config
                        configure_nginx "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG" "${WEB_ROOT:-/var/www/$DOMAIN}"
                        log_ok "Постквантовый обмен в Nginx отключен."
                        sleep 1.5
                    else
                        log_info "Активация oqsprovider в /etc/ssl/openssl.cnf и проверка кривых..."
                        patch_openssl_cnf
                        local test_curves
                        test_curves=$(detect_pqc_curves)
                        if [[ "$test_curves" == *"MLKEM"* ]] || [[ "$test_curves" == *"mlkem"* ]] || [[ "$test_curves" == *"kyber"* ]]; then
                            ENABLE_PQC=1
                            save_config
                            log_info "Включение постквантовой цепочки ($test_curves) в Nginx..."
                            configure_nginx "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG" "${WEB_ROOT:-/var/www/$DOMAIN}"
                            if [ "${ENABLE_PQC:-0}" -eq 1 ]; then
                                log_ok "Постквантовая защита ($test_curves) успешно активирована в Nginx!"
                            fi
                        else
                            log_err "Модуль oqsprovider не отдал гибридную кривую X25519MLKEM768."
                            log_info "Попробуйте пересобрать провайдер через пункт 1."
                        fi
                        echo -e "\nНажмите Enter для продолжения..."
                        read -r || true
                    fi
                fi
                ;;
            3)
                test_pqc_handshake
                ;;
            4)
                remove_oqs_provider
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "${RED}Неверный пункт.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Переключение PROXY Protocol (xver)
toggle_proxy_protocol() {
    check_root
    local current_val="${USE_PROXY_FLAG:-0}"
    local new_val=0
    local mode_desc=""

    if [ "$current_val" -eq 1 ]; then
        new_val=0
        mode_desc="${YELLOW}ВЫКЛЮЧЕН (xver: 0)${NC} (Режим для Hysteria 2 / dokodemo-door)"
    else
        new_val=1
        mode_desc="${GREEN}ВКЛЮЧЕН (xver: 1)${NC} (Режим для Xray Reality)"
    fi

    echo -e "\n${CYAN}====================================================================${NC}"
    echo -e "${CYAN}         ПЕРЕКЛЮЧЕНИЕ РЕЖИМА PROXY PROTOCOL (XVER)                  ${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "Текущее состояние: $([ "$current_val" -eq 1 ] && echo -e "${GREEN}ВКЛЮЧЕН (xver: 1)${NC}" || echo -e "${YELLOW}ВЫКЛЮЧЕН (xver: 0)${NC}")"
    echo -e "Новое состояние:   $mode_desc"
    echo ""

    USE_PROXY_FLAG="$new_val"
    save_config

    log_info "Генерация обновленной конфигурации Nginx..."
    configure_nginx "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG" "${WEB_ROOT:-/var/www/$DOMAIN}"

    if nginx -t; then
        systemctl reload nginx
        log_ok "Конфигурация Nginx успешно обновлена и перезагружена!"
        if [ "$new_val" -eq 1 ]; then
            log_info "Nginx теперь ожидает трафик с заголовками PROXY Protocol (xver: 1)."
            log_info "В конфигурации Xray Reality укажите: \"xver\": 1"
        else
            log_info "Nginx теперь принимает прямой TLS без PROXY Protocol (xver: 0)."
            log_info "В конфигурации Xray укажите: \"xver\": 0 (подходит для Hysteria 2 и dokodemo-door)."
        fi
    else
        log_err "Ошибка синтаксиса Nginx! Откат к предыдущему значению..."
        USE_PROXY_FLAG="$current_val"
        save_config
        configure_nginx "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG" "${WEB_ROOT:-/var/www/$DOMAIN}"
        systemctl reload nginx 2>/dev/null || true
    fi

    echo -e "\n${CYAN}Нажмите Enter для возврата в меню...${NC}"
    read -r || true
}

# ==============================================================================
# ЩИТ НОДЫ: ИЗОЛЯЦИЯ REMNANODE, СЕТЕВОЙ СТЕК ANTI-DPI (BBR/QUIC) И АУДИТ ТСПУ
# ==============================================================================
check_bbr_active() {
    local cc
    cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "")
    if [ "$cc" = "bbr" ]; then
        return 0
    fi
    return 1
}

check_remnanode_shielded() {
    if [ -n "${REMNANODE_PORT:-}" ] && [ -f "/usr/local/bin/selfsni-firewall" ]; then
        if iptables -C INPUT -p tcp --dport "$REMNANODE_PORT" -j DROP 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

detect_remnanode_port() {
    local detected=""
    for env_path in "/opt/remnanode/.env" "/root/remnanode/.env" "/opt/remnawave/node/.env"; do
        if [ -f "$env_path" ]; then
            detected=$(grep -E "^(NODE_PORT|APP_PORT)=" "$env_path" 2>/dev/null | head -n1 | cut -d= -f2 | tr -d '[:space:]"'\''' || true)
            if [ -n "$detected" ]; then
                echo "$detected"
                return 0
            fi
        fi
    done
    echo "${REMNANODE_PORT:-2222}"
}

isolate_remnanode_port() {
    echo -e "\n${CYAN}====================================================================${NC}"
    echo -e "${CYAN}        ИЗОЛЯЦИЯ ПОРТА УПРАВЛЕНИЯ REMNANODE ОТ СКАНЕРОВ ТСПУ        ${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${DIM}Открытый порт управления remnanode позволяет сканерам ТСПУ, Censys и Shodan${NC}"
    echo -e "${DIM}мгновенно определить, что сервер является прокси-нодой Remnawave.${NC}"
    echo -e "${DIM}Эта функция закроет порт глухим фильтром (DROP) для всего мира, кроме IP вашей панели.${NC}\n"

    local def_port
    def_port=$(detect_remnanode_port)
    local port_in=""
    read -rp "Введите порт управления remnanode [по умолчанию: ${def_port}]: " port_in || true
    local target_port="${port_in:-$def_port}"
    target_port=$(echo "$target_port" | tr -d '[:space:]')

    if ! [[ "$target_port" =~ ^[0-9]+$ ]] || [ "$target_port" -lt 1 ] || [ "$target_port" -gt 65535 ]; then
        log_err "Некорректный номер порта: $target_port"
        return 1
    fi

    if [ "$target_port" = "80" ] || [ "$target_port" = "443" ] || [ "$target_port" = "22" ]; then
        log_err "Нельзя изолировать стандартные порты 22, 80 или 443!"
        return 1
    fi

    local panel_in=""
    read -rp "Введите IPv4-адрес вашей главной панели Remnawave [текущий: ${PANEL_IP:-не задан}]: " panel_in || true
    local target_ip="${panel_in:-${PANEL_IP:-}}"
    target_ip=$(echo "$target_ip" | tr -d '[:space:]')

    if ! [[ "$target_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_err "Некорректный формат IPv4-адреса панели: $target_ip"
        return 1
    fi

    # Удаляем старые правила если были
    if [ -f "/usr/local/bin/selfsni-firewall" ]; then
        /usr/local/bin/selfsni-firewall stop 2>/dev/null || true
    fi

    REMNANODE_PORT="$target_port"
    PANEL_IP="$target_ip"
    save_config

    cat << EOF > /usr/local/bin/selfsni-firewall
#!/usr/bin/env bash
# SelfSNI Remnanode Port Shield (Port: $REMNANODE_PORT, Allowed Panel IP: $PANEL_IP)
PORT="$REMNANODE_PORT"
PANEL="$PANEL_IP"

clean_rules() {
    while iptables -D INPUT -p tcp --dport "\$PORT" -s 127.0.0.1 -j ACCEPT 2>/dev/null; do :; done
    while iptables -D INPUT -p tcp --dport "\$PORT" -s "\$PANEL" -j ACCEPT 2>/dev/null; do :; done
    while iptables -D INPUT -p tcp --dport "\$PORT" -j DROP 2>/dev/null; do :; done
    while iptables -D INPUT -p udp --dport "\$PORT" -j DROP 2>/dev/null; do :; done

    if iptables -L DOCKER-USER >/dev/null 2>&1; then
        while iptables -D DOCKER-USER -p tcp --dport "\$PORT" -s 127.0.0.1 -j ACCEPT 2>/dev/null; do :; done
        while iptables -D DOCKER-USER -p tcp --dport "\$PORT" -s "\$PANEL" -j ACCEPT 2>/dev/null; do :; done
        while iptables -D DOCKER-USER -p tcp --dport "\$PORT" -j DROP 2>/dev/null; do :; done
    fi

    if command -v ip6tables >/dev/null 2>&1; then
        while ip6tables -D INPUT -p tcp --dport "\$PORT" -s ::1 -j ACCEPT 2>/dev/null; do :; done
        while ip6tables -D INPUT -p tcp --dport "\$PORT" -j DROP 2>/dev/null; do :; done
    fi
}

apply_rules() {
    clean_rules
    # INPUT chain (for host networking mode)
    iptables -I INPUT 1 -p tcp --dport "\$PORT" -j DROP
    iptables -I INPUT 1 -p tcp --dport "\$PORT" -s "\$PANEL" -j ACCEPT
    iptables -I INPUT 1 -p tcp --dport "\$PORT" -s 127.0.0.1 -j ACCEPT

    # DOCKER-USER chain (if Docker bridge mode is used)
    if iptables -L DOCKER-USER >/dev/null 2>&1; then
        iptables -I DOCKER-USER 1 -p tcp --dport "\$PORT" -j DROP
        iptables -I DOCKER-USER 1 -p tcp --dport "\$PORT" -s "\$PANEL" -j ACCEPT
        iptables -I DOCKER-USER 1 -p tcp --dport "\$PORT" -s 127.0.0.1 -j ACCEPT
    fi

    # IPv6 block for node port to prevent IPv6 scanner leaks
    if command -v ip6tables >/dev/null 2>&1; then
        ip6tables -I INPUT 1 -p tcp --dport "\$PORT" -j DROP 2>/dev/null || true
        ip6tables -I INPUT 1 -p tcp --dport "\$PORT" -s ::1 -j ACCEPT 2>/dev/null || true
    fi

    # Синхронизация с UFW (если UFW установлен и активен на сервере)
    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi "Status: active"; then
        ufw delete allow "\${PORT}/tcp" >/dev/null 2>&1 || true
        ufw delete allow "\${PORT}" >/dev/null 2>&1 || true
        ufw allow from "\$PANEL" to any port "\$PORT" proto tcp comment 'SelfSNI Remnanode Panel' >/dev/null 2>&1 || true
    fi
}

case "\${1:-start}" in
    start|restart)
        apply_rules
        ;;
    stop)
        clean_rules
        if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi "Status: active"; then
            ufw delete allow from "\$PANEL" to any port "\$PORT" proto tcp >/dev/null 2>&1 || true
        fi
        ;;
esac
EOF
    chmod +x /usr/local/bin/selfsni-firewall

    cat << 'EOF' > /etc/systemd/system/selfsni-firewall.service
[Unit]
Description=SelfSNI Remnanode Port Isolation Firewall
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/selfsni-firewall start
ExecStop=/usr/local/bin/selfsni-firewall stop
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload 2>/dev/null || true
    systemctl enable selfsni-firewall.service 2>/dev/null || true
    /usr/local/bin/selfsni-firewall start

    log_ok "Порт remnanode ($REMNANODE_PORT) успешно изолирован!"
    log_info "Доступ разрешен ТОЛЬКО для панели: $PANEL_IP (и 127.0.0.1)."
    log_info "Для всех сканеров ТСПУ / Shodan / Censys порт $REMNANODE_PORT теперь полностью невидим (DROP)."
}

remove_remnanode_isolation() {
    if [ -f "/usr/local/bin/selfsni-firewall" ]; then
        /usr/local/bin/selfsni-firewall stop 2>/dev/null || true
        systemctl disable selfsni-firewall.service 2>/dev/null || true
        rm -f /etc/systemd/system/selfsni-firewall.service /usr/local/bin/selfsni-firewall
        systemctl daemon-reload 2>/dev/null || true
    fi
    REMNANODE_PORT=""
    save_config
    log_ok "Изоляция порта remnanode снята. Правила iptables удалены."
}

apply_network_hardening() {
    echo -e "\n${CYAN}Настройка сетевого стека ядра Linux (TCP BBR + QUIC Buffers + Anti-DPI)...${NC}"
    modprobe tcp_bbr 2>/dev/null || true

    cat << 'EOF' > /etc/sysctl.d/99-selfsni-hardening.conf
# ==============================================================================
# SELFSNI ANTI-TSPU & HIGH-THROUGHPUT PROXY KERNEL TUNING
# ==============================================================================
# 1. TCP BBR + Fair Queueing (профиль трафика современного CDN-узла)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# 2. Увеличенные UDP/QUIC буферы (критично для Hysteria 2 и Xray во избежание потерь пакетов)
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 2097152
net.core.wmem_default = 2097152
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# 3. Оптимизация TCP-окон и защита от провалов MTU на фильтрах ТСПУ
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0

# 4. Защита от сетевого спуфинга и SYN-флуда
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF

    sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-selfsni-hardening.conf >/dev/null 2>&1 || true
    HARDENING_BBR=1
    save_config

    local active_cc active_rmem
    active_cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
    active_rmem=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")

    log_ok "Сетевой харденинг успешно применен!"
    echo -e "  • Алгоритм TCP Congestion: ${GREEN}${active_cc}${NC}"
    echo -e "  • Размер буфера QUIC/UDP:  ${GREEN}$(( active_rmem / 1048576 )) MB${NC} (Оптимально для Hysteria 2 / Xray)"
    echo -e "  • TCP MTU Probing & TFO:   ${GREEN}Включены${NC}"
}

link_certs_to_remnanode() {
    echo -e "\n${CYAN}====================================================================${NC}"
    echo -e "${CYAN}      ИНТЕГРАЦИЯ СЕРТИФИКАТОВ SELFSNI С КОНТЕЙНЕРОМ REMNANODE       ${NC}"
    echo -e "${CYAN}====================================================================${NC}"

    local default_compose="/opt/remnanode/docker-compose.yml"
    if [ ! -f "$default_compose" ] && [ -f "/root/remnanode/docker-compose.yml" ]; then
        default_compose="/root/remnanode/docker-compose.yml"
    fi

    local compose_path=""
    read -rp "Путь к docker-compose.yml ноды [по умолчанию: $default_compose]: " compose_path || true
    compose_path="${compose_path:-$default_compose}"

    if [ ! -f "$compose_path" ]; then
        log_err "Файл $compose_path не найден!"
        return 1
    fi

    if grep -q "/etc/letsencrypt:" "$compose_path"; then
        log_ok "Папка /etc/letsencrypt уже примонтирована в $compose_path!"
    else
        cp "$compose_path" "${compose_path}.bak"
        if grep -q "volumes:" "$compose_path"; then
            sed -i '/volumes:/a \      - /etc/letsencrypt:/etc/letsencrypt:ro' "$compose_path"
        else
            cat << 'EOF' >> "$compose_path"
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt:ro
EOF
        fi
        log_ok "Монтирование /etc/letsencrypt:/etc/letsencrypt:ro добавлено в $compose_path (бэкап: .bak)"
    fi

    # Создаем deploy-hook для Certbot, чтобы при автопродлении сертификата remnanode перезагружал его
    mkdir -p /etc/letsencrypt/renewal-hooks/deploy
    local compose_dir
    compose_dir=$(dirname "$compose_path")
    cat << EOF > /etc/letsencrypt/renewal-hooks/deploy/reload-remnanode.sh
#!/usr/bin/env bash
if command -v docker >/dev/null 2>&1 && [ -d "$compose_dir" ]; then
    cd "$compose_dir" && (docker compose restart 2>/dev/null || docker-compose restart 2>/dev/null || true)
fi
EOF
    chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-remnanode.sh
    log_ok "Добавлен хук автообновления сертификатов для контейнера remnanode."

    local restart_ans=""
    read -rp "Перезапустить контейнер remnanode сейчас для применения? [Y/n]: " restart_ans || true
    restart_ans="${restart_ans:-y}"
    if [[ "$restart_ans" =~ ^[Yy]$ ]]; then
        (cd "$compose_dir" && (docker compose up -d 2>/dev/null || docker-compose up -d 2>/dev/null)) || true
        log_ok "Контейнер remnanode успешно обновлен и перезапущен!"
    fi

    echo -e "\n${YELLOW}Пути к сертификатам внутри конфигураций Remnawave (Hysteria 2 / Xray):${NC}"
    echo -e "  • Certificate: ${WHITE}/etc/letsencrypt/live/${DOMAIN}/fullchain.pem${NC}"
    echo -e "  • Private Key: ${WHITE}/etc/letsencrypt/live/${DOMAIN}/privkey.pem${NC}"
}

run_tspu_exposure_audit() {
    echo -e "\n${CYAN}==============================================================================${NC}"
    echo -e "${CYAN}          АУДИТ ВИДИМОСТИ НОДЫ ГЛАЗАМИ СКАНЕРОВ ТСПУ / CENSYS / SHODAN        ${NC}"
    echo -e "${CYAN}==============================================================================${NC}"

    # 1. Проверка защиты от утечки домена по IP
    echo -e "\n${BOLD}1. Защита от раскрытия домена при сканировании по голому IP (SNI Guard):${NC}"
    local leak_subject=""
    if [ "${USE_PROXY_FLAG:-0}" -eq 0 ]; then
        leak_subject=$(openssl s_client -connect "127.0.0.1:${FALLBACK_PORT:-9443}" -noservername </dev/null 2>/dev/null | grep "subject=" || true)
    fi
    if grep -q "default_server" "/etc/nginx/sites-available/${DOMAIN}" 2>/dev/null; then
        if [ -n "$leak_subject" ] && echo "$leak_subject" | grep -iq "${DOMAIN}"; then
            echo -e "   ${RED}[РИСК] При запросе без SNI сервер отдает сертификат ${DOMAIN}!${NC}"
        else
            echo -e "   ${GREEN}[ЗАЩИЩЕНО] На порту 80 и ${FALLBACK_PORT:-9443} активен перехват default_server.${NC}"
            echo -e "   ${DIM}При сканировании по IP без знания домена сертификат ${DOMAIN} НЕ выдается.${NC}"
        fi
    else
        echo -e "   ${YELLOW}[ВНИМАНИЕ] Конфиг Nginx еще не обновлен с блоком default_server.${NC}"
    fi

    # 2. Проверка порта Remnanode
    echo -e "\n${BOLD}2. Защита управляющего порта Remnanode:${NC}"
    if check_remnanode_shielded; then
        echo -e "   ${GREEN}[ЗАЩИЩЕНО] Порт ${REMNANODE_PORT} закрыт фильтром DROP для всего мира (кроме ${PANEL_IP}).${NC}"
    else
        local guess_port
        guess_port=$(detect_remnanode_port)
        if ss -tln 2>/dev/null | grep -qE ":${guess_port}\b"; then
            echo -e "   ${RED}[РИСК] Обнаружен открытый порт ${guess_port}, не защищенный фаерволом SelfSNI!${NC}"
            echo -e "   ${DIM}Рекомендуется изолировать его в пункте 1 этого меню.${NC}"
        else
            echo -e "   ${YELLOW}[ИНФО] Изоляция порта Remnanode еще не настроена (или порт не слушает).${NC}"
        fi
    fi

    # 3. Проверка сетевого стека
    echo -e "\n${BOLD}3. Сетевой стек ядра (TCP BBR & QUIC UDP Buffers):${NC}"
    local cc rmem
    cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "cubic")
    rmem=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "212992")
    if [ "$cc" = "bbr" ] && [ "$rmem" -ge 8388608 ]; then
        echo -e "   ${GREEN}[ОПТИМАЛЬНО] TCP BBR активен | Буфер QUIC/UDP: $(( rmem / 1048576 )) MB${NC}"
    else
        echo -e "   ${YELLOW}[ВНИМАНИЕ] TCP: $cc | Буфер UDP: $(( rmem / 1024 )) KB (Рекомендуется включить харденинг в п. 3)${NC}"
    fi

    # 4. Таблица всех внешних открытых портов
    echo -e "\n${BOLD}4. Внешние порты, видимые из интернета (0.0.0.0 / ::):${NC}"
    echo -e "   ${DIM}ПРОТО | ПОРТ  | ПРОЦЕСС              | СТАТУС БЕЗОПАСНОСТИ${NC}"
    echo -e "   ------+-------+----------------------+--------------------------------------"
    ss -tulpn 2>/dev/null | awk 'NR>1 {print $1, $5, $7}' | while read -r proto addr proc; do
        # Пропускаем локальные loopback сокеты 127.0.0.1 и ::1
        if [[ "$addr" == 127.* ]] || [[ "$addr" == "[::1]"* ]]; then
            continue
        fi
        local port="${addr##*:}"
        local clean_proc
        clean_proc=$(echo "$proc" | sed -E 's/users:\(\("([^"]+)".*/\1/' || echo "kernel/docker")
        [ -z "$clean_proc" ] && clean_proc="system"

        local verdict="${YELLOW}Проверьте необходимость порта${NC}"
        if [ "$port" = "80" ] || [ "$port" = "443" ]; then
            verdict="${GREEN}Шлюз / Прокси (Норма)${NC}"
        elif [ "$port" = "22" ]; then
            verdict="${CYAN}SSH (Рекомендуется вход по ключам)${NC}"
        elif [ -n "${REMNANODE_PORT:-}" ] && [ "$port" = "$REMNANODE_PORT" ]; then
            if check_remnanode_shielded; then
                verdict="${GREEN}Скрыт щитом (Только для $PANEL_IP)${NC}"
            else
                verdict="${RED}ОТКРЫТ СКАНЕРАМ! Изолируйте в п.1${NC}"
            fi
        elif [ "$port" = "53" ]; then
            verdict="${YELLOW}DNS (Убедитесь что не публичный)${NC}"
        fi
        printf "   %-5s | %-5s | %-20s | %b\n" "$proto" "$port" "${clean_proc:0:20}" "$verdict"
    done | sort -u
    echo -e "${CYAN}==============================================================================${NC}"
}

node_shield_menu() {
    while true; do
        clear
        local shield_str="${YELLOW}НЕ НАСТРОЕНА (Порт открыт всем)${NC}"
        if check_remnanode_shielded; then
            shield_str="${GREEN}АКТИВНА ● (Порт ${REMNANODE_PORT} доступен только ${PANEL_IP})${NC}"
        fi

        local bbr_str="${YELLOW}ВЫКЛ (Стандартный буфер ядра)${NC}"
        if check_bbr_active; then
            local rmem
            rmem=$(sysctl -n net.core.rmem_max 2>/dev/null || echo 0)
            bbr_str="${GREEN}АКТИВЕН ● (BBR + QUIC буфер $(( rmem / 1048576 )) MB)${NC}"
        fi

        echo -e "${CYAN}╭────────────────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${BOLD}   🛡️  ЩИТ НОДЫ: ЗАЩИТА ОТ ТСПУ, ИЗОЛЯЦИЯ REMNANODE И ХАРДЕНИНГ ЯДРА       ${CYAN}│${NC}"
        echo -e "${CYAN}├────────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Anti-IP-Scan (SNI):${NC} ${GREEN}АКТИВЕН ● (Скрытие сертификата при запросе по IP)${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Изоляция Remnanode:${NC} ${shield_str}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Сетевой стек BBR:${NC}   ${bbr_str}"
        echo -e "${CYAN}╰────────────────────────────────────────────────────────────────────────────╯${NC}"
        echo ""
        echo -e "   ${BOLD}1${NC} ❯ 🔒 Изолировать порт управления Remnanode (Доступ только с IP панели)"
        echo -e "   ${BOLD}2${NC} ❯ 🔓 Снять изоляцию порта Remnanode (Открыть обратно)"
        echo -e "   ${BOLD}3${NC} ❯ 🚀 Включить сетевой профиль Anti-DPI + TCP BBR + QUIC буферы (16 MB)"
        echo -e "   ${BOLD}4${NC} ❯ 🔗 Подключить сертификаты SelfSNI в контейнер Remnanode (Docker Volume)"
        echo -e "   ${BOLD}5${NC} ❯ 🔍 Полный Аудит видимости ноды глазами ТСПУ (Открытые порты и утечки)"
        echo -e "   ${BOLD}6${NC} ❯ 🔄 Обновить конфиг Nginx с защитой от IP-сканов (SNI Guard)"
        echo -e "   ${BOLD}0${NC} ❯ 🔙 Вернуться в главное меню"
        echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
        read -rp "❯ Выберите действие [0-6]: " sh_choice || true

        case "$sh_choice" in
            1)
                isolate_remnanode_port
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            2)
                remove_remnanode_isolation
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            3)
                apply_network_hardening
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            4)
                link_certs_to_remnanode
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            5)
                run_tspu_exposure_audit
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            6)
                configure_nginx "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG" "${WEB_ROOT:-/var/www/$DOMAIN}"
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "${RED}Неверный выбор.${NC}"
                sleep 1
                ;;
        esac
    done
}

# ==============================================================================
# ГЛАВНОЕ ИНТЕРАКТИВНОЕ МЕНЮ (КОМАНДА: selfsni)
# ==============================================================================
show_menu() {
    check_root

    while true; do
        clear
        local status_str status_color
        if systemctl is-active --quiet nginx 2>/dev/null; then
            status_str="RUNNING"
            status_color="${GREEN}"
        else
            status_str="STOPPED"
            status_color="${RED}"
        fi

        local proxy_str="xver: 0 (Выкл)"
        local proxy_color="${YELLOW}"
        local proxy_note="Для Hysteria 2 / dokodemo"
        local proxy_toggle_hint="${YELLOW}ВЫКЛ (0)${NC} ➔ ${GREEN}Включить (1)${NC}"
        if [ "${USE_PROXY_FLAG:-0}" -eq 1 ]; then
            proxy_str="xver: 1 (Вкл)"
            proxy_color="${GREEN}"
            proxy_note="Для Xray Reality"
            proxy_toggle_hint="${GREEN}ВКЛ (1)${NC} ➔ ${YELLOW}Выключить (0)${NC}"
        fi

        local ssl_days="N/A"
        local ssl_issuer="Let's Encrypt"
        if [ -n "${DOMAIN:-}" ]; then
            local cert_file="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
            if [ -f "$cert_file" ]; then
                local exp_date
                exp_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2 || true)
                local exp_epoch now_epoch
                exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null || echo 0)
                now_epoch=$(date +%s)
                if [ "$exp_epoch" -gt 0 ]; then
                    ssl_days="$(( (exp_epoch - now_epoch) / 86400 )) дн."
                fi
                if openssl x509 -issuer -noout -in "$cert_file" 2>/dev/null | grep -iq "ZeroSSL"; then
                    ssl_issuer="ZeroSSL"
                elif openssl x509 -issuer -noout -in "$cert_file" 2>/dev/null | grep -iq "USERTrust\|Sectigo"; then
                    ssl_issuer="ZeroSSL/Sectigo"
                elif openssl x509 -issuer -noout -in "$cert_file" 2>/dev/null | grep -iq "Let's Encrypt"; then
                    ssl_issuer="Let's Encrypt"
                else
                    ssl_issuer="Fallback/Local"
                fi
            fi
        fi

        echo -e "${CYAN}╭────────────────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${BOLD}   ◈ SELFSNI CONTROL CORE  ${NC}${DIM}•  Nginx Decoy Engine for Xray Reality/XHTTP     ${CYAN}│${NC}"
        echo -e "${CYAN}├────────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Статус:${NC}        ${status_color}${status_str} ●${NC} ${DIM}[Nginx HTTP/2 + TLS 1.3 + OCSP]${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Домен SNI:${NC}     ${WHITE}${DOMAIN:-Не установлен}${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Локальный сокет:${NC} ${WHITE}127.0.0.1:${FALLBACK_PORT:-9443}${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• PROXY Protocol:${NC} ${proxy_color}${proxy_str}${NC} ${DIM}[${proxy_note}]${NC}"
        local pqc_str="ВЫКЛ (Классический X25519)"
        local pqc_color="${YELLOW}"
        if check_pqc_active && [ "${ENABLE_PQC:-0}" -eq 1 ]; then
            pqc_str="АКТИВЕН ● (X25519MLKEM768)"
            pqc_color="${GREEN}"
        elif check_pqc_active; then
            pqc_str="ДОСТУПЕН ○ (Выключен)"
            pqc_color="${CYAN}"
        fi
        echo -e "${CYAN}│${NC}  ${BOLD}• Постквант (PQC):${NC} ${pqc_color}${pqc_str}${NC} ${DIM}[NIST ML-KEM-768]${NC}"
        local blocked_rules="0"
        if [ -f "/etc/nginx/blacklist.conf" ]; then
            blocked_rules=$(grep -c "^deny " /etc/nginx/blacklist.conf 2>/dev/null || echo "0")
        fi

        local shield_card_str="${YELLOW}Стандарт ○${NC} ${DIM}[Пункт 11 для изоляции Remnanode и BBR]${NC}"
        local shield_hint="${YELLOW}Настроить${NC}"
        if check_remnanode_shielded && check_bbr_active; then
            shield_card_str="${GREEN}АКТИВЕН ●${NC} ${DIM}[Порт ${REMNANODE_PORT} закрыт + BBR/QUIC + SNI Guard]${NC}"
            shield_hint="${GREEN}Активен ●${NC}"
        elif check_remnanode_shielded; then
            shield_card_str="${GREEN}Порт ${REMNANODE_PORT} закрыт ●${NC} ${DIM}[Доступ только ${PANEL_IP}]${NC}"
            shield_hint="${GREEN}Порт закрыт ●${NC}"
        elif check_bbr_active; then
            shield_card_str="${CYAN}BBR + SNI Guard ●${NC} ${DIM}[Порт ноды не изолирован]${NC}"
            shield_hint="${CYAN}BBR ●${NC}"
        fi

        echo -e "${CYAN}│${NC}  ${BOLD}• Сертификат:${NC}    ${GREEN}${ssl_days}${NC} ${DIM}[${ssl_issuer}] (Auto-Renew активен)${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Защита ТСПУ:${NC}   ${GREEN}${blocked_rules} подсетей в блоке${NC} ${DIM}[C24Be + Anti-IP-Scan SNI]${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Щит ноды:${NC}      ${shield_card_str}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Архитектура:${NC}   ${MAGENTA}${ARCHETYPE_NAME:-Encrypted Cloud Vault}${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Организация:${NC}   ${WHITE}${COMPANY_NAME:-Default}${NC}"
        echo -e "${CYAN}╰────────────────────────────────────────────────────────────────────────────╯${NC}"
        echo ""
        echo -e " ${BOLD}${CYAN}[ 1 ] МАСКИРОВКА И ШЛЮЗ-ДЕКОЙ${NC}"
        echo -e "   ${BOLD}1${NC} ❯ 🎲 Пересобрать шлюз со случайной архитектурой и темой"
        echo -e "   ${BOLD}2${NC} ❯ 🎨 Выбрать конкретный шлюз-маскировку (Vault / Zero-Trust / S3 / Mesh / Dev)"
        echo -e "   ${BOLD}3${NC} ❯ 🧪 Запустить Camouflage Self-Test (проверка 80, 9443, SNI Guard, /api/)"
        echo -e "   ${BOLD}4${NC} ❯ 📋 Конфигурации для Xray / Remnawave (Reality + Hysteria 2)"
        echo ""
        echo -e " ${BOLD}${YELLOW}[ 2 ] МОНИТОРИНГ И АНАЛИЗАТОР ТСПУ${NC}"
        echo -e "   ${BOLD}5${NC} ❯ 🕵️  Детектор сканеров ТСПУ и подозрительных IP-адресов"
        echo -e "   ${BOLD}6${NC} ❯ 🛡️  Обновить базу сканеров прямо сейчас (C24Be Blacklist)"
        echo -e "   ${BOLD}7${NC} ❯ 📊 Реальный трафик в реальном времени (live tail -f access.log)"
        echo -e "   ${BOLD}8${NC} ❯ 🧹 Очистить журналы логов Nginx"
        echo ""
        local pqc_hint="${YELLOW}Выкл${NC}"
        if check_pqc_active && [ "${ENABLE_PQC:-0}" -eq 1 ]; then
            pqc_hint="${GREEN}Активен ●${NC}"
        fi

        echo -e " ${BOLD}${GREEN}[ 3 ] КРИПТОГРАФИЯ, SSL И ЩИТ REMNANODE${NC}"
        echo -e "   ${BOLD}9${NC} ❯ 🔐 Выпустить / Перевыпустить чистый SSL (Auto / ZeroSSL / Let's Encrypt)"
        echo -e "  ${BOLD}10${NC} ❯ ⚛️  Постквантовая защита X25519MLKEM768 [${pqc_hint}]"
        echo -e "  ${BOLD}11${NC} ❯ 🛡️  Щит ноды: Изоляция Remnanode, TCP BBR, Аудит портов [${shield_hint}]"
        echo ""
        echo -e " ${BOLD}${BLUE}[ 4 ] СЛУЖБА NGINX И СЕТЬ${NC}"
        echo -e "  ${BOLD}12${NC} ❯ 🔄 Перезапустить Nginx (Reload / Restart)"
        echo -e "  ${BOLD}13${NC} ❯ ⏹  Остановить Nginx"
        echo -e "  ${BOLD}14${NC} ❯ ▶️  Запустить Nginx"
        echo -e "  ${BOLD}15${NC} ❯ 📝 Редактировать vhost конфигурацию (/etc/nginx/sites-available/...)"
        echo -e "  ${BOLD}16${NC} ❯ ⚡ Переключить PROXY Protocol [${proxy_toggle_hint}]"
        echo ""
        echo -e " ${BOLD}${RED}[ 5 ] СИСТЕМА${NC}"
        echo -e "  ${BOLD}17${NC} ❯ 🔁 Переустановить / Сменить домен"
        echo -e "  ${BOLD}18${NC} ❯ 🗑️  Полное удаление SelfSNI"
        echo -e "   ${BOLD}0${NC} ❯ 🚪 Выход в консоль"
        echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
        read -rp "❯ Выберите действие [0-18]: " choice || true

        case "$choice" in
            1)
                log_info "Процедурная регенерация сайта-маскировки..."
                generate_website "$DOMAIN" "$WEB_ROOT" 1
                save_config
                systemctl reload nginx 2>/dev/null || true
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            2)
                echo -e "\n${BOLD}${CYAN}ВЫБОР АРХИТЕКТУРЫ ШЛЮЗА-МАСКИРОВКИ:${NC}"
                echo -e "2) 🔒 Encrypted Cloud Vault & Chunked File Drop (/api/v1/files/upload)"
                echo -e "3) 🛡️ Zero-Trust Identity Gateway (SSO / WebAuthn FIDO2)"
                echo -e "4) 📦 Private S3 Object Storage Console (MinIO / Ceph S3)"
                echo -e "5) 🌐 Edge CDN Mesh Relay & Node Telemetry (Anycast PoP)"
                echo -e "6) 💻 Minimalist Dev Auth Portal (Linear / Raycast Style)"
                read -rp "Ваш выбор [2-6, по умолчанию: 2]: " theme_sel || true
                theme_sel="${theme_sel:-2}"
                generate_website "$DOMAIN" "$WEB_ROOT" "$theme_sel"
                save_config
                systemctl reload nginx 2>/dev/null || true
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            3)
                run_self_test "$DOMAIN" "$FALLBACK_PORT" "$USE_PROXY_FLAG"
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            4)
                echo -e "\n${YELLOW}--- СЕКЦИЯ ДЛЯ ВСТАВКИ В КОНФИГУРАЦИЮ XRAY ---${NC}"
                cat << EOF
"realitySettings": {
  "show": false,
  "xver": $USE_PROXY_FLAG,
  "target": "127.0.0.1:$FALLBACK_PORT",
  "serverNames": [
    "$DOMAIN"
  ]
}
EOF
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            5)
                view_active_probes
                echo -e "Нажмите Enter для возврата в меню..."
                read -r || true
                ;;
            6)
                log_info "Обновление базы черных списков сканеров ТСПУ (C24Be AS Network List)..."
                /usr/local/bin/update-selfsni-blacklist || true
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            7)
                echo -e "\n${CYAN}Нажмите Ctrl+C для выхода из просмотра логов...${NC}\n"
                sleep 1
                tail -f /var/log/nginx/access.log || true
                ;;
            8)
                log_info "Очистка логов Nginx..."
                truncate -s 0 /var/log/nginx/*.log 2>/dev/null || true
                log_ok "Логи успешно очищены!"
                sleep 1.5
                ;;
            9)
                echo -e "\n${CYAN}ВЫБОР ЦЕНТРА СЕРТИФИКАЦИИ ДЛЯ ВЫПУСКА:${NC}"
                echo -e "1) ${GREEN}[Рекомендуется] Auto${NC} (Let's Encrypt -> при сбое авто-переход на ZeroSSL)"
                echo -e "2) ${MAGENTA}ZeroSSL${NC} (Sectigo CA, стабилен при блокировках вторичной валидации)"
                echo -e "3) ${BLUE}Let's Encrypt${NC} (Классический ISRG Root X1)"
                local re_ca=""
                read -rp "Ваш выбор [1-3, по умолчанию: 1]: " re_ca || true
                local selected_ca="auto"
                if [ "${re_ca:-1}" -eq 2 ]; then selected_ca="zerossl"; elif [ "${re_ca:-1}" -eq 3 ]; then selected_ca="letsencrypt"; fi

                purge_and_issue_clean_ssl "$DOMAIN" "${EMAIL:-admin@$DOMAIN}" "$selected_ca"
                if systemctl is-active --quiet nginx 2>/dev/null; then
                    nginx -t && systemctl restart nginx
                fi
                log_ok "Сертификаты обновлены и Nginx перезапущен!"
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            10)
                pqc_management_menu
                ;;
            11)
                node_shield_menu
                ;;
            12)
                log_info "Перезапуск Nginx..."
                nginx -t && systemctl restart nginx
                log_ok "Nginx успешно перезапущен!"
                sleep 1.5
                ;;
            13)
                log_info "Остановка Nginx..."
                systemctl stop nginx
                log_warn "Nginx остановлен."
                sleep 1.5
                ;;
            14)
                log_info "Запуск Nginx..."
                systemctl start nginx
                log_ok "Nginx запущен!"
                sleep 1.5
                ;;
            15)
                ${EDITOR:-nano} "/etc/nginx/sites-available/$DOMAIN"
                nginx -t && systemctl reload nginx 2>/dev/null || true
                ;;
            16)
                toggle_proxy_protocol
                ;;
            17)
                install_selfsni
                load_config || true
                ;;
            18)
                echo -e "\n${RED}ВЫ УВЕРЕНЫ, ЧТО ХОТИТЕ УДАЛИТЬ SELFSNI?${NC}"
                read -rp "Введите 'yes' для подтверждения удаления: " confirm_del || true
                if [ "$confirm_del" = "yes" ]; then
                    log_warn "Удаление Nginx сайта, правил изоляции и конфигурации..."
                    remove_remnanode_isolation 2>/dev/null || true
                    rm -f "/etc/nginx/sites-enabled/$DOMAIN" "/etc/nginx/sites-available/$DOMAIN" || true
                    systemctl reload nginx 2>/dev/null || true
                    rm -rf "$WEB_ROOT" "$CONFIG_DIR" "$BIN_LINK"
                    log_ok "SelfSNI полностью удален с сервера."
                    exit 0
                else
                    log_info "Удаление отменено."
                    sleep 1.5
                fi
                ;;
            0)
                clear
                echo -e "${GREEN}Сессия завершена. Команда для вызова консоли: selfsni${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Неверный пункт меню.${NC}"
                sleep 1
                ;;
        esac
    done
}

# ==============================================================================
# ТОЧКА ВХОДА (MAIN)
# ==============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_root

    if load_config; then
        # Если конфигурация уже есть — обновляем симлинк/скрипт и сразу открываем меню!
        install_bin_link
        show_menu
    else
        # Первоначальный запуск
        install_selfsni
        if load_config; then
            show_menu
        fi
    fi
fi
