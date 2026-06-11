wget -q --no-check-certificate https://live-feed.net/enigma2/installer.sh -O - | /bin/sh

#!/bin/bash
## setup command example:
## wget -q "--no-check-certificate" https://live-feed.net/enigma2/installer.sh -O - | /bin/sh

WATCH_MODE=0
for arg in "$@"; do
    case "$arg" in
        --watch|--no-restart)
            WATCH_MODE=1
            ;;
    esac
done

BASE_URL="https://live-feed.net/enigma2/"
OPKG_PLUGIN_PREFIX="enigma2-plugin-extensions-livefeed"
DEB_PLUGIN_PREFIX="enigma2-plugin-extensions-livefeed"
PLUGIN_VERSION="0.3.27"
PACKAGE_RELEASE="r1"
DEB_PACKAGE_RELEASE="r0.3"
WGET_UA="LiveFeedInstaller/${PLUGIN_VERSION}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

TMP_DIR="/tmp/lfpkg_install"
PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/LiveFeed"
LEGACY_PLUGIN_DIRS="
/usr/lib/enigma2/python/Plugins/Extensions/LiveFeed
/usr/lib/enigma2/python/Plugins/Extensions/LiveFe_ed
"
OPKG_PACKAGE_NAME="enigma2-plugin-extensions-livefeed"
DEB_PACKAGE_NAME="enigma2-plugin-extensions-livefeed"
AUTO_BISS_DB="/etc/enigma2/auto_biss_db.json"
AUTO_BISS_SYNC_CACHE="/etc/enigma2/livefeed_autobiss_cache.dat"
SERVICE_LEARN_CACHE="/etc/enigma2/livefeed_service_learn_cache.json"
SNAPSHOT_CACHE_DIR="/tmp/live_feed_plugin"

say() {
    printf "%b\n" "$1"
}

divider() {
    say "${BLUE}--------------------------------------------------${NC}"
}

headline() {
    divider
    say "${WHITE}Live Feed Installer${NC}"
    divider
}

step() {
    say "${MAGENTA}>>${NC} $1"
}

cleanup_tmp() {
    rm -rf "$TMP_DIR" >/dev/null 2>&1
}

cleanup_livefeed_state() {
    step "Cleaning previous Live Feed files"

    if command -v opkg >/dev/null 2>&1; then
        if opkg status "$OPKG_PACKAGE_NAME" >/dev/null 2>&1; then
            opkg remove "$OPKG_PACKAGE_NAME" >/dev/null 2>&1 || true
        fi
    fi

    if command -v dpkg >/dev/null 2>&1; then
        if dpkg -s "$DEB_PACKAGE_NAME" >/dev/null 2>&1; then
            dpkg -r "$DEB_PACKAGE_NAME" >/dev/null 2>&1 || true
        fi
    fi

    printf '%s\n' "$LEGACY_PLUGIN_DIRS" | while IFS= read -r dir; do
        [ -n "$dir" ] || continue
        rm -rf "$dir" >/dev/null 2>&1
    done
    rm -rf "$SNAPSHOT_CACHE_DIR" >/dev/null 2>&1
    rm -rf /tmp/livefeed_* >/dev/null 2>&1
    rm -f /tmp/livefeed.log /tmp/livefeed.log.* >/dev/null 2>&1
    rm -f "$AUTO_BISS_DB" >/dev/null 2>&1
    rm -f "$AUTO_BISS_SYNC_CACHE" >/dev/null 2>&1
    rm -f "$SERVICE_LEARN_CACHE" >/dev/null 2>&1
}

detect_package_manager() {
    if [ -f /var/lib/dpkg/status ] && command -v dpkg >/dev/null 2>&1; then
        echo "dpkg"
        return 0
    fi
    if command -v opkg >/dev/null 2>&1; then
        echo "opkg"
        return 0
    fi
    if command -v dpkg >/dev/null 2>&1; then
        echo "dpkg"
        return 0
    fi
    return 1
}

detect_architecture() {
    local arch=""
    if command -v opkg >/dev/null 2>&1; then
        arch="$(opkg print-architecture 2>/dev/null | awk '{print $2}' | grep -E '^(aarch64|cortexa15hf-neon-vfpv4)$' | head -n 1)"
    fi
    if [ -n "$arch" ]; then
        echo "$arch"
        return 0
    fi

    case "$(uname -m 2>/dev/null)" in
        aarch64|arm64)
            echo "aarch64"
            ;;
        armv7l|armv7*|arm*)
            echo "cortexa15hf-neon-vfpv4"
            ;;
        *)
            return 1
            ;;
    esac
}

