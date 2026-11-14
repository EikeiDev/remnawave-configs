#!/usr/bin/env bash
# ==============================================================================
# Скрипт развертывания и управления Telegram WEB Proxy (tproxy-server + MTProxy)
# в единой связке с Nginx SelfSNI и Remnanode (Xray Reality / XHTTP на 443 порту)
# Поддерживаемые ОС: Ubuntu 22.04+, Debian 12+ (x86_64)
# ==============================================================================

set -euo pipefail

# Автоматическая очистка CRLF (\r), если файл был скопирован из буфера обмена Windows
if [ -f "${BASH_SOURCE[0]:-$0}" ] && grep -q $'\r' "${BASH_SOURCE[0]:-$0}" 2>/dev/null; then
    sed -i 's/\r$//' "${BASH_SOURCE[0]:-$0}" 2>/dev/null || true
    exec bash "${BASH_SOURCE[0]:-$0}" "$@"
fi

# Цветовая палитра (в едином стиле с SelfSNI Control Core)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Пути конфигурации
SELFSNI_CONF="/etc/selfsni/selfsni.conf"
TPROXY_ENV="/etc/tproxy-server/selfsni-tproxy.env"
TPROXY_CONF="/etc/tproxy-server/config.json"
TPROXY_PROFILES="/etc/tproxy-server/profiles.json"
TPROXY_TOKEN_KEY="/etc/tproxy-server/token.key"
TPROXY_NFT="/etc/tproxy-server/firewall.nft"
MTPROXY_ENV="/etc/mtproxy/mtproxy.env"
TPROXY_SRC_DIR="/opt/tproxy-server-src"
TPROXY_REPO_URL="https://github.com/telegramdesktop/tproxy-server.git"
TPROXY_ARCHIVE_URL="https://github.com/telegramdesktop/tproxy-server/archive/refs/heads/master.tar.gz"
NGINX_UPSTREAM_CONF="/etc/nginx/conf.d/tproxy-upstream.conf"
NGINX_EXT_DIR="/etc/nginx/selfsni-extensions"
NGINX_EXT_CONF="/etc/nginx/selfsni-extensions/tproxy.conf"

# Глобальные переменные состояния
DOMAIN=""
FALLBACK_PORT="9443"
USE_PROXY_FLAG="1"
WEB_ROOT=""
XHTTP_PATH="/api/v1/files/upload"
BASE_PATH=""
CARRIER_MODE="websocket"
PRIMARY_SECRET=""
MTPROXY_AD_TAG=""
MTPROXY_WORKERS="1"
MTPROXY_MAX_CONN="4096"
MOBILE_OPTIMIZED="1"
TPROXY_PORT="8080"
TPROXY_ADMIN_PORT="8081"
MIRROR_PORT="9480"
MTPROXY_PORT="2398"
MTPROXY_STATS_PORT="8888"
DIRECT_443_MODE="0"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

check_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        log_err "Этот скрипт должен запускаться от имени root (используйте sudo)!"
        exit 1
    fi
}

check_arch() {
    if [ "$(uname -m)" != "x86_64" ]; then
        log_err "Официальный движок MTProxy поддерживает только архитектуру x86_64 (текущая: $(uname -m))."
        exit 1
    fi
}

# ==============================================================================
# ЗАГРУЗКА И СОХРАНЕНИЕ КОНФИГУРАЦИИ СВЯЗКИ SELFSNI + TPROXY
# ==============================================================================
load_configs() {
    if [ ! -f "$SELFSNI_CONF" ] && [ -f "/etc/selfsni/config.env" ]; then
        SELFSNI_CONF="/etc/selfsni/config.env"
    fi
    if [ -f "$SELFSNI_CONF" ]; then
        # shellcheck disable=SC1090
        source "$SELFSNI_CONF"
    fi
    if [ -f "$TPROXY_ENV" ]; then
        # shellcheck disable=SC1090
        source "$TPROXY_ENV"
    fi
    if [ -f "$SELFSNI_CONF" ]; then
        # Домен, порт и пути SelfSNI всегда синхронизируются с основным конфигом SelfSNI
        local s_domain s_port s_proxy s_root s_xhttp
        s_domain=$(sed -n 's/^DOMAIN="\([^"]*\)"/\1/p' "$SELFSNI_CONF" | head -n1 || true)
        s_port=$(sed -n 's/^FALLBACK_PORT="\([^"]*\)"/\1/p' "$SELFSNI_CONF" | head -n1 || true)
        s_proxy=$(sed -n 's/^USE_PROXY_FLAG="\([^"]*\)"/\1/p' "$SELFSNI_CONF" | head -n1 || true)
        s_root=$(sed -n 's/^WEB_ROOT="\([^"]*\)"/\1/p' "$SELFSNI_CONF" | head -n1 || true)
        s_xhttp=$(sed -n 's/^XHTTP_PATH="\([^"]*\)"/\1/p' "$SELFSNI_CONF" | head -n1 || true)
        [ -n "$s_domain" ] && DOMAIN="$s_domain"
        [ -n "$s_port" ] && FALLBACK_PORT="$s_port"
        [ -n "$s_proxy" ] && USE_PROXY_FLAG="$s_proxy"
        [ -n "$s_root" ] && WEB_ROOT="$s_root"
        [ -n "$s_xhttp" ] && XHTTP_PATH="$s_xhttp"
    elif [ -z "${DOMAIN:-}" ] && [ -d /etc/nginx/sites-available ]; then
        # Автоопределение домена из виртуальных хостов Nginx, если файл конфига не найден
        local detected_vhost
        detected_vhost=$(find /etc/nginx/sites-available -maxdepth 1 -type f ! -name "default" ! -name "*.bak*" -printf "%f\n" 2>/dev/null | head -n1 || true)
        [ -n "$detected_vhost" ] && DOMAIN="$detected_vhost"
    fi
    WEB_ROOT="${WEB_ROOT:-/var/www/${DOMAIN:-localhost}}"
    XHTTP_PATH="${XHTTP_PATH:-/api/v1/files/upload}"
}

save_tproxy_env() {
    mkdir -p /etc/tproxy-server
    cat << EOF > "$TPROXY_ENV"
DOMAIN="${DOMAIN}"
FALLBACK_PORT="${FALLBACK_PORT:-9443}"
WEB_ROOT="${WEB_ROOT:-/var/www/$DOMAIN}"
XHTTP_PATH="${XHTTP_PATH:-/api/v1/files/upload}"
BASE_PATH="${BASE_PATH}"
CARRIER_MODE="${CARRIER_MODE:-websocket}"
PRIMARY_SECRET="${PRIMARY_SECRET}"
MTPROXY_AD_TAG="${MTPROXY_AD_TAG:-}"
MTPROXY_WORKERS="${MTPROXY_WORKERS:-1}"
MTPROXY_MAX_CONN="${MTPROXY_MAX_CONN:-4096}"
MOBILE_OPTIMIZED="${MOBILE_OPTIMIZED:-1}"
TPROXY_PORT="${TPROXY_PORT:-8080}"
TPROXY_ADMIN_PORT="${TPROXY_ADMIN_PORT:-8081}"
MIRROR_PORT="${MIRROR_PORT:-9480}"
MTPROXY_PORT="${MTPROXY_PORT:-2398}"
MTPROXY_STATS_PORT="${MTPROXY_STATS_PORT:-8888}"
DIRECT_443_MODE="${DIRECT_443_MODE:-0}"
EOF
    chmod 600 "$TPROXY_ENV"
}

# ==============================================================================
# КОДИРОВАНИЕ КЛИЕНТСКОГО СЕКРЕТА И ФОРМИРОВАНИЕ ССЫЛОК TELEGRAM WEB PROXY
# ==============================================================================
# При наличии base_path ссылка t.me/webproxy требует маркированный секрет:
# base64url(0x70 || raw_16_byte_secret) без паддинга '='.
# В корневом режиме (base_path == "") используется обычный 32-символьный hex.
derive_client_secret() {
    local raw_hex="$1"
    local bpath="${2:-}"
    # Если секрет с префиксом dd (34 символа), для вычисления маркера берем чистые 16 байт или как есть
    if [ -z "$bpath" ]; then
        printf '%s' "$raw_hex"
        return 0
    fi
    {
        printf '\x70'
        printf "$(printf '%s' "$raw_hex" | sed 's/../\\x&/g')"
    } | base64 | tr '+/' '-_' | tr -d '=\n'
}

generate_random_slug() {
    if command -v base32 >/dev/null 2>&1; then
        head -c 10 /dev/urandom | base32 | tr 'A-Z' 'a-z' | tr -d '=\n'
    else
        openssl rand -hex 8
    fi
}

generate_random_secret() {
    openssl rand -hex 16
}

# ==============================================================================
# АВТОМАТИЧЕСКАЯ ЗАГРУЗКА ИСХОДНИКОВ TPROXY-SERVER С GITHUB В /opt/tproxy-server-src
# ==============================================================================
locate_and_stage_sources() {
    local force_remote="${1:-0}"

    # 1. Если в /opt/tproxy-server-src уже клонирован git-репозиторий — подтягиваем свежие коммиты
    if [ -d "$TPROXY_SRC_DIR/.git" ] && command -v git >/dev/null 2>&1; then
        log_info "Проверка обновлений в официальном репозитории telegramdesktop/tproxy-server..."
        if git -C "$TPROXY_SRC_DIR" fetch --depth 1 origin master >/dev/null 2>&1 && \
           git -C "$TPROXY_SRC_DIR" reset --hard origin/master >/dev/null 2>&1 && \
           [ -f "$TPROXY_SRC_DIR/cmd/tproxy-server/main.go" ]; then
            chown -R root:root "$TPROXY_SRC_DIR"
            chmod -R u+rwX,go+rX "$TPROXY_SRC_DIR"
            local rev
            rev="$(git -C "$TPROXY_SRC_DIR" rev-parse --short HEAD 2>/dev/null || echo 'master')"
            log_ok "Репозиторий telegramdesktop/tproxy-server актуален (commit: ${rev})"
            return 0
        fi
    fi

    # 2. Автоматическая загрузка с GitHub (git clone -> fallback на tar.gz архив)
    if [ "$force_remote" = "1" ] || [ ! -f "$TPROXY_SRC_DIR/cmd/tproxy-server/main.go" ]; then
        log_info "Автоматическая загрузка исходников с GitHub (${TPROXY_REPO_URL})..."
        local tmp_src
        tmp_src="$(mktemp -d /tmp/tproxy-src.XXXXXX)"

        if command -v git >/dev/null 2>&1 && \
           git clone --depth 1 "$TPROXY_REPO_URL" "$tmp_src/repo" >/dev/null 2>&1 && \
           [ -f "$tmp_src/repo/cmd/tproxy-server/main.go" ]; then
            rm -rf "$TPROXY_SRC_DIR"
            mv "$tmp_src/repo" "$TPROXY_SRC_DIR"
            rm -rf "$tmp_src"
            chown -R root:root "$TPROXY_SRC_DIR"
            chmod -R u+rwX,go+rX "$TPROXY_SRC_DIR"
            local rev
            rev="$(git -C "$TPROXY_SRC_DIR" rev-parse --short HEAD 2>/dev/null || echo 'master')"
            log_ok "Репозиторий telegramdesktop/tproxy-server (commit: ${rev}) загружен в $TPROXY_SRC_DIR"
            return 0
        fi

        log_info "Загрузка архива исходников telegramdesktop/tproxy-server (master.tar.gz)..."
        if curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
            --output "$tmp_src/master.tar.gz" "$TPROXY_ARCHIVE_URL" 2>/dev/null && \
           mkdir -p "$tmp_src/extracted" && \
           tar -C "$tmp_src/extracted" --strip-components=1 -xzf "$tmp_src/master.tar.gz" 2>/dev/null && \
           [ -f "$tmp_src/extracted/cmd/tproxy-server/main.go" ]; then
            rm -rf "$TPROXY_SRC_DIR"
            mv "$tmp_src/extracted" "$TPROXY_SRC_DIR"
            rm -rf "$tmp_src"
            chown -R root:root "$TPROXY_SRC_DIR"
            chmod -R u+rwX,go+rX "$TPROXY_SRC_DIR"
            log_ok "Исходный код telegramdesktop/tproxy-server успешно скачан и распакован в $TPROXY_SRC_DIR"
            return 0
        fi
        rm -rf "$tmp_src"
        log_warn "Не удалось скачать репозиторий напрямую с GitHub, проверяем локальные каталоги..."
    fi

    # 3. Резервный поиск в локальных каталогах (если сервер без прямого доступа к GitHub)
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local candidates=(
        "$TPROXY_SRC_DIR"
        "$script_dir/tproxy-server-master"
        "$script_dir"
        "$(pwd)/tproxy-server-master"
        "$(pwd)"
        "/root/tproxy-server-master"
        "/root/tproxy-server"
        "/tmp/tproxy-server-master"
        "/tmp/tproxy-server"
    )

    local found_src=""
    for cand in "${candidates[@]}"; do
        if [ -f "$cand/cmd/tproxy-server/main.go" ] && [ -f "$cand/go.mod" ]; then
            found_src="$(cd "$cand" && pwd -P)"
            break
        fi
    done

    if [ -z "$found_src" ]; then
        log_err "Не удалось загрузить telegramdesktop/tproxy-server с GitHub, и локальная папка не найдена!"
        return 1
    fi

    if [ "$found_src" != "$TPROXY_SRC_DIR" ]; then
        log_info "Копирование локального исходного кода tproxy-server в $TPROXY_SRC_DIR..."
        rm -rf "$TPROXY_SRC_DIR"
        mkdir -p "$TPROXY_SRC_DIR"
        cp -a "$found_src/." "$TPROXY_SRC_DIR/"
        chown -R root:root "$TPROXY_SRC_DIR"
        chmod -R u+rwX,go+rX "$TPROXY_SRC_DIR"
    fi

    log_ok "Исходный код tproxy-server готов в $TPROXY_SRC_DIR"
}

