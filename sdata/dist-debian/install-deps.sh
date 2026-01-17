# Install dependencies for iNiR on Debian/Ubuntu-based systems
# This script is meant to be sourced, not run directly.

# shellcheck shell=bash

#####################################################################################
# Verify we're on Debian/Ubuntu
#####################################################################################
if ! command -v apt >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: apt not found. This script is for Debian/Ubuntu-based systems only.${STY_RST}\n"
  exit 1
fi

# Detect Ubuntu vs Debian for version-specific handling
IS_UBUNTU=false
IS_DEBIAN=false
UBUNTU_VERSION=""
DEBIAN_VERSION=""

if grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
  IS_UBUNTU=true
  UBUNTU_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  echo -e "${STY_CYAN}[$0]: Detected Ubuntu ${UBUNTU_VERSION}${STY_RST}"
elif [[ -f /etc/debian_version ]]; then
  IS_DEBIAN=true
  DEBIAN_VERSION=$(cat /etc/debian_version)
  echo -e "${STY_CYAN}[$0]: Detected Debian ${DEBIAN_VERSION}${STY_RST}"
fi

# Detect architecture
ARCH=$(dpkg --print-architecture)
echo -e "${STY_CYAN}[$0]: Architecture: ${ARCH}${STY_RST}"

#####################################################################################
# Version warnings
#####################################################################################
if $IS_UBUNTU; then
  case "$UBUNTU_VERSION" in
    22.04|22.10)
      echo -e "${STY_YELLOW}[$0]: Ubuntu ${UBUNTU_VERSION} has older Qt6 packages.${STY_RST}"
      echo -e "${STY_YELLOW}[$0]: Some features may not work. Ubuntu 24.04+ recommended.${STY_RST}"
      ;;
  esac
fi

if $IS_DEBIAN; then
  case "$DEBIAN_VERSION" in
    11*|10*|9*)
      echo -e "${STY_RED}[$0]: Debian ${DEBIAN_VERSION} does not have Qt6 packages.${STY_RST}"
      echo -e "${STY_RED}[$0]: Debian 12 (bookworm) or newer is required.${STY_RST}"
      exit 1
      ;;
  esac
fi

#####################################################################################
# System update
#####################################################################################
case ${SKIP_SYSUPDATE:-false} in
  true) 
    echo -e "${STY_CYAN}[$0]: Skipping system update${STY_RST}"
    ;;
  *) 
    echo -e "${STY_CYAN}[$0]: Updating system...${STY_RST}"
    v sudo apt update
    v sudo apt upgrade -y
    ;;
esac

#####################################################################################
# Install official repository packages
#####################################################################################
echo -e "${STY_CYAN}[$0]: Installing packages from official repositories...${STY_RST}"

# Core system packages
DEBIAN_CORE_PKGS=(
  # Basic utilities
  bc
  coreutils
  curl
  wget
  ripgrep
  jq
  xdg-user-dirs
  rsync
  git
  wl-clipboard
  libnotify-bin
  wlsunset
  dunst
  unzip
  
  # XDG Portals
  xdg-desktop-portal
  xdg-desktop-portal-gtk
  xdg-desktop-portal-gnome
  
  # Polkit
  policykit-1
  policykit-1-gnome
  
  # Network
  network-manager
  gnome-keyring
  
  # File manager
  dolphin
  kio-extras
  
  # Terminal
  foot
  
  # Shell (required for scripts)
  fish
  
  # Thumbnails
  ffmpegthumbnailer
  tumbler
  
  # Translation widget
  translate-shell
  
  # Build essentials (needed for compiling niri/quickshell)
  build-essential
  cmake
  ninja-build
  pkg-config
)

# Qt6 packages
DEBIAN_QT6_PKGS=(
  # Core Qt6
  qt6-base-dev
  qt6-declarative-dev
  libqt6svg6-dev
  qt6-wayland-dev
  qt6-5compat-dev
  qt6-multimedia-dev
  qt6-image-formats-plugins
  libqt6positioning6
  libqt6sensors6
  
  # Runtime libraries
  libqt6core6
  libqt6gui6
  libqt6qml6
  libqt6quick6
  libqt6waylandclient6
  
  # System libs
  libjemalloc-dev
  libpipewire-0.3-dev
  libxcb1-dev
  libwayland-dev
  libdrm-dev
  
  # KDE integration
  kdialog
  
  # Qt theming
  qt6ct
  kde-config-gtk-style
  breeze-gtk-theme
)

