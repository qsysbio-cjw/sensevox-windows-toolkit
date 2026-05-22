@echo off
REM ==========================================================
REM  sensevox runner - launch with venv pythonw (no console)
REM  Window opens auto-running the listener, press F9 to use.
REM ==========================================================

set "TOOLKIT_DIR=%~dp0.."
if not defined INSTALL_DIR set "INSTALL_DIR=%TOOLKIT_DIR%\..\sensevox"
for %%I in ("%INSTALL_DIR%") do set "INSTALL_DIR=%%~fI"

REM Kill old sensevox instances to avoid double hotkey grab.
REM Filter by INSTALL_DIR path so we don't murder unrelated pythonw GUIs
REM (Spyder, other wx apps, etc.) that the user may be running.
powershell -NoProfile -Command "$dir='%INSTALL_DIR%'; Get-Process pythonw -EA SilentlyContinue | Where-Object { $_.Path -like \"$dir\*\" } | Stop-Process -Force -EA SilentlyContinue" >nul 2>&1
timeout /t 1 >nul

cd /d "%INSTALL_DIR%"
start "" "%INSTALL_DIR%\venv\Scripts\pythonw.exe" "%INSTALL_DIR%\sensevox.py"