# ==============================================================================
# УСТАНОВКА ЗАВИСИМОСТЕЙ, СБОРКА MTPROXY И TPROXY-SERVER (БЕЗ CADDY!)
# ==============================================================================
ensure_dependencies_and_go() {
    export DEBIAN_FRONTEND=noninteractive
    log_info "Установка системных пакетов (git, build-essential, libssl-dev, zlib1g-dev, nftables, jq)..."
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends \
        ca-certificates curl git tar build-essential iproute2 libssl-dev \
        util-linux zlib1g-dev nftables jq openssl coreutils >/dev/null

    # Если на сервере был запущен Caddy от старых попыток установки — аккуратно гасим его,
    # чтобы он не конфликтовал с Nginx SelfSNI на 80 порту и Remnanode на 443 порту
    if systemctl is-active --quiet caddy 2>/dev/null || systemctl is-enabled --quiet caddy 2>/dev/null; then
        log_warn "Обнаружен сервис Caddy. Останавливаем и отключаем его, так как фронтендом выступает Nginx SelfSNI..."
        systemctl stop caddy 2>/dev/null || true
        systemctl disable caddy 2>/dev/null || true
    fi

    # Проверка наличия Go >= 1.20
    GO_BIN=""
    if command -v go >/dev/null 2>&1; then
        local go_minor
        go_minor="$(go env GOVERSION 2>/dev/null | sed -E 's/^go1\.([0-9]+).*/\1/' || true)"
        if [[ "$go_minor" =~ ^[0-9]+$ ]] && [ "$go_minor" -ge 20 ]; then
            GO_BIN="$(command -v go)"
        fi
    fi

    if [ -z "$GO_BIN" ] && [ -x "/opt/go1.26.5/bin/go" ]; then
        GO_BIN="/opt/go1.26.5/bin/go"
    fi

    if [ -z "$GO_BIN" ]; then
        local go_version="1.26.5"
        local go_checksum="5c2c3b16caefa1d968a94c1daca04a7ca301a496d9b086e17ad77bb81393f053"
        log_info "Установка официального компилятора Go v${go_version} (с проверкой SHA-256)..."
        local go_archive go_directory
        go_archive="$(mktemp /tmp/go-linux-amd64.XXXXXX.tar.gz)"
        go_directory="$(mktemp -d /tmp/go-linux-amd64.XXXXXX)"
        curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
            --output "$go_archive" "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
        if [ "$(sha256sum "$go_archive" | awk '{print $1}')" != "$go_checksum" ]; then
            rm -f "$go_archive"
            rm -rf "$go_directory"
            log_err "Контрольная сумма архива Go не совпала!"
            return 1
        fi
        tar -C "$go_directory" -xzf "$go_archive"
        rm -rf "/opt/go${go_version}"
        mv "$go_directory/go" "/opt/go${go_version}"
        rm -f "$go_archive"
        rm -rf "$go_directory"
        ln -sf "/opt/go${go_version}/bin/go" /usr/local/bin/go
        GO_BIN="/opt/go${go_version}/bin/go"
        log_ok "Компилятор Go v${go_version} успешно установлен!"
    else
        log_ok "Используется компилятор Go: $($GO_BIN version)"
    fi
}

build_and_install_mtproxy() {
    if ! id mtproxy >/dev/null 2>&1; then
        useradd --system --home /nonexistent --shell /usr/sbin/nologin mtproxy
    fi

    local source_directory="/opt/MTProxy"
    local mtproxy_commit="f36d8af769ffaeac36978d38c2c0f6d1104c2137"
    local mtproxy_checksum="919795c416b870670841a21d1930ad97a24c7b84b9eb8c6f9e3de32f2fdf4655"

    if [ ! -x "$source_directory/objs/bin/mtproto-proxy" ] || \
       [ ! -f "$source_directory/.tproxy-commit" ] || \
       ! grep -Fxq "$mtproxy_commit" "$source_directory/.tproxy-commit" 2>/dev/null; then
        log_info "Загрузка и компиляция официального Telegram MTProxy (commit ${mtproxy_commit:0:8})..."
        local temporary archive build_directory
        temporary="$(mktemp -d /tmp/mtproxy-build.XXXXXX)"
        chmod 0711 "$temporary"
        archive="$temporary/MTProxy.tar.gz"
        build_directory="$temporary/MTProxy"

        curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
            --output "$archive" \
            "https://github.com/TelegramMessenger/MTProxy/archive/${mtproxy_commit}.tar.gz"

        if [ "$(sha256sum "$archive" | awk '{print $1}')" != "$mtproxy_checksum" ]; then
            rm -rf "$temporary"
            log_err "Ошибка проверки SHA-256 архива MTProxy!"
            return 1
        fi

        install -d -o mtproxy -g mtproxy -m 0755 "$build_directory"
        tar -C "$build_directory" --strip-components=1 -xzf "$archive"
        chown -R mtproxy:mtproxy "$build_directory"
        runuser -u mtproxy -- make -C "$build_directory" -j"$(nproc)" >/dev/null
        if [ ! -x "$build_directory/objs/bin/mtproto-proxy" ]; then
            rm -rf "$temporary"
            log_err "Не удалось скомпилировать mtproto-proxy!"
            return 1
        fi
        printf '%s\n' "$mtproxy_commit" > "$build_directory/.tproxy-commit"
        chown -R root:root "$build_directory"
        rm -rf "$source_directory"
        mv "$build_directory" "$source_directory"
        rm -rf "$temporary"
        log_ok "Официальный бинарник mtproto-proxy успешно скомпилирован!"
    else
        log_ok "Официальный бинарник mtproto-proxy уже скомпилирован и актуален."
    fi

    find "$source_directory" -type d -exec chmod 0755 {} +
    chmod 0755 "$source_directory/objs/bin/mtproto-proxy"

    log_info "Загрузка актуальных ключей и маршрутов датацентров Telegram (proxy-secret & proxy-multi.conf)..."
    install -d -o root -g mtproxy -m 0750 /etc/mtproxy
    local secret_temp config_temp
    secret_temp="$(mktemp /etc/mtproxy/proxy-secret.XXXXXX)"
    config_temp="$(mktemp /etc/mtproxy/proxy-multi.conf.XXXXXX)"

    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
        --output "$secret_temp" https://core.telegram.org/getProxySecret
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
        --output "$config_temp" https://core.telegram.org/getProxyConfig

    if [ "$(wc -c < "$secret_temp")" -ne 128 ] || [ "$(wc -c < "$config_temp")" -lt 100 ]; then
        rm -f "$secret_temp" "$config_temp"
        log_err "Некорректный ответ от core.telegram.org при загрузке конфигурации MTProxy!"
        return 1
    fi

    chown root:mtproxy "$secret_temp" "$config_temp"
    chmod 0640 "$secret_temp" "$config_temp"
    mv -f "$secret_temp" /etc/mtproxy/proxy-secret
    mv -f "$config_temp" /etc/mtproxy/proxy-multi.conf
    log_ok "Конфигурация Telegram DC успешно загружена в /etc/mtproxy."
}

build_and_install_tproxy_relay() {
    local force_remote="${1:-0}"
    if ! id tproxy >/dev/null 2>&1; then
        useradd --system --home /nonexistent --shell /usr/sbin/nologin tproxy
    fi

    ensure_dependencies_and_go
    locate_and_stage_sources "$force_remote"

    log_info "Проверка модульных тестов Go и компиляция tproxy-server..."
    (cd "$TPROXY_SRC_DIR" && "$GO_BIN" test ./internal/config ./internal/frame ./internal/session ./internal/bridge >/dev/null)
    (cd "$TPROXY_SRC_DIR" && "$GO_BIN" build -trimpath -ldflags='-s -w' -o /usr/local/bin/tproxy-server ./cmd/tproxy-server)
    chown root:root /usr/local/bin/tproxy-server
    chmod 0755 /usr/local/bin/tproxy-server
    log_ok "Сервер релея /usr/local/bin/tproxy-server успешно скомпилирован и установлен!"
}

# ==============================================================================
# ГЕНЕРАЦИЯ TOKEN.KEY, CONFIG.JSON, PROFILES.JSON, MTPROXY.ENV И SYSTEMD ЮНИТОВ
# ==============================================================================
ensure_token_key() {
    install -d -o root -g tproxy -m 0750 /etc/tproxy-server
    if [ ! -f "$TPROXY_TOKEN_KEY" ] || [ "$(wc -c < "$TPROXY_TOKEN_KEY" 2>/dev/null || echo 0)" -ne 32 ]; then
        log_info "Генерация 256-битного криптографического ключа подписи токенов ($TPROXY_TOKEN_KEY)..."
        rm -f "$TPROXY_TOKEN_KEY"
        head -c 32 /dev/urandom > "$TPROXY_TOKEN_KEY"
    fi
    chown tproxy:tproxy "$TPROXY_TOKEN_KEY"
    chmod 0400 "$TPROXY_TOKEN_KEY"
}

