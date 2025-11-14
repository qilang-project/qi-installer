@echo off
REM 奇语言编译器安装脚本 (Windows)
REM Qi Language Compiler Installer

setlocal enabledelayedexpansion

echo ================================================
echo        奇语言编译器安装程序
echo        Qi Language Compiler Installer
echo ================================================
echo.

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 设置安装目录
set INSTALL_DIR=%ProgramFiles%\Qi
set BIN_DIR=%INSTALL_DIR%\bin
set LIB_DIR=%INSTALL_DIR%\lib

REM 检查必要文件
echo [信息] 检查安装文件...

set QI_BINARY=%SCRIPT_DIR%bin\qi.exe
set QI_LIB=%SCRIPT_DIR%lib\qi_compiler.lib
set QI_GUI_LIB=%SCRIPT_DIR%lib\qi_gui.lib

if not exist "%QI_BINARY%" (
    echo [错误] 找不到 qi.exe 文件: %QI_BINARY%
    pause
    exit /b 1
)

if not exist "%QI_LIB%" (
    echo [错误] 找不到 qi_compiler.lib 库文件: %QI_LIB%
    pause
    exit /b 1
)

REM GUI 库是可选的
set HAS_GUI=false
if exist "%QI_GUI_LIB%" (
    set HAS_GUI=true
    echo [信息] 检测到 GUI 库支持
) else (
    echo [警告] 未检测到 GUI 库 ^(图形化功能将不可用^)
)

echo [成功] 所有必要文件检查通过
echo.

REM 显示安装信息
echo [信息] 安装位置:
echo   可执行文件: %BIN_DIR%\qi.exe
echo   运行时库:   %LIB_DIR%\qi_compiler.lib
if "%HAS_GUI%"=="true" (
    echo   GUI 库:     %LIB_DIR%\qi_gui.lib
)
echo.

REM 询问用户确认
set /p CONFIRM="是否继续安装? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo [信息] 安装已取消
    pause
    exit /b 0
)

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] 需要管理员权限才能安装
    echo [信息] 请右键点击此脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

REM 创建安装目录
echo [信息] 创建安装目录...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

REM 复制文件
echo [信息] 复制可执行文件...
copy /Y "%QI_BINARY%" "%BIN_DIR%\qi.exe" >nul
if %errorLevel% neq 0 (
    echo [错误] 复制可执行文件失败
    pause
    exit /b 1
)

echo [信息] 复制运行时库...
copy /Y "%QI_LIB%" "%LIB_DIR%\qi_compiler.lib" >nul
if %errorLevel% neq 0 (
    echo [错误] 复制运行时库失败
    pause
    exit /b 1
)

REM 复制 GUI 库（如果存在）
if "%HAS_GUI%"=="true" (
    echo [信息] 复制 GUI 库...
    copy /Y "%QI_GUI_LIB%" "%LIB_DIR%\qi_gui.lib" >nul
    if %errorLevel% neq 0 (
        echo [错误] 复制 GUI 库失败
        pause
        exit /b 1
    )
)

REM 添加到 PATH 环境变量
echo [信息] 添加到 PATH 环境变量...
setx PATH "%PATH%;%BIN_DIR%" /M >nul 2>&1
if %errorLevel% neq 0 (
    echo [警告] 自动添加到 PATH 失败，请手动添加
    echo [信息] 请将以下路径添加到系统 PATH 环境变量:
    echo   %BIN_DIR%
) else (
    echo [成功] 已添加到 PATH 环境变量
)

echo.
echo [成功] 奇语言编译器安装成功！
echo.
echo [信息] 使用方法:
echo   qi run ^<文件.qi^>       - 运行奇语言程序
echo   qi compile ^<文件.qi^>   - 编译奇语言程序
echo   qi check ^<文件.qi^>     - 检查语法
echo   qi --help              - 查看帮助
echo.
echo [注意] 请重新打开命令提示符窗口以使用 qi 命令
echo.
echo ================================================
echo [成功] 安装完成！
echo ================================================
echo.
pause
