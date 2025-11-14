# 奇语言编译器安装包构建指南

本文档详细说明如何为不同平台构建奇语言编译器的安装包。

## 安装包类型

奇语言编译器提供三种类型的安装包：

1. **macOS PKG** - macOS 原生图形化安装程序
2. **Windows MSI** - Windows 原生图形化安装程序
3. **TAR.GZ** - 跨平台命令行安装包（macOS/Linux）

---

## 1. macOS PKG 包

### 工具需求

- macOS 系统（10.15+）
- Xcode Command Line Tools（包含 `pkgbuild` 和 `productbuild`）
- Rust 工具链

### 构建步骤

```bash
cd qi-installer
chmod +x build-macos-pkg.sh
./build-macos-pkg.sh
```

### 工作原理

`build-macos-pkg.sh` 脚本执行以下操作：

1. **编译 Rust 项目**
   ```bash
   cargo build --release
   ```

2. **创建 PKG 目录结构**
   ```
   pkg-root/
   ├── usr/
   │   └── local/
   │       ├── bin/
   │       │   └── qi                    # 可执行文件
   │       └── lib/
   │           └── qi/
   │               └── libqi_compiler.a   # 运行时库
   ```

3. **生成安装后脚本** (`postinstall`)
   - 设置正确的文件权限
   - 显示安装成功消息

4. **使用 pkgbuild 创建组件包**
   ```bash
   pkgbuild --root pkg-root \
       --identifier com.qilang.qi-compiler \
       --version 0.1.0 \
       --scripts pkg-scripts \
       --install-location / \
       qi-component.pkg
   ```

5. **创建 Distribution XML**
   - 定义安装界面
   - 欢迎页面、许可证、结束页面

6. **使用 productbuild 创建最终 PKG**
   ```bash
   productbuild --distribution distribution.xml \
       --package-path . \
       --resources . \
       qi-installer-0.1.0.pkg
   ```

### PKG 包特性

- ✅ 原生 macOS 安装界面
- ✅ 支持 arm64 和 x86_64 架构
- ✅ 安装到系统标准位置 (`/usr/local/`)
- ✅ 自动配置环境变量（PATH 已包含 `/usr/local/bin`）
- ✅ 可通过系统偏好设置卸载
- ✅ 包含欢迎页面、许可证和安装完成提示

### 安装位置

- 可执行文件：`/usr/local/bin/qi`
- 运行时库：`/usr/local/lib/qi/libqi_compiler.a`

### 用户使用方式

**图形界面安装：**
```bash
# 双击 qi-installer-0.1.0.pkg
```

**命令行安装：**
```bash
sudo installer -pkg qi-installer-0.1.0.pkg -target /
```

---

## 2. Windows MSI 包

### 工具需求