# Audio packages
DEBIAN_AUDIO_PKGS=(
  pipewire
  pipewire-pulse
  pipewire-alsa
  wireplumber
  playerctl
  libdbusmenu-gtk3-4
  pavucontrol
  easyeffects
  mpv
  yt-dlp
)

# Toolkit packages
DEBIAN_TOOLKIT_PKGS=(
  upower
  wtype
  ydotool
  python3-evdev
  python3-pil
  brightnessctl
  ddcutil
  geoclue-2.0
  swayidle
  swaylock
  grim
  slurp
  imagemagick
  qalculate
  blueman
  tesseract-ocr
  tesseract-ocr-eng
  tesseract-ocr-spa
)

# Screen capture packages
DEBIAN_SCREENCAPTURE_PKGS=(
  grim
  slurp
  wf-recorder
  imagemagick
  ffmpeg
)

# Check if swappy is available (only in trixie/sid, not bookworm)
if apt-cache show swappy &>/dev/null 2>&1; then
  DEBIAN_SCREENCAPTURE_PKGS+=(swappy)
fi

# Font packages
DEBIAN_FONT_PKGS=(
  fontconfig
  fonts-dejavu
  fonts-liberation
  fonts-noto-color-emoji
  fonts-jetbrains-mono
  
  # Launcher
  fuzzel
  libglib2.0-0
  
  # Qt theming
  kvantum
)

# Wayland packages
DEBIAN_WAYLAND_PKGS=(
  wayland-protocols
  libwayland-client0
  libwayland-server0
  libxkbcommon-dev
)

# Check if cliphist is available in repos (Ubuntu 24.04+)
if $IS_UBUNTU && [[ "${UBUNTU_VERSION%%.*}" -ge 24 ]]; then
  DEBIAN_CORE_PKGS+=(cliphist)
fi

# Check if cava is available in repos
if apt-cache show cava &>/dev/null 2>&1; then
  DEBIAN_AUDIO_PKGS+=(cava)
fi

# Check if kf6-kconfig is available (Ubuntu 24.04+, Debian trixie+)
if apt-cache show kf6-kconfig &>/dev/null 2>&1; then
  DEBIAN_FONT_PKGS+=(kf6-kconfig)
fi

installflags=""
$ask || installflags="-y"

# Install core packages
echo -e "${STY_BLUE}[$0]: Installing core packages...${STY_RST}"
v sudo apt install $installflags "${DEBIAN_CORE_PKGS[@]}"

# Install Qt6 packages
echo -e "${STY_BLUE}[$0]: Installing Qt6 packages...${STY_RST}"
v sudo apt install $installflags "${DEBIAN_QT6_PKGS[@]}"

# Install Wayland packages
echo -e "${STY_BLUE}[$0]: Installing Wayland packages...${STY_RST}"
v sudo apt install $installflags "${DEBIAN_WAYLAND_PKGS[@]}"

# Install based on flags
if ${INSTALL_AUDIO:-true}; then
  echo -e "${STY_BLUE}[$0]: Installing audio packages...${STY_RST}"
  v sudo apt install $installflags "${DEBIAN_AUDIO_PKGS[@]}"
fi

if ${INSTALL_TOOLKIT:-true}; then
  echo -e "${STY_BLUE}[$0]: Installing toolkit packages...${STY_RST}"
  v sudo apt install $installflags "${DEBIAN_TOOLKIT_PKGS[@]}"
fi

if ${INSTALL_SCREENCAPTURE:-true}; then
  echo -e "${STY_BLUE}[$0]: Installing screen capture packages...${STY_RST}"
  v sudo apt install $installflags "${DEBIAN_SCREENCAPTURE_PKGS[@]}"
fi

if ${INSTALL_FONTS:-true}; then
  echo -e "${STY_BLUE}[$0]: Installing font packages...${STY_RST}"
  v sudo apt install $installflags "${DEBIAN_FONT_PKGS[@]}"
fi

