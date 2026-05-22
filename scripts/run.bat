@echo off
REM ==========================================================
REM  sensevox runner - launch with venv pythonw (no console)
REM  Window opens auto-running the listener, press F9 to use.
REM ==========================================================

set "TOOLKIT_DIR=%~dp0.."
if not defined INSTALL_DIR set "INSTALL_DIR=%TOOLKIT_DIR%\..\sensevox"
for %%I in ("%INSTALL_DIR%") do set "INSTALL_DIR=%%~fI"

REM Kill old instances to avoid double hotkey grab
taskkill /f /im pythonw.exe >nul 2>&1
timeout /t 1 >nul

cd /d "%INSTALL_DIR%"
start "" "%INSTALL_DIR%\venv\Scripts\pythonw.exe" "%INSTALL_DIR%\sensevox.py"
