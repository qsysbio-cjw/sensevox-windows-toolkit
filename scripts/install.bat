@echo off
REM ==========================================================
REM  sensevox-windows-toolkit - one-click install to F:\sensevox\
REM
REM  Steps:
REM    1. Pull upstream sensevox.py
REM    2. Download SenseVoice ONNX model (int8, ~239MB)
REM    3. Download GTCRN denoiser model (~536KB)
REM    4. Create venv + pip install (Aliyun mirror)
REM    5. Run apply_mods.py
REM    6. Write default configs
REM
REM  Requirements:
REM    - Windows 10/11
REM    - Python 3.10+ in PATH
REM    - For CN users: HuggingFace requires proxy or hf-mirror
REM      Set HF_MIRROR=1 to use https://hf-mirror.com instead
REM ==========================================================

set "INSTALL_DIR=F:\sensevox"
set "TOOLKIT_DIR=%~dp0.."
set "PIP_MIRROR=https://mirrors.aliyun.com/pypi/simple"

REM HuggingFace mirror logic
if defined HF_MIRROR (
    set "HF_BASE=https://hf-mirror.com"
    echo [INFO] Using HuggingFace mirror: hf-mirror.com
) else (
    set "HF_BASE=https://huggingface.co"
)

echo.
echo ==========================================
echo  sensevox-windows-toolkit installer
echo ==========================================
echo Install to: %INSTALL_DIR%
echo Toolkit:    %TOOLKIT_DIR%
echo Python:
python --version 2>&1
echo HF source:  %HF_BASE%
echo.
if exist "%INSTALL_DIR%\sensevox.py" (
    echo [WARN] %INSTALL_DIR%\sensevox.py already exists.
    echo        Continuing will overwrite. Backup first if needed.
    set /p ok=Type Y then Enter to continue:
    if /i not "%ok%"=="Y" exit /b 0
)
echo Press any key to start...
pause >nul

echo.
echo === [1/6] Create install dir + assets subdir ===
mkdir "%INSTALL_DIR%" 2>nul
mkdir "%INSTALL_DIR%\assets" 2>nul
mkdir "%INSTALL_DIR%\assets\sensevoicesmallonnx" 2>nul

echo.
echo === [2/6] Pull upstream sensevox.py ===
curl -L -o "%INSTALL_DIR%\sensevox.py" "https://raw.githubusercontent.com/dapanggougou/sensevox/main/new/sensevox.py"
if not exist "%INSTALL_DIR%\sensevox.py" (
    echo [ERROR] Failed to fetch source. Check network.
    pause & exit /b 1
)
echo OK

echo.
echo === [3/6] Download SenseVoice ONNX model (int8, ~239MB) ===
echo (Upstream sensevox.zip does NOT bundle model, must fetch separately)
curl -L -o "%INSTALL_DIR%\assets\sensevoicesmallonnx\model.onnx" ^
    "%HF_BASE%/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/model.int8.onnx"
curl -L -o "%INSTALL_DIR%\assets\sensevoicesmallonnx\tokens.txt" ^
    "%HF_BASE%/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/tokens.txt"
if not exist "%INSTALL_DIR%\assets\sensevoicesmallonnx\model.onnx" (
    echo [ERROR] model.onnx download failed.
    echo         CN users: rerun with  set HF_MIRROR=1  then install.bat
    echo         Or use VPN/proxy.
    pause & exit /b 1
)
if not exist "%INSTALL_DIR%\assets\sensevoicesmallonnx\tokens.txt" (
    echo [ERROR] tokens.txt download failed (model.onnx is fine but tokens.txt missing).
    echo         sensevox will fail with "Tokens file not found" on startup.
    echo         CN users: rerun with  set HF_MIRROR=1  then install.bat
    echo         Or use VPN/proxy.
    pause & exit /b 1
)
echo OK

echo.
echo === [4/6] Download GTCRN denoiser model (~536KB) ===
curl -L -o "%INSTALL_DIR%\assets\gtcrn_simple.onnx" ^
    "https://github.com/Xiaobin-Rong/gtcrn/raw/main/checkpoints/model_trained_on_dns3.onnx"
if not exist "%INSTALL_DIR%\assets\gtcrn_simple.onnx" (
    echo [WARN] GTCRN download failed, denoise feature disabled (not critical)
)

echo.
echo === [5/6] Create venv + install deps ===
cd /d "%INSTALL_DIR%"
python -m venv venv
if errorlevel 1 ( echo [ERROR] venv creation failed & pause & exit /b 1 )

"%INSTALL_DIR%\venv\Scripts\python.exe" -m pip install --upgrade pip -i %PIP_MIRROR%
"%INSTALL_DIR%\venv\Scripts\python.exe" -m pip install -r "%TOOLKIT_DIR%\requirements.txt" -i %PIP_MIRROR%
if errorlevel 1 ( echo [ERROR] pip install failed & pause & exit /b 1 )
echo OK

echo.
echo === [6/6] Apply patches + write default configs ===
"%INSTALL_DIR%\venv\Scripts\python.exe" "%TOOLKIT_DIR%\scripts\apply_mods.py" "%INSTALL_DIR%\sensevox.py"

REM Write default configs (override upstream defaults)
REM Note: must use `<nul set /p=...>file` NOT `echo|set /p=...>file`
REM   the latter redirects echo (not set /p) and writes GBK garbage on zh-CN cmd
<nul set /p=f9>"%INSTALL_DIR%\assets\hotkey.txt"
<nul set /p=True>"%INSTALL_DIR%\assets\gtcrn_config.txt"
<nul set /p=True>"%INSTALL_DIR%\assets\save_recording_config.txt"
<nul set /p=true>"%INSTALL_DIR%\assets\transcript_config.txt"
<nul set /p=false>"%INSTALL_DIR%\assets\opencc_enabled.txt"

REM Copy task scheduler template
copy /y "%TOOLKIT_DIR%\sensevox-task.xml" "%INSTALL_DIR%\sensevox-task.xml" >nul

echo.
echo ==========================================
echo  [OK] Installation complete
echo ==========================================
echo.
echo Next steps:
echo   1. Test run:        scripts\run.bat
echo   2. Register service: scripts\setup-service.bat (needs admin)
echo.
pause
