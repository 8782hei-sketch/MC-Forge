#!/usr/bin/env bash
###############################################################################
#  Minecraft Forge Server - Auto Installer (Linux & Termux)
#  Support: Minecraft 1.1 s/d versi terbaru (mengikuti data resmi Forge)
#  Author : https://github.com/8782hei-sketch
###############################################################################
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
cat <<'EOF'

  ███╗   ███╗ ██████╗    ███████╗ ██████╗ ██████╗ ██████╗ ███████╗
  ████╗ ████║██╔════╝    ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
  ██╔████╔██║██║         █████╗  ██║  ██║██████╔╝██║  ██║█████╗
  ██║╚██╔╝██║██║         ██╔══╝  ██║  ██║██╔══██╗██║  ██║██╔══╝
  ██║ ╚═╝ ██║╚██████╗    ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
  ╚═╝     ╚═╝ ╚═════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
              Server Installer  -  Linux & Termux Edition
EOF
}

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[PERHATIAN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

detect_env() {
  if [ -d /data/data/com.termux ]; then
    ENVIRONMENT="termux"
    PKG_UPDATE="pkg update -y"
    PKG_INSTALL="pkg install -y"
  elif command -v apt >/dev/null 2>&1; then
    ENVIRONMENT="linux-apt"
    PKG_UPDATE="sudo apt-get update -y"
    PKG_INSTALL="sudo apt-get install -y"
  elif command -v dnf >/dev/null 2>&1; then
    ENVIRONMENT="linux-dnf"
    PKG_UPDATE="sudo dnf makecache"
    PKG_INSTALL="sudo dnf install -y"
  elif command -v pacman >/dev/null 2>&1; then
    ENVIRONMENT="linux-pacman"
    PKG_UPDATE="sudo pacman -Sy"
    PKG_INSTALL="sudo pacman -S --noconfirm"
  else
    ENVIRONMENT="linux-unknown"
    PKG_UPDATE=""
    PKG_INSTALL=""
  fi
  info "Lingkungan terdeteksi: ${BOLD}${ENVIRONMENT}${NC}"
}

need_cmd() { command -v "$1" >/dev/null 2>&1; }

ensure_dep() {
  local cmd="$1" pkg="$2"
  if ! need_cmd "$cmd"; then
    warn "'$cmd' belum terpasang, mencoba install paket '$pkg'..."
    if [ -n "$PKG_INSTALL" ]; then
      $PKG_UPDATE >/dev/null 2>&1 || true
      $PKG_INSTALL "$pkg"
    else
      err "Tidak bisa auto-install. Install manual: $pkg"
      exit 1
    fi
  fi
}

install_dependencies() {
  ensure_dep curl curl
  ensure_dep unzip unzip
  ensure_dep jq jq
  ensure_dep tar tar
  ok "Semua dependensi tersedia."
}

version_lt() {
  [ "$1" = "$2" ] && return 1
  [ "$1" = "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" ]
}

determine_java_version() {
  local mc="$1"
  if version_lt "$mc" "1.17"; then
    echo 8
  elif version_lt "$mc" "1.18"; then
    echo 16
  elif version_lt "$mc" "1.20.5"; then
    echo 17
  else
    echo 21
  fi
}

FORGE_META_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/maven-metadata.xml"
FORGE_PROMO_URL="https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json"
TMP_DIR="$(mktemp -d)"

fetch_forge_data() {
  info "Mengambil daftar versi Forge dari server resmi..."
  if ! curl -fsSL "$FORGE_META_URL" -o "$TMP_DIR/meta.xml"; then
    err "Gagal mengambil data dari $FORGE_META_URL. Cek koneksi internet."
    exit 1
  fi
  curl -fsSL "$FORGE_PROMO_URL" -o "$TMP_DIR/promo.json" || true
  ok "Data versi Forge berhasil diambil."
}

all_forge_versions() {
  grep -o '<version>[^<]*</version>' "$TMP_DIR/meta.xml" \
    | sed -e 's/<version>//' -e 's/<\/version>//'
}

list_mc_versions() {
  all_forge_versions | sed -E 's/-.*//' | sort -Vu
}

builds_for_mc() {
  local mc="$1"
  all_forge_versions | grep -E "^${mc//./\\.}-" || true
}

promo_for_mc() {
  local mc="$1"
  [ -s "$TMP_DIR/promo.json" ] || return 0
  jq -r --arg mc "$mc" \
    '.promos | to_entries[] | select(.key==($mc+"-recommended") or .key==($mc+"-latest")) | "\(.key)=\(.value)"' \
    "$TMP_DIR/promo.json" 2>/dev/null
}

choose_versions() {
  local mc build_choice full_version

  while true; do
    echo
    echo -e "${BOLD}Masukkan versi Minecraft yang diinginkan (contoh: 1.20.1)${NC}"
    echo -e "  Ketik ${YELLOW}list${NC} untuk melihat semua versi yang didukung Forge"
    echo -e "  Support resmi: dari Minecraft 1.1 sampai versi terbaru"
    read -rp "> Versi Minecraft: " mc

    if [ "$mc" = "list" ]; then
      list_mc_versions | column
      continue
    fi

    local candidates
    candidates="$(builds_for_mc "$mc")"
    if [ -z "$candidates" ]; then
      err "Versi Minecraft '$mc' tidak ditemukan di data Forge. Coba lagi (ketik 'list' untuk lihat pilihan)."
      continue
    fi
    break
  done

  MC_VERSION="$mc"

  echo
  echo -e "${BOLD}Build Forge yang tersedia untuk Minecraft $MC_VERSION:${NC}"
  local promo
  promo="$(promo_for_mc "$MC_VERSION")"
  if [ -n "$promo" ]; then
    echo -e "${GREEN}$promo${NC}"
  fi
  echo "$candidates" | sed 's/^/  - /' | tail -n 15
  local total
  total="$(echo "$candidates" | wc -l)"
  if [ "$total" -gt 15 ]; then
    info "(menampilkan 15 build terbaru dari total $total build yang tersedia)"
  fi

  echo
  echo -e "Ketik ${YELLOW}recommended${NC} untuk otomatis pilih build paling stabil,"
  echo -e "atau ${YELLOW}latest${NC} untuk build paling baru, atau ketik nomor build manual."
  read -rp "> Pilihan build Forge [recommended]: " build_choice
  build_choice="${build_choice:-recommended}"

  case "$build_choice" in
    recommended|latest)
      full_version="$(echo "$promo" | grep "$build_choice" | sed "s/^.*=//")"
      if [ -z "$full_version" ]; then
        warn "Tidak ada rekomendasi resmi untuk versi ini, memakai build terbaru yang tersedia."
        full_version="$(echo "$candidates" | tail -n1 | sed "s/^${MC_VERSION}-//")"
      fi
      ;;
    *)
      full_version="$build_choice"
      ;;
  esac

  FORGE_BUILD="$full_version"
  FORGE_FULL="${MC_VERSION}-${FORGE_BUILD}"

  if ! echo "$candidates" | grep -qx "$FORGE_FULL"; then
    err "Build '$FORGE_BUILD' tidak valid untuk Minecraft $MC_VERSION."
    exit 1
  fi

  ok "Dipilih: Minecraft ${BOLD}$MC_VERSION${NC} + Forge build ${BOLD}$FORGE_BUILD${NC}"
}

