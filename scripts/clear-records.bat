@echo off
echo 即将删除以下文件夹里的所有内容:
echo    F:\sensevox\录音\
echo    F:\sensevox\转写记录\
echo.
set /p ok=确认删除请输入 Y 再回车(其它键取消):
if /i not "%ok%"=="Y" ( echo 已取消。& pause & exit /b )
del /q "F:\sensevox\录音\*" 2>nul
del /q "F:\sensevox\转写记录\*" 2>nul
echo 完成,已清空。
pause
