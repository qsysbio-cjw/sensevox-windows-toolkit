@echo off
REM Clear sensevox audio records and transcripts
REM (Chinese folder names are written below in GBK; cmd handles them fine)

set "TOOLKIT_DIR=%~dp0.."
if not defined INSTALL_DIR set "INSTALL_DIR=%TOOLKIT_DIR%\..\sensevox"
for %%I in ("%INSTALL_DIR%") do set "INSTALL_DIR=%%~fI"
set "AUDIO_DIR=%INSTALL_DIR%\¼��"
set "TEXT_DIR=%INSTALL_DIR%\תд��¼"

echo Will delete files in:
echo   %AUDIO_DIR%\
echo   %TEXT_DIR%\
echo.
set /p ok=Type Y then Enter to confirm:
if /i not "%ok%"=="Y" ( echo Cancelled & pause & exit /b )

del /q "%AUDIO_DIR%\*" 2>nul
del /q "%TEXT_DIR%\*" 2>nul
echo.
echo Done.
pause