# ---------------------------------------------------------------------------
# SIAPKAN FOLDER SERVER
# ---------------------------------------------------------------------------
setup_server_dir() {
  read -rp "> Nama folder server [mc-server]: " dir_name
  dir_name="${dir_name:-mc-server}"
  SERVER_DIR="$(pwd)/$dir_name"
  mkdir -p "$SERVER_DIR"
  cd "$SERVER_DIR"
  ok "Folder server: $SERVER_DIR"
}

setup_java() {
  local java_major
  java_major="$(determine_java_version "$MC_VERSION")"
  info "Minecraft $MC_VERSION butuh OpenJDK versi ${BOLD}$java_major${NC}"

  if [ "$ENVIRONMENT" = "termux" ]; then
    warn "Di Termux, JDK diambil dari paket resmi Termux (bisa berbeda versi persis)."
    if [ "$java_major" -le 8 ]; then
      warn "Minecraft versi lama (<=1.16.5) butuh Java 8, dan paket ini sering TIDAK tersedia"
      warn "di Termux terbaru. Server mungkin gagal jalan. Rekomendasi: gunakan VPS Linux"
      warn "untuk versi Minecraft lawas, atau lanjutkan untuk coba peruntungan."
      read -rp "Lanjutkan tetap install dengan JDK yang ada di Termux? (y/n): " cont
      [ "$cont" = "y" ] || exit 1
      java_major=17
    fi
    ensure_dep java "openjdk-${java_major}"
    JAVA_BIN="java"
    USE_LOCAL_JDK=0
  else
    info "Mengunduh OpenJDK $java_major portable (Adoptium) khusus untuk server ini..."
    local arch at_arch
    arch="$(uname -m)"
    case "$arch" in
      x86_64) at_arch="x64" ;;
      aarch64|arm64) at_arch="aarch64" ;;
      armv7l|armv6l) at_arch="arm" ;;
      *) at_arch="x64" ;;
    esac

    local jdk_url="https://api.adoptium.net/v3/binary/latest/${java_major}/ga/linux/${at_arch}/jdk/hotspot/normal/eclipse"
    if curl -fsSL "$jdk_url" -o jdk.tar.gz; then
      rm -rf jdk && mkdir -p jdk
      tar -xzf jdk.tar.gz -C jdk --strip-components=1
      rm -f jdk.tar.gz
      JAVA_BIN="$SERVER_DIR/jdk/bin/java"
      USE_LOCAL_JDK=1
      ok "OpenJDK $java_major terpasang secara lokal di folder server (tidak mengubah sistem)."
    else
      warn "Gagal mengunduh JDK portable, mencoba pakai Java sistem sebagai gantinya."
      ensure_dep java "openjdk-${java_major}-jdk"
      JAVA_BIN="java"
      USE_LOCAL_JDK=0
    fi
  fi
}