detect_python_tag() {
    if command -v python3 >/dev/null 2>&1; then
        local py_minor
        py_minor="$(python3 -c 'import sys; print("%d.%d" % (sys.version_info[0], sys.version_info[1]))' 2>/dev/null)"
        case "$py_minor" in
            3.13)
                echo "py3.13"
                return 0
                ;;
            3.14)
                echo "py3.14"
                return 0
                ;;
        esac
    fi
    return 1
}

find_installed_plugin_dir() {
    local dir=""
    if [ -n "${1:-}" ]; then
        dir="$1"
        if [ -f "$dir/plugin.py" ] || [ -f "$dir/plugin.pyo" ] || [ -f "$dir/livefeed.so" ] || [ -f "$dir/livefeed.py" ] || [ -f "$dir/livefeed.pyo" ]; then
            echo "$dir"
            return 0
        fi
    fi

    printf '%s\n' "$LEGACY_PLUGIN_DIRS" | while IFS= read -r dir; do
        [ -n "$dir" ] || continue
        if [ -f "$dir/plugin.py" ] || [ -f "$dir/plugin.pyo" ] || [ -f "$dir/livefeed.so" ] || [ -f "$dir/livefeed.py" ] || [ -f "$dir/livefeed.pyo" ]; then
            echo "$dir"
            exit 0
        fi
    done
    return 1
}

version_sort_key() {
    printf '%s\n' "$1" | awk '
        BEGIN { FS="[^0-9]+"; out="" }
        {
            for (i = 1; i <= NF; i++) {
                if ($i == "") {
                    continue
                }
                value = $i + 0
                if (length($i) == 1) {
                    value = value * 10
                }
                out = out sprintf("%05d", value)
            }
        }
        END { print out }
    '
}

package_sort_key() {
    local file_name="$1"
    local package_manager="$2"
    local payload=""
    local version_text=""
    local release_text=""

    if [ "$package_manager" = "opkg" ]; then
        payload="${file_name#${OPKG_PLUGIN_PREFIX}-}"
        version_text="${payload%%-r*}"
        release_text="${payload#${version_text}-}"
        release_text="${release_text%%-*}"
    else
        payload="${file_name#${DEB_PLUGIN_PREFIX}_}"
        payload="${payload%%_*}"
        version_text="${payload%%-r*}"
        release_text="${payload#${version_text}-}"
    fi

    printf '%s%s\n' "$(version_sort_key "$version_text")" "$(version_sort_key "$release_text")"
}

fetch_package_index() {
    wget -q --user-agent="$WGET_UA" --no-check-certificate -O - "$BASE_URL" 2>/dev/null || true
}

resolve_latest_package() {
    local package_manager="$1"
    local arch="$2"
    local py_tag="${3:-}"
    local listing=""
    local pattern=""
    local fallback=""
    local latest=""

    listing="$(fetch_package_index)"

    if [ "$package_manager" = "opkg" ]; then
        pattern="${OPKG_PLUGIN_PREFIX}-[0-9][^\"' <>]*-${arch}-${py_tag}\\.ipk"
        fallback="${OPKG_PLUGIN_PREFIX}-${PLUGIN_VERSION}-${PACKAGE_RELEASE}-${arch}-${py_tag}.ipk"
    else
        pattern="${DEB_PLUGIN_PREFIX}_[0-9][^\"' <>]*_${arch}\\.deb"
        fallback="${DEB_PLUGIN_PREFIX}_${PLUGIN_VERSION}-${DEB_PACKAGE_RELEASE}_${arch}.deb"
    fi

    if [ -n "$listing" ]; then
        local candidate=""
        local latest_key=""
        local candidate_key=""
        for candidate in $(printf '%s\n' "$listing" | grep -oE "$pattern" | sort -u); do
            [ -n "$candidate" ] || continue
            candidate_key="$(package_sort_key "$candidate" "$package_manager")"
            if [ -z "$latest" ] || [ "$candidate_key" \> "$latest_key" ]; then
                latest="$candidate"
                latest_key="$candidate_key"
            fi
        done
    fi

    if [ -n "$latest" ]; then
        echo "$latest"
        return 0
    fi

    echo "$fallback"
    return 0
}