detect_mtproxy_nat_args() {
    local local_address public_address=""
    local_address="$(ip -4 route get 149.154.175.50 2>/dev/null | sed -n 's/.*[[:space:]]src[[:space:]]\+\([0-9.]\+\).*/\1/p' | head -n 1 || true)"
    for probe in https://api.ipify.org https://ifconfig.co/ip https://icanhazip.com; do
        local candidate
        candidate="$(curl --fail --silent --show-error --location --ipv4 --max-time 8 \
            --proto '=https' --proto-redir '=https' --tlsv1.2 "$probe" 2>/dev/null | tr -d '[:space:]' || true)"
        if [[ "$candidate" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            public_address="$candidate"
            break
        fi
    done
    if [ -z "$public_address" ] && [ -n "${DOMAIN:-}" ]; then
        public_address="$(getent ahostsv4 "$DOMAIN" 2>/dev/null | awk 'NR==1 {print $1}' || true)"
    fi
    if [ -n "$local_address" ] && [ -n "$public_address" ] && [ "$local_address" != "$public_address" ]; then
        echo "--nat-info ${local_address}:${public_address}"
    else
        echo ""
    fi
}

write_tproxy_configs() {
    ensure_token_key

    local grace="2m"
    local max_frame="1048576"
    if [ "${MOBILE_OPTIMIZED:-1}" = "1" ]; then
        grace="5m"
        max_frame="524288"
    fi

    cat << EOF > "$TPROXY_CONF"
{
  "public_hostname": "${DOMAIN}",
  "base_path": "${BASE_PATH}",
  "listen": "127.0.0.1:${TPROXY_PORT}",
  "admin_listen": "127.0.0.1:${TPROXY_ADMIN_PORT}",
  "public_upstream": "http://127.0.0.1:${MIRROR_PORT}",
  "token_key_file": "${TPROXY_TOKEN_KEY}",
  "static_routes": "exact",
  "profiles_file": "/run/credentials/tproxy-server.service/profiles.json",
  "enable_pprof": false,
  "limits": {
    "max_header_bytes": 16384,
    "max_body_bytes": 2097152,
    "max_frame_payload": ${max_frame},
    "carrier_batch_bytes": 2097152,
    "max_streams_per_session": 128,
    "max_closed_stream_ids": 4096,
    "max_pending_per_session": 33554432,
    "max_pending_global": 536870912,
    "max_pending_items_per_session": 16384,
    "max_pending_items_global": 262144,
    "max_sessions_per_ip": 0,
    "max_sessions_global": 128,
    "max_streams_global": 4096,
    "max_backend_dials_in_flight": 256,
    "new_sessions_per_minute": 600,
    "new_sessions_burst": 128,
    "new_streams_per_minute": 6000,
    "new_streams_burst": 512,
    "max_bootstraps_per_ip": 0,
    "max_bootstraps_global": 512,
    "new_bootstraps_per_minute": 1200,
    "new_bootstraps_burst": 256,
    "max_profiles": 32
  },
  "timeouts": {
    "backend_dial": "5s",
    "long_poll": "25s",
    "reconnect_grace": "${grace}",
    "bootstrap_lifetime": "2m",
    "read_header": "10s",
    "idle": "75s",
    "shutdown": "15s"
  }
}
EOF
    chown root:tproxy "$TPROXY_CONF"
    chmod 0640 "$TPROXY_CONF"

    # Если файла профилей еще нет — создаем с основным профилем default
    if [ ! -f "$TPROXY_PROFILES" ]; then
        cat << EOF > "$TPROXY_PROFILES"
{
  "profiles": [
    {
      "name": "default",
      "secret": "${PRIMARY_SECRET}",
      "backend": "127.0.0.1:${MTPROXY_PORT}",
      "carrier_mode": "${CARRIER_MODE}"
    }
  ]
}
EOF
    else
        # Обновляем профиль default в существующем profiles.json, сохраняя дополнительные профили
        local tmp_prof
        tmp_prof="$(mktemp /etc/tproxy-server/profiles.XXXXXX)"
        if jq --arg sec "$PRIMARY_SECRET" --arg mode "$CARRIER_MODE" --arg back "127.0.0.1:${MTPROXY_PORT}" '
            if (.profiles | map(.name == "default") | any) then
                .profiles |= map(if .name == "default" then .secret = $sec | .carrier_mode = $mode | .backend = $back else . end)
            else
                .profiles = [{"name":"default","secret":$sec,"backend":$back,"carrier_mode":$mode}] + .profiles
            end
        ' "$TPROXY_PROFILES" > "$tmp_prof" 2>/dev/null; then
            mv -f "$tmp_prof" "$TPROXY_PROFILES"
        else
            rm -f "$tmp_prof"
        fi
    fi
    chown root:tproxy "$TPROXY_PROFILES"
    chmod 0400 "$TPROXY_PROFILES"

    # Формируем список всех уникальных 16-байтных секретов из profiles.json для передачи в mtproto-proxy (-S sec1 -S sec2)
    local mt_secret_args=""
    local raw_secrets
    raw_secrets=$(jq -r '.profiles[].secret' "$TPROXY_PROFILES" 2>/dev/null || echo "$PRIMARY_SECRET")
    local seen_secs=""
    for s in $raw_secrets; do
        local clean_s="$s"
        if [[ "$clean_s" == dd* ]] && [ "${#clean_s}" -eq 34 ]; then
            clean_s="${clean_s:2}"
        fi
        if ! echo "$seen_secs" | grep -qw "$clean_s"; then
            seen_secs="$seen_secs $clean_s"
            if [ -z "$mt_secret_args" ]; then
                mt_secret_args="$clean_s"
            else
                mt_secret_args="$mt_secret_args -S $clean_s"
            fi
        fi
    done

    local nat_args
    nat_args="$(detect_mtproxy_nat_args)"
    if [ -n "$nat_args" ]; then
        log_info "Обнаружен 1:1 NAT на сервере, активирован параметр MTProxy: ${nat_args}"
    fi

    local tag_args=""
    if [[ "${MTPROXY_AD_TAG:-}" =~ ^[0-9a-fA-F]{32}$ ]]; then
        tag_args="-P $(echo "$MTPROXY_AD_TAG" | tr 'A-F' 'a-f')"
    fi

    install -d -o root -g mtproxy -m 0750 /etc/mtproxy
    cat << EOF > "$MTPROXY_ENV"
MTPROXY_SECRET=${mt_secret_args}
MTPROXY_TAG_ARGS=${tag_args}
MTPROXY_WORKERS=${MTPROXY_WORKERS:-1}
MTPROXY_MAX_CONNECTIONS=${MTPROXY_MAX_CONN:-4096}
MTPROXY_NAT_ARGS=${nat_args}
EOF
    chown root:mtproxy "$MTPROXY_ENV"
    chmod 0640 "$MTPROXY_ENV"

    # Если юнит mtproxy.service уже создан без MTPROXY_TAG_ARGS — обновляем его автоматически
    if [ -f /etc/systemd/system/mtproxy.service ] && ! grep -q "MTPROXY_TAG_ARGS" /etc/systemd/system/mtproxy.service; then
        sed -i '/Environment=MTPROXY_NAT_ARGS=/a Environment=MTPROXY_TAG_ARGS=' /etc/systemd/system/mtproxy.service
        sed -i 's/-S \$MTPROXY_SECRET \$MTPROXY_NAT_ARGS/-S $MTPROXY_SECRET $MTPROXY_TAG_ARGS $MTPROXY_NAT_ARGS/' /etc/systemd/system/mtproxy.service
        systemctl daemon-reload 2>/dev/null || true
    fi
}

install_systemd_units_and_firewall() {
    log_info "Настройка nftables защиты локальных портов MTProxy (${MTPROXY_PORT}, ${MTPROXY_STATS_PORT})..."
    cat << EOF > "$TPROXY_NFT"
table inet tproxy_backend {
	chain local_backend {
		type filter hook input priority -10; policy accept;
		iifname != "lo" tcp dport { ${MTPROXY_PORT}, ${MTPROXY_STATS_PORT} } drop
	}
}
EOF
    chmod 0644 "$TPROXY_NFT"

    cat << 'EOF' > /etc/systemd/system/tproxy-firewall.service
[Unit]
Description=Configure local proxy backend ports (TProxy + MTProxy)
After=nftables.service
PartOf=nftables.service
Before=mtproxy.service tproxy-server.service

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=-/usr/sbin/nft delete table inet tproxy_backend
ExecStart=/usr/sbin/nft -f /etc/tproxy-server/firewall.nft
ExecReload=-/usr/sbin/nft delete table inet tproxy_backend
ExecReload=/usr/sbin/nft -f /etc/tproxy-server/firewall.nft
ExecStop=-/usr/sbin/nft delete table inet tproxy_backend

[Install]
WantedBy=multi-user.target
EOF

    cat << EOF > /etc/systemd/system/mtproxy.service
[Unit]
Description=Official Telegram MTProxy backend (SelfSNI Integrated)
After=network-online.target tproxy-firewall.service
Wants=network-online.target
Requires=tproxy-firewall.service

[Service]
Type=simple
User=mtproxy
Group=mtproxy
EnvironmentFile=/etc/mtproxy/mtproxy.env
Environment=MTPROXY_WORKERS=1
Environment=MTPROXY_MAX_CONNECTIONS=4096
Environment=MTPROXY_TAG_ARGS=
Environment=MTPROXY_NAT_ARGS=
WorkingDirectory=/opt/MTProxy
ExecStart=/opt/MTProxy/objs/bin/mtproto-proxy -u mtproxy -p ${MTPROXY_STATS_PORT} -H ${MTPROXY_PORT} -S \$MTPROXY_SECRET \$MTPROXY_TAG_ARGS \$MTPROXY_NAT_ARGS --aes-pwd /etc/mtproxy/proxy-secret /etc/mtproxy/proxy-multi.conf -M \${MTPROXY_WORKERS} -C \${MTPROXY_MAX_CONNECTIONS}
Restart=on-failure
RestartSec=3s
LimitNOFILE=1048576
NoNewPrivileges=true
PrivateDevices=true
PrivateTmp=true
ProtectHome=true
ProtectProc=invisible
ProtectSystem=strict
ProcSubset=pid
ReadOnlyPaths=/etc/mtproxy
RestrictAddressFamilies=AF_INET AF_INET6
RestrictNamespaces=true
RestrictRealtime=true
LockPersonality=true

[Install]
WantedBy=multi-user.target
EOF

    cat << 'EOF' > /etc/systemd/system/tproxy-server.service
[Unit]
Description=Telegram Browser HTTPS/WebSocket Transport Relay (SelfSNI Integrated)
After=network-online.target mtproxy.service tproxy-firewall.service
Wants=network-online.target mtproxy.service
Requires=tproxy-firewall.service

[Service]
Type=simple
User=tproxy
Group=tproxy
LoadCredential=profiles.json:/etc/tproxy-server/profiles.json
ExecStart=/usr/local/bin/tproxy-server -config /etc/tproxy-server/config.json
Restart=on-failure
RestartSec=3s
TimeoutStopSec=20s
LimitNOFILE=1048576
NoNewPrivileges=true
PrivateDevices=true
PrivateTmp=true
ProtectClock=true
ProtectControlGroups=true
ProtectHome=true
ProtectHostname=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectProc=invisible
ProtectSystem=strict
ProcSubset=pid
RestrictAddressFamilies=AF_INET AF_INET6
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true
LockPersonality=true
MemoryDenyWriteExecute=true
CapabilityBoundingSet=
IPAddressDeny=any
IPAddressAllow=localhost
SystemCallArchitectures=native
SystemCallFilter=@system-service
UMask=0077

[Install]
WantedBy=multi-user.target
EOF

    cat << 'EOF' > /usr/local/sbin/refresh-mtproxy-config
#!/usr/bin/env bash
set -euo pipefail

# Автоматическая очистка CRLF (\r), если файл был скопирован из буфера обмена Windows
if [ -f "${BASH_SOURCE[0]:-$0}" ] && grep -q $'\r' "${BASH_SOURCE[0]:-$0}" 2>/dev/null; then
    sed -i 's/\r$//' "${BASH_SOURCE[0]:-$0}" 2>/dev/null || true
    exec bash "${BASH_SOURCE[0]:-$0}" "$@"
fi

destination=/etc/mtproxy/proxy-multi.conf
temporary="$(mktemp /etc/mtproxy/proxy-multi.conf.XXXXXX)"
trap 'rm -f "$temporary"' EXIT

curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
	--output "$temporary" https://core.telegram.org/getProxyConfig
test "$(wc -c < "$temporary")" -ge 100
grep -q '^default ' "$temporary"
grep -q '^proxy_for ' "$temporary"
chown root:mtproxy "$temporary"
chmod 0640 "$temporary"
if [[ -e "$destination" ]] && cmp -s "$temporary" "$destination"; then
	rm -f "$temporary"
	trap - EXIT
	exit 0
fi
mv -f "$temporary" "$destination"
trap - EXIT
systemctl try-restart mtproxy.service
EOF
    chmod 0755 /usr/local/sbin/refresh-mtproxy-config

    cat << 'EOF' > /etc/systemd/system/refresh-mtproxy-config.service
[Unit]
Description=Refresh official MTProxy routing configuration
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/refresh-mtproxy-config
ProtectProc=invisible
ProcSubset=pid
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/etc/mtproxy
EOF
    chmod 0644 /etc/systemd/system/refresh-mtproxy-config.service

    cat << 'EOF' > /etc/systemd/system/refresh-mtproxy-config.timer
[Unit]
Description=Daily official MTProxy routing refresh

[Timer]
OnBootSec=10m
OnUnitActiveSec=1d
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF
    chmod 0644 /etc/systemd/system/refresh-mtproxy-config.timer
}

# ==============================================================================
# БЕСШОВНАЯ ИНТЕГРАЦИЯ С NGINX SELFSNI (MIRROR + UPSTREAM + LOCATION)
# ==============================================================================
configure_nginx_integration() {
    load_configs
    if [ -z "${DOMAIN:-}" ]; then
        log_err "Домен SelfSNI не определен! Сначала установите SelfSNI или укажите домен."
        return 1
    fi

    mkdir -p /etc/nginx/conf.d "$NGINX_EXT_DIR"

    # 1. Создаем upstream и локальное зеркало сайта SelfSNI на 127.0.0.1:9480.
    # Зачем нужно зеркало: когда на /<base_path>/ приходит запрос без валидного секрета (например, сканер ТСПУ),
    # tproxy-server проксирует его в public_upstream (127.0.0.1:9480), который отдает ТОТ ЖЕ САМЫЙ сайт и 404.html,
    # что и основной шлюз SelfSNI — никакого отличия в ответах нет!
    cat << EOF > "$NGINX_UPSTREAM_CONF"
# ==============================================================================
# TPROXY-SERVER UPSTREAM & LOOPBACK DECOY MIRROR (FOR SELFSNI INTEGRATION)
# ==============================================================================
map \$http_upgrade \$tproxy_connection_upgrade {
    default upgrade;
    ''      "";
}

upstream tproxy_relay {
    server 127.0.0.1:${TPROXY_PORT};
    keepalive 32;
}

server {
    listen 127.0.0.1:${MIRROR_PORT};
    server_name _;

    root ${WEB_ROOT};
    index index.html;
    server_tokens off;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location = /health {
        default_type application/json;
        return 200 '{"status":"HEALTHY","cluster":"edge-node-01","uptime":"99.995%","region":"eu-west"}';
    }

    location = /api/v1/status {
        default_type application/json;
        return 200 '{"cluster":"operational","pop":"tier4-datacenter","mesh":"synchronized"}';
    }

    location = /api/v1/contact {
        default_type application/json;
        return 200 '{"success":true,"ticket":"INC-84920","status":"QUEUED","message":"Technical brief received and assigned to edge operations"}';
    }

    location = ${XHTTP_PATH} {
        default_type application/json;
        if (\$request_method = POST) {
            return 401 '{"status":"error","code":"UNAUTHORIZED","message":"Multipart session authorization signature required","path":"${XHTTP_PATH}"}';
        }
        return 405 '{"status":"error","code":"METHOD_NOT_ALLOWED","message":"POST multipart/form-data required on file upload endpoint"}';
    }

    location ~ ^/api/ {
        default_type application/json;
        return 401 '{"status":"error","code":"UNAUTHORIZED","message":"Authorization bearer token missing or expired"}';
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

    # 2. Создаем конфигурацию локации внутри основного HTTPS-блока SelfSNI
    if [ -n "$BASE_PATH" ]; then
        cat << EOF > "$NGINX_EXT_CONF"
# Интеграция Telegram WEB Proxy (Mode B: Co-hosting по префиксу /${BASE_PATH}/)
client_max_body_size 4m;

location ^~ /${BASE_PATH}/ {
    proxy_pass http://tproxy_relay;
    proxy_http_version 1.1;

    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$tproxy_connection_upgrade;

    proxy_read_timeout 90s;
    proxy_send_timeout 90s;
    proxy_buffering off;
    proxy_request_buffering off;

    # Отключаем наследование X-Frame-Options: SAMEORIGIN от server{},
    # чтобы не блокировать CSP WebView-моста Telegram Desktop/Mobile
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    access_log off;
}
EOF
    else
        cat << EOF > "$NGINX_EXT_CONF"
# Интеграция Telegram WEB Proxy (Mode A: Корневой режим на / и /api/v1/*)
client_max_body_size 4m;

location = / {
    proxy_pass http://tproxy_relay;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_read_timeout 90s;
    proxy_send_timeout 90s;
    proxy_buffering off;
    proxy_request_buffering off;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    access_log off;
}

location ^~ /api/v1/session {
    proxy_pass http://tproxy_relay;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_read_timeout 90s;
    proxy_send_timeout 90s;
    proxy_buffering off;
    proxy_request_buffering off;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    access_log off;
}

location ^~ /api/v1/up {
    proxy_pass http://tproxy_relay;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_read_timeout 90s;
    proxy_send_timeout 90s;
    proxy_buffering off;
    proxy_request_buffering off;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    access_log off;
}

location ^~ /api/v1/down {
    proxy_pass http://tproxy_relay;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_read_timeout 90s;
    proxy_send_timeout 90s;
    proxy_buffering off;
    proxy_request_buffering off;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    access_log off;
}

location ^~ /api/v1/ws {
    proxy_pass http://tproxy_relay;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$tproxy_connection_upgrade;
    proxy_read_timeout 90s;
    proxy_send_timeout 90s;
    proxy_buffering off;
    proxy_request_buffering off;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    access_log off;
}
EOF
    fi

    # 3. Проверяем наличие директивы include /etc/nginx/selfsni-extensions/*.conf; в конфиге домена SelfSNI
    #    а также настраиваем умный режим порта 443 (работа как с нодой Remnanode, так и без ноды!)
    local vhost_file="/etc/nginx/sites-available/${DOMAIN}"
    if [ -f "$vhost_file" ]; then
        if ! grep -q "/etc/nginx/selfsni-extensions/\*\.conf" "$vhost_file"; then
            log_info "Подключение хука selfsni-extensions в $vhost_file..."
            cp "$vhost_file" "${vhost_file}.bak-tproxy"
            # Убираем server-level limit_req (если был на уровне server), чтобы он не душил мультиплекс TProxy
            sed -i '/^[[:space:]]*limit_req zone=selfsni_limit/d' "$vhost_file"
            # Вставляем include перед первой локацией в основном блоке сервера
            sed -i '/add_header Strict-Transport-Security/a \    include /etc/nginx/selfsni-extensions/*.conf;' "$vhost_file"
        fi

        # Настраиваем режим порта 443 строго по выбору пользователя (0 = с нодой Remnanode, 1 = без ноды напрямую)
        local want_direct_443="0"
        if [ "${DIRECT_443_MODE:-0}" = "1" ]; then
            want_direct_443="1"
            log_info "Режим БЕЗ ноды: включаем прямой прием внешнего 443 порта в Nginx (+ сохраняем 127.0.0.1:${FALLBACK_PORT})..."
        else
            want_direct_443="0"
            log_info "Режим С НОДОЙ Remnanode: Nginx слушает только внутренний порт 127.0.0.1:${FALLBACK_PORT} (порт 443 свободен для Xray)..."
        fi

        sed -i '/# SELFSNI_DIRECT_443/d' "$vhost_file"
        if [ "$want_direct_443" = "1" ]; then
            local h2_tok=""
            if grep -qE "listen[[:space:]]+127\.0\.0\.1:[0-9]+[[:space:]]+ssl[[:space:]]+http2" "$vhost_file"; then
                h2_tok=" http2"
            fi
            local has_v6="0"
            if grep -q "listen \[::\]:80" "$vhost_file"; then
                has_v6="1"
            fi
            local tmp_v
            tmp_v="$(mktemp /tmp/vhost-443.XXXXXX)"
            if awk -v h2="$h2_tok" -v v6="$has_v6" '
                /listen[[:space:]]+127\.0\.0\.1:[0-9]+[[:space:]]+ssl/ {
                    if ($0 ~ /default_server/) {
                        print "    listen 443 ssl" h2 " default_server; # SELFSNI_DIRECT_443"
                        if (v6 == "1") print "    listen [::]:443 ssl" h2 " default_server; # SELFSNI_DIRECT_443"
                    } else {
                        print "    listen 443 ssl" h2 "; # SELFSNI_DIRECT_443"
                        if (v6 == "1") print "    listen [::]:443 ssl" h2 "; # SELFSNI_DIRECT_443"
                    }
                }
                { print }
            ' "$vhost_file" > "$tmp_v"; then
                mv -f "$tmp_v" "$vhost_file"
            else
                rm -f "$tmp_v"
            fi
            if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi "Status: active"; then
                ufw allow 443/tcp >/dev/null 2>&1 || true
                ufw allow 443/udp >/dev/null 2>&1 || true
            fi
        fi
    else
        log_warn "Файл $vhost_file не найден! Убедитесь, что SelfSNI установлен для домена $DOMAIN."
    fi

    if nginx -t >/dev/null 2>&1; then
        systemctl reload nginx 2>/dev/null || systemctl restart nginx
        log_ok "Конфигурация Nginx SelfSNI успешно синхронизирована с TProxy!"
    else
        log_err "Ошибка проверки конфигурации Nginx (nginx -t)!"
        nginx -t || true
        return 1
    fi
}

# ==============================================================================
# ЗАПУСК И ПРОВЕРКА СЛУЖБ TPROXY + MTPROXY
# ==============================================================================
start_and_verify_services() {
    log_info "Валидация конфигурации tproxy-server..."
    /usr/local/bin/tproxy-server -config "$TPROXY_CONF" -profiles-file "$TPROXY_PROFILES" -check

    systemctl daemon-reload
    systemctl enable --now tproxy-firewall.service >/dev/null 2>&1
    systemctl restart tproxy-firewall.service
    systemctl enable --now mtproxy.service >/dev/null 2>&1
    systemctl restart mtproxy.service
    systemctl enable --now tproxy-server.service >/dev/null 2>&1
    systemctl restart tproxy-server.service
    if [ -f /etc/systemd/system/refresh-mtproxy-config.timer ]; then
        systemctl enable --now refresh-mtproxy-config.timer >/dev/null 2>&1 || true
    fi

    log_info "Ожидание готовности релея (127.0.0.1:${TPROXY_ADMIN_PORT}/readyz)..."
    local ready=0
    for _ in $(seq 1 20); do
        if curl --fail --silent --output /dev/null "http://127.0.0.1:${TPROXY_ADMIN_PORT}/readyz" 2>/dev/null; then
            ready=1
            break
        fi
        sleep 1
    done

    if [ "$ready" -eq 1 ]; then
        log_ok "Службы tproxy-server и mtproxy активны и готовы к приему трафика!"
    else
        log_warn "tproxy-server запустился, но /readyz еще не вернул 200 OK. Проверьте пункт диагностики в меню."
    fi
}

# ==============================================================================
# ВЫВОД ДАННЫХ ПОДКЛЮЧЕНИЯ И ССЫЛОК ДЛЯ КЛИЕНТОВ TELEGRAM
# ==============================================================================
print_connection_info() {
    load_configs
    echo -e "\n${CYAN}╭────────────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${BOLD}   📲 ДАННЫЕ ПОДКЛЮЧЕНИЯ TELEGRAM WEB PROXY (ДЛЯ DESKTOP / ANDROID / IOS)   ${CYAN}│${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────────────────────────────────╯${NC}"

    if [ ! -f "$TPROXY_PROFILES" ]; then
        log_warn "Файл профилей $TPROXY_PROFILES еще не создан."
        return 0
    fi

    local server_field="$DOMAIN"
    local url_server_field="$DOMAIN"
    if [ -n "$BASE_PATH" ]; then
        server_field="${DOMAIN}/${BASE_PATH}"
        url_server_field="${DOMAIN}%2F${BASE_PATH//\//%2F}"
    fi

    local count
    count=$(jq '.profiles | length' "$TPROXY_PROFILES" 2>/dev/null || echo 0)

    for ((i = 0; i < count; i++)); do
        local p_name p_sec p_mode p_client_sec
        p_name=$(jq -r ".profiles[$i].name" "$TPROXY_PROFILES")
        p_sec=$(jq -r ".profiles[$i].secret" "$TPROXY_PROFILES")
        p_mode=$(jq -r ".profiles[$i].carrier_mode // \"https\"" "$TPROXY_PROFILES")
        p_client_sec="$(derive_client_secret "$p_sec" "$BASE_PATH")"

        echo -e "\n ${BOLD}${MAGENTA}◈ Профиль [$((i + 1))]: ${WHITE}${p_name}${NC} ${DIM}(Carrier Mode: ${CYAN}${p_mode}${NC}${DIM})${NC}"
        echo -e " ${GRAY}────────────────────────────────────────────────────────────────────────────${NC}"
        echo -e "  • ${BOLD}Для ручного ввода в настройках Telegram (Proxy ➔ WEB Proxy):${NC}"
        echo -e "    Server (Хост):      ${GREEN}${BOLD}${server_field}${NC}"
        echo -e "    Secret (Hex):       ${YELLOW}${BOLD}${p_sec}${NC}"
        if [ -n "$BASE_PATH" ]; then
            echo -e "    Secret (Marked):    ${CYAN}${p_client_sec}${NC} ${DIM}(используется внутри ссылок с Base Path)${NC}"
        fi
        echo -e "\n  • ${BOLD}Готовые ссылки для быстрого подключения в 1 клик:${NC}"
        echo -e "    🔗 ${WHITE}https://t.me/webproxy?server=${url_server_field}&secret=${p_client_sec}${NC}"
        echo -e "    🔗 ${WHITE}tg://webproxy?server=${url_server_field}&secret=${p_client_sec}${NC}"
    done
    echo -e "\n${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${DIM}Примечание: Снаружи весь трафик идет через 443 порт ➔ Remnanode (Reality) ➔ Nginx SelfSNI ➔ TProxy.${NC}"
}

# ==============================================================================
# КОМПЛЕКСНЫЙ SELF-TEST И ДИАГНОСТИКА СВЯЗКИ SELFSNI + TPROXY + MTPROXY
# ==============================================================================
run_full_diagnostics() {
    load_configs
    echo -e "\n${CYAN}==============================================================================${NC}"
    echo -e "${CYAN}     🧪 ДИАГНОСТИКА СВЯЗКИ: REMNA (443) ➔ NGINX SELFSNI ➔ TPROXY ➔ MTPROXY    ${NC}"
    echo -e "${CYAN}==============================================================================${NC}\n"

    # 1. Проверка systemd служб
    for svc in nginx tproxy-firewall mtproxy tproxy-server; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "  ${GREEN}[OK]${NC} Служба ${BOLD}${svc}${NC}: АКТИВНА (RUNNING)"
        else
            echo -e "  ${RED}[СБОЙ]${NC} Служба ${BOLD}${svc}${NC}: НЕ ЗАПУЩЕНА!"
        fi
    done

    # 2. Проверка локальных эндпоинтов /healthz и /readyz
    local health_out ready_out
    health_out=$(curl -s --max-time 3 "http://127.0.0.1:${TPROXY_ADMIN_PORT}/healthz" || true)
    ready_out=$(curl -s --max-time 3 "http://127.0.0.1:${TPROXY_ADMIN_PORT}/readyz" || true)
    if [ "$health_out" = "ok" ]; then
        echo -e "  ${GREEN}[OK]${NC} Релей Healthcheck (/healthz): ${GREEN}200 OK${NC}"
    else
        echo -e "  ${RED}[СБОЙ]${NC} Релей Healthcheck (/healthz): Нет ответа!"
    fi
    if [ "$ready_out" = "ready" ]; then
        echo -e "  ${GREEN}[OK]${NC} Связь релея с локальным MTProxy (/readyz): ${GREEN}200 READY (127.0.0.1:${MTPROXY_PORT})${NC}"
    else
        echo -e "  ${RED}[СБОЙ]${NC} Связь релея с MTProxy (/readyz): ${RED}503 Backend Unavailable${NC}"
    fi

    # 3. Проверка соединения MTProxy с Telegram RPC Middle-End (защита от NAT-ошибки)
    local rpc_drops
    rpc_drops=$(journalctl -u mtproxy --since "-5min" 2>/dev/null | grep -c "Disconnected from RPC Middle-End" || true)
    if [ "${rpc_drops:-0}" -le 2 ]; then
        echo -e "  ${GREEN}[OK]${NC} Соединение MTProxy с датацентрами Telegram (RPC Middle-End): ${GREEN}СТАБИЛЬНО${NC}"
    else
        echo -e "  ${RED}[ВНИМАНИЕ]${NC} Обнаружены сбросы RPC Middle-End (${rpc_drops} за 5 мин)! Проверьте настройки NAT в п. 10."
    fi

    # 4. Проверка таблицы nftables (закрытие портов 2398 и 8888 снаружи)
    if nft list table inet tproxy_backend >/dev/null 2>&1; then
        echo -e "  ${GREEN}[OK]${NC} Защита портов ${MTPROXY_PORT}/${MTPROXY_STATS_PORT} (nftables inet tproxy_backend): ${GREEN}АКТИВНА${NC}"
    else
        echo -e "  ${RED}[РИСК]${NC} Таблица nftables inet tproxy_backend не загружена! Порт ${MTPROXY_PORT} может быть виден снаружи."
    fi

    # 5. Проверка зеркала SelfSNI (127.0.0.1:9480) и маскировки при неверном ?bridge=wrong
    local mirror_code probe_code
    mirror_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://127.0.0.1:${MIRROR_PORT}/" || echo "000")
    if [ "$mirror_code" = "200" ]; then
        echo -e "  ${GREEN}[OK]${NC} Локальное зеркало сайта SelfSNI (127.0.0.1:${MIRROR_PORT}): ${GREEN}HTTP 200 OK${NC}"
    else
        echo -e "  ${YELLOW}[WARN]${NC} Локальное зеркало SelfSNI (127.0.0.1:${MIRROR_PORT}) вернуло код: ${mirror_code}"
    fi

    local test_path="/?bridge=wrong_probe_test"
    [ -n "$BASE_PATH" ] && test_path="/${BASE_PATH}/?bridge=wrong_probe_test"
    probe_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 -H "Host: ${DOMAIN}" "http://127.0.0.1:${TPROXY_PORT}${test_path}" || echo "000")
    if [ -n "$BASE_PATH" ] && [ "$probe_code" = "404" ]; then
        echo -e "  ${GREEN}[OK]${NC} Защита от пробинга (${test_path}): ${GREEN}Возвращает неотличимый 404 сайта SelfSNI${NC}"
    elif [ -z "$BASE_PATH" ] && [ "$probe_code" = "200" ]; then
        echo -e "  ${GREEN}[OK]${NC} Защита от пробинга (${test_path}): ${GREEN}Возвращает главную страницу сайта SelfSNI (200)${NC}"
    else
        echo -e "  ${YELLOW}[ИНФО]${NC} Ответ на тестовый пробинг (${test_path}): HTTP ${probe_code}"
    fi

    echo -e "${CYAN}==============================================================================${NC}"
}

# ==============================================================================
# УПРАВЛЕНИЕ ПРОФИЛЯМИ И СЕКРЕТАМИ (МУЛЬТИ-ПРОФИЛИ В PROFILES.JSON)
# ==============================================================================
profiles_management_menu() {
    while true; do
        clear
        load_configs
        echo -e "${CYAN}╭────────────────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${BOLD}   👥 УПРАВЛЕНИЕ ПРОФИЛЯМИ И СЕКРЕТАМИ TELEGRAM WEB PROXY                   ${CYAN}│${NC}"
        echo -e "${CYAN}╰────────────────────────────────────────────────────────────────────────────╯${NC}"
        print_connection_info

        local ad_tag_display="${DIM}Не задан${NC}"
        if [ -n "${MTPROXY_AD_TAG:-}" ]; then
            ad_tag_display="${GREEN}${BOLD}${MTPROXY_AD_TAG}${NC}"
        fi
        echo -e "  • ${BOLD}Рекламный тег (@MTProxyBot Ad-Tag):${NC} ${ad_tag_display}"

        echo -e "\n   ${BOLD}1${NC} ❯ ➕ Добавить новый профиль (отдельный секрет и свой Carrier Mode)"
        echo -e "   ${BOLD}2${NC} ❯ 🔄 Сгенерировать новый секрет для основного профиля (default)"
        echo -e "   ${BOLD}3${NC} ❯ 🗑️  Удалить дополнительный профиль"
        echo -e "   ${BOLD}4${NC} ❯ 📢 Установить / изменить рекламный тег (ad_tag от @MTProxyBot)"
        echo -e "   ${BOLD}0${NC} ❯ ↩️  Назад в главное меню"
        echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
        local p_choice=""
        read -rp "❯ Выберите действие [0-4]: " p_choice || true
        p_choice=$(echo "$p_choice" | tr -cd '0-9')

        case "$p_choice" in
            1)
                local new_name=""
                read -rp "Введите имя нового профиля (латиница/цифры, например friend1 или ios): " new_name || true
                new_name=$(echo "$new_name" | tr -cd 'a-zA-Z0-9_-')
                if [ -z "$new_name" ]; then
                    log_warn "Имя профиля не может быть пустым."
                    sleep 1.5
                    continue
                fi
                local auto_sec
                auto_sec="$(generate_random_secret)"
                local new_sec=""
                read -rp "Секрет (32 hex) [Enter для автогенерации: $auto_sec]: " new_sec || true
                new_sec="${new_sec:-$auto_sec}"
                new_sec=$(echo "$new_sec" | tr 'A-F' 'a-f' | tr -d '[:space:]')
                if ! [[ "$new_sec" =~ ^([0-9a-f]{32}|dd[0-9a-f]{32})$ ]]; then
                    log_err "Секрет должен содержать 32 hex-символа (или 34 с префиксом dd)!"
                    sleep 2
                    continue
                fi
                echo -e "\nВыберите Carrier Mode для профиля ${BOLD}${new_name}${NC}:"
                echo -e "  1) websocket (Рекомендуется — единый быстрый WebSocket)"
                echo -e "  2) websocket-lanes (Многопоточный WebSocket для тяжелых медиа)"
                echo -e "  3) https-lanes (Многопоточный HTTP/2 POST + Long-Poll)"
                echo -e "  4) https (Консервативный базовый HTTPS)"
                local m_sel=""
                read -rp "Ваш выбор [1-4, по умолчанию: 1]: " m_sel || true
                local chosen_mode="websocket"
                case "${m_sel:-1}" in
                    2) chosen_mode="websocket-lanes" ;;
                    3) chosen_mode="https-lanes" ;;
                    4) chosen_mode="https" ;;
                    *) chosen_mode="websocket" ;;
                esac

                local tmp_p
                tmp_p="$(mktemp /etc/tproxy-server/profiles.XXXXXX)"
                if jq --arg n "$new_name" --arg s "$new_sec" --arg m "$chosen_mode" --arg b "127.0.0.1:${MTPROXY_PORT}" \
                    '.profiles += [{"name":$n,"secret":$s,"backend":$b,"carrier_mode":$m}]' "$TPROXY_PROFILES" > "$tmp_p"; then
                    mv -f "$tmp_p" "$TPROXY_PROFILES"
                    chown root:tproxy "$TPROXY_PROFILES"
                    chmod 0400 "$TPROXY_PROFILES"
                    write_tproxy_configs
                    start_and_verify_services
                    log_ok "Профиль '$new_name' успешно добавлен и активирован!"
                else
                    rm -f "$tmp_p"
                    log_err "Не удалось обновить profiles.json!"
                fi
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            2)
                local new_def_sec
                new_def_sec="$(generate_random_secret)"
                local custom_sec=""
                read -rp "Новый секрет для default [Enter для случайного: $new_def_sec]: " custom_sec || true
                PRIMARY_SECRET="${custom_sec:-$new_def_sec}"
                PRIMARY_SECRET=$(echo "$PRIMARY_SECRET" | tr 'A-F' 'a-f' | tr -d '[:space:]')
                if ! [[ "$PRIMARY_SECRET" =~ ^([0-9a-f]{32}|dd[0-9a-f]{32})$ ]]; then
                    log_err "Некорректный формат секрета!"
                    sleep 2
                    continue
                fi
                save_tproxy_env
                write_tproxy_configs
                start_and_verify_services
                log_ok "Основной секрет успешно обновлен!"
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            3)
                local del_name=""
                read -rp "Введите имя профиля для удаления (кроме default): " del_name || true
                if [ -z "$del_name" ] || [ "$del_name" = "default" ]; then
                    log_warn "Основной профиль default удалить нельзя (можно сменить его секрет в п. 2)."
                    sleep 2
                    continue
                fi
                local tmp_p
                tmp_p="$(mktemp /etc/tproxy-server/profiles.XXXXXX)"
                if jq --arg n "$del_name" '.profiles |= map(select(.name != $n))' "$TPROXY_PROFILES" > "$tmp_p"; then
                    mv -f "$tmp_p" "$TPROXY_PROFILES"
                    chown root:tproxy "$TPROXY_PROFILES"
                    chmod 0400 "$TPROXY_PROFILES"
                    write_tproxy_configs
                    start_and_verify_services
                    log_ok "Профиль '$del_name' удален!"
                else
                    rm -f "$tmp_p"
                fi
                sleep 1.5
                ;;
            4)
                echo -e "\n${BOLD}${CYAN}НАСТРОЙКА РЕКЛАМНОГО ТЕГА (@MTProxyBot Ad-Tag / -P):${NC}"
                echo -e "${DIM}Как получить: напишите @MTProxyBot ➔ /newproxy ➔ укажите <IP_сервера>:443 и ваш 32-hex Secret.${NC}"
                local tag_in=""
                read -rp "Введите 32-символьный hex Ad-Tag [оставьте пустым для отключения]: " tag_in || true
                tag_in=$(echo "$tag_in" | tr 'A-F' 'a-f' | tr -d '[:space:]')
                if [ -z "$tag_in" ]; then
                    MTPROXY_AD_TAG=""
                    log_info "Рекламный тег (ad_tag) отключен."
                elif [[ "$tag_in" =~ ^[0-9a-f]{32}$ ]]; then
                    MTPROXY_AD_TAG="$tag_in"
                    log_ok "Рекламный тег установлен: $MTPROXY_AD_TAG"
                else
                    log_err "Некорректный формат! Ad-Tag от @MTProxyBot должен состоять ровно из 32 hex-символов."
                    sleep 2
                    continue
                fi
                save_tproxy_env
                write_tproxy_configs
                start_and_verify_services
                echo -e "\nНажмите Enter для продолжения..."
                read -r || true
                ;;
            0)
                return 0
                ;;
        esac
    done
}

