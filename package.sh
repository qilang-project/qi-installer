#!/bin/bash
# 奇语言编译器打包脚本
# 自动打包 release 版本的编译器

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 捆绑 homebrew 动态库并修正 rpath —— 让无 homebrew 的机器也能跑
# (homebrew LLVM 静态链接后仍连带 libz3/libzstd 动态依赖;打进包里,
#  加载路径改 @rpath,rpath 指向 安装位(/usr/local/lib/qi) 和 解压即用位(bin/../lib))
bundle_homebrew_dylibs() {
    local target_bin="$1"   # 要修的 qi 二进制
    local dylib_dir="$2"    # dylib 落哪
    mkdir -p "$dylib_dir"
    otool -L "$target_bin" | awk '/\/opt\/homebrew\//{print $1}' | while read -r dep; do
        local base
        base=$(basename "$dep")
        cp -f "$dep" "$dylib_dir/$base"
        chmod 755 "$dylib_dir/$base"
        install_name_tool -change "$dep" "@rpath/$base" "$target_bin"
        print_info "  捆绑动态库: $base"
    done
    install_name_tool -add_rpath /usr/local/lib/qi "$target_bin" 2>/dev/null || true
    install_name_tool -add_rpath @executable_path/../lib "$target_bin" 2>/dev/null || true
    install_name_tool -add_rpath @executable_path/../lib/qi "$target_bin" 2>/dev/null || true
    # install_name_tool 会毁掉 arm64 签名,ad-hoc 重签
    codesign --force -s - "$target_bin" 2>/dev/null || true
    # 自检:不许残留 homebrew 绝对路径
    if otool -L "$target_bin" | grep -q "/opt/homebrew/"; then
        print_error "仍有 homebrew 动态依赖未处理:"
        otool -L "$target_bin" | grep "/opt/homebrew/"
        exit 1
    fi
}

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_DIR="$SCRIPT_DIR/.."
QI_DIR="$WORKSPACE_DIR/qi"
QI_GUI_DIR="$WORKSPACE_DIR/qi-gui"

print_info "=================================================="
print_info "       奇语言编译器打包工具"
print_info "=================================================="
echo ""

# 检查是否包含 GUI 库
INCLUDE_GUI=true
if [ "$1" == "--no-gui" ]; then
    INCLUDE_GUI=false
    print_info "不包含 GUI 库（使用 --no-gui 参数）"
else
    print_info "将包含 GUI 库（使用 --no-gui 参数可排除）"
fi
echo ""

# 检查 qi 项目目录
if [ ! -d "$QI_DIR" ]; then
    print_error "找不到 qi 项目目录: $QI_DIR"
    exit 1
fi

# 进入 workspace 目录
cd "$WORKSPACE_DIR"

# 编译 release 版本
print_info "编译 release 版本..."
if [ "$INCLUDE_GUI" = true ]; then
    print_info "构建包含 GUI 的完整版本..."
    cargo build --workspace --release
else
    print_info "构建不含 GUI 的版本..."
    cargo build -p qi-compiler --release
fi

# 构建无 LLVM 的 qi-runtime 归档（inkwell 后端链接用户程序用它）
print_info "构建 qi-runtime 归档..."
(cd "$WORKSPACE_DIR/qi-runtime" && cargo build --release)

# 检查编译产物
QI_BINARY="target/release/qi"
QI_LIB="qi-runtime/target/release/libqi_runtime.a"
QI_GUI_LIB="target/release/libqi_gui.a"

if [ ! -f "$QI_BINARY" ]; then
    print_error "找不到编译后的 qi 可执行文件"
    exit 1
fi

if [ ! -f "$QI_LIB" ]; then
    print_error "找不到编译后的 libqi_runtime.a"
    exit 1
fi

# 检查 GUI 库（可选）
HAS_GUI=false
if [ "$INCLUDE_GUI" = true ] && [ -f "$QI_GUI_LIB" ]; then
    HAS_GUI=true
    print_info "检测到 GUI 库"
fi

print_success "编译完成"
echo ""

# 复制文件到安装器目录
print_info "复制文件到安装器目录..."

