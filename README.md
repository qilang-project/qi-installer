# 奇语言编译器安装器

奇语言（Qi Language）- 100% 中文关键字编程语言

## 快速安装

### macOS

**方式一：PKG 安装包（推荐）**

1. 双击 `qi-installer-*.pkg` 文件
2. 按照安装向导提示完成安装
3. 安装程序会自动配置环境变量

**方式二：命令行安装**

```bash
# 解压安装包
tar -xzf qi-installer-*.tar.gz
cd qi-installer-*

# 运行安装脚本
./install.sh
```

### Linux

```bash
# 解压安装包
tar -xzf qi-installer-*.tar.gz
cd qi-installer-*

# 运行安装脚本
./install.sh
```

### Windows

**方式一：MSI 安装包（推荐）**

1. 双击 `qi-installer-*.msi` 文件
2. 按照安装向导提示完成安装
3. 安装程序会自动配置环境变量

**方式二：批处理安装**

1. 解压安装包
2. 右键点击 `install.bat`
3. 选择"以管理员身份运行"

## 验证安装

安装完成后，打开新的终端窗口，输入：

```bash
qi --version
```

如果看到版本信息，说明安装成功！

## 使用示例

### 运行程序

```bash
qi run 示例.qi
```

### 编译程序

```bash
qi compile 示例.qi -o 输出文件
```

### 检查语法

```bash
qi check 示例.qi
```

## Hello World 示例

创建文件 `你好世界.qi`：

```qi
包 主程序;

函数 入口() {
    打印行("你好，世界！");
}
```

运行：

```bash
qi run 你好世界.qi
```

输出：

```
你好，世界！
```

## 卸载

### macOS / Linux

```bash
# 进入安装目录
cd qi-installer-*

# 运行卸载脚本
./uninstall.sh
```

### Windows

手动删除以下内容：

1. 删除 `C:\Program Files\Qi` 目录
2. 从系统 PATH 环境变量中移除 `C:\Program Files\Qi\bin`

## 目录结构

安装后的目录结构：

```
macOS/Linux:
/usr/local/bin/qi                    # 可执行文件
/usr/local/lib/qi/libqi_compiler.a   # 运行时库
/usr/local/lib/qi/libqi_gui.a        # GUI 库 (可选)

Windows:
C:\Program Files\Qi\bin\qi.exe          # 可执行文件
C:\Program Files\Qi\lib\qi_compiler.lib # 运行时库
C:\Program Files\Qi\lib\qi_gui.lib      # GUI 库 (可选)
```

**注意**: GUI 库是可选组件。如果安装包中包含 GUI 库，则会自动安装；否则图形化功能将不可用，但不影响其他功能的使用。

## 系统要求

- **macOS**: macOS 10.15 或更高版本
- **Linux**: 主流发行版（Ubuntu 20.04+, Debian 11+, Fedora 35+ 等）
- **Windows**: Windows 10/11（需要管理员权限）

## 命令行工具

奇语言提供以下命令：

| 命令 | 说明 | 示例 |
|------|------|------|
| `qi run` | 运行奇语言程序 | `qi run 程序.qi` |
| `qi compile` | 编译为可执行文件 | `qi compile 程序.qi -o 输出` |
| `qi check` | 检查语法 | `qi check 程序.qi` |
| `qi --help` | 显示帮助信息 | `qi --help` |
| `qi --version` | 显示版本信息 | `qi --version` |

## 标准库模块

奇语言内置以下标准库模块：

- **标准库.操作系统** - 操作系统功能（文件、目录、环境变量等）
- **标准库.命令行** - 命令行参数解析
- **标准库.大模型** - LLM 集成
- **标准库.输入输出** - IO 操作
- **标准库.加密** - 加密和哈希功能
- **标准库.向量计算** - 向量和矩阵运算
- **标准库.图形化** - GUI 图形界面（需要 GUI 库支持）

## 常见问题

### Q: 安装后提示"找不到 qi 命令"？

**A:** 请确保安装目录在你的 PATH 环境变量中。

macOS/Linux:
```bash
export PATH="/usr/local/bin:$PATH"
```

Windows: 重新打开命令提示符窗口。

### Q: macOS 提示"无法打开，因为无法验证开发者"？

**A:** 运行以下命令：
```bash
sudo xattr -rd com.apple.quarantine /usr/local/bin/qi
```

### Q: 需要什么编译器吗？

**A:** 不需要！奇语言编译器是完全独立的，无需额外安装 C/C++ 编译器。

### Q: 如何知道是否安装了 GUI 库？

**A:** 安装时会显示是否检测到 GUI 库。你也可以检查安装目录：

macOS/Linux:
```bash
ls -la /usr/local/lib/qi/libqi_gui.a
```

Windows:
```cmd
dir "C:\Program Files\Qi\lib\qi_gui.lib"
```

如果文件存在，说明已安装 GUI 库，可以使用 `标准库.图形化` 模块。

### Q: 没有 GUI 库会影响使用吗？

**A:** 不会！只有使用图形化界面功能时才需要 GUI 库。其他所有功能（命令行程序、文件操作、网络请求等）都不受影响。

## 更多资源

- **官方文档**: [即将推出]
- **示例代码**: 查看 `qi/示例` 目录
- **GitHub**: [https://github.com/qilang](https://github.com/qilang)

## 许可证

[待定]

## 支持

如有问题，请提交 Issue 或联系开发团队。

---

## 构建安装包

### 构建 macOS PKG 包

在 macOS 上运行：

```bash
cd qi-installer
chmod +x build-macos-pkg.sh
./build-macos-pkg.sh
```

这将生成 `qi-installer-0.1.0.pkg` 文件。

**PKG 包特性：**
- 原生 macOS 安装程序
- 图形化安装界面
- 自动配置环境变量
- 支持卸载（通过系统偏好设置）
- 使用 macOS 系统工具 `pkgbuild` 和 `productbuild`

### 构建 Windows MSI 包

在 Windows 上运行（需要先安装 [WiX Toolset](https://wixtoolset.org/)）：

```powershell
cd qi-installer
.\build-windows-msi.ps1
```

如果 WiX 安装在非默认位置，指定路径：

```powershell
.\build-windows-msi.ps1 -WixPath "C:\path\to\wix\bin"
```

这将生成 `qi-installer-0.1.0-x64.msi` 文件。

**MSI 包特性：**
- 原生 Windows 安装程序
- 图形化安装向导
- 自动配置 PATH 环境变量
- 支持通过"添加或删除程序"卸载
- 使用 WiX Toolset 构建

### 构建跨平台 TAR.GZ 包

```bash
cd qi-installer
chmod +x package.sh
./package.sh
```

这将生成 `qi-installer-{version}-{os}-{arch}.tar.gz` 文件，适用于命令行安装。

---

**奇语言** - 让编程回归中文！🚀