# ==============================================================================
# МАСТЕР ПЕРВОНАЧАЛЬНОЙ УСТАНОВКИ И ИНТЕГРАЦИИ С SELFSNI
# ==============================================================================
install_tproxy() {
    check_root
    check_arch
    clear
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${CYAN}   🚀 УСТАНОВКА TELEGRAM WEB PROXY (TPROXY-SERVER) В СВЯЗКЕ С NGINX SELFSNI   ${NC}"
    echo -e "${CYAN}==============================================================================${NC}\n"

    load_configs

    if [ -n "${DOMAIN:-}" ]; then
        log_ok "Обнаружена активная установка SelfSNI!"
        echo -e "  • Домен SNI:          ${GREEN}${BOLD}${DOMAIN}${NC}"
        echo -e "  • Внутренний порт:    ${WHITE}127.0.0.1:${FALLBACK_PORT}${NC}"
        echo -e "  • Папка сайта:        ${WHITE}${WEB_ROOT}${NC}"
        echo -e "  • Защищенный XHTTP:   ${WHITE}${XHTTP_PATH}${NC}\n"
    else
        log_warn "Конфигурация /etc/selfsni/selfsni.conf не найдена!"
        echo -e "Рекомендуется сначала установить SelfSNI, чтобы Nginx и SSL-сертификаты были готовы."
    fi

    local dom_input=""
    read -rp "Доменное имя для Telegram WEB Proxy [по умолчанию: ${DOMAIN:-}]: " dom_input || true
    DOMAIN="${dom_input:-${DOMAIN:-}}"
    DOMAIN=$(echo "$DOMAIN" | tr 'A-Z' 'a-z' | tr -d '[:space:]')
    if [ -z "$DOMAIN" ] || [[ ! "$DOMAIN" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] || [[ "$DOMAIN" != *.* ]]; then
        log_err "Некорректное доменное имя ($DOMAIN). Домен должен быть в нижнем регистре ASCII/Punycode."
        return 1
    fi
    WEB_ROOT="${WEB_ROOT:-/var/www/$DOMAIN}"

    echo -e "\n${MAGENTA}1. ВЫБОР РЕЖИМА МАРШРУТИЗАЦИИ И BASE PATH (ПРЕФИКСА ПУТИ):${NC}"
    echo -e "1) ${GREEN}[Рекомендуется] Случайный секретный Base Path (Mode B)${NC}"
    echo -e "   Генерируется 16-символьный префикс (например, /phcf2vfe7zgbrslg/)."
    echo -e "   Корень сайта и пути XHTTP (/api/v1/files/upload) остаются за Nginx SelfSNI,"
    echo -e "   а сканеры ТСПУ при проверке домена вообще не видят эндпоинтов релея."
    echo -e "2) ${CYAN}Свой кастомный Base Path (Mode B)${NC}"
    echo -e "   Например: edge-sync, cloud-telemetry, s3-gateway (красиво смотрится в логах)."
    echo -e "3) ${YELLOW}Корневой режим без префикса (Mode A, base_path = \"\")${NC}"
    echo -e "   Релей работает прямо в корне домена /. Подходит для старых клиентов без маркера 0x70."

    local bp_choice=""
    read -rp "Выберите режим пути [1-3, по умолчанию: 1]: " bp_choice || true
    bp_choice="${bp_choice:-1}"

    if [ "$bp_choice" = "3" ]; then
        BASE_PATH=""
        log_info "Выбран корневой режим (Mode A, без префикса пути)."
    elif [ "$bp_choice" = "2" ]; then
        local custom_bp=""
        read -rp "Введите свой префикс (латиница/цифры/дефис, без слешей по краям, например edge-sync-v2): " custom_bp || true
        custom_bp="${custom_bp#/}"
        custom_bp="${custom_bp%/}"
        if [ -z "$custom_bp" ] || ! [[ "$custom_bp" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*(/[A-Za-z0-9][A-Za-z0-9_-]*)*$ ]]; then
            log_warn "Некорректный префикс ($custom_bp). Сгенерирован безопасный случайный префикс."
            BASE_PATH="$(generate_random_slug)"
        else
            BASE_PATH="$custom_bp"
        fi
        log_info "Установлен префикс пути: /${BASE_PATH}/"
    else
        local default_slug
        default_slug="$(generate_random_slug)"
        BASE_PATH="$default_slug"
        log_info "Сгенерирован секретный префикс пути: /${BASE_PATH}/"
    fi

    echo -e "\n${MAGENTA}2. ВЫБОР ТРАНСПОРТНОГО РЕЖИМА WEBVIEW (CARRIER MODE):${NC}"
    echo -e "1) ${GREEN}[Рекомендуется] websocket${NC}       — Единый мультиплексированный WebSocket (быстрый старт, идеален для Desktop/iOS/macOS/Android)"
    echo -e "2) ${CYAN}websocket-lanes${NC} — Независимый WebSocket на каждый поток (макс. скорость загрузки медиа без задержек чата)"
    echo -e "3) ${BLUE}https-lanes${NC}     — Независимые HTTP/2 POST + Long-Poll потоки (отлично проходит, если провайдер режет WebSocket)"
    echo -e "4) ${YELLOW}https${NC}           — Базовый сериализованный HTTPS (1 POST + 1 Long-Poll, минимальная нагрузка)"

    local cm_choice=""
    read -rp "Выберите Carrier Mode [1-4, по умолчанию: 1]: " cm_choice || true
    case "${cm_choice:-1}" in
        2) CARRIER_MODE="websocket-lanes" ;;
        3) CARRIER_MODE="https-lanes" ;;
        4) CARRIER_MODE="https" ;;
        *) CARRIER_MODE="websocket" ;;
    esac
    log_info "Выбран транспортный режим: $CARRIER_MODE"

    echo -e "\n${MAGENTA}3. НАСТРОЙКА СЕКРЕТНОГО КЛЮЧА (WEB PROXY / MTPROXY SECRET):${NC}"
    local auto_secret
    auto_secret="$(generate_random_secret)"
    local sec_input=""
    read -rp "Секрет прокси (32 hex) [Нажмите Enter для случайного: $auto_secret]: " sec_input || true
    PRIMARY_SECRET="${sec_input:-$auto_secret}"
    PRIMARY_SECRET=$(echo "$PRIMARY_SECRET" | tr 'A-F' 'a-f' | tr -d '[:space:]')
    if ! [[ "$PRIMARY_SECRET" =~ ^([0-9a-f]{32}|dd[0-9a-f]{32})$ ]]; then
        log_warn "Некорректный формат секрета. Используется автоматически сгенерированный ключ."
        PRIMARY_SECRET="$auto_secret"
    fi
    log_info "Установлен секрет: $PRIMARY_SECRET"

    echo -e "\n${DIM}Подсказка: Вы можете зарегистрировать <IP_сервера>:443 и секрет $PRIMARY_SECRET в @MTProxyBot для спонсорского канала.${NC}"
    local tag_input=""
    read -rp "Рекламный тег от @MTProxyBot (32 hex, опционально) [Enter — пропустить]: " tag_input || true
    tag_input=$(echo "$tag_input" | tr 'A-F' 'a-f' | tr -d '[:space:]')
    if [[ "$tag_input" =~ ^[0-9a-f]{32}$ ]]; then
        MTPROXY_AD_TAG="$tag_input"
        log_info "Активирован рекламный тег (ad_tag): $MTPROXY_AD_TAG"
    else
        MTPROXY_AD_TAG=""
    fi

    echo -e "\n${MAGENTA}4. ОПТИМИЗАЦИЯ ДЛЯ МОБИЛЬНЫХ КЛИЕНТОВ И РЕСУРСОВ СЕРВЕРА:${NC}"
    local mob_input=""
    read -rp "Включить мобильный профиль (reconnect_grace=5m для удержания сессии в фоне + совместимость фреймов 512 КБ)? [Y/n, по умолчанию: Y]: " mob_input || true
    mob_input="${mob_input:-y}"
    if [[ "$mob_input" =~ ^[Yy]$ ]]; then
        MOBILE_OPTIMIZED="1"
        log_info "Мобильная оптимизация: ВКЛЮЧЕНА (reconnect_grace: 5m, max_frame_payload: 512 KiB)"
    else
        MOBILE_OPTIMIZED="0"
        log_info "Мобильная оптимизация: СТАНДАРТ (reconnect_grace: 2m, max_frame_payload: 1 MiB)"
    fi

    local cpu_cores
    cpu_cores="$(nproc 2>/dev/null || echo 1)"
    local workers_input=""
    read -rp "Количество воркеров официального MTProxy (доступно ядер CPU: $cpu_cores) [по умолчанию: 1]: " workers_input || true
    MTPROXY_WORKERS="${workers_input:-1}"
    if ! [[ "$MTPROXY_WORKERS" =~ ^[1-9][0-9]*$ ]] || [ "$MTPROXY_WORKERS" -gt 64 ]; then
        MTPROXY_WORKERS="1"
    fi

    local maxconn_input=""
    read -rp "Максимум клиентских соединений на 1 воркер MTProxy [по умолчанию: 4096]: " maxconn_input || true
    MTPROXY_MAX_CONN="${maxconn_input:-4096}"
    if ! [[ "$MTPROXY_MAX_CONN" =~ ^[1-9][0-9]*$ ]]; then
        MTPROXY_MAX_CONN="4096"
    fi

    echo -e "\n${MAGENTA}5. ВЫБОР РЕЖИМА РАБОТЫ ПОРТА 443 (С НОДОЙ REMNANODE ИЛИ БЕЗ НОДЫ):${NC}"
    echo -e "1) ${GREEN}В связке с нодой Remnanode / Xray${NC} — Nginx слушает только 127.0.0.1:${FALLBACK_PORT} (443 порт занимает нода)"
    echo -e "2) ${CYAN}Автономный режим БЕЗ ноды${NC}         — Nginx сам принимает внешний 443 порт (сайт и TProxy работают без ноды)"
    local m443_in=""
    read -rp "Выберите режим порта 443 [1-2, по умолчанию: 1]: " m443_in || true
    m443_in=$(echo "${m443_in:-1}" | tr -cd '0-9')
    if [ "$m443_in" = "2" ]; then
        DIRECT_443_MODE="1"
        log_info "Выбран автономный режим БЕЗ ноды (Nginx слушает внешний 443 порт + 127.0.0.1:${FALLBACK_PORT})."
    else
        DIRECT_443_MODE="0"
        log_info "Выбран режим В СВЯЗКЕ С НОДОЙ Remnanode (Nginx слушает только 127.0.0.1:${FALLBACK_PORT})."
    fi

    echo ""
    # Удаляем старый profiles.json при чистой переустановке, чтобы записать чистый профиль
    rm -f "$TPROXY_PROFILES"

    build_and_install_tproxy_relay
    build_and_install_mtproxy
    save_tproxy_env
    write_tproxy_configs
    install_systemd_units_and_firewall
    configure_nginx_integration
    start_and_verify_services

    # Установка глобальной команды tproxy
    local self_path
    self_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    if [ "$self_path" != "/usr/local/bin/tproxy" ]; then
        cp -f "$self_path" /usr/local/bin/tproxy
        chmod +x /usr/local/bin/tproxy
        log_ok "Команда управления 'tproxy' установлена глобально (/usr/local/bin/tproxy)!"
    fi

    print_connection_info
    echo -e "\n${GREEN}${BOLD}🎉 Установка и интеграция с SelfSNI успешно завершена!${NC}"
    echo -e "Для вызова панели управления в любой момент введите команду: ${CYAN}${BOLD}tproxy${NC}\n"
}

