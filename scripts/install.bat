@echo off
chcp 65001 >nul
REM ==========================================================
REM  sensevox-windows-toolkit  -  一键安装到 F:\sensevox\
REM
REM  做的事：
REM   1. 拉上游 sensevox 源码
REM   2. 下 SenseVoice ONNX 模型（int8, ~239MB）
REM   3. 下 GTCRN 降噪模型（~536KB）
REM   4. 建 Python venv + 装依赖（用阿里云镜像，国内更稳）
REM   5. 跑 apply_mods.py 打补丁
REM   6. 写默认配置（hotkey=F9 / GTCRN 开 / 保存录音 开 / 转写日志 开）
REM
REM  前置：
REM   - Windows 10/11
REM   - Python 3.10+  装好且在 PATH（cmd 输 python --version 能出版本）
REM   - 网络可达 raw.githubusercontent.com 和 huggingface.co
REM     （hf 模型下载约 240MB，国内用户建议先配 hf 镜像或挂代理）
REM ==========================================================

set "INSTALL_DIR=F:\sensevox"
set "TOOLKIT_DIR=%~dp0.."
set "PIP_MIRROR=https://mirrors.aliyun.com/pypi/simple"

echo.
echo ==========================================
echo  sensevox-windows-toolkit installer
echo ==========================================
echo 安装位置: %INSTALL_DIR%
echo 工具箱:   %TOOLKIT_DIR%
echo Python:
python --version 2>&1
echo.
if exist "%INSTALL_DIR%\sensevox.py" (
    echo [警告] %INSTALL_DIR% 已存在 sensevox.py
    echo 继续会覆盖。建议先 backup 或运行 uninstall.bat。
    set /p ok=继续？输入 Y 回车确认:
    if /i not "%ok%"=="Y" exit /b 0
)
echo 准备就绪，按任意键开始...
pause >nul

echo.
echo === [1/6] 创建安装目录 + assets 子目录 ===
mkdir "%INSTALL_DIR%" 2>nul
mkdir "%INSTALL_DIR%\assets" 2>nul
mkdir "%INSTALL_DIR%\assets\sensevoicesmallonnx" 2>nul

echo.
echo === [2/6] 拉上游 sensevox 源码 ===
curl -L -o "%INSTALL_DIR%\sensevox.py" "https://raw.githubusercontent.com/dapanggougou/sensevox/main/new/sensevox.py"
if not exist "%INSTALL_DIR%\sensevox.py" (
    echo [错误] 拉源码失败，请检查网络
    pause & exit /b 1
)
echo OK

echo.
echo === [3/6] 下 SenseVoice ONNX 模型（int8, ~239MB）===
echo （上游 sensevox.zip 故意不含模型，必须单独下）
curl -L -o "%INSTALL_DIR%\assets\sensevoicesmallonnx\model.onnx" ^
    "https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/model.int8.onnx"
curl -L -o "%INSTALL_DIR%\assets\sensevoicesmallonnx\tokens.txt" ^
    "https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/tokens.txt"
if not exist "%INSTALL_DIR%\assets\sensevoicesmallonnx\model.onnx" (
    echo [错误] 模型下载失败，请检查网络（国内建议挂代理或用 hf-mirror）
    pause & exit /b 1
)
echo OK

echo.
echo === [4/6] 下 GTCRN 降噪模型（~536KB）===
curl -L -o "%INSTALL_DIR%\assets\gtcrn_simple.onnx" ^
    "https://github.com/Xiaobin-Rong/gtcrn/raw/main/checkpoints/model_trained_on_dns3.onnx"
if not exist "%INSTALL_DIR%\assets\gtcrn_simple.onnx" (
    echo [警告] GTCRN 下载失败，降噪功能将不可用（不影响主功能）
)

echo.
echo === [5/6] 建 venv + 装依赖 ===
cd /d "%INSTALL_DIR%"
python -m venv venv
if errorlevel 1 ( echo [错误] venv 建失败 & pause & exit /b 1 )

"%INSTALL_DIR%\venv\Scripts\python.exe" -m pip install --upgrade pip -i %PIP_MIRROR%
"%INSTALL_DIR%\venv\Scripts\python.exe" -m pip install -r "%TOOLKIT_DIR%\requirements.txt" -i %PIP_MIRROR%
if errorlevel 1 ( echo [错误] 依赖装失败 & pause & exit /b 1 )
echo OK

echo.
echo === [6/6] 打补丁 + 写默认配置 ===
"%INSTALL_DIR%\venv\Scripts\python.exe" "%TOOLKIT_DIR%\scripts\apply_mods.py" "%INSTALL_DIR%\sensevox.py"

REM 写默认配置（覆盖上游默认值）
> "%INSTALL_DIR%\assets\hotkey.txt" echo|set /p=f9
> "%INSTALL_DIR%\assets\gtcrn_config.txt" echo|set /p=True
> "%INSTALL_DIR%\assets\save_recording_config.txt" echo|set /p=True
> "%INSTALL_DIR%\assets\transcript_config.txt" echo|set /p=true
> "%INSTALL_DIR%\assets\opencc_enabled.txt" echo|set /p=false

REM 拷任务计划模板（注册自启用）
copy /y "%TOOLKIT_DIR%\sensevox-task.xml" "%INSTALL_DIR%\sensevox-task.xml" >nul

echo.
echo ==========================================
echo  ✅ 安装完成
echo ==========================================
echo.
echo 下一步：
echo   1. 测试运行：  双击  scripts\run.bat
echo   2. 注册自启：  以管理员身份运行  scripts\setup-service.bat
echo.
pause
