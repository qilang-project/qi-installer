#!/bin/bash
# 奇语言编译器安装脚本
# Qi Language Compiler Installer

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    else
        print_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    print_info "检测到操作系统: $OS"
}

# 检查是否有 sudo 权限
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        print_warning "此脚本需要 sudo 权限来安装到系统目录"
        print_info "正在请求 sudo 权限..."
        sudo -v || {
            print_error "需要 sudo 权限才能继续安装"
            exit 1
        }
    fi
}

# 安装目录
INSTALL_PREFIX="/usr/local"
BIN_DIR="$INSTALL_PREFIX/bin"
LIB_DIR="$INSTALL_PREFIX/lib/qi"

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

print_info "=================================================="
print_info "       奇语言编译器安装程序"
print_info "       Qi Language Compiler Installer"
print_info "=================================================="
echo ""

# 检测操作系统
detect_os

# 检查必要文件
print_info "检查安装文件..."

QI_BINARY="$SCRIPT_DIR/bin/qi"
QI_LIB="$SCRIPT_DIR/lib/libqi_compiler.a"
QI_GUI_LIB="$SCRIPT_DIR/lib/libqi_gui.a"

if [ ! -f "$QI_BINARY" ]; then
    print_error "找不到 qi 可执行文件: $QI_BINARY"
    exit 1
fi

if [ ! -f "$QI_LIB" ]; then
    print_error "找不到 libqi_compiler.a 库文件: $QI_LIB"
    exit 1
fi

# GUI 库是可选的
HAS_GUI=false
if [ -f "$QI_GUI_LIB" ]; then
    HAS_GUI=true
    print_info "检测到 GUI 库支持"
else
    print_warning "未检测到 GUI 库 (图形化功能将不可用)"
fi

print_success "所有必要文件检查通过"
echo ""

# 显示安装信息
print_info "安装位置:"
print_info "  可执行文件: $BIN_DIR/qi"
print_info "  运行时库:   $LIB_DIR/libqi_compiler.a"
if [ "$HAS_GUI" = true ]; then
    print_info "  GUI 库:     $LIB_DIR/libqi_gui.a"
fi
echo ""

# 询问用户确认
read -p "是否继续安装? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "安装已取消"
    exit 0
fi

# 检查 sudo 权限
check_sudo

# 创建安装目录
print_info "创建安装目录..."
sudo mkdir -p "$BIN_DIR"
sudo mkdir -p "$LIB_DIR"

# 复制文件
print_info "复制可执行文件..."
sudo cp "$QI_BINARY" "$BIN_DIR/qi"
sudo chmod +x "$BIN_DIR/qi"

# 创建中文别名软链接
print_info "创建中文命令别名..."
sudo ln -sf "$BIN_DIR/qi" "$BIN_DIR/奇"

print_info "复制运行时库..."
sudo cp "$QI_LIB" "$LIB_DIR/libqi_compiler.a"
sudo chmod 644 "$LIB_DIR/libqi_compiler.a"

# 复制 GUI 库（如果存在）
if [ "$HAS_GUI" = true ]; then
    print_info "复制 GUI 库..."
    sudo cp "$QI_GUI_LIB" "$LIB_DIR/libqi_gui.a"
    sudo chmod 644 "$LIB_DIR/libqi_gui.a"
fi

# 验证安装
print_info "验证安装..."
if command -v qi &> /dev/null; then
    QI_VERSION=$(qi --version 2>&1 || echo "未知版本")
    print_success "奇语言编译器安装成功！"
    echo ""
    print_info "版本信息:"
    echo "  $QI_VERSION"
    echo ""
    print_info "使用方法:"
    print_info "  qi 运行 <文件.qi>       - 运行奇语言程序"
    print_info "  qi 编译 <文件.qi>       - 编译奇语言程序"
    print_info "  qi 检查 <文件.qi>       - 检查语法"
    print_info "  qi --帮助               - 查看帮助"
    echo ""
    print_info "或使用中文命令:"
    print_info "  奇 运行 <文件.qi>       - 运行奇语言程序"
    print_info "  奇 编译 <文件.qi>       - 编译奇语言程序"
    print_info "  奇 检查 <文件.qi>       - 检查语法"
    echo ""
    print_success "现在你可以在任何地方使用 'qi' 或 '奇' 命令了！"
else
    print_error "安装似乎成功了，但无法找到 qi 命令"
    print_warning "请确保 $BIN_DIR 在你的 PATH 环境变量中"
    print_info "你可以运行以下命令来添加到 PATH:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    exit 1
fi

echo ""
print_info "=================================================="
print_success "安装完成！"
print_info "=================================================="
