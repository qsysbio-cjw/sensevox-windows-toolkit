@echo off
REM ==========================================================
REM  sensevox-windows-toolkit - one-click install
REM  Default install dir = sibling of toolkit clone (override with INSTALL_DIR env)
REM
REM  Steps:
REM    1. Copy sensevox.py from toolkit (already patched)
REM    2. Download SenseVoice ONNX model (int8, ~239MB)
REM    3. Download GTCRN denoiser model (~536KB)
REM    4. Create venv + pip install (Aliyun mirror)
REM    5. (placeholder)
REM    6. Write default configs + generate task xml
REM
REM  Requirements:
REM    - Windows 10/11
REM    - Python 3.10+ in PATH
REM    - For CN users without VPN:
REM        set HF_MIRROR=1   uses https://hf-mirror.com  (for SenseVoice model)
REM        set GH_MIRROR=1   uses https://ghfast.top/   (for github.com/raw.githubusercontent.com)
REM      Note: the toolkit clone itself also needs the mirror, e.g.
REM        git clone https://ghfast.top/https://github.com/qsysbio-cjw/sensevox-windows-toolkit.git
REM    - Resilience switch:
REM        set MIRROR_OWN=1  pulls models from our github release v1.0-models
REM                          instead of upstream HF / GitHub (in case upstream goes down)
REM ==========================================================

set "TOOLKIT_DIR=%~dp0.."
for %%I in ("%TOOLKIT_DIR%") do set "TOOLKIT_DIR=%%~fI"
REM Default INSTALL_DIR = sibling of clone (e.g. cloned to D:\foo\sensevox-windows-toolkit\
REM => installs to D:\foo\sensevox\). Override with: set INSTALL_DIR=X:\path before running.
if not defined INSTALL_DIR set "INSTALL_DIR=%TOOLKIT_DIR%\..\sensevox"
for %%I in ("%INSTALL_DIR%") do set "INSTALL_DIR=%%~fI"
set "PIP_MIRROR=https://mirrors.aliyun.com/pypi/simple"

REM HuggingFace mirror logic
if defined HF_MIRROR (
    set "HF_BASE=https://hf-mirror.com"
    echo [INFO] Using HuggingFace mirror: hf-mirror.com
) else (
    set "HF_BASE=https://huggingface.co"
)

REM GitHub mirror logic (for CN users without VPN; covers github.com + raw.githubusercontent.com)
if defined GH_MIRROR (
    set "GH_PREFIX=https://ghfast.top/"
    echo [INFO] Using GitHub mirror prefix: ghfast.top
) else (
    set "GH_PREFIX="
)

REM Self-host mirror (use OUR github release assets instead of upstream HF/GitHub).
REM Trade-off: upstream model files might disappear / move; our release is locked to known-good bytes.
set "RELEASE_BASE=%GH_PREFIX%https://github.com/qsysbio-cjw/sensevox-windows-toolkit/releases/download/v1.0-models"
if defined MIRROR_OWN (
    set "MODEL_URL=%RELEASE_BASE%/model.onnx"
    set "TOKENS_URL=%RELEASE_BASE%/tokens.txt"
    set "GTCRN_URL=%RELEASE_BASE%/gtcrn_simple.onnx"
    echo [INFO] Using own mirror: github.com/qsysbio-cjw/sensevox-windows-toolkit/releases/v1.0-models
) else (
    set "MODEL_URL=%HF_BASE%/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/model.int8.onnx"
    set "TOKENS_URL=%HF_BASE%/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/tokens.txt"
    set "GTCRN_URL=%GH_PREFIX%https://github.com/Xiaobin-Rong/gtcrn/raw/main/checkpoints/model_trained_on_dns3.onnx"
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
    echo [INFO] %INSTALL_DIR% already exists - resuming install
    echo        Per-step skip-if-exists will preserve downloaded files.
    echo        If you want a clean reinstall: run scripts\uninstall.bat first.
)
echo Press any key to start...
pause >nul

echo.
echo === [1/6] Create install dir + assets subdir ===
mkdir "%INSTALL_DIR%" 2>nul
mkdir "%INSTALL_DIR%\assets" 2>nul
mkdir "%INSTALL_DIR%\assets\sensevoicesmallonnx" 2>nul

