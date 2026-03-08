#!/bin/bash

# =================================================================
#  SINGULARITY v21.0 SUPERNOVA - THE ULTIMATE STABLE CORE
# =================================================================

# Renkler
R='\033[38;5;196m'; G='\033[38;5;82m'; Y='\033[38;5;226m'; B='\033[38;5;33m'
C='\033[38;5;51m'; W='\033[38;5;15m'; P='\033[38;5;165m'; NC='\033[0m'; BOLD='\033[1m'

# Global Değişkenler
SDK_PATH="$HOME/.android_singularity_sdk"
CPU_CORES=$(nproc 2>/dev/null || echo 4)
ARCH=$(uname -m)

# Yardımcı Fonksiyonlar
log() { echo -e "\n${C}[$(date +%T)]${NC} ${G}»${NC} ${W}$1${NC}"; }
status() { echo -e "${B}${BOLD}>>> ŞU AN KURULUYOR:${NC} ${P}$1${NC}"; }
error() { echo -e "${R}[X] HATA: $1${NC}"; exit 1; }

# --- [ GİRİŞ EKRANI ] ---
clear
echo -e "${P}${BOLD}
   ███████╗██╗   ██╗██████╗ ███████╗██████╗ ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔═══██╗██║   ██║██╔══██╗
   ███████╗██║   ██║██████╔╝█████╗  ██████╔╝██╔██╗ ██║██║   ██║██║   ██║███████║
   ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║
   ███████║╚██████╔╝██║     ███████╗██║  ██║██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║
   ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝ v21.0${NC}"

# --- [ INTERAKTIF SORULAR - STDIN FIX ] ---
# /dev/tty kullanarak curl | bash hatasını engelliyoruz.
echo -e "\n${B}--- [ YAPILANDIRMA SEÇENEKLERİ ] ---${NC}"

echo -e "${W}Hangi derleme sistemini kurmak istersiniz?${NC}"
echo -e "1) ${G}Gradle${NC} (Standart)"
echo -e "2) ${G}Bazel${NC} (Hız)"
echo -e "3) ${G}Buck2${NC} (Meta)"
echo -e "4) ${G}Hepsi${NC}"
echo -e "5) ${R}Hiçbiri${NC}"
echo -ne "${Y}[?] Seçiminiz [1-5]: ${NC}"
read -r BUILD_CHOICE < /dev/tty

echo -ne "${Y}[?] Android NDK (C/C++ desteği) kurulsun mu? [y/n]: ${NC}"
read -r NDK_CHOICE < /dev/tty

# --- [ SİSTEM HAZIRLIĞI ] ---
log "Sistem teşhis ediliyor..."
if [ -d "/data/data/com.termux/files/usr" ]; then
    IS_TERMUX=true; PKG_MGR="pkg"; INSTALL_CMD="pkg install -y"
    status "Termux Paket Listesi Güncelleniyor"
    pkg update -y
else
    IS_TERMUX=false; PKG_MGR="apt"; INSTALL_CMD="sudo apt-get install -y"
    status "Linux Paket Listesi Güncelleniyor"
    sudo apt-get update -qq
fi

# --- [ TEMEL BAĞIMLILIKLAR ] ---
DEPS=(git openjdk-17 wget curl zip unzip python clang cmake ninja zstd jq tar)
for dep in "${DEPS[@]}"; do
    status "Temel Bağımlılık: $dep"
    $INSTALL_CMD "$dep" > /dev/null 2>&1 || status "$dep zaten kurulu veya atlandı."
done

# --- [ ANDROID SDK KURULUMU ] ---
log "Android SDK Core yapılandırılıyor..."
mkdir -p "$SDK_PATH/cmdline-tools"

if [ ! -d "$SDK_PATH/cmdline-tools/latest" ]; then
    status "Android Command-Line Tools (latest)"
    SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    curl -L "$SDK_URL" -o /tmp/tools.zip
    unzip -q /tmp/tools.zip -d "$SDK_PATH/cmdline-tools"
    mv "$SDK_PATH/cmdline-tools/cmdline-tools" "$SDK_PATH/cmdline-tools/latest"
    rm /tmp/tools.zip
fi

export ANDROID_HOME="$SDK_PATH"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

status "SDK Lisansları Onaylanıyor"
yes | sdkmanager --licenses > /dev/null 2>&1

status "Platform Tools & API 35"
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0" > /dev/null 2>&1

# --- [ DERLEME SİSTEMLERİ ] ---
case $BUILD_CHOICE in
    1|4)
        status "Gradle 8.5 Engine"
        wget -q https://services.gradle.org/distributions/gradle-8.5-bin.zip -O /tmp/gradle.zip
        unzip -q /tmp/gradle.zip -d "$HOME/.gradle_root"
        export PATH="$PATH:$HOME/.gradle_root/gradle-8.5/bin"
        ;;
esac

if [[ "$BUILD_CHOICE" == "2" || "$BUILD_CHOICE" == "4" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        status "Bazel Build System"
        curl -fLO https://github.com/bazelbuild/bazel/releases/download/6.4.0/bazel-6.4.0-linux-x86_64
        chmod +x bazel-6.4.0-linux-x86_64
        [ "$IS_TERMUX" = false ] && sudo mv bazel-6.4.0-linux-x86_64 /usr/local/bin/bazel || mv bazel-6.4.0-linux-x86_64 $PREFIX/bin/bazel
    fi
fi

if [[ "$BUILD_CHOICE" == "3" || "$BUILD_CHOICE" == "4" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        status "Buck2 Build System"
        curl -L "https://github.com/facebook/buck2/releases/latest/download/buck2-x86_64-unknown-linux-musl.zst" -o /tmp/buck2.zst
        zstd -d /tmp/buck2.zst -o /tmp/buck2 && chmod +x /tmp/buck2 && mv /tmp/buck2 $HOME/.local/bin/ 2>/dev/null
    fi
fi

# --- [ NDK KURULUMU ] ---
if [[ "$NDK_CHOICE" =~ ^[Yy]$ ]]; then
    status "Android NDK r27 (Bu işlem uzun sürebilir...)"
    sdkmanager "ndk;27.0.12077973" "cmake;3.22.1" --verbose
fi

# --- [ KALICI YAPILANDIRMA ] ---
log "Sistem mühürleniyor..."
RC_FILE="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && RC_FILE="$HOME/.zshrc"

sed -i '/# --- SINGULARITY_V21/,/# --- END_V21/d' "$RC_FILE"
cat << EOF >> "$RC_FILE"

# --- SINGULARITY_V21 START (SUPERNOVA) ---
export ANDROID_HOME="$SDK_PATH"
export JAVA_HOME="$([ -d /data/data/com.termux ] && echo "/data/data/com.termux/files/usr/lib/jvm/openjdk-17" || echo "/usr/lib/jvm/java-17-openjdk-amd64")"
export PATH="\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools"
[ -d "$HOME/.gradle_root/gradle-8.5/bin" ] && export PATH="\$PATH:$HOME/.gradle_root/gradle-8.5/bin"
export NDK_HOME="\$ANDROID_HOME/ndk/\$(ls \$ANDROID_HOME/ndk 2>/dev/null | head -n 1)"
export MAKEFLAGS="-j$CPU_CORES"
# --- END_V21 ---
