#!/bin/bash
# 奇语言编译器卸载脚本
# Qi Language Compiler Uninstaller

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 安装目录
INSTALL_PREFIX="/usr/local"
BIN_DIR="$INSTALL_PREFIX/bin"
LIB_DIR="$INSTALL_PREFIX/lib/qi"

print_info "=================================================="
print_info "       奇语言编译器卸载程序"
print_info "       Qi Language Compiler Uninstaller"
print_info "=================================================="
echo ""

# 检查是否已安装
if [ ! -f "$BIN_DIR/qi" ] && [ ! -d "$LIB_DIR" ]; then
    print_warning "未检测到奇语言编译器安装"
    exit 0
fi

print_info "将删除以下文件:"
if [ -f "$BIN_DIR/qi" ]; then
    print_info "  $BIN_DIR/qi"
fi
if [ -d "$LIB_DIR" ]; then
    print_info "  $LIB_DIR/"
fi
echo ""

# 询问确认
read -p "确定要卸载奇语言编译器吗? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "卸载已取消"
    exit 0
fi

# 检查 sudo 权限
if [ "$EUID" -ne 0 ]; then
    print_info "请求 sudo 权限..."
    sudo -v || {
        print_error "需要 sudo 权限才能卸载"
        exit 1
    }
fi

# 删除文件
print_info "正在卸载..."

if [ -f "$BIN_DIR/qi" ]; then
    sudo rm -f "$BIN_DIR/qi"
    print_success "已删除可执行文件"
fi

# 删除捆绑工具与中文别名
for tool in qi-init qifmt qi-bindgen 奇; do
    if [ -e "$BIN_DIR/$tool" ] || [ -L "$BIN_DIR/$tool" ]; then
        sudo rm -f "$BIN_DIR/$tool"
        print_success "已删除 $tool"
    fi
done

if [ -d "$LIB_DIR" ]; then
    sudo rm -rf "$LIB_DIR"
    print_success "已删除运行时库"
fi

echo ""
print_success "奇语言编译器已成功卸载"
print_info "=================================================="