#####################################################################################
# Helper function to download and install from GitHub
#####################################################################################
install_github_binary() {
  local name="$1"
  local repo="$2"
  local asset_pattern="$3"
  local install_path="${4:-/usr/local/bin}"
  
  if command -v "$name" &>/dev/null; then
    echo -e "${STY_GREEN}[$0]: $name already installed${STY_RST}"
    return 0
  fi
  
  echo -e "${STY_BLUE}[$0]: Installing $name from GitHub releases...${STY_RST}"
  
  local download_url
  download_url=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | \
    jq -r ".assets[] | select(.name | test(\"${asset_pattern}\")) | .browser_download_url" | head -1)
  
  if [[ -z "$download_url" || "$download_url" == "null" ]]; then
    echo -e "${STY_YELLOW}[$0]: Could not find $name binary for your architecture${STY_RST}"
    return 1
  fi
  
  local temp_dir="/tmp/${name}-install-$$"
  mkdir -p "$temp_dir"
  
  local filename=$(basename "$download_url")
  echo -e "${STY_FAINT}Downloading: $filename${STY_RST}"
  
  if curl -fsSL -o "$temp_dir/$filename" "$download_url"; then
    case "$filename" in
      *.tar.gz|*.tgz)
        tar -xzf "$temp_dir/$filename" -C "$temp_dir"
        local binary=$(find "$temp_dir" -type f -name "$name" 2>/dev/null | head -1)
        [[ -z "$binary" ]] && binary=$(find "$temp_dir" -type f -executable 2>/dev/null | grep -v "\.tar" | head -1)
        [[ -n "$binary" ]] && sudo cp "$binary" "$install_path/$name"
        ;;
      *.zip)
        unzip -o "$temp_dir/$filename" -d "$temp_dir" >/dev/null
        local binary=$(find "$temp_dir" -type f -name "$name" 2>/dev/null | head -1)
        [[ -n "$binary" ]] && sudo cp "$binary" "$install_path/$name"
        ;;
      *.deb)
        sudo dpkg -i "$temp_dir/$filename" || sudo apt install -f -y
        rm -rf "$temp_dir"
        return 0
        ;;
      *)
        # Direct binary
        sudo cp "$temp_dir/$filename" "$install_path/$name"
        ;;
    esac
    sudo chmod +x "$install_path/$name" 2>/dev/null
    echo -e "${STY_GREEN}[$0]: $name installed successfully${STY_RST}"
  else
    echo -e "${STY_YELLOW}[$0]: Failed to download $name${STY_RST}"
    rm -rf "$temp_dir"
    return 1
  fi
  
  rm -rf "$temp_dir"
}

#####################################################################################
# Install packages from GitHub releases (precompiled binaries)
#####################################################################################
echo -e "${STY_CYAN}[$0]: Installing packages from GitHub releases...${STY_RST}"

# gum - TUI tool (download .deb from GitHub)
if ! command -v gum &>/dev/null; then
  echo -e "${STY_BLUE}[$0]: Installing gum from GitHub...${STY_RST}"
  GUM_DEB_URL=$(curl -s "https://api.github.com/repos/charmbracelet/gum/releases/latest" | \
    jq -r ".assets[] | select(.name | test(\"linux_${ARCH}.deb$\")) | .browser_download_url" | head -1)
  if [[ -n "$GUM_DEB_URL" && "$GUM_DEB_URL" != "null" ]]; then
    TEMP_DEB="/tmp/gum-$$.deb"
    curl -fsSL -o "$TEMP_DEB" "$GUM_DEB_URL"
    sudo dpkg -i "$TEMP_DEB" || sudo apt install -f -y
    rm -f "$TEMP_DEB"
    echo -e "${STY_GREEN}[$0]: gum installed${STY_RST}"
  fi
fi

# cliphist - clipboard manager (if not in repos)
if ! command -v cliphist &>/dev/null; then
  install_github_binary "cliphist" "sentriz/cliphist" "linux-amd64$"
fi

# matugen - color generator
install_github_binary "matugen" "InioX/matugen" "x86_64.*tar.gz"

