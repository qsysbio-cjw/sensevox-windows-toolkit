@echo off
set "TOOLKIT_DIR=%~dp0.."
if not defined INSTALL_DIR set "INSTALL_DIR=%TOOLKIT_DIR%\..\sensevox"
for %%I in ("%INSTALL_DIR%") do set "INSTALL_DIR=%%~fI"

echo ============================================================
echo  Uninstall sensevox (app + managed service)
echo ============================================================
echo Will remove:
echo   - Scheduled task "sensevox" (autostart service)
echo   - Running sensevox processes
echo   - Startup\sensevox-autostart.bat (if present)
echo   - %INSTALL_DIR%  (installed app)
echo   - %INSTALL_DIR%.bak  (if exists)
echo   - %TEMP%\sensevox.zip  (download cache)
echo.
set /p ok=Type Y then Enter to confirm:
if /i not "%ok%"=="Y" ( echo Cancelled. & pause & exit /b )

echo Stopping service + processes...
schtasks /end /tn "sensevox" >nul 2>&1
schtasks /delete /tn "sensevox" /f >nul 2>&1
powershell -NoProfile -Command "$dir='%INSTALL_DIR%'; Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like \"$dir\*\" } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1
taskkill /f /im "sensevox.exe" >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\sensevox-autostart.bat" >nul 2>&1
ping -n 3 127.0.0.1 >nul

echo Deleting installed files...
rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
rmdir /s /q "%INSTALL_DIR%.bak" >nul 2>&1
del /q "%TEMP%\sensevox.zip" >nul 2>&1

echo.
echo Done. App + service removed.
pause
