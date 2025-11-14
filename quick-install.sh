#!/bin/bash
# 快速重新安装脚本

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

print_info "=================================================="
print_info "       奇语言编译器快速重新安装"
print_info "=================================================="
echo ""

# 卸载旧版本（如果存在）
if [ -f "/usr/local/bin/qi" ]; then
    print_info "卸载旧版本..."
    sudo rm -f /usr/local/bin/qi
    sudo rm -rf /usr/local/lib/qi
    print_success "旧版本已卸载"
fi

# 安装新版本
print_info "安装新版本..."
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/local/lib/qi

sudo cp "$SCRIPT_DIR/bin/qi" /usr/local/bin/qi
sudo chmod +x /usr/local/bin/qi

sudo cp "$SCRIPT_DIR/lib/libqi_compiler.a" /usr/local/lib/qi/libqi_compiler.a
sudo chmod 644 /usr/local/lib/qi/libqi_compiler.a

print_success "新版本安装完成！"
echo ""

# 验证
print_info "验证安装..."
QI_VERSION=$(qi --version 2>&1 || echo "未知版本")
echo "  $QI_VERSION"

print_info "文件信息:"
ls -lh /usr/local/bin/qi | awk '{print "  "$6, $7, $8, $9}'

echo ""
print_success "安装完成！可以使用 'qi run 文件.qi' 命令了"
print_info "=================================================="
