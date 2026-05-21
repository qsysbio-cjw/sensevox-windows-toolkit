@echo off
REM ==========================================================
REM  sensevox runner - launch with venv pythonw (no console)
REM  Window opens auto-running the listener, press F9 to use.
REM ==========================================================

set "INSTALL_DIR=F:\sensevox"

REM Kill old instances to avoid double hotkey grab
taskkill /f /im pythonw.exe >nul 2>&1
timeout /t 1 >nul

cd /d "%INSTALL_DIR%"
start "" "%INSTALL_DIR%\venv\Scripts\pythonw.exe" "%INSTALL_DIR%\sensevox.py"
