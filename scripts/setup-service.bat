@echo off
echo ===================================================
echo   Register sensevox as a managed autostart service
echo   (starts at logon, auto-restarts if it crashes)
echo ===================================================
echo.
echo IMPORTANT: close any running sensevox window FIRST,
echo            then this will start a fresh managed one.
echo.
pause

REM remove the older simple startup launcher if it exists (avoid double-launch)
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\sensevox-autostart.bat" 2>nul

REM register / overwrite the scheduled task from the XML
schtasks /create /tn "sensevox" /xml "F:\sensevox\sensevox-task.xml" /f
if errorlevel 1 (
  echo.
  echo [!] Failed to register. Try: right-click this file -^> Run as administrator.
  pause
  exit /b 1
)

echo.
echo [OK] Task "sensevox" registered. Starting it now...
schtasks /run /tn "sensevox"
echo.
echo Done. It now auto-starts at login and restarts on crash.
echo To remove later:  schtasks /delete /tn "sensevox" /f
echo.
pause