# ==============================================================================
# ПОЛНОЕ УДАЛЕНИЕ TPROXY (С СОХРАНЕНИЕМ РАБОТЫ SELFSNI И REMNANODE)
# ==============================================================================
uninstall_tproxy() {
    echo -e "\n${RED}${BOLD}ВНИМАНИЕ: Будут удалены службы tproxy-server и mtproxy.${NC}"
    echo -e "${GREEN}Шлюз Nginx SelfSNI и нода Remnanode (443 порт) продолжат работать в штатном режиме!${NC}"
    local confirm=""
    read -rp "Вы уверены, что хотите полностью удалить TProxy? [y/N]: " confirm || true
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Удаление отменено."
        return 0
    fi

    log_info "Остановка и отключение служб TProxy / MTProxy..."
    systemctl stop tproxy-server.service mtproxy.service tproxy-firewall.service refresh-mtproxy-config.timer 2>/dev/null || true
    systemctl disable tproxy-server.service mtproxy.service tproxy-firewall.service refresh-mtproxy-config.timer 2>/dev/null || true

    rm -f /etc/systemd/system/tproxy-server.service \
          /etc/systemd/system/mtproxy.service \
          /etc/systemd/system/tproxy-firewall.service \
          /etc/systemd/system/refresh-mtproxy-config.service \
          /etc/systemd/system/refresh-mtproxy-config.timer
    systemctl daemon-reload

    nft delete table inet tproxy_backend 2>/dev/null || true

    log_info "Отключение маршрутов TProxy из Nginx SelfSNI..."
    rm -f "$NGINX_UPSTREAM_CONF" "$NGINX_EXT_CONF"
    if nginx -t >/dev/null 2>&1; then
        systemctl reload nginx 2>/dev/null || true
    fi

    rm -rf /etc/tproxy-server /etc/mtproxy /opt/MTProxy "$TPROXY_SRC_DIR"
    rm -f /usr/local/bin/tproxy-server /usr/local/sbin/refresh-mtproxy-config /usr/local/bin/tproxy

    log_ok "TProxy полностью удален! Nginx SelfSNI и Remnanode продолжают работать."
    exit 0
}

