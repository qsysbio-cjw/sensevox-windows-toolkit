@echo off
REM Clear sensevox audio records and transcripts
REM (Chinese folder names are written below in GBK; cmd handles them fine)

set "AUDIO_DIR=F:\sensevox\Â¼Òô"
set "TEXT_DIR=F:\sensevox\×ªÐ´¼ÇÂ¼"

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