run_forge_installer() {
  local url="https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_FULL}/forge-${FORGE_FULL}-installer.jar"
  info "Mengunduh Forge installer: $FORGE_FULL"
  if ! curl -fsSL "$url" -o forge-installer.jar; then
    err "Gagal mengunduh installer Forge. Kemungkinan versi ini tidak memakai format installer"
    err "(umumnya berlaku untuk Minecraft di bawah 1.5.2). Silakan instal manual untuk versi ini."
    exit 1
  fi

  info "Menjalankan Forge installer (--installServer)..."
  export PATH="$SERVER_DIR/jdk/bin:$PATH" 2>/dev/null || true
  "$JAVA_BIN" -jar forge-installer.jar --installServer
  ok "Instalasi Forge server selesai."
}

setup_eula() {
  echo
  echo -e "${BOLD}Mojang mewajibkan persetujuan EULA untuk menjalankan server.${NC}"
  echo "Baca di: https://www.minecraft.net/eula"
  read -rp "Apakah kamu SETUJU dengan Minecraft EULA? (y/n): " agree
  if [ "$agree" != "y" ]; then
    err "EULA tidak disetujui. Server tidak bisa dijalankan tanpa ini."
    exit 1
  fi
  echo "eula=true" > eula.txt
  ok "eula.txt dibuat."
}

setup_server_properties() {
  echo
  read -rp "Atur pengaturan server sekarang (port, RAM, dll)? (y/n) [n]: " customize
  customize="${customize:-n}"

  RAM_MIN="1024"
  RAM_MAX="2048"
  local port="25565" difficulty="easy" gamemode="survival" motd="A Minecraft Server" maxplayers="20" whitelist="false"

  if [ "$customize" = "y" ]; then
    read -rp "Server port [25565]: " p; port="${p:-$port}"
    read -rp "Difficulty (peaceful/easy/normal/hard) [easy]: " d; difficulty="${d:-$difficulty}"
    read -rp "Gamemode (survival/creative/adventure) [survival]: " g; gamemode="${g:-$gamemode}"
    read -rp "MOTD [A Minecraft Server]: " m; motd="${m:-$motd}"
    read -rp "Max players [20]: " mp; maxplayers="${mp:-$maxplayers}"
    read -rp "Whitelist aktif? (true/false) [false]: " w; whitelist="${w:-$whitelist}"
    read -rp "RAM minimum (MB) [1024]: " rmin; RAM_MIN="${rmin:-$RAM_MIN}"
    read -rp "RAM maksimum (MB) [2048]: " rmax; RAM_MAX="${rmax:-$RAM_MAX}"
  fi

  if [ -f server.properties ]; then
    sed -i "s/^server-port=.*/server-port=${port}/" server.properties 2>/dev/null || true
  fi

  cat >> server.properties <<EOF 2>/dev/null || true
server-port=${port}
difficulty=${difficulty}
gamemode=${gamemode}
motd=${motd}
max-players=${maxplayers}
white-list=${whitelist}
EOF
  ok "server.properties disiapkan (port=$port, difficulty=$difficulty, gamemode=$gamemode)."
}

create_start_script() {
  local server_jar
  server_jar="$(ls forge-*-universal.jar forge-*.jar 2>/dev/null | grep -v installer | head -n1)"

  cat > start-server.sh <<EOF
#!/usr/bin/env bash
cd "\$(dirname "\$0")"
EOF

  if [ "${USE_LOCAL_JDK:-0}" = "1" ]; then
    cat >> start-server.sh <<'EOF'
export JAVA_HOME="$(pwd)/jdk"
export PATH="$JAVA_HOME/bin:$PATH"
EOF
  fi

  if [ -f run.sh ]; then
    cat >> start-server.sh <<'EOF'
chmod +x run.sh
./run.sh nogui
EOF
  else
    cat >> start-server.sh <<EOF
java -Xms${RAM_MIN}M -Xmx${RAM_MAX}M -jar "${server_jar}" nogui
EOF
  fi

  chmod +x start-server.sh
  ok "Script start dibuat: ${BOLD}start-server.sh${NC}"
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
  clear 2>/dev/null || true
  banner
  detect_env
  install_dependencies
  fetch_forge_data
  choose_versions
  setup_server_dir
  setup_java
  run_forge_installer
  setup_eula
  setup_server_properties
  create_start_script

  echo
  echo -e "${GREEN}${BOLD}=========================================${NC}"
  echo -e "${GREEN}${BOLD} Server Minecraft Forge $MC_VERSION siap! ${NC}"
  echo -e "${GREEN}${BOLD}=========================================${NC}"
  echo -e "Lokasi   : $SERVER_DIR"
  echo -e "Jalankan : ${YELLOW}cd \"$SERVER_DIR\" && ./start-server.sh${NC}"
  echo
  info "Untuk menghentikan server, ketik 'stop' di console server."
  if [ "$ENVIRONMENT" = "termux" ]; then
    info "Tips Termux: jalankan 'termux-wake-lock' sebelum start biar HP gak sleep."
  fi
}

trap 'rm -rf "$TMP_DIR"' EXIT
main "$@"
