@echo off
chcp 65001 >nul
REM ==========================================================
REM  sensevox runner  -  用 venv pythonw 启动（不带控制台窗口）
REM  双击启动；启动后窗口自动跑 listener，按 F9 即用。
REM ==========================================================

set "INSTALL_DIR=F:\sensevox"

REM 先 kill 旧实例（避免双开抢热键）
taskkill /f /im pythonw.exe >nul 2>&1
timeout /t 1 >nul

cd /d "%INSTALL_DIR%"
start "" "%INSTALL_DIR%\venv\Scripts\pythonw.exe" "%INSTALL_DIR%\sensevox.py"
