# 奇语言编译器 Windows MSI 打包脚本
# 使用 WiX Toolset 生成 .msi 安装包
# 需要先安装 WiX Toolset: https://wixtoolset.org/

param(
    [string]$WixPath = "C:\Program Files (x86)\WiX Toolset v3.11\bin",
    [switch]$NoGui
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[信息] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[成功] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[错误] $Message" -ForegroundColor Red
}

Write-Info "=================================================="
Write-Info "       奇语言编译器 Windows MSI 打包工具"
Write-Info "=================================================="
Write-Host ""

# 检查是否包含 GUI 库
$IncludeGui = -not $NoGui
if ($NoGui) {
    Write-Info "不包含 GUI 库（使用 -NoGui 参数）"
} else {
    Write-Info "将包含 GUI 库（使用 -NoGui 参数可排除）"
}
Write-Host ""

# 检查 WiX Toolset
$candle = Join-Path $WixPath "candle.exe"
$light = Join-Path $WixPath "light.exe"

if (-not (Test-Path $candle)) {
    Write-Error-Custom "找不到 WiX Toolset"
    Write-Error-Custom "请从 https://wixtoolset.org/ 下载并安装 WiX Toolset"
    Write-Error-Custom "或指定 WiX 安装路径: .\build-windows-msi.ps1 -WixPath 'C:\path\to\wix\bin'"
    exit 1
}

Write-Success "找到 WiX Toolset: $WixPath"
Write-Host ""

# 获取脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = Join-Path $ScriptDir ".."
$QiDir = Join-Path $WorkspaceDir "qi"

# 编译 Rust 项目
Write-Info "编译 release 版本..."
Push-Location $WorkspaceDir
if ($IncludeGui) {
    Write-Info "构建包含 GUI 的完整版本..."
    cargo build --workspace --release
} else {
    Write-Info "构建不含 GUI 的版本..."
    cargo build -p qi-compiler --release
}
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "编译失败"
    Pop-Location
    exit 1
}
Pop-Location

Write-Success "编译完成"
Write-Host ""

# 检查编译产物
$QiBinary = Join-Path $WorkspaceDir "target\release\qi.exe"
$QiLib = Join-Path $WorkspaceDir "qi-runtime\target\release\qi_runtime.lib"
$QiGuiLib = Join-Path $WorkspaceDir "target\release\qi_gui.lib"

if (-not (Test-Path $QiBinary)) {
    Write-Error-Custom "找不到 qi.exe: $QiBinary"
    exit 1
}

if (-not (Test-Path $QiLib)) {
    Write-Error-Custom "找不到 qi_runtime.lib: $QiLib"
    exit 1
}

# 检查 GUI 库（可选）
$HasGui = $false
if ($IncludeGui -and (Test-Path $QiGuiLib)) {
    $HasGui = $true
    Write-Info "检测到 GUI 库"
}

# 复制文件到打包目录
Write-Info "准备打包文件..."
$BinDir = Join-Path $ScriptDir "bin"
$LibDir = Join-Path $ScriptDir "lib"

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path $LibDir | Out-Null

Copy-Item $QiBinary -Destination (Join-Path $BinDir "qi.exe") -Force
Copy-Item $QiLib -Destination (Join-Path $LibDir "qi_runtime.lib") -Force

# 复制 GUI 库（如果存在）
if ($HasGui) {
    Copy-Item $QiGuiLib -Destination (Join-Path $LibDir "qi_gui.lib") -Force
    Write-Info "已复制 GUI 库"
}

Write-Success "文件准备完成"
Write-Host ""

# 创建许可证 RTF 文件（WiX 需要 RTF 格式）
Write-Info "创建许可证文件..."
$LicenseRtf = Join-Path $ScriptDir "license.rtf"
$LicenseContent = @"
{\rtf1\ansi\ansicpg936\deff0\nouicompat\deflang2052
{\fonttbl{\f0\fnil\fcharset134 SimSun;}}
{\*\generator Riched20 10.0.19041}\viewkind4\uc1
\pard\sa200\sl276\slmult1\f0\fs22\lang2052
\b\fs28 奇语言编译器许可证\b0\fs22\par
\par
版权所有 (c) 2024 奇语言项目\par
\par
允许任何人免费使用此软件。\par
\par
此软件按"原样"提供，不提供任何明示或暗示的保证。\par
}
"@
Set-Content -Path $LicenseRtf -Value $LicenseContent -Encoding ASCII

Write-Success "许可证文件创建完成"
Write-Host ""

# 使用 candle.exe 编译 WXS 文件
Write-Info "编译 WiX 源文件..."
$WxsFile = Join-Path $ScriptDir "qi-installer.wxs"
$WixObjFile = Join-Path $ScriptDir "qi-installer.wixobj"

& $candle -arch x64 -out $WixObjFile $WxsFile
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "WiX 编译失败"
    exit 1
}

Write-Success "WiX 编译完成"
Write-Host ""

# 使用 light.exe 链接生成 MSI
Write-Info "生成 MSI 安装包..."
# 根据是否包含 GUI 库添加后缀
if ($HasGui) {
    $MsiFile = Join-Path $ScriptDir "qi-installer-0.1.0-x64.msi"
} else {
    $MsiFile = Join-Path $ScriptDir "qi-installer-0.1.0-x64-nogui.msi"
}

& $light -out $MsiFile -ext WixUIExtension $WixObjFile
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "MSI 生成失败"
    exit 1
}

# 清理临时文件
Remove-Item $WixObjFile -ErrorAction SilentlyContinue
Remove-Item $LicenseRtf -ErrorAction SilentlyContinue

if (Test-Path $MsiFile) {
    $MsiSize = (Get-Item $MsiFile).Length / 1MB
    $MsiSizeStr = "{0:N2} MB" -f $MsiSize
    $MsiFileName = Split-Path -Leaf $MsiFile

    Write-Success "MSI 安装包创建成功！"
    Write-Host ""
    Write-Info "  文件名: $MsiFileName"
    Write-Info "  大小:   $MsiSizeStr"
    Write-Info "  路径:   $MsiFile"
    Write-Host ""
    Write-Info "=================================================="
    Write-Success "打包完成！"
    Write-Info "=================================================="
    Write-Host ""
    Write-Info "用户可以双击 .msi 文件进行图形化安装"
    Write-Info "或使用命令行安装: msiexec /i $MsiFileName"
} else {
    Write-Error-Custom "创建 MSI 安装包失败"
    exit 1
}
