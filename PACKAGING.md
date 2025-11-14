# 打包指南

## 概述

qi-installer 支持打包两种版本的安装包：

1. **完整版** - 包含 GUI 库支持
2. **精简版** - 不含 GUI 库（体积更小）

## 使用打包脚本

### 打包完整版（含 GUI）

```bash
cd qi-installer
./package.sh
```

这将创建包含 GUI 库的完整安装包：
- 文件名: `qi-installer-{version}-{os}-{arch}.tar.gz`
- 包含: qi 编译器 + libqi_compiler.a + libqi_gui.a

### 打包精简版（不含 GUI）

```bash
cd qi-installer
./package.sh --no-gui
```

这将创建不含 GUI 库的精简安装包：
- 文件名: `qi-installer-{version}-{os}-{arch}-nogui.tar.gz`
- 包含: qi 编译器 + libqi_compiler.a

## 版本差异

### 完整版
- **优点**:
  - 支持所有功能，包括图形化界面
  - 可使用 `标准库.图形化` 模块
- **缺点**:
  - 体积较大（约 200MB+）
  - 依赖系统图形库（macOS/Linux/Windows GUI 框架）

### 精简版
- **优点**:
  - 体积小（约 15-20MB）
  - 无额外系统依赖
  - 适合服务器环境
- **缺点**:
  - 不支持图形化功能
  - 无法使用 `标准库.图形化` 模块

## 安装行为

两个版本的安装脚本 (`install.sh` / `install.bat`) 都会自动检测 GUI 库：

- **如果找到 GUI 库**: 显示 "检测到 GUI 库支持"，并安装
- **如果未找到 GUI 库**: 显示警告 "未检测到 GUI 库 (图形化功能将不可用)"，继续安装其他组件

## 推荐使用场景

### 使用完整版的场景
- 桌面应用开发
- GUI 程序开发
- 需要完整功能的开发环境
- 教学和演示

### 使用精简版的场景
- 服务器部署
- CI/CD 环境
- 命令行工具开发
- 容器/Docker 环境
- 存储空间有限的环境

## 构建示例

```bash
# 在 macOS 上打包
cd qi-installer

# 完整版
./package.sh
# 生成: qi-installer-0.1.0-darwin-arm64.tar.gz (约 200MB)

# 精简版
./package.sh --no-gui
# 生成: qi-installer-0.1.0-darwin-arm64-nogui.tar.gz (约 15MB)
```

## 技术细节

### 编译命令差异

**完整版**:
```bash
cargo build --workspace --release
```

**精简版**:
```bash
cargo build -p qi-compiler --release
```

### 包含的文件

**完整版**:
- bin/qi
- lib/libqi_compiler.a
- lib/libqi_gui.a ← GUI 库
- install.sh
- uninstall.sh
- README.md

**精简版**:
- bin/qi
- lib/libqi_compiler.a
- install.sh
- uninstall.sh
- README.md

## 常见问题

### Q: 如何知道用户安装了哪个版本？

A: 用户可以检查安装目录：
```bash
# macOS/Linux
ls -la /usr/local/lib/qi/

# Windows
dir "C:\Program Files\Qi\lib\"
```

如果存在 `libqi_gui.a` 或 `qi_gui.lib`，则是完整版。

### Q: 可以先安装精简版，后续再添加 GUI 库吗？

A: 可以。只需：
1. 下载完整版安装包
2. 手动复制 GUI 库到安装目录
   ```bash
   sudo cp libqi_gui.a /usr/local/lib/qi/
   ```

### Q: GUI 库大约占用多少空间？

A: 约 180-200MB（静态链接了所有依赖）

## 发布清单

发布新版本时，建议同时提供两个版本：

- [ ] qi-installer-{version}-{os}-{arch}.tar.gz (完整版)
- [ ] qi-installer-{version}-{os}-{arch}-nogui.tar.gz (精简版)
- [ ] 更新 Release Notes，说明两个版本的区别
- [ ] 测试两个版本的安装和卸载流程
- [ ] 验证精简版确实不包含 GUI 库
- [ ] 验证完整版的 GUI 功能正常工作
