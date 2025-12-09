#!/bin/bash
# 奇语言编译器 macOS PKG 打包脚本
# 生成原生 macOS 安装包 (.pkg)

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

# 检查是否在 macOS 上
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "此脚本只能在 macOS 上运行"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_DIR="$SCRIPT_DIR/.."
QI_DIR="$WORKSPACE_DIR/qi"

print_info "=================================================="
print_info "       奇语言编译器 macOS PKG 打包工具"
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

# 获取版本号
cd "$QI_DIR"
VERSION=$(grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/')
print_info "版本: $VERSION"

# 编译 release 版本
cd "$WORKSPACE_DIR"
print_info "编译 release 版本..."
if [ "$INCLUDE_GUI" = true ]; then
    print_info "构建包含 GUI 的完整版本..."
    cargo build --workspace --release
else
    print_info "构建不含 GUI 的版本..."
    cargo build -p qi-compiler --release
fi

# 检查编译产物
QI_BINARY="target/release/qi"
QI_LIB="target/release/libqi_compiler.a"
QI_GUI_LIB="target/release/libqi_gui.a"

if [ ! -f "$QI_BINARY" ]; then
    print_error "找不到编译后的 qi 可执行文件"
    exit 1
fi

if [ ! -f "$QI_LIB" ]; then
    print_error "找不到编译后的 libqi_compiler.a"
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

# 创建临时目录结构
print_info "创建 PKG 目录结构..."
PKG_ROOT="$SCRIPT_DIR/pkg-root"
PKG_SCRIPTS="$SCRIPT_DIR/pkg-scripts"

rm -rf "$PKG_ROOT" "$PKG_SCRIPTS"
mkdir -p "$PKG_ROOT/usr/local/bin"
mkdir -p "$PKG_ROOT/usr/local/lib/qi"
mkdir -p "$PKG_SCRIPTS"

# 复制文件到 PKG 根目录
cp "$WORKSPACE_DIR/$QI_BINARY" "$PKG_ROOT/usr/local/bin/qi"
cp "$WORKSPACE_DIR/$QI_LIB" "$PKG_ROOT/usr/local/lib/qi/libqi_compiler.a"

# 创建中文别名软链接
print_info "创建中文命令别名 '奇'..."
ln -sf qi "$PKG_ROOT/usr/local/bin/奇"

# 复制 GUI 库（如果存在）
if [ "$HAS_GUI" = true ]; then
    cp "$WORKSPACE_DIR/$QI_GUI_LIB" "$PKG_ROOT/usr/local/lib/qi/libqi_gui.a"
    print_info "已复制 GUI 库"
fi

# 设置权限
chmod 755 "$PKG_ROOT/usr/local/bin/qi"
chmod 644 "$PKG_ROOT/usr/local/lib/qi/libqi_compiler.a"
if [ "$HAS_GUI" = true ]; then
    chmod 644 "$PKG_ROOT/usr/local/lib/qi/libqi_gui.a"
fi

print_success "目录结构创建完成"
echo ""

# 创建 postinstall 脚本（安装后执行）
print_info "创建安装后脚本..."
cat > "$PKG_SCRIPTS/postinstall" << 'POSTINSTALL_EOF'
#!/bin/bash
# PKG 安装后脚本

# 确保权限正确
chmod 755 /usr/local/bin/qi
chmod 644 /usr/local/lib/qi/libqi_compiler.a

# 显示成功消息
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ 奇语言编译器安装成功！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "使用方法:"
echo "  qi 运行 <文件.qi>       - 运行奇语言程序"
echo "  qi 编译 <文件.qi>       - 编译奇语言程序"
echo "  qi --帮助               - 查看帮助"
echo ""
echo "或使用中文命令:"
echo "  奇 运行 <文件.qi>       - 运行奇语言程序"
echo "  奇 编译 <文件.qi>       - 编译奇语言程序"
echo ""
echo "请打开新的终端窗口以使用 qi 或 奇 命令"
echo ""

exit 0
POSTINSTALL_EOF

chmod +x "$PKG_SCRIPTS/postinstall"

print_success "安装后脚本创建完成"
echo ""

# 生成 PKG 包
print_info "生成 PKG 包..."

PKG_IDENTIFIER="com.qilang.qi-compiler"
# 根据是否包含 GUI 库添加后缀
if [ "$HAS_GUI" = true ]; then
    PKG_NAME="qi-installer-${VERSION}.pkg"
else
    PKG_NAME="qi-installer-${VERSION}-nogui.pkg"
fi
PKG_PATH="$SCRIPT_DIR/$PKG_NAME"

# 使用 pkgbuild 创建组件包
COMPONENT_PKG="$SCRIPT_DIR/qi-component.pkg"

pkgbuild --root "$PKG_ROOT" \
    --identifier "$PKG_IDENTIFIER" \
    --version "$VERSION" \
    --scripts "$PKG_SCRIPTS" \
    --install-location "/" \
    "$COMPONENT_PKG"

# 创建 Distribution XML（用于自定义安装界面）
DISTRIBUTION_XML="$SCRIPT_DIR/distribution.xml"
cat > "$DISTRIBUTION_XML" << DIST_EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>奇语言编译器 Qi Compiler</title>
    <welcome file="welcome.html"/>
    <license file="license.txt"/>
    <conclusion file="conclusion.html"/>
    <pkg-ref id="$PKG_IDENTIFIER"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <choices-outline>
        <line choice="default">
            <line choice="$PKG_IDENTIFIER"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$PKG_IDENTIFIER" visible="false">
        <pkg-ref id="$PKG_IDENTIFIER"/>
    </choice>
    <pkg-ref id="$PKG_IDENTIFIER" version="$VERSION" onConclusion="none">qi-component.pkg</pkg-ref>
</installer-gui-script>
DIST_EOF

# 创建欢迎页面
if [ "$HAS_GUI" = true ]; then
cat > "$SCRIPT_DIR/welcome.html" << 'WELCOME_EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: -apple-system, sans-serif; font-size: 13px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>欢迎安装奇语言编译器（完整版）</h1>
    <p>奇语言（Qi Language）是一个 100% 中文关键字的编程语言。</p>
    <p>此安装程序将安装以下组件：</p>
    <ul>
        <li>qi 编译器（/usr/local/bin/qi）</li>
        <li>奇 命令别名（/usr/local/bin/奇）</li>
        <li>运行时库（/usr/local/lib/qi/libqi_compiler.a）</li>
        <li>GUI 库（/usr/local/lib/qi/libqi_gui.a）</li>
    </ul>
    <p>安装后，您可以在终端中使用 <code>qi</code> 或 <code>奇</code> 命令，包括图形化功能。</p>
</body>
</html>
WELCOME_EOF
else
cat > "$SCRIPT_DIR/welcome.html" << 'WELCOME_EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: -apple-system, sans-serif; font-size: 13px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>欢迎安装奇语言编译器（精简版）</h1>
    <p>奇语言（Qi Language）是一个 100% 中文关键字的编程语言。</p>
    <p>此安装程序将安装以下组件：</p>
    <ul>
        <li>qi 编译器（/usr/local/bin/qi）</li>
        <li>奇 命令别名（/usr/local/bin/奇）</li>
        <li>运行时库（/usr/local/lib/qi/libqi_compiler.a）</li>
    </ul>
    <p><strong>注意：</strong>此版本不包含 GUI 库，图形化功能将不可用。</p>
    <p>安装后，您可以在终端中使用 <code>qi</code> 或 <code>奇</code> 命令。</p>
</body>
</html>
WELCOME_EOF
fi

# 创建许可证文件
cat > "$SCRIPT_DIR/license.txt" << 'LICENSE_EOF'
奇语言编译器许可证

版权所有 (c) 2024 奇语言项目

允许任何人免费使用此软件。

此软件按"原样"提供，不提供任何明示或暗示的保证。
LICENSE_EOF

# 创建结束页面
cat > "$SCRIPT_DIR/conclusion.html" << 'CONCLUSION_EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: -apple-system, sans-serif; font-size: 13px; }
        h1 { color: #28a745; }
        code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>✓ 安装成功！</h1>
    <p>奇语言编译器已成功安装到您的系统。</p>
    <h2>快速开始：</h2>
    <p>打开终端，输入以下命令查看版本：</p>
    <pre><code>qi --version</code></pre>
    <p>运行示例程序：</p>
    <pre><code>qi 运行 示例.qi
# 或使用中文命令
奇 运行 示例.qi</code></pre>
    <p>查看帮助：</p>
    <pre><code>qi --帮助</code></pre>
    <h2>更多信息：</h2>
    <p>访问官方文档了解更多内容。</p>
</body>
</html>
CONCLUSION_EOF

# 使用 productbuild 创建最终的分发包（带自定义界面）
productbuild --distribution "$DISTRIBUTION_XML" \
    --package-path "$SCRIPT_DIR" \
    --resources "$SCRIPT_DIR" \
    "$PKG_PATH"

# 清理临时文件
rm -rf "$PKG_ROOT" "$PKG_SCRIPTS" "$COMPONENT_PKG" "$DISTRIBUTION_XML"
rm -f "$SCRIPT_DIR/welcome.html" "$SCRIPT_DIR/license.txt" "$SCRIPT_DIR/conclusion.html"

if [ -f "$PKG_PATH" ]; then
    PKG_SIZE=$(ls -lh "$PKG_PATH" | awk '{print $5}')
    print_success "PKG 包创建成功！"
    echo ""
    print_info "  文件名: $PKG_NAME"
    print_info "  大小:   $PKG_SIZE"
    print_info "  路径:   $PKG_PATH"
    echo ""
    print_info "=================================================="
    print_success "打包完成！"
    print_info "=================================================="
    echo ""
    print_info "用户可以双击 .pkg 文件进行图形化安装"
    print_info "或使用命令行安装: sudo installer -pkg $PKG_NAME -target /"
else
    print_error "创建 PKG 包失败"
    exit 1
fi
