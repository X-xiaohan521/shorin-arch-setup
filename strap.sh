#!/usr/bin/env bash

# ==============================================================================
# Bootstrap Script for Shorin Arch Setup
# ==============================================================================

# 启用严格模式：遇到错误、未定义变量或管道错误时立即退出
set -euo pipefail

# --- [颜色配置] ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- [默认参数] ---
OFFLINE_MODE=false

# --- [解析命令行参数] ---
for arg in "$@"; do
    case "$arg" in
        -o|--offline)
            OFFLINE_MODE=true
            shift
            ;;
        *)
            ;;
    esac
done

# --- [环境检测] ---

# 1. 检查是否为 Linux 内核
if [ "$(uname -s)" != "Linux" ]; then
    printf "%bError: This installer only supports Linux systems.%b\n" "$RED" "$NC"
    exit 1
fi

# 2. 检查架构是否匹配 (仅允许 x86_64)
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    printf "%bError: Unsupported architecture: %s%b\n" "$RED" "$ARCH" "$NC"
    printf "This installer is strictly designed for x86_64 (amd64) systems only.\n"
    exit 1
fi
ARCH_NAME="amd64"

# --- [配置区域] ---
# 优先使用环境变量传入的分支名，如果没传，则默认使用 'main'
TARGET_BRANCH="${BRANCH:-main}"
REPO_URL="https://github.com/SHORiN-KiWATA/shorin-arch-setup.git"

# 强制将引导目录设定在内存盘 /tmp 下，安全、极速、无残留
TARGET_DIR="/tmp/shorin-arch-setup"

# --- [打印开始信息] ---
if [ "$OFFLINE_MODE" = false ]; then
    printf "%b>>> Preparing to install from remote branch: %s on %s%b\n" "$BLUE" "$TARGET_BRANCH" "$ARCH_NAME" "$NC"
else
    printf "%b>>> Offline mode: preparing to install from local repository."

# --- [执行流程] ---

# 1. 如果不是离线模式，检查 git
if [ "$OFFLINE_MODE" = false ]; then
    if ! command -v git >/dev/null 2>&1; then
        printf "Git not found. Installing...\n"
        sudo pacman -Syu --noconfirm git
    fi
fi

# 2. 清理旧目录
if [ -d "$TARGET_DIR" ]; then
    printf "Removing existing directory '%s'...\n" "$TARGET_DIR"
    sudo rm -rf "$TARGET_DIR"
fi

# 3. 获取安装脚本
if [ "$OFFLINE_MODE" = true ]; then

    printf "%bOffline mode enabled. Copying local repository...%b\n" "$BLUE" "$NC"

    if cp -r . "$TARGET_DIR" --exclude=.git; then
        sudo chmod 755 "$TARGET_DIR"
        printf "%bCopy successful.%b\n" "$GREEN" "$NC"
    else
        printf "%bError: Failed to copy the scripts to '%s'.%b\n" "$RED" "$TARGET_DIR" "$NC"
        exit 1
    fi

else

    printf "Cloning repository to %s...\n" "$TARGET_DIR"

    if git clone --depth 1 -b "$TARGET_BRANCH" "$REPO_URL" "$TARGET_DIR"; then
        sudo chmod 755 "$TARGET_DIR"
        printf "%bClone successful.%b\n" "$GREEN" "$NC"

    else
        printf "%bError: Failed to clone branch '%s'.%b\n" "$RED" "$TARGET_BRANCH" "$NC"
        printf "%bTip: If you are offline, run the installer with:%b\n" "$BLUE" "$NC"
        printf "    ./strap.sh --offline\n"
        exit 1
    fi
fi

# 4. 运行安装
cd "$TARGET_DIR"
printf "Starting installer...\n"
# 直接调用 sudo bash 执行核心安装逻辑
sudo bash install.sh < /dev/tty