# darkly - Qt theme (download .deb from GitHub)
if ${INSTALL_FONTS:-true}; then
  if ! dpkg -l 2>/dev/null | grep -q darkly; then
    echo -e "${STY_BLUE}[$0]: Installing darkly theme from GitHub...${STY_RST}"
    DARKLY_DEB_URL=$(curl -s "https://api.github.com/repos/Bali10050/darkly/releases/latest" | \
      jq -r '.assets[] | select(.name | test("debian.*amd64.deb$")) | .browser_download_url' | head -1)
    
    if [[ -n "$DARKLY_DEB_URL" && "$DARKLY_DEB_URL" != "null" ]]; then
      TEMP_DEB="/tmp/darkly-$$.deb"
      curl -fsSL -o "$TEMP_DEB" "$DARKLY_DEB_URL"
      sudo dpkg -i "$TEMP_DEB" || sudo apt install -f -y
      rm -f "$TEMP_DEB"
      echo -e "${STY_GREEN}[$0]: darkly installed${STY_RST}"
    fi
  fi
fi

# swappy - screenshot annotation (not in bookworm, compile from source)
if ${INSTALL_SCREENCAPTURE:-true}; then
  if ! command -v swappy &>/dev/null; then
    echo -e "${STY_BLUE}[$0]: Installing swappy from source...${STY_RST}"
    v sudo apt install $installflags libgtk-3-dev libcairo2-dev libpango1.0-dev
    
    SWAPPY_BUILD_DIR="/tmp/swappy-build-$$"
    git clone https://github.com/jtheoof/swappy.git "$SWAPPY_BUILD_DIR"
    cd "$SWAPPY_BUILD_DIR"
    meson setup build
    ninja -C build
    sudo ninja -C build install
    cd "${REPO_ROOT}"
    rm -rf "$SWAPPY_BUILD_DIR"
    echo -e "${STY_GREEN}[$0]: swappy installed${STY_RST}"
  fi
fi

#####################################################################################
# Install Rust toolchain (needed for niri, quickshell, xwayland-satellite)
#####################################################################################
echo -e "${STY_CYAN}[$0]: Setting up Rust toolchain...${STY_RST}"

if ! command -v cargo &>/dev/null; then
  echo -e "${STY_BLUE}[$0]: Installing Rust via rustup...${STY_RST}"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

#####################################################################################
# Install uv (Python package manager) - from official installer
#####################################################################################
echo -e "${STY_CYAN}[$0]: Installing uv...${STY_RST}"
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || {
    if command -v cargo &>/dev/null; then
      cargo install uv
    fi
  }
fi

#####################################################################################
# Install Niri (PPA for Ubuntu 25.10+, compile for others)
#####################################################################################
echo -e "${STY_CYAN}[$0]: Installing Niri compositor...${STY_RST}"