install_package() {
    local file_name="$1"
    local package_manager="$2"
    local expected_plugin_dir="$3"
    local detected_plugin_dir=""

    mkdir -p "$TMP_DIR" || return 1
    cd "$TMP_DIR" || return 1

    local url="${BASE_URL}${file_name}"
    step "Downloading package"
    say "${CYAN}$url${NC}"
    if ! wget -q --user-agent="$WGET_UA" --no-check-certificate "$url" -O "$file_name"; then
        say "${RED}Download failed:${NC} $url"
        return 1
    fi

    step "Installing package"
    say "${CYAN}$file_name${NC}"
    if [ "$package_manager" = "opkg" ]; then
        if ! opkg install --force-reinstall "./$file_name"; then
            say "${RED}Installation failed.${NC}"
            return 1
        fi
    else
        if ! dpkg -i "./$file_name"; then
            say "${RED}Installation failed.${NC}"
            return 1
        fi
    fi

    detected_plugin_dir="$(find_installed_plugin_dir "$expected_plugin_dir" || true)"
    if [ -n "$detected_plugin_dir" ]; then
        step "Detected installed plugin directory"
        say "${GREEN}$detected_plugin_dir${NC}"
        return 0
    fi

    if command -v dpkg >/dev/null 2>&1 && [ "$package_manager" = "dpkg" ]; then
        step "Installed package contents"
        dpkg -L "$DEB_PACKAGE_NAME" 2>/dev/null || true
    fi

    if command -v opkg >/dev/null 2>&1 && [ "$package_manager" = "opkg" ]; then
        step "Installed package contents"
        opkg files "$OPKG_PACKAGE_NAME" 2>/dev/null || true
    fi

    if [ ! -f "$expected_plugin_dir/plugin.py" ] && [ ! -f "$expected_plugin_dir/plugin.pyo" ] && [ ! -f "$expected_plugin_dir/livefeed.so" ] && [ ! -f "$expected_plugin_dir/livefeed.py" ] && [ ! -f "$expected_plugin_dir/livefeed.pyo" ]; then
        say "${RED}Plugin files were not found after install.${NC}"
        return 1
    fi

    return 0
}

headline

PKG_MANAGER="$(detect_package_manager || true)"
if [ "$PKG_MANAGER" = "opkg" ]; then
    ARCH="$(detect_architecture || true)"
    if [ -z "$ARCH" ]; then
        say "${RED}Unsupported architecture.${NC}"
        say "Supported: aarch64, cortexa15hf-neon-vfpv4"
        cleanup_tmp
        exit 1
    fi

    PY_TAG="$(detect_python_tag || true)"
    if [ -z "$PY_TAG" ]; then
        say "${RED}Unsupported Python version.${NC}"
        say "Supported: Python 3.13, Python 3.14"
        cleanup_tmp
        exit 1
    fi

    step "Detected environment"
    say "${GREEN}Package manager:${NC} opkg"
    say "${GREEN}Architecture:${NC} $ARCH"
    say "${GREEN}Python:${NC} $PY_TAG"

    FILE_NAME="$(resolve_latest_package "$PKG_MANAGER" "$ARCH" "$PY_TAG")"
    INSTALL_PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/LiveFe_ed"
elif [ "$PKG_MANAGER" = "dpkg" ]; then
    ARCH="$(dpkg --print-architecture 2>/dev/null || true)"
    if [ -z "$ARCH" ]; then
        say "${RED}Unsupported architecture.${NC}"
        cleanup_tmp
        exit 1
    fi

    step "Detected environment"
    say "${GREEN}Package manager:${NC} dpkg"
    say "${GREEN}Architecture:${NC} $ARCH"

    FILE_NAME="$(resolve_latest_package "$PKG_MANAGER" "$ARCH")"
    INSTALL_PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/LiveFe_ed"
else
    say "${RED}Unsupported package manager.${NC}"
    cleanup_tmp
    exit 1
fi

cleanup_livefeed_state

if install_package "$FILE_NAME" "$PKG_MANAGER" "$INSTALL_PLUGIN_DIR"; then
    cleanup_tmp
    sync
    headline
    say "${GREEN}Live Feed is ready.${NC}"
    if [ "$WATCH_MODE" = "1" ]; then
        say "${CYAN}Caller will restart Enigma2.${NC}"
        exit 0
    fi
    say "${CYAN}Enigma2 will restart now.${NC}"
    sleep 3
    if pidof enigma2 >/dev/null 2>&1; then
        killall -9 enigma2 >/dev/null 2>&1 || true
    fi
    exit 0
fi

cleanup_tmp
exit 1