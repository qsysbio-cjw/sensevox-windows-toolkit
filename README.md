# sensevox-windows-toolkit

把 [sensevox](https://github.com/dapanggougou/sensevox)（基于 SenseVoice 的 Windows 离线中英语音输入）从「能跑」变成「**开机自启 + 崩溃自愈 + 转写日志的省心常驻服务**」的一套脚本、补丁与踩坑经验。

> 📝 **关于上游与本仓库**：上游 sensevox 没有 LICENSE。本工具是个人/小圈子自用工具，为防上游失效造成装机断链，仓库内含一份已打补丁的 `sensevox.py`（基于上游 `dapanggougou/sensevox` 改造，12 处增强见 `scripts/apply_mods.py`）。模型文件仍从 sherpa-onnx / GTCRN 上游下载。版权归各原作者所有，本仓库仅作个人工具便利使用，不用于商业分发。

---

## 这套东西给你什么

- **一键安装**：copy 已打补丁的 sensevox.py → 下模型 → 建 venv → 写默认配置
- **12 处增强（diff 见 `scripts/apply_mods.py`）**：
  - 单次录音上限 **30s → 120s**（上游写死，GUI 改不了）
  - **按天转写日志**：每句即时写入 `转写记录/YYYY-MM-DD.md`（UTF-8，`- [HH:MM:SS] 文本`），可开关
  - **保留全部标点**（上游会把短句末尾标点删掉，本补丁让识别原文 1:1 落地）
  - **启动后自动激活 listener**（上游需手动点 Start 按钮才开始监听热键）
  - 转写日志路径在冻结/非冻结模式下都稳定指向 app 同级目录
- **托管服务**：Windows 任务计划程序，开机自启 + 崩溃 1 分钟内自动重启（等价 systemd `Restart=on-failure`）
- **小工具**：清空录音/转写、卸载、临时启动

---

## 真正值钱的部分：我们踩过的坑

1. **GitHub 的 `sensevox.zip`（36MB）不含模型。** 上游 README 写"内置 200MB"指的是网盘版。症状：启动报 `Model file not found ... model.onnx`。**解法**：下 int8 模型 `model.int8.onnx`（239MB）改名 `model.onnx` 放到 `assets/sensevoicesmallonnx/`。
   `install.bat` 已经把这步自动化。
2. **热键千万别用修饰键。** 全局键盘钩子挂在 Alt/Ctrl/Shift（或空格）上，一旦没正确释放会让修饰键「卡死」→ 中文打不了、按钮失灵、终端错乱，要重启才好。**用 F9/F10 这类非修饰、非打字键。** 出事逃生：任务管理器结束进程即解钩子。
   `install.bat` 默认热键写 **F9**。
3. **它是 CPU-only，别折腾 GPU。** 作者刻意不上显卡（通用性 + 包体积）。按住即说场景里 SenseVoice int8 在 CPU 上 ~70ms，GPU 没收益，笔记本上还白耗电。
4. **没有内置开机自启 / 托盘。** 用任务计划程序做真·托管（自启 + 崩溃重启）；想隐藏窗口可手动最小化（sensevox 源码层面没托盘支持）。
5. **30s 硬上限**（`MAX_RECORD_SECONDS`），GUI 不可调；本补丁提到 120s。真要几分钟长录的正解是 VAD 分段（本补丁未做）——SenseVoice 偏好短段，单次几分钟会变慢、可能掉准确率。
6. **PyInstaller 打包的坑**：上游用 PyInstaller 打 exe，但对**单文件 Python 模块**（如 `miniaudio.py`）的处理有 bug，重打包会漏 → 启动报 `Miniaudio library not found`。**本工具箱采用 venv 直跑路线**，绕开打包问题；如果有人想打 exe，需要在 .spec 里显式 `('miniaudio.py', '.', 'DATA')` 这样塞进去。
7. **Windows 编码雷区**：
   - 含中文路径的 `.bat` 要存 **GBK**（或用 `chcp 65001` + UTF-8）
   - 任务计划 XML 必须 **UTF-16 LE + BOM**
   - exe 用中文名到处是坑 → 本仓库统一用 ASCII 名 `sensevox.py`
8. **国内 pip 镜像**：清华源（`pypi.tuna.tsinghua.edu.cn`）2026-05 曾出现 TLS 中断；**阿里云源（`mirrors.aliyun.com/pypi/simple`）更稳**。`install.bat` 默认用阿里云。

---

## 依赖

- Windows 10/11
- Python **3.10+**（建议 3.13，实测 OK）；装好且在 PATH
- Git（用来 clone 本仓库；没 git 也可以走 ZIP 路径，见 [备选](#备选无-git-用-zip-下载)）
- ~1.5GB 空闲磁盘（venv ~200MB + 模型 ~240MB + Python 包等）
- **需要梯子**：要从 github.com + huggingface.co 拉源码和模型。纯国内网试过 ghfast.top 镜像，228MB 模型 ~40KB/s 基本等不动，所以默认就是挂梯子跑。pip 走阿里云不用梯子。
- **安装路径建议纯英文**（部分 ONNX 运行时对非 ASCII 路径兼容性差，曾遇到 `Protobuf parsing failed` / `invalid unordered_map<K, T> key` 报错）

---

## Step 0：检查 / 安装 Python + Git

在 **PowerShell** 里跑（Win10/11 自带 winget）：

```powershell
# 1. 先验证是否已经装好
python --version
git --version

# 2. 缺什么装什么（已装的会自动跳过）
winget install -e --id Python.Python.3.13
winget install -e --id Git.Git

# 3. 装完后关掉当前 PowerShell，重开一个新的，再验证一次
python --version
git --version
```

> Python 安装器**默认勾上 "Add to PATH"**——winget 装的是命令行模式，已经处理好。如果是手动从 python.org 下载安装包，**第一个屏幕底部那个 "Add python.exe to PATH" 一定要勾**，否则装完 cmd 找不到 python。

---

## 快速开始

```powershell
# 1. 选一个全英文路径作为父目录，cd 过去（例：D:\tools）
cd D:\tools

# 2. clone 本仓库
git clone https://github.com/qsysbio-cjw/sensevox-windows-toolkit.git
cd sensevox-windows-toolkit

# 3. 安装（默认装到 clone 的同级目录，即 D:\tools\sensevox\）
#    想换别处：先 set INSTALL_DIR=X:\path\sensevox 再跑
scripts\install.bat

# 4. 测试运行（按 F9 说一句话，文字应出现在光标位置）
scripts\run.bat

# 5. 注册开机自启服务（需要管理员 PowerShell）
scripts\setup-service.bat
```

之后：
- 转写日志看 `<安装目录>\转写记录\YYYY-MM-DD.md`
- 录音原文件在 `<安装目录>\录音\`
- 想换热键 / 关录音 / 开简繁转换：直接在 sensevox 主窗口 GUI 里改，自动保存到 `assets\*.txt`
- 清空旧记录：`scripts\clear-records.bat`
- 完全卸载：`scripts\uninstall.bat`

---

## 备选：无 git 用 ZIP 下载

不想装 git 也行，github 自带 ZIP 下载：

```powershell
# 在 D:\tools 之类的英文路径下：
Invoke-WebRequest -Uri https://github.com/qsysbio-cjw/sensevox-windows-toolkit/archive/refs/heads/main.zip -OutFile sensevox-toolkit.zip
Expand-Archive sensevox-toolkit.zip -DestinationPath .
Rename-Item sensevox-windows-toolkit-main sensevox-windows-toolkit
Remove-Item sensevox-toolkit.zip
cd sensevox-windows-toolkit
scripts\install.bat
```

后续 `run.bat` / `setup-service.bat` 一样。缺点：以后想更新得手动重下 ZIP；用 git 的 `git pull` 一行搞定。

---

## 仓库结构

```
sensevox-windows-toolkit/
├── README.md                   本文档
├── sensevox.py                 已打 12 处补丁的 sensevox 主程序（install 时复制到安装目录）
├── requirements.txt            Python 依赖清单（venv 安装用）
├── sensevox-task.xml           Windows 任务计划模板（UTF-16，已指向 venv pythonw）
└── scripts/
    ├── apply_mods.py           归档：12 处补丁的 EDIT 列表（记录我们改了上游什么；install 不再调用）
    ├── install.bat             一键安装：copy sensevox.py + 下模型 + 建 venv + 写配置
    ├── run.bat                 启动 sensevox（用 venv pythonw，不带控制台窗口）
    ├── setup-service.bat       注册任务计划（自启 + 崩溃重启）
    ├── clear-records.bat       清空 录音\ 与 转写记录\
    └── uninstall.bat           卸载 app + 服务
```

---

## 配置文件（位于 `F:\sensevox\assets\`，都是纯文本）

| 文件 | 默认值 | 说明 |
|---|---|---|
| `hotkey.txt` | `f9` | 全局热键。**千万别用 Alt/Ctrl/Shift/空格**（见踩坑 #2） |
| `gtcrn_config.txt` | `True` | GTCRN 降噪开关。安静环境可关 |
| `save_recording_config.txt` | `True` | 是否保存 WAV 录音原文件（16kHz mono，~1.9MB/分钟） |
| `transcript_config.txt` | `true` | 是否写按天转写日志 |
| `opencc_enabled.txt` | `false` | OpenCC 简繁转换开关 |

改完重启 sensevox 生效（任务管理器 kill pythonw → 双击 `run.bat`）。

---

## 故障排查

| 症状 | 原因 + 解法 |
|---|---|
| `Model file not found` | 模型没下；重跑 `install.bat` 或手动下到 `assets/sensevoicesmallonnx/model.onnx` |
| `Miniaudio library not found` | 依赖装不全；激活 venv 后 `pip install miniaudio==1.71` |
| 按 F9 无反应 | sensevox 窗口里看是否「Listener thread started」；没有就是补丁第 9 处没生效 |
| 热键设成 Alt 后系统卡死 | 任务管理器结束 pythonw 进程，重启后改 `hotkey.txt` 为 f9 |
| 模型下载卡死 | 国内挂代理或换 `hf-mirror.com`：`set HF_ENDPOINT=https://hf-mirror.com` |
| 任务计划注册失败 | `setup-service.bat` 要以管理员身份运行 |

---

## 致谢 / 上游

- **应用**：[dapanggougou/sensevox](https://github.com/dapanggougou/sensevox)（无许可证，自行获取源码）
- **ASR 模型**：FunASR **SenseVoice-Small**，经 [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) 导出的 ONNX int8
- **降噪模型**：[Xiaobin-Rong/gtcrn](https://github.com/Xiaobin-Rong/gtcrn)
- **本工具箱**（脚本 + 文档 + 补丁）：MIT License
