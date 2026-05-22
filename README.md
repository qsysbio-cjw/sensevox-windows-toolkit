# sensevox-windows-toolkit

把 [sensevox](https://github.com/dapanggougou/sensevox)（基于 SenseVoice 的 Windows 离线中英语音输入）从「能跑」变成「**开机自启 + 崩溃自愈 + 转写日志的省心常驻服务**」的一套脚本、补丁与踩坑经验。

> ⚠️ **许可证声明**：上游 sensevox **没有任何 LICENSE**（默认保留所有权利）。本仓库**不分发它的任何代码或编译产物**，只提供：我们自己的脚本、一份**改动补丁（diff）** 和文档。`install.bat` 会让你**从上游官方仓库自动拉源码**后在本地打补丁。模型同理从 sherpa-onnx / GTCRN 上游下载。请尊重各上游的权利。

---

## 这套东西给你什么

- **一键安装**：拉上游源码 → 下模型 → 建 venv → 打补丁 → 写默认配置
- **9 处增强（补丁形式，可读 diff 在 `patch/`）**：
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
- Python **3.10+**（建议 3.13，实测 OK）；装好且在 PATH（cmd 输 `python --version` 能出版本）
- ~1.5GB 空闲磁盘（venv ~200MB + 模型 ~240MB + Python 包等）
- **需要梯子**：要从 github.com + huggingface.co 拉源码和模型。纯国内网试过 ghfast.top 镜像，228MB 模型 ~40KB/s 基本等不动，所以默认就是挂梯子跑。pip 走阿里云不用梯子。

---

## 快速开始

```bat
:: 1. 克隆本仓库
git clone https://github.com/qsysbio-cjw/sensevox-windows-toolkit.git
cd sensevox-windows-toolkit

:: 2. 安装（默认装到 F:\sensevox\）
::    想换地方：先编辑 scripts\install.bat 第 23 行的 INSTALL_DIR，
::    同步改 sensevox-task.xml 里的两处 F:\sensevox 路径（自启用）
scripts\install.bat

:: 3. 测试运行
scripts\run.bat
:: 窗口出来后日志显示 "Listener thread started. Monitoring hotkey: 'f9'."
:: 按 F9 说一句话试试，文字应该在你光标位置出现，标点也保留

:: 4. 注册开机自启服务（需要管理员权限）
scripts\setup-service.bat
```

之后：
- 转写日志看 `F:\sensevox\转写记录\YYYY-MM-DD.md`
- 录音原文件在 `F:\sensevox\录音\`
- 清空旧记录：`scripts\clear-records.bat`
- 完全卸载：`scripts\uninstall.bat`

---

## 仓库结构

```
sensevox-windows-toolkit/
├── README.md                   本文档
├── requirements.txt            Python 依赖清单（venv 安装用）
├── sensevox-task.xml           Windows 任务计划模板（UTF-16，已指向 venv pythonw）
└── scripts/
    ├── apply_mods.py           把改动应用到上游 sensevox.py（无需 git，幂等，人读 EDITS 列表）
    ├── install.bat             一键安装：取源码+模型 → 建 venv → 打补丁
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