if ! command -v niri &>/dev/null; then
  # Check for Ubuntu 25.10+ which has PPA available
  if $IS_UBUNTU && [[ "${UBUNTU_VERSION%%.*}" -ge 25 ]]; then
    echo -e "${STY_GREEN}[$0]: Ubuntu 25.10+ detected - using PPA (no compilation!)${STY_RST}"
    if ! grep -q "avengemedia/danklinux" /etc/apt/sources.list.d/* 2>/dev/null; then
      sudo add-apt-repository -y ppa:avengemedia/danklinux || {
        echo -e "${STY_YELLOW}[$0]: PPA failed, falling back to source compilation${STY_RST}"
      }
      sudo apt update
    fi
    if sudo apt install -y niri 2>/dev/null; then
      echo -e "${STY_GREEN}[$0]: Niri installed from PPA!${STY_RST}"
    fi
  fi
  
  # If still not installed, compile from source
  if ! command -v niri &>/dev/null; then
    echo -e "${STY_YELLOW}[$0]: Niri must be compiled from source.${STY_RST}"
  
    # Install Niri build dependencies
    echo -e "${STY_BLUE}[$0]: Installing Niri build dependencies...${STY_RST}"
    v sudo apt install $installflags \
      libgbm-dev \
      libseat-dev \
      libinput-dev \
      libudev-dev \
      libxkbcommon-dev \
      libpango1.0-dev \
      libdbus-1-dev \
      libsystemd-dev \
      libpipewire-0.3-dev \
      clang
    
    NIRI_BUILD_DIR="/tmp/niri-build-$$"
    
    echo -e "${STY_BLUE}[$0]: Cloning Niri...${STY_RST}"
    git clone https://github.com/YaLTeR/niri.git "$NIRI_BUILD_DIR"
    
    echo -e "${STY_BLUE}[$0]: Building Niri (this may take a while)...${STY_RST}"
    cd "$NIRI_BUILD_DIR"
    cargo build --release
    
    echo -e "${STY_BLUE}[$0]: Installing Niri...${STY_RST}"
    sudo cp target/release/niri /usr/local/bin/
    sudo cp resources/niri.desktop /usr/share/wayland-sessions/ 2>/dev/null || true
    sudo cp resources/niri-portals.conf /usr/share/xdg-desktop-portal/ 2>/dev/null || true
    
    cd "${REPO_ROOT}"
    rm -rf "$NIRI_BUILD_DIR"
    
    echo -e "${STY_GREEN}[$0]: Niri installed successfully!${STY_RST}"
  fi
else
  echo -e "${STY_GREEN}[$0]: Niri already installed.${STY_RST}"
fi

#####################################################################################
# Install xwayland-satellite
#####################################################################################
if ! command -v xwayland-satellite &>/dev/null; then
  echo -e "${STY_BLUE}[$0]: Installing xwayland-satellite...${STY_RST}"
  cargo install xwayland-satellite
fi

#####################################################################################
# Install Quickshell (must compile - no prebuilt binaries)
#####################################################################################
echo -e "${STY_CYAN}[$0]: Installing Quickshell...${STY_RST}"

if ! command -v qs &>/dev/null; then
  echo -e "${STY_YELLOW}[$0]: Quickshell must be compiled from source.${STY_RST}"
  
  # Install additional build dependencies
  echo -e "${STY_BLUE}[$0]: Installing Quickshell build dependencies...${STY_RST}"
  v sudo apt install $installflags \
    libpam0g-dev \
    qt6-base-private-dev \
    qt6-declarative-private-dev \
    libqt6shadertools6-dev \
    qt6-wayland-dev
  
  QUICKSHELL_BUILD_DIR="/tmp/quickshell-build-$$"
  
  echo -e "${STY_BLUE}[$0]: Cloning Quickshell...${STY_RST}"
  git clone --recursive https://github.com/quickshell-mirror/quickshell.git "$QUICKSHELL_BUILD_DIR"
  
  echo -e "${STY_BLUE}[$0]: Building Quickshell...${STY_RST}"
  cd "$QUICKSHELL_BUILD_DIR"
  cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DSERVICE_PIPEWIRE=ON \
    -DSERVICE_PAM=ON
  cmake --build build -j$(nproc)
  
  echo -e "${STY_BLUE}[$0]: Installing Quickshell...${STY_RST}"
  sudo cmake --install build
  
  cd "${REPO_ROOT}"
  rm -rf "$QUICKSHELL_BUILD_DIR"
  
  echo -e "${STY_GREEN}[$0]: Quickshell installed successfully!${STY_RST}"
else
  echo -e "${STY_GREEN}[$0]: Quickshell already installed.${STY_RST}"
fi

#####################################################################################
# Install cava if not available in repos
#####################################################################################
if ! command -v cava &>/dev/null; then
  echo -e "${STY_BLUE}[$0]: Installing cava from source...${STY_RST}"
  v sudo apt install $installflags \
    libfftw3-dev \
    libasound2-dev \
    libpulse-dev \
    libpipewire-0.3-dev \
    libncursesw5-dev \
    libiniparser-dev \
    autoconf \
    automake \
    libtool
  
  CAVA_BUILD_DIR="/tmp/cava-build-$$"
  git clone https://github.com/karlstav/cava.git "$CAVA_BUILD_DIR"
  cd "$CAVA_BUILD_DIR"
  ./autogen.sh
  ./configure
  make -j$(nproc)
  sudo make install
  cd "${REPO_ROOT}"
  rm -rf "$CAVA_BUILD_DIR"
  echo -e "${STY_GREEN}[$0]: cava installed${STY_RST}"
fi

#####################################################################################
# Install critical fonts
#####################################################################################
echo -e "${STY_CYAN}[$0]: Installing critical fonts...${STY_RST}"

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# JetBrains Mono Nerd Font
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
  echo -e "${STY_BLUE}[$0]: Downloading JetBrains Mono Nerd Font...${STY_RST}"
  
  NERD_FONTS_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  TEMP_DIR="/tmp/nerdfonts-$$"
  mkdir -p "$TEMP_DIR"
  
  if curl -fsSL -o "$TEMP_DIR/JetBrainsMono.zip" "$NERD_FONTS_URL"; then
    unzip -o "$TEMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR" >/dev/null 2>&1
    fc-cache -f "$FONT_DIR"
    echo -e "${STY_GREEN}[$0]: JetBrains Mono Nerd Font installed.${STY_RST}"
  fi
  
  rm -rf "$TEMP_DIR"
fi

# Material Symbols fonts (CRITICAL - UI icons)
if ! fc-list | grep -qi "Material Symbols Rounded"; then
  echo -e "${STY_BLUE}[$0]: Downloading Material Symbols Rounded font...${STY_RST}"
  
  MATERIAL_URL="https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
  
  if curl -fsSL -o "$FONT_DIR/MaterialSymbolsRounded.ttf" "$MATERIAL_URL"; then
    echo -e "${STY_GREEN}[$0]: Material Symbols Rounded font installed.${STY_RST}"
  else
    echo -e "${STY_RED}[$0]: CRITICAL - Could not download Material Symbols. UI icons will be broken.${STY_RST}"
  fi
fi

if ! fc-list | grep -qi "Material Symbols Outlined"; then
  echo -e "${STY_BLUE}[$0]: Downloading Material Symbols Outlined font...${STY_RST}"
  
  MATERIAL_URL="https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsOutlined%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
  
  if curl -fsSL -o "$FONT_DIR/MaterialSymbolsOutlined.ttf" "$MATERIAL_URL"; then
    echo -e "${STY_GREEN}[$0]: Material Symbols Outlined font installed.${STY_RST}"
  fi
fi

# Refresh font cache
fc-cache -f "$FONT_DIR" 2>/dev/null

#####################################################################################
# Icon themes (WhiteSur, MacTahoe)
#####################################################################################
echo -e "${STY_CYAN}[$0]: Installing icon themes...${STY_RST}"

ICON_DIR="$HOME/.local/share/icons"
mkdir -p "$ICON_DIR"

# WhiteSur icon theme
if [[ ! -d "$ICON_DIR/WhiteSur-dark" ]]; then
  echo -e "${STY_BLUE}[$0]: Installing WhiteSur icon theme...${STY_RST}"
  
  TEMP_DIR="/tmp/whitesur-icons-$$"
  mkdir -p "$TEMP_DIR"
  
  if curl -fsSL -o "$TEMP_DIR/whitesur.tar.gz" \
    "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.tar.gz"; then
    tar -xzf "$TEMP_DIR/whitesur.tar.gz" -C "$TEMP_DIR"
    cd "$TEMP_DIR/WhiteSur-icon-theme-master"
    ./install.sh -d "$ICON_DIR" -t default >/dev/null 2>&1 || {
      cp -r src/WhiteSur "$ICON_DIR/WhiteSur-dark" 2>/dev/null || true
    }
    cd - >/dev/null
    echo -e "${STY_GREEN}[$0]: WhiteSur icon theme installed.${STY_RST}"
  fi
  
  rm -rf "$TEMP_DIR"
fi

# MacTahoe icon theme (dock icons)
if [[ ! -d "$ICON_DIR/MacTahoe" ]]; then
  echo -e "${STY_BLUE}[$0]: Installing MacTahoe icon theme...${STY_RST}"
  
  TEMP_DIR="/tmp/mactahoe-icons-$$"
  mkdir -p "$TEMP_DIR"
  
  if curl -fsSL -o "$TEMP_DIR/mactahoe.tar.gz" \
    "https://github.com/vinceliuice/MacTahoe-icon-theme/archive/refs/heads/main.tar.gz"; then
    tar -xzf "$TEMP_DIR/mactahoe.tar.gz" -C "$TEMP_DIR"
    cd "$TEMP_DIR/MacTahoe-icon-theme-main"
    ./install.sh -d "$ICON_DIR" >/dev/null 2>&1 || {
      cp -r src/MacTahoe "$ICON_DIR/MacTahoe" 2>/dev/null || true
    }
    cd - >/dev/null
    echo -e "${STY_GREEN}[$0]: MacTahoe icon theme installed.${STY_RST}"
  fi
  
  rm -rf "$TEMP_DIR"
fi

#####################################################################################
# Cursor themes (Bibata, Capitaine)
#####################################################################################
echo -e "${STY_CYAN}[$0]: Installing cursor themes...${STY_RST}"

CURSOR_DIR="$HOME/.local/share/icons"

# Bibata Modern Classic cursor
if [[ ! -d "$CURSOR_DIR/Bibata-Modern-Classic" ]]; then
  echo -e "${STY_BLUE}[$0]: Installing Bibata Modern Classic cursor...${STY_RST}"
  
  BIBATA_URL=$(curl -s "https://api.github.com/repos/ful1e5/Bibata_Cursor/releases/latest" | \
    jq -r '.assets[] | select(.name | test("Bibata-Modern-Classic.tar.xz$")) | .browser_download_url' | head -1)
  
  if [[ -n "$BIBATA_URL" && "$BIBATA_URL" != "null" ]]; then
    TEMP_DIR="/tmp/bibata-$$"
    mkdir -p "$TEMP_DIR"
    
    if curl -fsSL -o "$TEMP_DIR/bibata.tar.xz" "$BIBATA_URL"; then
      tar -xJf "$TEMP_DIR/bibata.tar.xz" -C "$CURSOR_DIR"
      echo -e "${STY_GREEN}[$0]: Bibata Modern Classic cursor installed.${STY_RST}"
    fi
    
    rm -rf "$TEMP_DIR"
  fi
fi

# Bibata Modern Ice cursor
if [[ ! -d "$CURSOR_DIR/Bibata-Modern-Ice" ]]; then
  echo -e "${STY_BLUE}[$0]: Installing Bibata Modern Ice cursor...${STY_RST}"
  
  BIBATA_URL=$(curl -s "https://api.github.com/repos/ful1e5/Bibata_Cursor/releases/latest" | \
    jq -r '.assets[] | select(.name | test("Bibata-Modern-Ice.tar.xz$")) | .browser_download_url' | head -1)
  
  if [[ -n "$BIBATA_URL" && "$BIBATA_URL" != "null" ]]; then
    TEMP_DIR="/tmp/bibata-ice-$$"
    mkdir -p "$TEMP_DIR"
    
    if curl -fsSL -o "$TEMP_DIR/bibata.tar.xz" "$BIBATA_URL"; then
      tar -xJf "$TEMP_DIR/bibata.tar.xz" -C "$CURSOR_DIR"
      echo -e "${STY_GREEN}[$0]: Bibata Modern Ice cursor installed.${STY_RST}"
    fi
    
    rm -rf "$TEMP_DIR"
  fi
fi

#####################################################################################
# Python environment setup
#####################################################################################
showfun install-python-packages
v install-python-packages

#####################################################################################
# Post-install summary
#####################################################################################
echo ""
echo -e "${STY_GREEN}════════════════════════════════════════════════════════════════${STY_RST}"
echo -e "${STY_GREEN}  Debian/Ubuntu dependencies installed!${STY_RST}"
echo -e "${STY_GREEN}════════════════════════════════════════════════════════════════${STY_RST}"
echo ""
echo -e "${STY_CYAN}Installed from GitHub releases (no compilation):${STY_RST}"
echo "  - gum, cliphist, matugen, darkly"
echo "  - Material Symbols fonts, JetBrains Mono Nerd Font"
echo "  - WhiteSur, MacTahoe icon themes"
echo "  - Bibata cursor themes"
echo ""
echo -e "${STY_CYAN}Compiled from source:${STY_RST}"
echo "  - niri, quickshell, xwayland-satellite, cava, swappy"
echo ""

# Verify critical commands
echo -e "${STY_CYAN}Verifying installation:${STY_RST}"
for cmd in qs niri fish gum matugen cliphist; do
  if command -v "$cmd" &>/dev/null; then
    echo -e "  ${STY_GREEN}✓${STY_RST} $cmd"
  else
    echo -e "  ${STY_RED}✗${STY_RST} $cmd (not found)"
  fi
done
echo ""

# PATH reminder
if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]] || [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo -e "${STY_CYAN}Add to your shell config (~/.bashrc or ~/.config/fish/config.fish):${STY_RST}"
  echo '  export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"'
  echo ""
fi