# 创建目标目录
mkdir -p "$SCRIPT_DIR/bin"
mkdir -p "$SCRIPT_DIR/lib"

# 复制文件
cp "$QI_BINARY" "$SCRIPT_DIR/bin/qi"
print_info "捆绑 homebrew 动态库..."
bundle_homebrew_dylibs "$SCRIPT_DIR/bin/qi" "$SCRIPT_DIR/lib"

# 用刚打包的 qi 编译 Qi 写的工具(自举):qi-init 项目脚手架
print_info "编译 qi-init(Qi 写的脚手架)..."
QI_RUNTIME_LIB="$WORKSPACE_DIR/qi-runtime/target/release/libqi_runtime.a" \
  "$SCRIPT_DIR/bin/qi" -O standard compile "$WORKSPACE_DIR/qi-tools/qi-init/主程序.qi" -o "$SCRIPT_DIR/bin/qi-init"

# 自举工具第二个:qifmt 代码格式化器(同款 Qi 写的工具)
print_info "编译 qifmt(Qi 写的格式化器)..."
QI_RUNTIME_LIB="$WORKSPACE_DIR/qi-runtime/target/release/libqi_runtime.a" \
  "$SCRIPT_DIR/bin/qi" -O standard compile "$WORKSPACE_DIR/qi-tools/qi-fmt/主程序.qi" -o "$SCRIPT_DIR/bin/qifmt"

cp "$QI_LIB" "$SCRIPT_DIR/lib/libqi_runtime.a"

# 复制 GUI 库（如果存在）
if [ "$HAS_GUI" = true ]; then
    cp "$QI_GUI_LIB" "$SCRIPT_DIR/lib/libqi_gui.a"
    print_info "已复制 GUI 库"
fi

print_success "文件复制完成"
echo ""

print_info "文件位置:"
print_info "  可执行文件: $SCRIPT_DIR/bin/qi"
print_info "  运行时库:   $SCRIPT_DIR/lib/libqi_runtime.a"
if [ "$HAS_GUI" = true ]; then
    print_info "  GUI 库:     $SCRIPT_DIR/lib/libqi_gui.a"
fi
echo ""

# 创建发布包
print_info "创建发布包..."

VERSION=$(grep '^version' "$QI_DIR/Cargo.toml" | head -1 | sed 's/.*"\(.*\)".*/\1/')
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# 根据是否包含 GUI 库添加后缀
if [ "$HAS_GUI" = true ]; then
    PACKAGE_NAME="qi-installer-${VERSION}-${OS_TYPE}-${ARCH}.tar.gz"
else
    PACKAGE_NAME="qi-installer-${VERSION}-${OS_TYPE}-${ARCH}-nogui.tar.gz"
fi

PACKAGE_PATH="$SCRIPT_DIR/$PACKAGE_NAME"

cd "$SCRIPT_DIR"

# 构建文件列表
FILES_TO_PACK="install.sh uninstall.sh bin/qi bin/qi-init bin/qifmt lib/libqi_runtime.a README.md"
for dylib in lib/*.dylib; do
    [ -e "$dylib" ] && FILES_TO_PACK="$FILES_TO_PACK $dylib"
done
if [ "$HAS_GUI" = true ]; then
    FILES_TO_PACK="$FILES_TO_PACK lib/libqi_gui.a"
fi

tar -czf "$PACKAGE_NAME" $FILES_TO_PACK 2>/dev/null || true

if [ -f "$PACKAGE_PATH" ]; then
    PACKAGE_SIZE=$(ls -lh "$PACKAGE_PATH" | awk '{print $5}')
    print_success "发布包创建成功"
    print_info "  文件名: $PACKAGE_NAME"
    print_info "  大小:   $PACKAGE_SIZE"
    echo ""
else
    print_error "创建发布包失败"
    exit 1
fi

print_info "=================================================="
print_success "打包完成！"
print_info "=================================================="
print_info ""
print_info "现在可以分发 $PACKAGE_NAME"
print_info "用户只需解压后运行 ./install.sh 即可安装"