# ==============================================================================
# ГЛАВНОЕ ИНТЕРАКТИВНОЕ МЕНЮ (КОМАНДА: tproxy)
# ==============================================================================
show_menu() {
    check_root
    while true; do
        clear
        load_configs

        local tp_status="STOPPED" tp_color="${RED}"
        if systemctl is-active --quiet tproxy-server 2>/dev/null; then
            tp_status="RUNNING"
            tp_color="${GREEN}"
        fi

        local mt_status="STOPPED" mt_color="${RED}"
        if systemctl is-active --quiet mtproxy 2>/dev/null; then
            mt_status="RUNNING"
            mt_color="${GREEN}"
        fi

        local ng_status="STOPPED" ng_color="${RED}"
        if systemctl is-active --quiet nginx 2>/dev/null; then
            ng_status="CONNECTED"
            ng_color="${GREEN}"
        fi

        local dc_timer_status="OFF" dc_timer_color="${YELLOW}"
        if systemctl is-active --quiet refresh-mtproxy-config.timer 2>/dev/null; then
            dc_timer_status="AUTO (24h)"
            dc_timer_color="${GREEN}"
        fi

        # Считываем живые метрики с 127.0.0.1:8081/metrics
        local live_sessions="0" live_streams="0" bytes_up="0" bytes_down="0"
        local metrics_raw
        metrics_raw=$(curl -s --max-time 1 "http://127.0.0.1:${TPROXY_ADMIN_PORT}/metrics" 2>/dev/null || true)
        if [ -n "$metrics_raw" ]; then
            live_sessions=$(echo "$metrics_raw" | awk '/^tproxy_sessions_live / {print $2}' || echo 0)
            live_streams=$(echo "$metrics_raw" | awk '/^tproxy_streams_live / {print $2}' || echo 0)
            bytes_up=$(echo "$metrics_raw" | awk '/^tproxy_bytes_up_total / {printf "%.1f MB", $2/1048576}' || echo "0 MB")
            bytes_down=$(echo "$metrics_raw" | awk '/^tproxy_bytes_down_total / {printf "%.1f MB", $2/1048576}' || echo "0 MB")
        fi

        local route_display="/ (Корневой режим Mode A)"
        if [ -n "$BASE_PATH" ]; then
            route_display="/${BASE_PATH}/ (Скрытый префикс Mode B)"
        fi

        local bridge_mode_label="443 Reality ➔ :${FALLBACK_PORT} Nginx ➔ :${TPROXY_PORT} TProxy"
        if [ -f "/etc/nginx/sites-available/${DOMAIN}" ] && grep -q "# SELFSNI_DIRECT_443" "/etc/nginx/sites-available/${DOMAIN}" 2>/dev/null; then
            bridge_mode_label="Прямой :443 (Без ноды) + :${FALLBACK_PORT} ➔ :${TPROXY_PORT} TProxy"
        fi

        echo -e "${CYAN}╭────────────────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${BOLD}   ◈ TPROXY CONTROL CORE  ${NC}${DIM}•  Telegram WEB Proxy + SelfSNI Co-Hosting       ${CYAN}│${NC}"
        echo -e "${CYAN}├────────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Релей TProxy:${NC}   ${tp_color}${tp_status} ●${NC} ${DIM}[127.0.0.1:${TPROXY_PORT}]${NC}  |  ${BOLD}MTProxy:${NC} ${mt_color}${mt_status} ●${NC} ${DIM}[127.0.0.1:${MTPROXY_PORT}]${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Мост SelfSNI:${NC}   ${ng_color}${ng_status} ●${NC} ${DIM}[${bridge_mode_label}]${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Домен и путь:${NC}   ${WHITE}${DOMAIN:-Не настроен}${NC}  ${CYAN}${route_display}${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Carrier Mode:${NC}   ${GREEN}${CARRIER_MODE:-websocket}${NC} ${DIM}[Воркеров MTProxy: ${MTPROXY_WORKERS:-1} • Лимит: ${MTPROXY_MAX_CONN:-4096}]${NC}  |  ${BOLD}DC Sync:${NC} ${dc_timer_color}${dc_timer_status}${NC}"
        echo -e "${CYAN}│${NC}  ${BOLD}• Живой трафик:${NC}   ${WHITE}Сессий: ${GREEN}${live_sessions:-0}${WHITE} | Потоков: ${CYAN}${live_streams:-0}${WHITE} | ↑ ${bytes_up:-0 MB} ↓ ${bytes_down:-0 MB}${NC}"
        echo -e "${CYAN}╰────────────────────────────────────────────────────────────────────────────╯${NC}"
        echo ""
        echo -e " ${BOLD}${CYAN}[ 1 ] ПОДКЛЮЧЕНИЕ И ПРОФИЛИ${NC}"
        echo -e "   ${BOLD}1${NC} ❯ 📲 Показать ссылки подключения (t.me/webproxy) и секреты профилей"
        echo -e "   ${BOLD}2${NC} ❯ ⚡ Сменить транспортный режим Carrier Mode (websocket / lanes / https)"
        echo -e "   ${BOLD}3${NC} ❯ 👥 Управление профилями, секретами и Ad-Tag (@MTProxyBot)"
        echo -e "   ${BOLD}4${NC} ❯ 🔗 Сменить Base Path (префикс пути) или переключить Mode B / Mode A"
        echo ""
        echo -e " ${BOLD}${YELLOW}[ 2 ] ДИАГНОСТИКА И МОНИТОРИНГ${NC}"
        echo -e "   ${BOLD}5${NC} ❯ 🧪 Запустить полный Self-Test связки (SelfSNI + TProxy + MTProxy + NAT)"
        echo -e "   ${BOLD}6${NC} ❯ 📊 Подробная статистика релея (/metrics) и ядра MTProxy (/stats)"
        echo -e "   ${BOLD}7${NC} ❯ 📜 Просмотр логов служб (tproxy-server & mtproxy)"
        echo ""
        echo -e " ${BOLD}${GREEN}[ 3 ] ОБСЛУЖИВАНИЕ И ТЮНИНГ${NC}"
        echo -e "   ${BOLD}8${NC} ❯ 🔄 Принудительно обновить конфиги DC Telegram (автообновление: раз в сутки)"
        echo -e "   ${BOLD}9${NC} ❯ 🛠️  Обновить из GitHub (telegramdesktop/tproxy-server) и пересобрать"
        echo -e "  ${BOLD}10${NC} ❯ ⚙️  Тюнинг ресурсов (Воркеры MTProxy, Мобильный профиль, NAT --nat-info)"
        echo -e "  ${BOLD}11${NC} ❯ 🔌 Режим порта 443 (Без ноды ⇄ С нодой Remnanode) и синхронизация Nginx"
        echo ""
        echo -e " ${BOLD}${RED}[ 4 ] СИСТЕМА${NC}"
        echo -e "  ${BOLD}12${NC} ❯ 🔁 Полная переустановка TProxy с нуля"
        echo -e "  ${BOLD}13${NC} ❯ 🗑️  Полное удаление TProxy (сохраняя SelfSNI и Remnanode)"
        echo -e "   ${BOLD}0${NC} ❯ 🚪 Выход"
        echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
        local choice=""
        read -rp "❯ Выберите действие [0-13]: " choice || true
        choice=$(echo "$choice" | tr -cd '0-9')

        case "$choice" in
            1)
                print_connection_info
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            2)
                echo -e "\n${BOLD}${CYAN}ВЫБОР ТРАНСПОРТНОГО РЕЖИМА (CARRIER MODE):${NC}"
                echo -e "1) ${GREEN}websocket${NC}       — Единый мультиплексированный WebSocket (Рекомендуется)"
                echo -e "2) ${CYAN}websocket-lanes${NC} — Независимый WebSocket на каждый поток Telegram"
                echo -e "3) ${BLUE}https-lanes${NC}     — Независимые HTTP/2 POST + Long-Poll потоки"
                echo -e "4) ${YELLOW}https${NC}           — Консервативный HTTPS (1 POST + 1 Long-Poll)"
                local new_cm=""
                read -rp "Ваш выбор [1-4, по умолчанию: 1]: " new_cm || true
                case "${new_cm:-1}" in
                    2) CARRIER_MODE="websocket-lanes" ;;
                    3) CARRIER_MODE="https-lanes" ;;
                    4) CARRIER_MODE="https" ;;
                    *) CARRIER_MODE="websocket" ;;
                esac
                save_tproxy_env
                write_tproxy_configs
                start_and_verify_services
                log_ok "Режим транспорта переключен на: ${CARRIER_MODE} (клиенты переподключатся автоматически)!"
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            3)
                profiles_management_menu
                ;;
            4)
                echo -e "\n${BOLD}${CYAN}НАСТРОЙКА ПРЕФИКСА ПУТИ (BASE PATH):${NC}"
                echo -e "1) Сгенерировать новый случайный 16-символьный префикс (Mode B)"
                echo -e "2) Задать свой кастомный префикс (например, edge-sync-v2)"
                echo -e "3) Переключить в корневой режим без префикса (Mode A, base_path = \"\")"
                local bp_act=""
                read -rp "Ваш выбор [1-3, по умолчанию: 1]: " bp_act || true
                if [ "${bp_act:-1}" = "3" ]; then
                    BASE_PATH=""
                elif [ "${bp_act:-1}" = "2" ]; then
                    local c_bp=""
                    read -rp "Введите префикс (без слешей по краям): " c_bp || true
                    c_bp="${c_bp#/}"
                    c_bp="${c_bp%/}"
                    if [ -n "$c_bp" ] && [[ "$c_bp" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*(/[A-Za-z0-9][A-Za-z0-9_-]*)*$ ]]; then
                        BASE_PATH="$c_bp"
                    else
                        log_warn "Некорректный префикс! Оставлен прежний."
                    fi
                else
                    BASE_PATH="$(generate_random_slug)"
                fi
                save_tproxy_env
                write_tproxy_configs
                configure_nginx_integration
                start_and_verify_services
                print_connection_info
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            5)
                run_full_diagnostics
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            6)
                echo -e "\n${CYAN}=== МЕТРИКИ TPROXY-SERVER (http://127.0.0.1:${TPROXY_ADMIN_PORT}/metrics) ===${NC}"
                curl -s --max-time 3 "http://127.0.0.1:${TPROXY_ADMIN_PORT}/metrics" || echo "Нет ответа"
                echo -e "\n${CYAN}=== СТАТИСТИКА ЯДРА MTPROXY (http://127.0.0.1:${MTPROXY_STATS_PORT}/stats) ===${NC}"
                curl -s --max-time 3 "http://127.0.0.1:${MTPROXY_STATS_PORT}/stats" || echo "Нет ответа"
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            7)
                echo -e "\n${CYAN}=== ПОСЛЕДНИЕ 40 СТРОК ЖУРНАЛА TPROXY-SERVER & MTPROXY ===${NC}"
                journalctl -u tproxy-server -u mtproxy -n 40 --no-pager || true
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            8)
                log_info "Обновление конфигурации датацентров Telegram (proxy-multi.conf)..."
                if [ -x /usr/local/sbin/refresh-mtproxy-config ]; then
                    /usr/local/sbin/refresh-mtproxy-config || true
                fi
                systemctl restart mtproxy tproxy-server
                log_ok "Службы mtproxy и tproxy-server успешно перезапущены!"
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            9)
                build_and_install_tproxy_relay 1
                start_and_verify_services
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            10)
                echo -e "\n${BOLD}${CYAN}ТЮНИНГ РЕСУРСОВ И МОБИЛЬНОГО ПРОФИЛЯ:${NC}"
                local m_opt=""
                read -rp "Включить мобильный профиль (reconnect_grace=5m + фреймы 512 КБ)? [Y/n, сейчас: ${MOBILE_OPTIMIZED}]: " m_opt || true
                if [[ "${m_opt:-y}" =~ ^[Yy]$ ]]; then
                    MOBILE_OPTIMIZED="1"
                else
                    MOBILE_OPTIMIZED="0"
                fi
                local w_opt=""
                read -rp "Количество воркеров MTProxy [сейчас: ${MTPROXY_WORKERS}]: " w_opt || true
                w_opt="${w_opt:-$MTPROXY_WORKERS}"
                if [[ "$w_opt" =~ ^[1-9][0-9]*$ ]] && [ "$w_opt" -le 64 ]; then
                    MTPROXY_WORKERS="$w_opt"
                fi
                save_tproxy_env
                write_tproxy_configs
                start_and_verify_services
                log_ok "Параметры производительности обновлены!"
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            11)
                echo -e "\n${BOLD}${CYAN}ВЫБОР РЕЖИМА РАБОТЫ ПОРТА 443 И СИНХРОНИЗАЦИИ С NGINX SELFSNI:${NC}"
                echo -e "1) ${GREEN}В связке с нодой Remnanode / Xray${NC} — Nginx слушает только 127.0.0.1:${FALLBACK_PORT} (443 порт свободен для ноды)"
                echo -e "2) ${CYAN}Автономный режим БЕЗ ноды${NC}         — Nginx сам принимает внешний 443 порт + 127.0.0.1:${FALLBACK_PORT}"
                local mode443_sel=""
                read -rp "Выберите режим [1-2, по умолчанию: 1]: " mode443_sel || true
                mode443_sel=$(echo "${mode443_sel:-1}" | tr -cd '0-9')
                if [ "$mode443_sel" = "2" ]; then
                    DIRECT_443_MODE="1"
                else
                    DIRECT_443_MODE="0"
                fi
                save_tproxy_env
                configure_nginx_integration
                start_and_verify_services
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            12)
                install_tproxy
                echo -e "\nНажмите Enter для возврата в меню..."
                read -r || true
                ;;
            13)
                uninstall_tproxy
                ;;
            0)
                exit 0
                ;;
        esac
    done
}

# ==============================================================================
# ТОЧКА ВХОДА
# ==============================================================================
check_root
if [ -f "${BASH_SOURCE[0]:-}" ]; then
    _self_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    if [ "$_self_file" != "/usr/local/bin/tproxy" ] && [ -d /usr/local/bin ]; then
        cp -f "$_self_file" /usr/local/bin/tproxy 2>/dev/null || true
        chmod +x /usr/local/bin/tproxy 2>/dev/null || true
    fi
fi
if [ -f "$TPROXY_CONF" ] && [ -x "/usr/local/bin/tproxy-server" ]; then
    show_menu
else
    install_tproxy
fi