echo.
echo === [2/6] Copy sensevox.py from toolkit ===
if exist "%INSTALL_DIR%\sensevox.py" (
    echo [SKIP] sensevox.py already present - overwriting with toolkit copy
)
copy /y "%TOOLKIT_DIR%\sensevox.py" "%INSTALL_DIR%\sensevox.py" >nul
if not exist "%INSTALL_DIR%\sensevox.py" (
    echo [ERROR] Failed to copy sensevox.py from toolkit dir
    pause & exit /b 1
)
echo OK

echo.
echo === [3/6] Download SenseVoice ONNX model (int8, ~239MB) ===
if exist "%INSTALL_DIR%\assets\sensevoicesmallonnx\model.onnx" (
    echo [SKIP] model.onnx already present
) else (
    curl -L -o "%INSTALL_DIR%\assets\sensevoicesmallonnx\model.onnx" "%MODEL_URL%"
    if not exist "%INSTALL_DIR%\assets\sensevoicesmallonnx\model.onnx" (
        echo [ERROR] model.onnx download failed.
        echo         CN users: rerun with  set HF_MIRROR=1  then install.bat
        echo         Or use VPN/proxy.
        pause & exit /b 1
    )
)
if exist "%INSTALL_DIR%\assets\sensevoicesmallonnx\tokens.txt" (
    echo [SKIP] tokens.txt already present
) else (
    curl -L -o "%INSTALL_DIR%\assets\sensevoicesmallonnx\tokens.txt" "%TOKENS_URL%"
    if not exist "%INSTALL_DIR%\assets\sensevoicesmallonnx\tokens.txt" (
        echo [ERROR] tokens.txt download failed - model.onnx OK but tokens.txt missing.
        echo         sensevox will fail with "Tokens file not found" on startup.
        echo         CN users: rerun with  set HF_MIRROR=1  then install.bat
        echo         Or use VPN/proxy.
        pause & exit /b 1
    )
)
echo OK

echo.
echo === [4/6] Download GTCRN denoiser model (~536KB) ===
if exist "%INSTALL_DIR%\assets\gtcrn_simple.onnx" (
    echo [SKIP] gtcrn_simple.onnx already present
) else (
    curl -L -o "%INSTALL_DIR%\assets\gtcrn_simple.onnx" "%GTCRN_URL%"
    if not exist "%INSTALL_DIR%\assets\gtcrn_simple.onnx" (
        echo [WARN] GTCRN download failed, denoise feature disabled (not critical)
    )
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
echo === [6/6] Write default configs ===
REM (sensevox.py is shipped pre-patched in the toolkit; no apply_mods needed.
REM  scripts\apply_mods.py is retained for archival / re-patching a fresh upstream.)

REM Write default configs (override upstream defaults)
REM Note: must use `<nul set /p=...>file` NOT `echo|set /p=...>file`
REM   the latter redirects echo (not set /p) and writes GBK garbage on zh-CN cmd
<nul set /p=f9>"%INSTALL_DIR%\assets\hotkey.txt"
<nul set /p=True>"%INSTALL_DIR%\assets\gtcrn_config.txt"
<nul set /p=True>"%INSTALL_DIR%\assets\save_recording_config.txt"
<nul set /p=true>"%INSTALL_DIR%\assets\transcript_config.txt"
<nul set /p=false>"%INSTALL_DIR%\assets\opencc_enabled.txt"

REM Generate task scheduler XML with the actual install path injected.
REM Template uses F:\sensevox as the placeholder; literal .Replace() avoids regex pitfalls
REM (e.g. if INSTALL_DIR contains $ or backslash sequences). UTF-16 LE preserved.
powershell -NoProfile -Command "(Get-Content -Raw -Encoding Unicode '%TOOLKIT_DIR%\sensevox-task.xml').Replace('F:\sensevox', '%INSTALL_DIR%') | Set-Content -Encoding Unicode -NoNewline '%INSTALL_DIR%\sensevox-task.xml'"
if not exist "%INSTALL_DIR%\sensevox-task.xml" (
    echo [ERROR] Failed to generate sensevox-task.xml
    pause & exit /b 1
)

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