- Windows 10/11
- [WiX Toolset v3.11+](https://wixtoolset.org/)
- Rust 工具链（包含 MSVC 工具链）
- PowerShell 5.0+

### 安装 WiX Toolset

1. 下载：https://wixtoolset.org/releases/
2. 安装到默认路径：`C:\Program Files (x86)\WiX Toolset v3.11\`
3. 将 WiX bin 目录添加到 PATH（可选）

### 构建步骤

```powershell
cd qi-installer
.\build-windows-msi.ps1
```

如果 WiX 安装在非默认位置：

```powershell
.\build-windows-msi.ps1 -WixPath "D:\WiX\bin"
```

### 工作原理

`build-windows-msi.ps1` 脚本执行以下操作：

1. **编译 Rust 项目**
   ```powershell
   cargo build --release
   ```

2. **准备安装文件**
   - 复制 `qi.exe` 到 `bin/`
   - 复制 `qi_compiler.lib` 到 `lib/`

3. **生成许可证 RTF 文件**
   - WiX 需要 RTF 格式的许可证文件

4. **编译 WXS 文件**
   ```powershell
   candle.exe -arch x64 -out qi-installer.wixobj qi-installer.wxs
   ```

5. **链接生成 MSI**
   ```powershell
   light.exe -out qi-installer-0.1.0-x64.msi -ext WixUIExtension qi-installer.wixobj
   ```

### WXS 配置文件

`qi-installer.wxs` 定义了：

- **Product 信息**：名称、版本、制造商
- **安装目录**：`C:\Program Files\Qi`
- **文件组件**：
  - `qi.exe` → `C:\Program Files\Qi\bin\`
  - `qi_compiler.lib` → `C:\Program Files\Qi\lib\`
- **环境变量**：自动添加 `C:\Program Files\Qi\bin` 到系统 PATH
- **UI**：使用 WixUI_InstallDir 安装向导

### MSI 包特性

- ✅ 原生 Windows 安装向导
- ✅ 支持 x64 架构
- ✅ 安装到 Program Files
- ✅ 自动配置系统 PATH 环境变量
- ✅ 支持通过"添加或删除程序"卸载
- ✅ 支持静默安装
- ✅ 自动升级检测

### 安装位置

- 可执行文件：`C:\Program Files\Qi\bin\qi.exe`
- 运行时库：`C:\Program Files\Qi\lib\qi_compiler.lib`

### 用户使用方式

**图形界面安装：**
```powershell
# 双击 qi-installer-0.1.0-x64.msi
```

**命令行安装：**
```powershell
msiexec /i qi-installer-0.1.0-x64.msi

# 静默安装
msiexec /i qi-installer-0.1.0-x64.msi /quiet /norestart
```

**卸载：**
```powershell
msiexec /x qi-installer-0.1.0-x64.msi
```

---

## 3. TAR.GZ 跨平台包

### 工具需求

- Unix-like 系统（macOS/Linux）
- Bash
- Rust 工具链
- tar 和 gzip

### 构建步骤

```bash
cd qi-installer
chmod +x package.sh
./package.sh
```

### 工作原理

`package.sh` 脚本执行以下操作：

1. **编译 Rust 项目**
   ```bash
   cargo build --release
   ```

2. **复制文件到安装器目录**
   ```bash
   cp target/release/qi bin/qi
   cp target/release/libqi_compiler.a lib/libqi_compiler.a
   ```

3. **创建压缩包**
   ```bash
   tar -czf qi-installer-${VERSION}-${OS}-${ARCH}.tar.gz \
       install.sh \
       uninstall.sh \
       bin/qi \
       lib/libqi_compiler.a \
       README.md
   ```

### 包内容

```
qi-installer-0.1.0-darwin-arm64.tar.gz
├── install.sh           # 安装脚本
├── uninstall.sh        # 卸载脚本
├── bin/
│   └── qi              # 可执行文件
├── lib/
│   └── libqi_compiler.a # 运行时库
└── README.md           # 说明文档
```

### TAR.GZ 包特性

- ✅ 跨平台支持（macOS/Linux）
- ✅ 无需额外工具
- ✅ 命令行友好
- ✅ 适合服务器环境
- ✅ 包含完整的安装/卸载脚本

### 安装位置

- 可执行文件：`/usr/local/bin/qi`
- 运行时库：`/usr/local/lib/qi/libqi_compiler.a`

### 用户使用方式

```bash
# 解压
tar -xzf qi-installer-0.1.0-darwin-arm64.tar.gz
cd qi-installer-0.1.0-darwin-arm64

# 安装
./install.sh

# 卸载
./uninstall.sh
```

---

## 运行时库查找机制

奇语言编译器使用以下策略查找运行时库（按优先级）：

1. **同目录查找** - 与可执行文件相同目录
2. **当前工作目录** - 用于开发环境
3. **target/release/** - Rust 构建输出目录
4. **target/debug/** - Rust 调试构建目录
5. **项目根目录** - 相对于编译器位置
6. **系统安装路径**：
   - macOS/Linux: `/usr/local/lib/qi/`
   - Windows: `C:\Program Files\Qi\lib\`

这种多路径查找机制确保了：
- 开发环境下无需安装即可运行
- 安装后可在任何位置调用 `qi` 命令
- 支持便携式部署（将库放在可执行文件旁边）

---

## 版本管理

所有安装包的版本号从 `qi/Cargo.toml` 自动读取：

```toml
[package]
name = "qi-compiler"
version = "0.1.0"
```

构建脚本会自动提取版本号并应用到：
- PKG 包名称和元数据
- MSI 包产品版本
- TAR.GZ 文件名

---

## 测试安装包

### 测试 PKG 包（macOS）

```bash
# 查看包信息
pkgutil --payload-files qi-installer-0.1.0.pkg

# 测试安装（不实际安装）
sudo installer -pkg qi-installer-0.1.0.pkg -target / -dumplog

# 实际安装
sudo installer -pkg qi-installer-0.1.0.pkg -target /

# 验证
qi --version

# 查看已安装包
pkgutil --pkgs | grep qi

# 卸载（如果需要）
sudo pkgutil --forget com.qilang.qi-compiler
sudo rm /usr/local/bin/qi
sudo rm -rf /usr/local/lib/qi
```

### 测试 MSI 包（Windows）

```powershell
# 查看包信息
msiexec /i qi-installer-0.1.0-x64.msi /l*v install.log

# 测试安装
msiexec /i qi-installer-0.1.0-x64.msi

# 验证
qi --version

# 卸载
msiexec /x qi-installer-0.1.0-x64.msi
```

### 测试 TAR.GZ 包

```bash
# 解压到临时目录
tar -xzf qi-installer-0.1.0-darwin-arm64.tar.gz -C /tmp/test-install
cd /tmp/test-install/qi-installer-*

# 安装
./install.sh

# 验证
qi --version

# 卸载
./uninstall.sh
```

---

## 发布清单

构建完整发布包时，应生成以下文件：

### macOS
- `qi-installer-0.1.0.pkg` - 图形化安装包
- `qi-installer-0.1.0-darwin-arm64.tar.gz` - 命令行安装包（ARM）
- `qi-installer-0.1.0-darwin-x86_64.tar.gz` - 命令行安装包（Intel）

### Linux
- `qi-installer-0.1.0-linux-x86_64.tar.gz` - 命令行安装包

### Windows
- `qi-installer-0.1.0-x64.msi` - 图形化安装包
- `qi-installer-0.1.0-windows-x86_64.zip` - 便携版（可选）

---

## 常见问题

### Q: PKG 安装后提示"找不到 qi 命令"？

A: `/usr/local/bin` 应该在默认 PATH 中。检查：
```bash
echo $PATH | grep /usr/local/bin
```

如果没有，添加到 shell 配置：
```bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Q: MSI 安装后 PATH 未更新？

A: MSI 修改的是系统环境变量，需要：
1. 完全关闭当前命令提示符
2. 打开新的命令提示符窗口
3. 运行 `qi --version`

### Q: 如何创建通用 macOS 二进制（Universal Binary）？

A: 需要交叉编译：
```bash
# 编译 x86_64
cargo build --release --target x86_64-apple-darwin

# 编译 arm64
cargo build --release --target aarch64-apple-darwin

# 合并为 Universal Binary
lipo -create \
    target/x86_64-apple-darwin/release/qi \
    target/aarch64-apple-darwin/release/qi \
    -output target/release/qi
```

### Q: WiX Toolset 编译错误？

A: 常见问题：
1. 确保安装了 WiX 3.11 或更高版本
2. 检查 GUID 是否唯一（不要复制其他项目的 GUID）
3. 确保所有引用的文件路径正确
4. 检查 WXS 文件 XML 语法

---

## 参考资料

- **macOS PKG**: [Apple Developer - Creating Distribution-Signed Code](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code)
- **Windows MSI**: [WiX Toolset Documentation](https://wixtoolset.org/documentation/)
- **Rust 交叉编译**: [Rust Platform Support](https://doc.rust-lang.org/nightly/rustc/platform-support.html)

---

**构建日期**: 2024-11-12
**奇语言版本**: 0.1.0
