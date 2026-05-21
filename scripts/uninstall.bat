@echo off
echo ============================================================
echo  Uninstall sensevox (app + managed service)
echo  KEEPS F:\sensevox-build (build artifacts)
echo ============================================================
echo Will remove:
echo   - Scheduled task "sensevox" (autostart service)
echo   - Running sensevox processes (old + new)
echo   - Startup\sensevox-autostart.bat (if present)
echo   - C:\Users\Public\sensevox  (early leftover)
echo   - F:\sensevox and F:\sensevox.bak  (installed app)
echo   - %TEMP%\sensevox.zip  (download cache)
echo Keeps: F:\sensevox-build
echo.
set /p ok=Type Y then Enter to confirm:
if /i not "%ok%"=="Y" ( echo Cancelled. & pause & exit /b )

echo Stopping service + processes...
schtasks /end /tn "sensevox" >nul 2>&1
schtasks /delete /tn "sensevox" /f >nul 2>&1
powershell -NoProfile -Command "Get-Process -ErrorAction SilentlyContinue | Where-Object { ($_.Path -like 'F:\sensevox\*') -or ($_.Path -like 'C:\Users\Public\sensevox\*') } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1
taskkill /f /im "sensevox.exe" >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\sensevox-autostart.bat" >nul 2>&1
ping -n 3 127.0.0.1 >nul

echo Deleting installed files...
rmdir /s /q "C:\Users\Public\sensevox" >nul 2>&1
rmdir /s /q "F:\sensevox" >nul 2>&1
rmdir /s /q "F:\sensevox.bak" >nul 2>&1
del /q "%TEMP%\sensevox.zip" >nul 2>&1

echo.
echo Done. App + service removed. F:\sensevox-build kept.
pause
