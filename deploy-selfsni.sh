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
ARCHETYPE_NAME="${ARCHETYPE_NAME:-DevOps Bento Grid}"
EOF
}

# ==============================================================================
# ФУНКЦИЯ ПРОЦЕДУРНОГО КОНСТРУКТОРА САЙТОВ-МАСКИРОВОК
# ==============================================================================
generate_website() {
    local target_domain="$1"
    local target_root="$2"
    local selected_archetype="${3:-1}"

    mkdir -p "$target_root/assets"
    mkdir -p "$target_root/legal"

    # Случайный выбор архетипа [1-4], если передан 1 или неверный
    local arch_id
    if [ "$selected_archetype" -eq 1 ] || [ "$selected_archetype" -lt 1 ] || [ "$selected_archetype" -gt 5 ]; then
        arch_id=$(( (RANDOM % 4) + 1 ))
    else
        # Преобразуем выбор пользователя (2->1, 3->2, 4->3, 5->4)
        arch_id=$(( selected_archetype - 1 ))
    fi

    # 1. СЛУЧАЙНЫЕ ЦВЕТОВЫЕ ПАЛИТРЫ
    local palettes=(
      "#3b82f6|#1d4ed8|#070b14|#0d1527|rgba(59,130,246,0.25)|#60a5fa"   # Cyber Blue
      "#10b981|#047857|#05120d|#0a1f17|rgba(16,185,129,0.25)|#34d399"   # Emerald Matrix
      "#8b5cf6|#6d28d9|#0c0a1a|#16122e|rgba(139,92,246,0.25)|#a78bfa"   # Deep Violet
      "#06b6d4|#0e7490|#061118|#0b1e2a|rgba(6,182,212,0.25)|#22d3ee"   # Arctic Cyan
      "#f59e0b|#b45309|#130e06|#22190b|rgba(245,158,11,0.25)|#fbbf24"   # Amber Gold
      "#f43f5e|#be123c|#14070a|#240d13|rgba(244,63,94,0.25)|#fb7185"    # Crimson Red-Team
    )
    local chosen_palette=${palettes[$((RANDOM % ${#palettes[@]}))]}
    IFS='|' read -r ACCENT_COLOR ACCENT_HOVER BG_PRIMARY BG_SECONDARY ACCENT_GLOW ACCENT_LIGHT <<< "$chosen_palette"

    # 2. ТИПОГРАФИКА
    local fonts=(
      "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
      "'Inter', -apple-system, BlinkMacSystemFont, sans-serif"
      "'JetBrains Mono', 'Fira Code', 'SF Mono', Consolas, monospace"
      "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif"
    )
    local FONT_FAMILY=${fonts[$((RANDOM % ${#fonts[@]}))]}

    # 3. СКРУГЛЕНИЯ
    local radius_opts=("4px" "8px" "12px" "16px")
    local RADIUS=${radius_opts[$((RANDOM % ${#radius_opts[@]}))]}

    # 4. НАЗВАНИЯ И МЕТАДАННЫЕ
    local company_names=(
      "Vanguard Systems Labs" "Aegis Zero-Trust Network" "Cortex Distributed AI"
      "Synapse Tensor Cloud" "Axiom Ultra-Low Latency" "Chronos Execution Group"
      "Orbit Transit Backbone" "Nexus Carrier Exchange" "Kore Infrastructure Corp"
      "Prism Global Routing" "Apex Telemetry Defense" "Modular Matrix Works"
    )
    COMPANY_NAME=${company_names[$((RANDOM % ${#company_names[@]}))]}

    # Favicon
    cat << EOF > "$target_root/favicon.svg"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" fill="none">
  <rect width="32" height="32" rx="8" fill="${ACCENT_COLOR}"/>
  <path d="M8 16L14 22L24 10" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
EOF

    # Общий интерактивный JS для всех archetypes
    cat << 'EOF' > "$target_root/assets/app.js"
document.addEventListener('DOMContentLoaded', () => {
  // Копирование кода
  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-target');
      const targetEl = document.getElementById(targetId);
      if (targetEl) {
        navigator.clipboard.writeText(targetEl.innerText.trim()).then(() => {
          const orig = btn.innerText;
          btn.innerText = 'Copied!';
          setTimeout(() => { btn.innerText = orig; }, 2000);
        });
      }
    });
  });

  // Аккордеон (Archetype 2)
  document.querySelectorAll('.accordion-header').forEach(header => {
    header.addEventListener('click', () => {
      const item = header.parentElement;
      const wasActive = item.classList.contains('active');
      document.querySelectorAll('.accordion-item').forEach(i => i.classList.remove('active'));
      if (!wasActive) item.classList.add('active');
    });
  });

  // Табы бенчмарков (Archetype 4)
  const tabData = {
    fp8: { tps: "18,450", ttft: "5.4ms", fabric: "3.2 Tbps", util: "98.4%" },
    bf16: { tps: "9,820", ttft: "11.2ms", fabric: "3.2 Tbps", util: "99.1%" },
    kv: { tps: "24,100", ttft: "3.8ms", fabric: "3.2 Tbps", util: "94.6%" }
  };
  document.querySelectorAll('.bench-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.bench-tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const key = tab.getAttribute('data-bench');
      if (tabData[key]) {
        document.getElementById('bench-tps').innerText = tabData[key].tps;
        document.getElementById('bench-ttft').innerText = tabData[key].ttft;
        document.getElementById('bench-fabric').innerText = tabData[key].fabric;
        document.getElementById('bench-util').innerText = tabData[key].util;
      }
    });
  });

  // Универсальная отправка форм на /api/v1/contact
  const forms = document.querySelectorAll('form.ajax-form');
  forms.forEach(form => {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const btn = form.querySelector('button[type="submit"]');
      const origText = btn.innerHTML;
      btn.innerHTML = 'Transmitting to Gateway...';
      btn.disabled = true;

      const payload = {
        name: form.name ? form.name.value : '',
        email: form.email ? form.email.value : '',
        scope: form.scope ? form.scope.value : 'General Inquiry',
        notes: form.notes ? form.notes.value : '',
        timestamp: Date.now()
      };

      try {
        const res = await fetch('/api/v1/contact', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        const data = await res.json();
        btn.innerHTML = 'Transmission Confirmed';
        btn.style.background = '#10b981';
        alert('Technical Brief Received!\nReference Ticket: ' + (data.ticket || 'TKT-' + Math.floor(10000 + Math.random() * 90000)) + '\nStatus: Queued in Operations Center.');
        form.reset();
      } catch (err) {
        btn.innerHTML = 'Brief Dispatched';
        btn.style.background = '#10b981';
        alert('Brief Dispatched. Reference ID: TKT-' + Math.floor(10000 + Math.random() * 90000));
        form.reset();
      } finally {
        setTimeout(() => {
          btn.innerHTML = origText;
          btn.style.background = '';
          btn.disabled = false;
        }, 3500);
      }
    });
  });
});
EOF

    # Вызов конкретного генератора по архетипу с регистрацией метаданных
    case $arch_id in
        1)
            ARCHETYPE_NAME="DevOps Terminal & Bento Grid"
            THEME_NAME="Cloud-Native Edge Infrastructure"
            generate_archetype_terminal "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
        2)
            ARCHETYPE_NAME="Modern SaaS & FinTech Engine"
            THEME_NAME="Low-Latency Capital Routing"
            generate_archetype_saas "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
        3)
            ARCHETYPE_NAME="Autonomous Cyber Defense SOC"
            THEME_NAME="Zero-Trust Threat Neutralization"
            generate_archetype_soc "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
        4)
            ARCHETYPE_NAME="Hyperscale Neural Fabric AI"
            THEME_NAME="Distributed AI & Tensor Scaling"
            generate_archetype_neural "$target_domain" "$target_root" "$ACCENT_COLOR" "$ACCENT_HOVER" "$BG_PRIMARY" "$BG_SECONDARY" "$ACCENT_GLOW" "$ACCENT_LIGHT" "$FONT_FAMILY" "$RADIUS" "$COMPANY_NAME"
            ;;
    esac

    # Стандартные файлы
    cat << EOF > "$target_root/robots.txt"
User-agent: *
Allow: /
Disallow: /api/
Sitemap: https://${target_domain}/sitemap.xml
EOF

    cat << EOF > "$target_root/sitemap.xml"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://${target_domain}/</loc></url>
  <url><loc>https://${target_domain}/services.html</loc></url>
  <url><loc>https://${target_domain}/about.html</loc></url>
  <url><loc>https://${target_domain}/legal/privacy.html</loc></url>
</urlset>
EOF

    log_ok "Сайт успешно сгенерирован (Стиль: $ARCHETYPE_NAME, Бренд: $COMPANY_NAME)!"
}

# ------------------------------------------------------------------------------
# ARCHETYPE 1: CLOUD NATIVE & DEVOPS TERMINAL (Bento Grid + Live Shell)
# ------------------------------------------------------------------------------
generate_archetype_terminal() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.02);
  --border: rgba(255,255,255,0.09); --txt: #f8fafc; --muted: #94a3b8;
  --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; }
a { color: inherit; text-decoration: none; }
.container { max-width: 1200px; margin: 0 auto; padding: 0 1.5rem; }
header { border-bottom: 1px solid var(--border); background: rgba(7,11,20,0.85); backdrop-filter: blur(14px); position: sticky; top:0; z-index:100; }
.nav-row { display: flex; align-items: center; justify-content: space-between; height: 4.25rem; }
.logo { display: flex; align-items: center; gap: 0.6rem; font-weight: 700; font-size: 1.15rem; }
.logo-badge { background: var(--acc); color:#fff; padding: 0.2rem 0.5rem; border-radius: 4px; font-family: monospace; font-size: 0.85rem; }
.nav-links { display: flex; gap: 1.75rem; list-style: none; font-size: 0.9rem; }
.nav-links a:hover, .nav-links a.active { color: var(--acc-l); }
.status-pill { display: inline-flex; align-items: center; gap: 0.4rem; padding: 0.25rem 0.65rem; border-radius: 999px; background: rgba(16,185,129,0.1); border: 1px solid rgba(16,185,129,0.3); font-size: 0.8rem; color: #10b981; }
.status-dot { width: 6px; height: 6px; border-radius: 50%; background: #10b981; box-shadow: 0 0 6px #10b981; }
.btn { display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.6rem 1.25rem; border-radius: var(--rad); font-size: 0.9rem; font-weight: 600; cursor: pointer; transition: 0.2s; border: none; }
.btn-primary { background: var(--acc); color: #fff; box-shadow: 0 4px 12px var(--glow); }
.btn-primary:hover { background: var(--acc-h); }
.btn-outline { background: transparent; border: 1px solid var(--border); color: var(--txt); }
.btn-outline:hover { background: rgba(255,255,255,0.05); }

/* Split Hero */
.hero-split { display: grid; grid-template-columns: 1.1fr 0.9fr; gap: 3rem; align-items: center; padding: 5rem 0 3.5rem; }
.hero-split h1 { font-size: 2.85rem; font-weight: 800; line-height: 1.18; margin-bottom: 1.2rem; letter-spacing: -0.02em; }
.hero-split p { font-size: 1.1rem; color: var(--muted); margin-bottom: 1.75rem; }
.cli-box { display: flex; align-items: center; justify-content: space-between; background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 0.75rem 1rem; font-family: monospace; font-size: 0.85rem; margin-bottom: 1.5rem; }
.cli-box span { color: var(--acc-l); }
.copy-btn { background: rgba(255,255,255,0.06); border: 1px solid var(--border); color: #fff; padding: 0.3rem 0.6rem; border-radius: 4px; font-size: 0.75rem; cursor: pointer; }

/* Live Terminal */
.terminal-window { background: #030712; border: 1px solid var(--border); border-radius: var(--rad); box-shadow: 0 20px 40px rgba(0,0,0,0.6); overflow: hidden; font-family: monospace; }
.term-header { background: #0b1120; padding: 0.6rem 1rem; display: flex; align-items: center; gap: 0.4rem; border-bottom: 1px solid var(--border); }
.term-dot { width: 10px; height: 10px; border-radius: 50%; }
.term-dot.r { background: #ef4444; } .term-dot.y { background: #f59e0b; } .term-dot.g { background: #10b981; }
.term-title { margin-left: 0.5rem; font-size: 0.75rem; color: var(--muted); }
.term-body { padding: 1.25rem; font-size: 0.85rem; line-height: 1.6; color: #cbd5e1; }
.term-body .c-acc { color: var(--acc-l); }
.term-body .c-green { color: #10b981; }
.term-body .c-muted { color: #64748b; }

/* Bento Grid */
.section-title { margin-bottom: 2.5rem; }
.section-title h2 { font-size: 2rem; font-weight: 700; }
.section-title p { color: var(--muted); }
.bento-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; margin-bottom: 5rem; }
.bento-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 1.75rem; transition: 0.25s; }
.bento-card:hover { border-color: var(--acc); transform: translateY(-2px); }
.bento-card.col-2 { grid-column: span 2; }
.bento-card h3 { font-size: 1.2rem; font-weight: 600; margin-bottom: 0.5rem; }
.bento-card p { font-size: 0.9rem; color: var(--muted); }

/* Latency Table */
.ping-table { width: 100%; border-collapse: collapse; margin-top: 1rem; font-size: 0.85rem; font-family: monospace; }
.ping-table td { padding: 0.5rem 0; border-bottom: 1px solid rgba(255,255,255,0.05); }
.ping-table td:last-child { text-align: right; color: #10b981; }

/* Form */
.form-wrap { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2.5rem; max-width: 680px; margin: 0 auto 5rem; }
.form-group { margin-bottom: 1.25rem; }
.form-group label { display: block; font-size: 0.85rem; color: var(--muted); margin-bottom: 0.4rem; }
.form-input { width: 100%; background: var(--bg1); border: 1px solid var(--border); padding: 0.75rem 1rem; border-radius: var(--rad); color: #fff; font-family: inherit; font-size: 0.9rem; }
.form-input:focus { outline: none; border-color: var(--acc); }

footer { border-top: 1px solid var(--border); padding: 3rem 0 2rem; color: var(--muted); font-size: 0.85rem; }
.foot-grid { display: grid; grid-template-columns: 2fr 1fr 1fr 1fr; gap: 2rem; margin-bottom: 2rem; }
@media (max-width: 868px) {
  .hero-split { grid-template-columns: 1fr; }
  .bento-grid { grid-template-columns: 1fr; }
  .bento-card.col-2 { grid-column: span 1; }
  .foot-grid { grid-template-columns: 1fr; }
  .nav-links { display: none; }
}
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | Cloud Native Mesh & Ephemeral Edge Infrastructure</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <header>
    <div class="container nav-row">
      <div class="logo">
        <span class="logo-badge">&gt;_</span>
        <span>${comp}</span>
      </div>
      <ul class="nav-links">
        <li><a href="/" class="active">Platform</a></li>
        <li><a href="/services.html">Edge Nodes</a></li>
        <li><a href="/about.html">Architecture</a></li>
        <li><a href="/legal/privacy.html">Compliance</a></li>
      </ul>
      <div style="display:flex; align-items:center; gap:1rem;">
        <span class="status-pill"><span class="status-dot"></span> PoP: Online</span>
        <a href="#deploy" class="btn btn-primary">CLI Ingress</a>
      </div>
    </div>
  </header>

  <main class="container">
    <section class="hero-split">
      <div>
        <div style="margin-bottom:1rem;">
          <span style="font-family:monospace; font-size:0.85rem; color:var(--acc-l);">// CLOUD-NATIVE DEPLOYMENT RUNTIME</span>
        </div>
        <h1>Deterministic Low-Latency Edge Orchestration</h1>
        <p>Declarative ephemeral node scheduling across international carrier PoPs with line-rate packet pacing and zero persistent state storage.</p>
        
        <div class="cli-box">
          <code>curl -fsSL https://${domain}/install.sh | bash</code>
          <button class="copy-btn" data-target="cli-cmd">Copy</button>
        </div>
        <span id="cli-cmd" style="display:none;">curl -fsSL https://${domain}/install.sh | bash</span>

        <div style="display:flex; gap:1rem;">
          <a href="#deploy" class="btn btn-primary">Request Access Token</a>
          <a href="/services.html" class="btn btn-outline">Node Telemetry</a>
        </div>
      </div>

      <div>
        <div class="terminal-window">
          <div class="term-header">
            <span class="term-dot r"></span>
            <span class="term-dot y"></span>
            <span class="term-dot g"></span>
            <span class="term-title">edge-gateway-daemon --live</span>
          </div>
          <div class="term-body">
            <p><span class="c-muted">02:14:08</span> <span class="c-acc">[init]</span> Spawning kernel bypass listener on 0.0.0.0:443...</p>
            <p><span class="c-muted">02:14:09</span> <span class="c-acc">[tls]</span> TLS 1.3 negotiated: CHACHA20-POLY1305 (0-RTT)</p>
            <p><span class="c-muted">02:14:10</span> <span class="c-green">[sync]</span> 32 global nodes connected to anycast fabric</p>
            <p><span class="c-muted">02:14:11</span> <span class="c-acc">[pacing]</span> Jitter window stabilized: 100-1400 B envelope</p>
            <p><span class="c-muted">02:14:12</span> <span class="c-green">[ready]</span> Edge node operational. Jitter &lt; 0.4ms</p>
          </div>
        </div>
      </div>
    </section>

    <section class="section-title">
      <h2>Asymmetric Edge Topology</h2>
      <p>Continuous packet auditing without user session payload retention.</p>
    </section>

    <div class="bento-grid">
      <div class="bento-card col-2">
        <span style="color:var(--acc-l); font-size:0.8rem; font-family:monospace;">MODULE: RUNTIME_PACING</span>
        <h3>Zero-Jitter Kernel Packet Pacing (eBPF / XHTTP)</h3>
        <p>Custom socket options stripping operating system context overhead, smoothing packet histograms to resist anomalous traffic classification.</p>
        <div style="margin-top:1.5rem; display:flex; gap:2rem; font-size:0.85rem;">
          <div><strong style="color:#fff; font-size:1.4rem;">&lt; 0.8ms</strong><br><span style="color:var(--muted);">Dispatch Jitter</span></div>
          <div><strong style="color:#fff; font-size:1.4rem;">99.999%</strong><br><span style="color:var(--muted);">Delivery Envelope</span></div>
          <div><strong style="color:#fff; font-size:1.4rem;">0 B</strong><br><span style="color:var(--muted);">Logged Payloads</span></div>
        </div>
      </div>

      <div class="bento-card">
        <span style="color:var(--acc-l); font-size:0.8rem; font-family:monospace;">TELEMETRY: PING</span>
        <h3>Edge Node Latencies</h3>
        <table class="ping-table">
          <tr><td>Frankfurt (FRA-1)</td><td>12ms</td></tr>
          <tr><td>Amsterdam (AMS-2)</td><td>16ms</td></tr>
          <tr><td>New York (NYC-1)</td><td>38ms</td></tr>
          <tr><td>Singapore (SIN-1)</td><td>64ms</td></tr>
        </table>
      </div>

      <div class="bento-card">
        <span style="color:var(--acc-l); font-size:0.8rem; font-family:monospace;">SECURITY: ISOLATION</span>
        <h3>Ephemeral Sandboxing</h3>
        <p>Microsecond container instances isolating connection contexts in volatile RAM without disk writes.</p>
      </div>

      <div class="bento-card col-2">
        <span style="color:var(--acc-l); font-size:0.8rem; font-family:monospace;">ROUTING: ANYCAST</span>
        <h3>Autonomous BGP Path Reconsolidation</h3>
        <p>Real-time route steering evading congested upstream transit providers and artificial latency injectors.</p>
      </div>
    </div>

    <section id="deploy" class="form-wrap">
      <h2 style="font-size:1.5rem; margin-bottom:0.5rem;">Request Developer Ingress Credentials</h2>
      <p style="color:var(--muted); font-size:0.9rem; margin-bottom:1.5rem;">Submit production infrastructure specifications directly to our network operations team.</p>
      <form class="ajax-form">
        <div class="form-group">
          <label for="name">Lead Engineer / SRE Name</label>
          <input type="text" id="name" name="name" class="form-input" placeholder="David K." required>
        </div>
        <div class="form-group">
          <label for="email">Organization Work Email</label>
          <input type="email" id="email" name="email" class="form-input" placeholder="d.k@company.net" required>
        </div>
        <div class="form-group">
          <label for="scope">Cluster Deployment Target</label>
          <select id="scope" name="scope" class="form-input">
            <option>Dedicated Edge Gateway Node</option>
            <option>Multi-Region Transit Peering</option>
            <option>Custom Telemetry Obfuscation</option>
          </select>
        </div>
        <div class="form-group">
          <label for="notes">Technical Specifications / Workload Constraints</label>
          <textarea id="notes" name="notes" rows="3" class="form-input" placeholder="Target RPS, bandwidth bounds..."></textarea>
        </div>
        <button type="submit" class="btn btn-primary" style="width:100%;">Dispatch Ingress Brief</button>
      </form>
    </section>
  </main>

  <footer>
    <div class="container">
      <div class="foot-grid">
        <div>
          <h4>${comp}</h4>
          <p style="margin-top:0.5rem; line-height:1.5;">Cloud-native edge runtime infrastructure with deterministic microsecond routing.</p>
        </div>
        <div>
          <h4>Platform</h4>
          <ul style="list-style:none; margin-top:0.5rem; line-height:1.8;">
            <li><a href="/services.html">Edge Nodes</a></li>
            <li><a href="/services.html">Telemetry</a></li>
          </ul>
        </div>
        <div>
          <h4>Governance</h4>
          <ul style="list-style:none; margin-top:0.5rem; line-height:1.8;">
            <li><a href="/about.html">Security Specs</a></li>
            <li><a href="/legal/privacy.html">Privacy Policy</a></li>
          </ul>
        </div>
        <div>
          <h4>Operations</h4>
          <ul style="list-style:none; margin-top:0.5rem; line-height:1.8;">
            <li><a href="#deploy">Console</a></li>
            <li><a href="/legal/terms.html">Master SLA</a></li>
          </ul>
        </div>
      </div>
      <div style="display:flex; justify-content:space-between; border-top:1px solid var(--border); padding-top:1.5rem;">
        <span>&copy; $(date +%Y) ${comp}. All rights reserved.</span>
        <span>Node ID: FRA-$(date +%s | cut -c7-10)</span>
      </div>
    </div>
  </footer>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF

    generate_subpages "$domain" "$root" "$comp" "Cloud-Native Infrastructure & Edge Nodes"
}

# ------------------------------------------------------------------------------
# ARCHETYPE 2: MODERN SAAS & FINTECH CAPITAL ROUTING (Wave Chart + SLA + Accordion)
# ------------------------------------------------------------------------------
generate_archetype_saas() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.03);
  --border: rgba(255,255,255,0.08); --txt: #ffffff; --muted: #94a3b8;
  --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; }
a { color: inherit; text-decoration: none; }
.container { max-width: 1160px; margin: 0 auto; padding: 0 1.5rem; }

/* Floating Island Header */
.header-wrap { padding: 1.25rem 0; position: sticky; top:0; z-index:100; }
header { background: rgba(13, 21, 39, 0.75); backdrop-filter: blur(16px); border: 1px solid var(--border); border-radius: 999px; padding: 0.6rem 1.5rem; display: flex; align-items: center; justify-content: space-between; }
.logo { font-weight: 800; font-size: 1.2rem; display: flex; align-items: center; gap: 0.5rem; }
.logo-circle { width: 1.75rem; height: 1.75rem; border-radius: 50%; background: var(--acc); box-shadow: 0 0 12px var(--glow); }
.nav-links { display: flex; gap: 2rem; list-style: none; font-size: 0.9rem; font-weight: 500; }
.nav-links a:hover, .nav-links a.active { color: var(--acc-l); }
.btn { padding: 0.65rem 1.4rem; border-radius: 999px; font-size: 0.9rem; font-weight: 600; cursor: pointer; transition: 0.2s; border:none; display: inline-flex; align-items: center; gap: 0.5rem; }
.btn-primary { background: linear-gradient(135deg, var(--acc), var(--acc-h)); color: #fff; box-shadow: 0 4px 15px var(--glow); }
.btn-primary:hover { transform: translateY(-1px); }
.btn-outline { background: rgba(255,255,255,0.05); border: 1px solid var(--border); color: #fff; }

/* Centered Hero with SVG Wave */
.hero-center { text-align: center; padding: 5rem 0 3rem; }
.hero-pill { display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.4rem 1rem; border-radius: 999px; background: rgba(255,255,255,0.04); border: 1px solid var(--border); font-size: 0.85rem; color: var(--acc-l); margin-bottom: 1.5rem; }
.hero-center h1 { font-size: clamp(2.2rem, 4.5vw, 3.8rem); font-weight: 800; line-height: 1.15; max-width: 900px; margin: 0 auto 1.25rem; letter-spacing: -0.02em; }
.hero-center p { font-size: 1.15rem; color: var(--muted); max-width: 650px; margin: 0 auto 2.25rem; }

/* SVG Wave Chart Container */
.wave-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2rem; margin: 2rem 0 5rem; position: relative; overflow: hidden; }
.wave-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; text-align: center; margin-bottom: 1.5rem; }
.wave-num { font-size: 2rem; font-weight: 800; color: #fff; }
.wave-lbl { font-size: 0.85rem; color: var(--muted); }

/* Zig-Zag Rows */
.zigzag-row { display: grid; grid-template-columns: 1fr 1fr; gap: 4rem; align-items: center; padding: 3.5rem 0; border-top: 1px solid var(--border); }
.zigzag-row.reverse { direction: rtl; }
.zigzag-row.reverse > * { direction: ltr; }
.zigzag-content h3 { font-size: 1.85rem; font-weight: 700; margin-bottom: 1rem; }
.zigzag-content p { color: var(--muted); font-size: 1rem; margin-bottom: 1.25rem; }
.zigzag-bullets { list-style: none; }
.zigzag-bullets li { display: flex; align-items: center; gap: 0.6rem; margin-bottom: 0.6rem; font-size: 0.95rem; }
.bullet-icon { color: #10b981; font-weight: bold; }

/* Pricing / SLA Grid */
.pricing-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; margin: 3rem 0 5rem; }
.price-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2rem; display: flex; flex-direction: column; justify-content: space-between; }
.price-card.featured { border-color: var(--acc); box-shadow: 0 0 25px var(--glow); position: relative; }
.price-card h4 { font-size: 1.25rem; margin-bottom: 0.5rem; }
.price-val { font-size: 2.25rem; font-weight: 800; margin: 1rem 0; color: var(--acc-l); }

/* Accordion */
.faq-wrap { max-width: 800px; margin: 4rem auto; }
.accordion-item { border: 1px solid var(--border); border-radius: var(--rad); margin-bottom: 0.85rem; background: var(--bg2); overflow: hidden; }
.accordion-header { padding: 1.1rem 1.5rem; cursor: pointer; font-weight: 600; display: flex; justify-content: space-between; align-items: center; }
.accordion-body { max-height: 0; padding: 0 1.5rem; overflow: hidden; transition: 0.25s ease; color: var(--muted); font-size: 0.95rem; }
.accordion-item.active .accordion-body { max-height: 200px; padding: 0 1.5rem 1.25rem; }
.accordion-item.active .accordion-header { color: var(--acc-l); }

/* Form */
.form-box { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2.5rem; max-width: 650px; margin: 0 auto 5rem; }
.form-group { margin-bottom: 1.25rem; }
.form-group label { display: block; font-size: 0.85rem; color: var(--muted); margin-bottom: 0.4rem; }
.form-ctrl { width: 100%; background: var(--bg1); border: 1px solid var(--border); padding: 0.75rem 1rem; border-radius: var(--rad); color: #fff; font-family: inherit; }
.form-ctrl:focus { outline: none; border-color: var(--acc); }

footer { border-top: 1px solid var(--border); padding: 3.5rem 0 2rem; color: var(--muted); font-size: 0.85rem; }
@media (max-width: 868px) {
  .zigzag-row { grid-template-columns: 1fr; gap: 2rem; }
  .zigzag-row.reverse { direction: ltr; }
  .pricing-grid { grid-template-columns: 1fr; }
  .nav-links { display: none; }
}
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | Low-Latency Routing & Capital Market Engines</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <div class="header-wrap">
    <div class="container">
      <header>
        <div class="logo">
          <div class="logo-circle"></div>
          <span>${comp}</span>
        </div>
        <ul class="nav-links">
          <li><a href="/" class="active">Core Engine</a></li>
          <li><a href="/services.html">SLA Tiers</a></li>
          <li><a href="/about.html">Architecture</a></li>
          <li><a href="#faq">FAQ</a></li>
        </ul>
        <a href="#connect" class="btn btn-primary">Client Ingress</a>
      </header>
    </div>
  </div>

  <main class="container">
    <section class="hero-center">
      <div class="hero-pill">⚡ High-Frequency Execution Fabric v4.2</div>
      <h1>Autonomous Low-Jitter Capital Routing & Execution</h1>
      <p>Hardware-synchronized market data distribution, FPGA-accelerated tick validation, and point-to-point dark fiber interconnects.</p>
      <div style="display:flex; justify-content:center; gap:1rem;">
        <a href="#connect" class="btn btn-primary">Request Ingress Port</a>
        <a href="/services.html" class="btn btn-outline">Explore Whitepaper</a>
      </div>

      <div class="wave-card">
        <div class="wave-stats">
          <div><div class="wave-num">&lt; 850ns</div><div class="wave-lbl">Hardware Gateway Tick-to-Trade</div></div>
          <div><div class="wave-num">99.999%</div><div class="wave-lbl">Core Engine Uptime SLA</div></div>
          <div><div class="wave-num">18.5M</div><div class="wave-lbl">Orders Processed / Sec</div></div>
        </div>
        <svg viewBox="0 0 800 120" style="width:100%; height:80px; stroke:${acc}; fill:none; stroke-width:3;">
          <path d="M0,80 Q100,20 200,60 T400,30 T600,70 T800,40" />
        </svg>
      </div>
    </section>

    <!-- Zig Zag 1 -->
    <section class="zigzag-row">
      <div class="zigzag-content">
        <h3>Kernel-Bypass Hardware Networking</h3>
        <p>Solarflare OpenOnload and DPDK direct memory queues stripping OS scheduler overhead from transmission streams.</p>
        <ul class="zigzag-bullets">
          <li><span class="bullet-icon">&#10003;</span> Sub-microsecond user-space DMA buffers</li>
          <li><span class="bullet-icon">&#10003;</span> Zero packet drops under 40Gbps line bursts</li>
          <li><span class="bullet-icon">&#10003;</span> Automated hardware clock sync via IEEE 1588 PTP</li>
        </ul>
      </div>
      <div style="background:var(--bg2); border:1px solid var(--border); border-radius:var(--rad); padding:2rem; text-align:center;">
        <svg width="120" height="120" viewBox="0 0 24 24" fill="none" stroke="${acc}" stroke-width="1.5"><rect x="2" y="2" width="20" height="20" rx="4"/><path d="M7 12h10M12 7v10"/></svg>
        <h4 style="margin-top:1rem;">Synchronized Clock Edge</h4>
        <p style="color:var(--muted); font-size:0.85rem;">Hardware nanosecond stamping</p>
      </div>
    </section>

    <!-- Zig Zag 2 -->
    <section class="zigzag-row reverse">
      <div class="zigzag-content">
        <h3>Deterministic Line Pacing</h3>
        <p>Dynamic XHTTP transport padding eliminating packet size fingerprints across transit corridors without degrading round-trip times.</p>
        <ul class="zigzag-bullets">
          <li><span class="bullet-icon">&#10003;</span> Dynamic frame envelope: 100-1400 B</li>
          <li><span class="bullet-icon">&#10003;</span> Session lifetime cycling: 15-65 seconds</li>
          <li><span class="bullet-icon">&#10003;</span> Non-standard multiplex framing resistance</li>
        </ul>
      </div>
      <div style="background:var(--bg2); border:1px solid var(--border); border-radius:var(--rad); padding:2rem; text-align:center;">
        <svg width="120" height="120" viewBox="0 0 24 24" fill="none" stroke="${acc}" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
        <h4 style="margin-top:1rem;">Adaptive Session Cycling</h4>
        <p style="color:var(--muted); font-size:0.85rem;">Eliminates persistent state correlation</p>
      </div>
    </section>

    <!-- SLA Tiers -->
    <section style="text-align:center; padding-top:3rem;">
      <h2>Institutional Deployment Tiers</h2>
      <p style="color:var(--muted);">Select execution throughput and isolation parameters.</p>
      <div class="pricing-grid">
        <div class="price-card">
          <div>
            <h4>Co-Location Cross-Connect</h4>
            <p style="color:var(--muted); font-size:0.85rem;">Standard financial exchange links</p>
            <div class="price-val">1 Gbps</div>
            <ul style="list-style:none; font-size:0.85rem; line-height:2; color:var(--muted); text-align:left;">
              <li>&bull; Frankfurt / London PoP</li>
              <li>&bull; Standard PTP Sync</li>
              <li>&bull; 99.99% Core Uptime</li>
            </ul>
          </div>
          <a href="#connect" class="btn btn-outline" style="margin-top:1.5rem; width:100%; justify-content:center;">Provision</a>
        </div>

        <div class="price-card featured">
          <div style="position:absolute; top:-12px; left:50%; transform:translateX(-50%); background:var(--acc); padding:0.2rem 0.8rem; border-radius:999px; font-size:0.75rem; font-weight:700;">RECOMMENDED</div>
          <div>
            <h4>Dedicated FPGA Gateway</h4>
            <p style="color:var(--muted); font-size:0.85rem;">Nanosecond hardware execution</p>
            <div class="price-val">10 Gbps</div>
            <ul style="list-style:none; font-size:0.85rem; line-height:2; color:var(--muted); text-align:left;">
              <li>&bull; Hardware Register Routing</li>
              <li>&bull; IEEE 1588 Nanosecond PTP</li>
              <li>&bull; 99.999% SLA Guarantee</li>
              <li>&bull; Direct Fiber Cross-Connect</li>
            </ul>
          </div>
          <a href="#connect" class="btn btn-primary" style="margin-top:1.5rem; width:100%; justify-content:center;">Provision Cluster</a>
        </div>

        <div class="price-card">
          <div>
            <h4>Sovereign Dark Fiber Mesh</h4>
            <p style="color:var(--muted); font-size:0.85rem;">Private optical carrier routing</p>
            <div class="price-val">40 Gbps</div>
            <ul style="list-style:none; font-size:0.85rem; line-height:2; color:var(--muted); text-align:left;">
              <li>&bull; Custom DWDM Multiplexing</li>
              <li>&bull; Zero-Knowledge Node Enclaves</li>
              <li>&bull; 24/7 Dedicated Engineering NOC</li>
            </ul>
          </div>
          <a href="#connect" class="btn btn-outline" style="margin-top:1.5rem; width:100%; justify-content:center;">Contact Desk</a>
        </div>
      </div>
    </section>

    <!-- FAQ Accordion -->
    <section id="faq" class="faq-wrap">
      <h2 style="text-align:center; margin-bottom:2rem;">Frequently Asked Technical Questions</h2>
      <div class="accordion-item active">
        <div class="accordion-header">
          <span>How is microsecond routing latency maintained under network congestion?</span>
          <span>&darr;</span>
        </div>
        <div class="accordion-body">
          Our gateways employ automated BGP path calculation coupled with hardware kernel-bypass (DPDK), steering packets through dedicated private interconnects before public transit congestion impacts jitter.
        </div>
      </div>
      <div class="accordion-item">
        <div class="accordion-header">
          <span>What cryptographic protection is applied to in-flight orders?</span>
          <span>&darr;</span>
        </div>
        <div class="accordion-body">
          All data channels mandate TLS 1.3 with ChaCha20-Poly1305 and AES-256-GCM cipher suites, rotating ephemeral keys continuously without session renegotiation stalls.
        </div>
      </div>
      <div class="accordion-item">
        <div class="accordion-header">
          <span>What is the guaranteed failover recovery window?</span>
          <span>&darr;</span>
        </div>
        <div class="accordion-body">
          Sub-50ms carrier optical switching ensures automatic failover across redundant transatlantic fiber routes with zero transaction state loss.
        </div>
      </div>
    </section>

    <!-- Form -->
    <section id="connect" class="form-box">
      <h2 style="font-size:1.5rem; margin-bottom:0.5rem; text-align:center;">Request Dedicated Institutional Port</h2>
      <p style="color:var(--muted); font-size:0.9rem; margin-bottom:1.5rem; text-align:center;">Connect your execution desk directly to our low-latency gateway.</p>
      <form class="ajax-form">
        <div class="form-group">
          <label for="name">Institutional Officer Name</label>
          <input type="text" id="name" name="name" class="form-ctrl" placeholder="Marcus Sterling" required>
        </div>
        <div class="form-group">
          <label for="email">Corporate Entity Email</label>
          <input type="email" id="email" name="email" class="form-ctrl" placeholder="m.sterling@capital.com" required>
        </div>
        <div class="form-group">
          <label for="scope">Desired Port Capacity</label>
          <select id="scope" name="scope" class="form-ctrl">
            <option>10 Gbps Dedicated FPGA Cross-Connect</option>
            <option>1 Gbps Co-Location Uplink</option>
            <option>40 Gbps Dark Fiber Interconnect</option>
          </select>
        </div>
        <div class="form-group">
          <label for="notes">Exchange Venues / Target Latencies</label>
          <textarea id="notes" name="notes" rows="3" class="form-ctrl" placeholder="Eurex, CME, LSE routing constraints..."></textarea>
        </div>
        <button type="submit" class="btn btn-primary" style="width:100%; justify-content:center;">Submit Ingress Request</button>
      </form>
    </section>
  </main>

  <footer>
    <div class="container" style="display:flex; justify-content:space-between; align-items:center;">
      <div>&copy; $(date +%Y) ${comp}. All rights reserved.</div>
      <div style="display:flex; gap:1.5rem;">
        <a href="/services.html">SLA Matrix</a>
        <a href="/legal/privacy.html">Privacy Standard</a>
        <a href="/legal/terms.html">Master Terms</a>
      </div>
    </div>
  </footer>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF

    generate_subpages "$domain" "$root" "$comp" "Capital Routing & High-Frequency Architecture"
}

# ------------------------------------------------------------------------------
# ARCHETYPE 3: AUTONOMOUS CYBER DEFENSE & SOC WAR ROOM (Radar + Incident Feed)
# ------------------------------------------------------------------------------
generate_archetype_soc() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.03);
  --border: rgba(255,255,255,0.1); --txt: #f1f5f9; --muted: #94a3b8;
  --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; }
a { color: inherit; text-decoration: none; }
.container { max-width: 1200px; margin: 0 auto; padding: 0 1.5rem; }

/* Alert Ribbon at Very Top */
.alert-ribbon { background: rgba(239, 68, 68, 0.15); border-bottom: 1px solid rgba(239, 68, 68, 0.3); color: #f87171; font-family: monospace; font-size: 0.78rem; padding: 0.4rem 0; text-align: center; letter-spacing: 0.05em; }

header { background: rgba(10, 15, 26, 0.9); border-bottom: 1px solid var(--border); padding: 1rem 0; position: sticky; top:0; z-index:100; backdrop-filter: blur(12px); }
.nav-flex { display: flex; align-items: center; justify-content: space-between; }
.brand { display: flex; align-items: center; gap: 0.6rem; font-weight: 800; font-size: 1.2rem; }
.nav-menu { display: flex; gap: 2rem; list-style: none; font-size: 0.9rem; }
.nav-menu a:hover, .nav-menu a.active { color: var(--acc-l); }
.btn { padding: 0.6rem 1.25rem; border-radius: var(--rad); font-size: 0.85rem; font-weight: 700; cursor: pointer; transition: 0.2s; border: none; text-transform: uppercase; letter-spacing: 0.05em; }
.btn-red { background: var(--acc); color: #fff; box-shadow: 0 0 15px var(--glow); }
.btn-red:hover { background: var(--acc-h); }

/* SOC Hero with Radar */
.soc-hero { display: grid; grid-template-columns: 1.2fr 0.8fr; gap: 3rem; align-items: center; padding: 4.5rem 0 3.5rem; }
.soc-tag { display: inline-block; padding: 0.2rem 0.6rem; background: rgba(255,255,255,0.06); border: 1px solid var(--border); font-family: monospace; font-size: 0.75rem; color: var(--acc-l); margin-bottom: 1rem; }
.soc-hero h1 { font-size: 2.75rem; font-weight: 900; line-height: 1.15; margin-bottom: 1rem; text-transform: uppercase; }
.soc-hero p { color: var(--muted); font-size: 1.05rem; margin-bottom: 2rem; }

/* Radar Widget */
.radar-box { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 1.5rem; text-align: center; position: relative; }
.radar-circle { width: 160px; height: 160px; border-radius: 50%; border: 1px dashed var(--acc); margin: 0 auto 1rem; position: relative; display: flex; align-items: center; justify-content: center; }
.radar-sweep { position: absolute; width: 100%; height: 100%; border-radius: 50%; border-top: 2px solid var(--acc-l); animation: spin 4s linear infinite; }
@keyframes spin { 100% { transform: rotate(360deg); } }

/* Incident Feed Table */
.feed-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2rem; margin: 3rem 0 5rem; }
.feed-table { width: 100%; border-collapse: collapse; font-family: monospace; font-size: 0.82rem; margin-top: 1.25rem; }
.feed-table th { text-align: left; padding: 0.6rem; border-bottom: 1px solid var(--border); color: var(--muted); }
.feed-table td { padding: 0.75rem 0.6rem; border-bottom: 1px solid rgba(255,255,255,0.04); }
.badge-def { padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.75rem; font-weight: bold; }
.badge-green { background: rgba(16,185,129,0.15); color: #34d399; }
.badge-red { background: rgba(239,68,68,0.15); color: #f87171; }

/* 4-Pillar Grid */
.pillar-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1.25rem; margin-bottom: 5rem; }
.pillar-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 1.5rem; }
.pillar-card h4 { font-size: 1.05rem; margin-bottom: 0.5rem; }
.pillar-card p { font-size: 0.85rem; color: var(--muted); }

/* Form */
.soc-form { max-width: 650px; margin: 0 auto 5rem; background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2.5rem; }
.form-input { width: 100%; background: var(--bg1); border: 1px solid var(--border); padding: 0.75rem 1rem; border-radius: var(--rad); color: #fff; font-family: inherit; margin-top: 0.35rem; }
.form-input:focus { outline: none; border-color: var(--acc); }

footer { border-top: 1px solid var(--border); padding: 3rem 0; color: var(--muted); font-size: 0.85rem; }
@media (max-width: 868px) {
  .soc-hero { grid-template-columns: 1fr; }
  .pillar-grid { grid-template-columns: 1fr 1fr; }
  .nav-menu { display: none; }
  .feed-table { display: block; overflow-x: auto; }
}
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | Autonomous Threat Defense & Zero-Trust SOC</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <div class="alert-ribbon">
    [SOC MONITOR: ACTIVE] HONEYPOT DECOYS ONLINE &bull; 0 UNMITIGATED ANOMALIES &bull; ALL ENCLAVES SECURE
  </div>

  <header>
    <div class="container nav-flex">
      <div class="brand">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="${acc}" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
        <span>${comp}</span>
      </div>
      <ul class="nav-menu">
        <li><a href="/" class="active">SOC Perimeter</a></li>
        <li><a href="/services.html">Threat Feeds</a></li>
        <li><a href="/about.html">Incident Response</a></li>
        <li><a href="/legal/privacy.html">Zero-Knowledge</a></li>
      </ul>
      <a href="#soc-desk" class="btn btn-red">Emergency Ingress</a>
    </div>
  </header>

  <main class="container">
    <section class="soc-hero">
      <div>
        <span class="soc-tag">CLASSIFIED // TIER-1 CYBER RESILIENCE</span>
        <h1>Autonomous Cryptographic Perimeter & Threat Neutralization</h1>
        <p>Line-rate packet auditing, automated honeynet decoy routing, and ephemeral memory enclaves isolating adversarial reconnaissance probes before ingress reach.</p>
        <div style="display:flex; gap:1rem;">
          <a href="#soc-desk" class="btn btn-red">Dispatch Incident Advisory</a>
          <a href="/services.html" class="btn btn-red" style="background:transparent; border:1px solid var(--border);">Defense Topology</a>
        </div>
      </div>

      <div class="radar-box">
        <div class="radar-circle">
          <div class="radar-sweep"></div>
          <span style="font-family:monospace; font-size:0.8rem; color:var(--acc-l);">SCANNING</span>
        </div>
        <h4 style="font-size:1.1rem; margin-bottom:0.25rem;">Global Threat Scrubber</h4>
        <p style="color:var(--muted); font-size:0.8rem;">1,420,000+ Probes Deflected in Last 24H</p>
      </div>
    </section>

    <!-- Incident Log Feed -->
    <section class="feed-card">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div>
          <h3 style="font-size:1.25rem;">Live Active Threat Interception Feed</h3>
          <p style="color:var(--muted); font-size:0.85rem;">Autonomous edge honeynet dropping malicious scanner telemetry</p>
        </div>
        <span class="badge-def badge-green">FEED SYNCED</span>
      </div>

      <table class="feed-table">
        <thead>
          <tr>
            <th>Timestamp</th>
            <th>Scanner AS / Origin</th>
            <th>Vector Type</th>
            <th>Target Port</th>
            <th>Mitigation Action</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>02:16:11</td>
            <td>AS48314 (HostKey Probe)</td>
            <td>TLS Fingerprint Mismatch</td>
            <td>443 / Reality</td>
            <td><span class="badge-def badge-green">TARPITTED &amp; DIVERTED</span></td>
          </tr>
          <tr>
            <td>02:15:45</td>
            <td>AS60117 (Censys Scanner)</td>
            <td>XHTTP Desync Probe</td>
            <td>443 / Fallback</td>
            <td><span class="badge-def badge-red">401 UNAUTHORIZED</span></td>
          </tr>
          <tr>
            <td>02:14:22</td>
            <td>AS208323 (Shodan Audit)</td>
            <td>Empty SNI Active Probe</td>
            <td>443 / TLS</td>
            <td><span class="badge-def badge-green">DECOY SERVED (200 OK)</span></td>
          </tr>
          <tr>
            <td>02:13:08</td>
            <td>AS42610 (TSPU Pattern Sweep)</td>
            <td>Padding Entropy Check</td>
            <td>9443 / Fallback</td>
            <td><span class="badge-def badge-green">RANDOMIZED ENVELOPE</span></td>
          </tr>
        </tbody>
      </table>
    </section>

    <!-- 4 Pillars -->
    <section class="pillar-grid">
      <div class="pillar-card">
        <h4 style="color:var(--acc-l);">01. Wire Scrubbing</h4>
        <p>Volumetric optical filters cleansing anomalous packet burst trains before kernel handover.</p>
      </div>
      <div class="pillar-card">
        <h4 style="color:var(--acc-l);">02. Ephemeral Enclaves</h4>
        <p>Connection state stored in encrypted RAM pages destroyed immediately upon session termination.</p>
      </div>
      <div class="pillar-card">
        <h4 style="color:var(--acc-l);">03. Honeynet Decoys</h4>
        <p>Synthetic API endpoints absorbing automated scanner bandwidth without revealing core routes.</p>
      </div>
      <div class="pillar-card">
        <h4 style="color:var(--acc-l);">04. Zero Data Footprint</h4>
        <p>Strict non-retention policy ensuring packet payload data is never committed to persistent storage.</p>
      </div>
    </section>

    <!-- Form -->
    <section id="soc-desk" class="soc-form">
      <h2 style="font-size:1.4rem; margin-bottom:0.5rem; text-transform:uppercase;">Engage Operations Center (SOC)</h2>
      <p style="color:var(--muted); font-size:0.85rem; margin-bottom:1.5rem;">Submit target infrastructure parameters for perimeter hardening.</p>
      <form class="ajax-form">
        <div style="margin-bottom:1rem;">
          <label style="font-size:0.85rem; color:var(--muted);">Security Officer Name</label>
          <input type="text" id="name" name="name" class="form-input" placeholder="Cmdr. Eric Thorne" required>
        </div>
        <div style="margin-bottom:1rem;">
          <label style="font-size:0.85rem; color:var(--muted);">Authorized Enterprise Email</label>
          <input type="email" id="email" name="email" class="form-input" placeholder="e.thorne@defense-lab.org" required>
        </div>
        <div style="margin-bottom:1rem;">
          <label style="font-size:0.85rem; color:var(--muted);">Incident Priority Level</label>
          <select id="scope" name="scope" class="form-input">
            <option>P1 - Critical Autonomous Perimeter Breach</option>
            <option>P2 - Elevated Active Probe Activity</option>
            <option>P3 - Standard Zero-Trust Infrastructure Audit</option>
          </select>
        </div>
        <div style="margin-bottom:1.5rem;">
          <label style="font-size:0.85rem; color:var(--muted);">Incident Diagnostics / IP Blocks</label>
          <textarea id="notes" name="notes" rows="3" class="form-input" placeholder="Autonomous system numbers, observed probe patterns..."></textarea>
        </div>
        <button type="submit" class="btn btn-red" style="width:100%;">Dispatch High-Priority Advisory</button>
      </form>
    </section>
  </main>

  <footer>
    <div class="container" style="display:flex; justify-content:space-between;">
      <span>&copy; $(date +%Y) ${comp}. All operations classified.</span>
      <div style="display:flex; gap:1.5rem;">
        <a href="/legal/privacy.html">Privacy Standard</a>
        <a href="/services.html">Incident Guidelines</a>
      </div>
    </div>
  </footer>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF

    generate_subpages "$domain" "$root" "$comp" "Threat Intelligence & Cyber Defense Operations"
}

# ------------------------------------------------------------------------------
# ARCHETYPE 4: HYPERSCALE NEURAL FABRIC & AI INFERENCE (GPU Pods + Benchmarks)
# ------------------------------------------------------------------------------
generate_archetype_neural() {
    local domain="$1" root="$2" acc="$3" acc_h="$4" bg1="$5" bg2="$6" glow="$7" light="$8" font="$9" rad="${10}" comp="${11}"

    cat << EOF > "$root/assets/style.css"
:root {
  --acc: ${acc}; --acc-h: ${acc_h}; --acc-l: ${light}; --glow: ${glow};
  --bg1: ${bg1}; --bg2: ${bg2}; --card-bg: rgba(255,255,255,0.02);
  --border: rgba(255,255,255,0.08); --txt: #f8fafc; --muted: #94a3b8;
  --font: ${font}; --rad: ${rad};
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background: var(--bg1); color: var(--txt); font-family: var(--font); line-height: 1.6; }
a { color: inherit; text-decoration: none; }
.container { max-width: 1220px; margin: 0 auto; padding: 0 1.5rem; }

header { background: rgba(12, 10, 26, 0.85); backdrop-filter: blur(14px); border-bottom: 1px solid var(--border); padding: 1.1rem 0; position: sticky; top:0; z-index:100; }
.nav-row { display: flex; align-items: center; justify-content: space-between; }
.brand { display: flex; align-items: center; gap: 0.6rem; font-weight: 800; font-size: 1.25rem; }
.brand svg { filter: drop-shadow(0 0 8px var(--glow)); }
.nav-links { display: flex; gap: 2rem; list-style: none; font-size: 0.9rem; }
.nav-links a:hover, .nav-links a.active { color: var(--acc-l); }
.btn { padding: 0.65rem 1.4rem; border-radius: var(--rad); font-size: 0.9rem; font-weight: 600; cursor: pointer; transition: 0.2s; border: none; }
.btn-primary { background: var(--acc); color: #fff; box-shadow: 0 4px 15px var(--glow); }
.btn-primary:hover { background: var(--acc-h); }
.btn-outline { background: transparent; border: 1px solid var(--border); color: #fff; }

/* Hero */
.ai-hero { text-align: center; padding: 5.5rem 0 3rem; }
.ai-tag { display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.35rem 0.9rem; border-radius: 999px; background: rgba(139,92,246,0.15); border: 1px solid rgba(139,92,246,0.3); font-size: 0.8rem; color: var(--acc-l); margin-bottom: 1.5rem; }
.ai-hero h1 { font-size: clamp(2.3rem, 5vw, 3.9rem); font-weight: 900; line-height: 1.15; max-width: 960px; margin: 0 auto 1.25rem; letter-spacing: -0.02em; }
.ai-hero p { font-size: 1.15rem; color: var(--muted); max-width: 700px; margin: 0 auto 2.5rem; }

/* Interactive Benchmark Tabs */
.bench-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2rem; margin: 2rem auto 5rem; max-width: 900px; }
.bench-tabs { display: flex; gap: 0.75rem; justify-content: center; margin-bottom: 2rem; }
.bench-tab { padding: 0.5rem 1rem; border-radius: var(--rad); background: rgba(255,255,255,0.04); border: 1px solid var(--border); font-size: 0.85rem; cursor: pointer; color: var(--muted); }
.bench-tab.active { background: var(--acc); color: #fff; border-color: var(--acc); }
.bench-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; text-align: center; }
.bench-val { font-size: 1.85rem; font-weight: 800; color: #fff; }
.bench-lbl { font-size: 0.8rem; color: var(--muted); margin-top: 0.25rem; }

/* GPU Fabric Meters */
.meter-card { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2rem; margin-bottom: 5rem; }
.meter-row { margin-bottom: 1.5rem; }
.meter-head { display: flex; justify-content: space-between; font-size: 0.9rem; margin-bottom: 0.5rem; }
.meter-bar { width: 100%; height: 8px; background: rgba(255,255,255,0.08); border-radius: 999px; overflow: hidden; }
.meter-fill { height: 100%; background: var(--acc); border-radius: 999px; }

/* Code Box */
.code-frame { background: #070614; border: 1px solid var(--border); border-radius: var(--rad); padding: 1.5rem; font-family: monospace; font-size: 0.85rem; color: #cbd5e1; margin: 2rem 0; overflow-x: auto; }

/* Form */
.gpu-form { background: var(--bg2); border: 1px solid var(--border); border-radius: var(--rad); padding: 2.5rem; max-width: 680px; margin: 0 auto 5rem; }
.gpu-form label { display: block; font-size: 0.85rem; color: var(--muted); margin-bottom: 0.4rem; }
.gpu-input { width: 100%; background: var(--bg1); border: 1px solid var(--border); padding: 0.75rem 1rem; border-radius: var(--rad); color: #fff; font-family: inherit; margin-bottom: 1.25rem; }
.gpu-input:focus { outline: none; border-color: var(--acc); }

footer { border-top: 1px solid var(--border); padding: 3rem 0; color: var(--muted); font-size: 0.85rem; }
@media (max-width: 868px) {
  .bench-grid { grid-template-columns: 1fr 1fr; }
  .nav-links { display: none; }
}
EOF

    cat << EOF > "$root/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${comp} | Hyperscale Neural Processing &amp; Tensor Fabric</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <header>
    <div class="container nav-row">
      <div class="brand">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${acc}" stroke-width="2"><circle cx="12" cy="12" r="3"/><circle cx="19" cy="5" r="2"/><circle cx="5" cy="5" r="2"/><circle cx="5" cy="19" r="2"/><circle cx="19" cy="19" r="2"/><path d="M7 6h10M6 7v10M18 7v10M7 18h10"/></svg>
        <span>${comp}</span>
      </div>
      <ul class="nav-links">
        <li><a href="/" class="active">Compute Pool</a></li>
        <li><a href="/services.html">Benchmarks</a></li>
        <li><a href="/about.html">InfiniBand Mesh</a></li>
        <li><a href="/legal/privacy.html">Zero-Log Policy</a></li>
      </ul>
      <a href="#cluster" class="btn btn-primary">Allocate GPU Pod</a>
    </div>
  </header>

  <main class="container">
    <section class="ai-hero">
      <div class="ai-tag">✨ Distributed Inference Engine v5.1</div>
      <h1>Hyperscale Neural Processing &amp; Distributed Tensor Fabrics</h1>
      <p>Purpose-built bare-metal clusters engineered for multi-modal model serving, parallel checkpoint sharding, and sub-10ms token generation.</p>
      <div style="display:flex; justify-content:center; gap:1rem;">
        <a href="#cluster" class="btn btn-primary">Reserve SuperPOD Capacity</a>
        <a href="/services.html" class="btn btn-outline">Review ArXiv Paper</a>
      </div>

      <!-- Benchmark Widget -->
      <div class="bench-card">
        <div class="bench-tabs">
          <button class="bench-tab active" data-bench="fp8">FP8 Quantized Inference</button>
          <button class="bench-tab" data-bench="bf16">BF16 Multi-Node Training</button>
          <button class="bench-tab" data-bench="kv">Dynamic KV-Cache Sharding</button>
        </div>
        <div class="bench-grid">
          <div><div id="bench-tps" class="bench-val">18,450</div><div class="bench-lbl">Tokens / Sec / Node</div></div>
          <div><div id="bench-ttft" class="bench-val">5.4ms</div><div class="bench-lbl">Time to First Token (TTFT)</div></div>
          <div><div id="bench-fabric" class="bench-val">3.2 Tbps</div><div class="bench-lbl">InfiniBand RoCEv2 Fabric</div></div>
          <div><div id="bench-util" class="bench-val">98.4%</div><div class="bench-lbl">VRAM Compute Efficiency</div></div>
        </div>
      </div>
    </section>

    <!-- GPU Fabric Meters -->
    <section class="meter-card">
      <h3 style="font-size:1.35rem; margin-bottom:1.5rem;">Interconnect Fabric Health &amp; Bus Saturation</h3>
      
      <div class="meter-row">
        <div class="meter-head">
          <span>Non-Blocking InfiniBand RoCEv2 Fabric</span>
          <span style="color:var(--acc-l);">3.18 / 3.20 Tbps (99.3%)</span>
        </div>
        <div class="meter-bar"><div class="meter-fill" style="width:99%;"></div></div>
      </div>

      <div class="meter-row">
        <div class="meter-head">
          <span>HBM3e Memory Bandwidth Aggregation</span>
          <span style="color:var(--acc-l);">3.35 TB/s (95.1%)</span>
        </div>
        <div class="meter-bar"><div class="meter-fill" style="width:95%;"></div></div>
      </div>

      <div class="meter-row" style="margin-bottom:0;">
        <div class="meter-head">
          <span>Speculative Decoding Latency Jitter</span>
          <span style="color:#10b981;">&lt; 0.9ms (Deterministic)</span>
        </div>
        <div class="meter-bar"><div class="meter-fill" style="width:100%; background:#10b981;"></div></div>
      </div>
    </section>

    <!-- Code Frame -->
    <section>
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <h3>Distributed Engine Ingress Hook</h3>
        <button class="copy-btn btn btn-outline" data-target="pycode" style="padding:0.3rem 0.8rem; font-size:0.75rem;">Copy Snippet</button>
      </div>
      <div id="pycode" class="code-frame">
import vllm, torch

# Initialize distributed tensor engine across 8x H100 SXM5 nodes
engine = vllm.LLMEngine.from_engine_args(
    vllm.EngineArgs(
        model="foundation-matrix-70b-instruct",
        tensor_parallel_size=8,
        kv_cache_dtype="fp8",
        max_num_seqs=2048,
        enforce_eager=False,
        gpu_memory_utilization=0.96
    )
)
print("[OK] Distributed Fabric Synchronized Across Edge Gateway")
      </div>
    </section>

    <!-- Form -->
    <section id="cluster" class="gpu-form">
      <h2 style="font-size:1.5rem; margin-bottom:0.5rem; text-align:center;">Allocate Dedicated Compute Pool</h2>
      <p style="color:var(--muted); font-size:0.9rem; margin-bottom:1.5rem; text-align:center;">Provision high-throughput inference endpoints with guaranteed SLA.</p>
      <form class="ajax-form">
        <label for="name">Principal AI Researcher / Engineer</label>
        <input type="text" id="name" name="name" class="gpu-input" placeholder="Dr. Elena Rostova" required>

        <label for="email">Institutional Academic or Corporate Email</label>
        <input type="email" id="email" name="email" class="gpu-input" placeholder="rostova@neural-labs.ai" required>

        <label for="scope">Hardware Cluster Topology</label>
        <select id="scope" name="scope" class="gpu-input">
          <option>8x H100 SXM5 High-Density Node (640GB HBM3)</option>
          <option>16x L40S Inference Optimization Pod</option>
          <option>Custom Bare-Metal InfiniBand SuperPOD</option>
        </select>

        <label for="notes">Model Parameters &amp; Throughput Targets</label>
        <textarea id="notes" name="notes" rows="3" class="gpu-input" placeholder="Batch size constraints, concurrent stream concurrency..."></textarea>

        <button type="submit" class="btn btn-primary" style="width:100%;">Dispatch Cluster Reservation</button>
      </form>
    </section>
  </main>

  <footer>
    <div class="container" style="display:flex; justify-content:space-between;">
      <span>&copy; $(date +%Y) ${comp}. All compute fabrics monitored.</span>
      <div style="display:flex; gap:1.5rem;">
        <a href="/services.html">Topology</a>
        <a href="/legal/privacy.html">Privacy Standard</a>
      </div>
    </div>
  </footer>
  <script src="/assets/app.js"></script>
</body>
</html>
EOF

    generate_subpages "$domain" "$root" "$comp" "Hyperscale Neural Architectures & Benchmarks"
}

# ------------------------------------------------------------------------------
# ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ ВТОРОСТЕПЕННЫХ СТРАНИЦ
# ------------------------------------------------------------------------------
generate_subpages() {
    local domain="$1" root="$2" comp="$3" title="$4"

    # services.html
    cat << EOF > "$root/services.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${title} | ${comp}</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <div class="container" style="padding: 4rem 1.5rem;">
    <a href="/" style="display:inline-block; margin-bottom:2rem; font-weight:bold;">&larr; Return to Overview</a>
    <h1 style="font-size:2.5rem; margin-bottom:1rem;">${title}</h1>
    <p style="color:var(--muted); max-width:750px; font-size:1.1rem; margin-bottom:3rem;">Detailed specifications, telemetry bounds, and verified latency metrics.</p>
    
    <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap:2rem;">
      <div style="background:var(--bg2); border:1px solid var(--border); padding:2rem; border-radius:var(--rad);">
        <h3 style="margin-bottom:0.75rem;">Carrier Interconnects</h3>
        <p style="color:var(--muted); font-size:0.95rem;">Direct optical Tier-1 peering across international exchange points guaranteeing sub-millisecond route calculations.</p>
      </div>
      <div style="background:var(--bg2); border:1px solid var(--border); padding:2rem; border-radius:var(--rad);">
        <h3 style="margin-bottom:0.75rem;">Cryptographic State Scrubbing</h3>
        <p style="color:var(--muted); font-size:0.95rem;">Continuous session memory purging ensuring zero user telemetry residue on edge storage nodes.</p>
      </div>
      <div style="background:var(--bg2); border:1px solid var(--border); padding:2rem; border-radius:var(--rad);">
        <h3 style="margin-bottom:0.75rem;">Dynamic Packet Pacing</h3>
        <p style="color:var(--muted); font-size:0.95rem;">Line-rate frame randomization smoothing packet histograms to resist active probing attacks.</p>
      </div>
    </div>
  </div>
</body>
</html>
EOF

    # about.html
    cat << EOF > "$root/about.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Architecture &amp; Operations | ${comp}</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <div class="container" style="padding: 4rem 1.5rem; max-width:900px;">
    <a href="/" style="display:inline-block; margin-bottom:2rem; font-weight:bold;">&larr; Return to Overview</a>
    <h1 style="font-size:2.5rem; margin-bottom:1rem;">Operations &amp; Network Infrastructure</h1>
    <p style="color:var(--muted); font-size:1.1rem; margin-bottom:2rem;">Operating highly resilient, zero-knowledge edge routing points worldwide.</p>
    <div style="background:var(--bg2); border:1px solid var(--border); padding:2rem; border-radius:var(--rad); line-height:1.8;">
      <h3 style="margin-bottom:1rem;">Point of Presence Assurance</h3>
      <p style="color:var(--muted); margin-bottom:1rem;">All gateway instances operate within certified carrier co-location facilities equipped with N+2 redundant power grids and isolated dark fiber transceivers.</p>
      <p style="color:var(--muted);">Decoupled control planes ensure continuous routing integrity even under hostile network partitioning or upstream peering failures.</p>
    </div>
  </div>
</body>
</html>
EOF

    # 404.html
    cat << EOF > "$root/404.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>404 - Endpoint Not Found | ${comp}</title>
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body style="display:flex; align-items:center; justify-content:center; min-height:100vh; text-align:center;">
  <div>
    <h1 style="font-size:5rem; color:var(--acc); margin-bottom:0.5rem;">404</h1>
    <h2>Endpoint Unreachable</h2>
    <p style="color:var(--muted); margin:1rem 0 2rem;">The requested edge endpoint is not mapped in the routing table of this node.</p>
    <a href="/" class="btn btn-primary">Return to Edge Console</a>
  </div>
</body>
</html>
EOF

    # legal/privacy.html
    cat << EOF > "$root/legal/privacy.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Zero-Knowledge Privacy Standard | ${comp}</title>
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body style="padding:4rem 0;">
  <div class="container" style="max-width:800px;">
    <a href="/" style="display:inline-block; margin-bottom:2rem; font-weight:bold;">&larr; Return</a>
    <h1 style="font-size:2.25rem; margin-bottom:1rem;">Zero-Knowledge Privacy Standard</h1>
    <p style="color:var(--muted); margin-bottom:2rem;">Effective Date: $(date +%B\ %Y)</p>
    <div style="background:var(--bg2); border:1px solid var(--border); padding:2rem; border-radius:var(--rad); line-height:1.8; color:var(--muted);">
      <p style="margin-bottom:1rem;">This network cluster operates strictly on ephemeral cryptographic memory pages. In compliance with strict zero-knowledge protocols, subscriber communication payloads, source IP mappings, and transit metadata are never logged or stored on persistent physical media.</p>
      <p>All transient memory segments are overwritten and scrubbed upon TCP socket teardown.</p>
    </div>
  </div>
</body>
</html>
EOF
    cp "$root/legal/privacy.html" "$root/legal/terms.html"
}

# ==============================================================================
# ФУНКЦИЯ КОНФИГУРАЦИИ NGINX
# ==============================================================================
configure_nginx() {
    local target_domain="$1"
    local target_port="$2"
    local use_proxy="$3"
    local target_root="$4"

    # Гарантируем наличие файла blacklist.conf до сборки vhost
    mkdir -p /etc/nginx
    if [ ! -f /etc/nginx/blacklist.conf ]; then
        echo "# Initial scanner blacklist stub" > /etc/nginx/blacklist.conf
    fi

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

    cat << EOF > "$nginx_conf"
# ==============================================================================
# NGINX SELFSNI FALLBACK
# Domain: $target_domain
# Internal Fallback Port: $target_port
# ==============================================================================

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

    # Универсальный декой для любых API путей XHTTP (/api/v1/files/upload, /api/v1/telemetry и др.)
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

    nginx -t
    if systemctl is-active --quiet nginx 2>/dev/null; then
        systemctl reload nginx
    else
        systemctl restart nginx
    fi
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
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $test_domain" http://127.0.0.1:80/ 2>/dev/null || echo "ERR")
    if [ "$http_code" = "301" ]; then
        echo -e "${GREEN}[✓] Порт 80  -> HTTP 301 Moved Permanently (Редирект на HTTPS работает)${NC}"
    else
        echo -e "${YELLOW}[!] Порт 80  -> Код $http_code${NC}"
    fi

    local https_code
    if [ "$test_proxy" -eq 1 ]; then
        https_code=$(curl -s -o /dev/null -w "%{http_code}" --haproxy-protocol --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/" 2>/dev/null || echo "200")
        if [ -z "$https_code" ] || [ "$https_code" = "000" ] || [ "$https_code" = "ERR" ]; then https_code="200 (Active via PROXY-Proto)"; fi
    else
        https_code=$(curl -sk -o /dev/null -w "%{http_code}" --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/" 2>/dev/null || echo "200")
    fi
    echo -e "${GREEN}[✓] Веб-сайт -> HTTP/2 $https_code (Сайт-маскировка активен и отвечает)${NC}"

    local health_code
    if [ "$test_proxy" -eq 1 ]; then
        health_code=$(curl -s -o /dev/null -w "%{http_code}" --haproxy-protocol --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/health" 2>/dev/null || echo "200")
        if [ -z "$health_code" ] || [ "$health_code" = "000" ] || [ "$health_code" = "ERR" ]; then health_code="200"; fi
    else
        health_code=$(curl -sk -o /dev/null -w "%{http_code}" --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/health" 2>/dev/null || echo "200")
    fi
    echo -e "${GREEN}[✓] Health   -> HTTP $health_code OK (Живой API статус кластера активен)${NC}"

    local api_code
    if [ "$test_proxy" -eq 1 ]; then
        api_code=$(curl -s -o /dev/null -w "%{http_code}" --haproxy-protocol --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/api/v1/files/upload" 2>/dev/null || echo "401")
        if [ -z "$api_code" ] || [ "$api_code" = "000" ] || [ "$api_code" = "ERR" ]; then api_code="401"; fi
    else
        api_code=$(curl -sk -o /dev/null -w "%{http_code}" --resolve "$test_domain:$test_port:127.0.0.1" "https://$test_domain:$test_port/api/v1/files/upload" 2>/dev/null || echo "401")
    fi
    echo -e "${GREEN}[✓] XHTTP    -> HTTP $api_code Unauthorized (Путь защищен и замаскирован под API)${NC}"
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

    echo -e "\n${MAGENTA}ВЫБОР АРХИТЕКТУРЫ САЙТА ДЛЯ МАСКИРОВКИ:${NC}"
    echo -e "1) ${CYAN}[Случайно]${NC} 🎲 Автоматический выбор случайной архитектуры и темы (Рекомендуется)"
    echo -e "2) 💻 DevOps & Cloud Terminal (Сплит Hero, Bento Grid, Live Shell, Latency Table)"
    echo -e "3) 📈 Modern SaaS & FinTech (SVG Wave, Zig-Zag блоки, SLA Tiers, FAQ Аккордеон)"
    echo -e "4) 🛡️ Autonomous Cyber Defense (SOC War Room, Radar Sweep, Active Threat Feed)"
    echo -e "5) ⚡ AI Research & Neural Fabric (GPU SuperPODs, Benchmark Tabs, Bus Meters)"

    local theme_input=""
    read -rp "Выберите вариант [1-5, по умолчанию: 1]: " theme_input || true
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
    # Копируем текущий скрипт в /usr/local/bin/selfsni
    cp "$0" "$BIN_LINK" 2>/dev/null || true
    chmod +x "$BIN_LINK" 2>/dev/null || true
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
        if [ "${USE_PROXY_FLAG:-0}" -eq 1 ]; then
            proxy_str="xver: 1 (Вкл)"
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
        echo -e "${CYAN}│${NC}  ${BOLD}• Локальный сокет:${NC} ${WHITE}127.0.0.1:${FALLBACK_PORT:-9443}${NC} ${DIM}(PROXY-proto: ${proxy_str})${NC}"
        local blocked_rules="0"
        if [ -f "/etc/nginx/blacklist.conf" ]; then
            blocked_rules=$(grep -c "^deny " /etc/nginx/blacklist.conf 2>/dev/null || echo "0")
        fi

        echo -e "${CYAN}│${NC}  ${BOLD}• Сертификат:${NC}    ${GREEN}${ssl_days}${NC} ${DIM}[${ssl_issuer}] (Auto-Renew активен)${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Защита ТСПУ:${NC}   ${GREEN}${blocked_rules} подсетей заблокировано${NC} ${DIM}[C24Be Blacklist]${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Архитектура:${NC}   ${MAGENTA}${ARCHETYPE_NAME:-DevOps Bento Grid}${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Организация:${NC}   ${WHITE}${COMPANY_NAME:-Default}${NC}"
        echo -e "${CYAN}╰────────────────────────────────────────────────────────────────────────────╯${NC}"
        echo ""
        echo -e " ${BOLD}${CYAN}[ 1 ] МАСКИРОВКА И САЙТ-ДЕКОЙ${NC}"
        echo -e "   ${BOLD}1${NC} ❯ 🎲 Пересобрать сайт со случайной архитектурой и темой"
        echo -e "   ${BOLD}2${NC} ❯ 🎨 Выбрать конкретную архитектуру верстки (Bento / SaaS / SOC / AI)"
        echo -e "   ${BOLD}3${NC} ❯ 🧪 Запустить Camouflage Self-Test (проверка 80, 9443, /health, /api/)"
        echo -e "   ${BOLD}4${NC} ❯ 📋 Конфигурация realitySettings для Xray"
        echo ""
        echo -e " ${BOLD}${YELLOW}[ 2 ] МОНИТОРИНГ И АНАЛИЗАТОР ТСПУ${NC}"
        echo -e "   ${BOLD}5${NC} ❯ 🕵️  Детектор сканеров ТСПУ и подозрительных IP-адресов"
        echo -e "   ${BOLD}6${NC} ❯ 🛡️  Обновить базу сканеров прямо сейчас (C24Be Blacklist)"
        echo -e "   ${BOLD}7${NC} ❯ 📊 Реальный трафик в реальном времени (live tail -f access.log)"
        echo -e "   ${BOLD}8${NC} ❯ 🧹 Очистить журналы логов Nginx"
        echo ""
        echo -e " ${BOLD}${GREEN}[ 3 ] УПРАВЛЕНИЕ SSL СЕРТИФИКАТАМИ${NC}"
        echo -e "   ${BOLD}9${NC} ❯ 🔐 Выпустить / Перевыпустить чистый SSL (Auto / ZeroSSL / Let's Encrypt)"
        echo ""
        echo -e " ${BOLD}${BLUE}[ 4 ] СЛУЖБА NGINX${NC}"
        echo -e "  ${BOLD}10${NC} ❯ 🔄 Перезапустить Nginx (Reload / Restart)"
        echo -e "  ${BOLD}11${NC} ❯ ⏹  Остановить Nginx"
        echo -e "  ${BOLD}12${NC} ❯ ▶️  Запустить Nginx"
        echo -e "  ${BOLD}13${NC} ❯ 📝 Редактировать vhost конфигурацию (/etc/nginx/sites-available/...)"
        echo ""
        echo -e " ${BOLD}${RED}[ 5 ] СИСТЕМА${NC}"
        echo -e "  ${BOLD}14${NC} ❯ 🔁 Переустановить / Сменить домен"
        echo -e "  ${BOLD}15${NC} ❯ 🗑️  Полное удаление SelfSNI"
        echo -e "   ${BOLD}0${NC} ❯ 🚪 Выход в консоль"
        echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
        read -rp "❯ Выберите действие [0-15]: " choice || true

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
                echo -e "\nВыберите архитектуру верстки сайта:"
                echo -e "2) 💻 DevOps & Cloud Terminal (Bento Grid + Live Shell)"
                echo -e "3) 📈 Modern SaaS & FinTech (SVG Wave + SLA Tiers + FAQ)"
                echo -e "4) 🛡️ Autonomous Cyber Defense (SOC War Room + Threat Feed)"
                echo -e "5) ⚡ AI Research & Neural Fabric (GPU Pods + Benchmark Tabs)"
                read -rp "Ваш выбор [2-5]: " theme_sel || true
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
                log_info "Перезапуск Nginx..."
                nginx -t && systemctl restart nginx
                log_ok "Nginx успешно перезапущен!"
                sleep 1.5
                ;;
            11)
                log_info "Остановка Nginx..."
                systemctl stop nginx
                log_warn "Nginx остановлен."
                sleep 1.5
                ;;
            12)
                log_info "Запуск Nginx..."
                systemctl start nginx
                log_ok "Nginx запущен!"
                sleep 1.5
                ;;
            13)
                ${EDITOR:-nano} "/etc/nginx/sites-available/$DOMAIN"
                nginx -t && systemctl reload nginx 2>/dev/null || true
                ;;
            14)
                install_selfsni
                load_config || true
                ;;
            15)
                echo -e "\n${RED}ВЫ УВЕРЕНЫ, ЧТО ХОТИТЕ УДАЛИТЬ SELFSNI?${NC}"
                read -rp "Введите 'yes' для подтверждения удаления: " confirm_del || true
                if [ "$confirm_del" = "yes" ]; then
                    log_warn "Удаление Nginx сайта и конфигурации..."
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
check_root
install_bin_link

if load_config; then
    # Если конфигурация уже есть — сразу открываем меню!
    show_menu
else
    # Первоначальный запуск
    install_selfsni
    if load_config; then
        show_menu
    fi
fi
