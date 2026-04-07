@echo off
chcp 65001 >nul
echo ================================================
echo    AI PMO Web Server 启动器
echo ================================================
echo.

REM 检查 Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 Python！
    echo.
    echo 请先安装 Python: https://www.python.org/downloads/
    echo 安装时勾选 "Add Python to PATH"
    echo.
    pause
    exit /b 1
)

echo [✓] Python 已安装
echo.

REM 进入目录
cd /d "%~dp0"
echo [✓] 目录：%CD%
echo.

REM 检查依赖
echo 正在检查依赖...
pip show flask >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 安装 Flask...
    pip install -r requirements.txt
    echo.
)

echo ================================================
echo    服务器启动中...
echo ================================================
echo.
echo 🌐 访问地址：http://localhost:5000
echo 📊 API 端点：http://localhost:5000/api/projects
echo.
echo 按 Ctrl+C 停止服务器
echo.

python server.py

pause
