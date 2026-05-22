#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
apply_mods.py — 把本工具箱的全部增强应用到上游 sensevox 的 new/sensevox.py。

（上游 sensevox 无许可证，本仓库不分发其代码；
  请先从 https://github.com/dapanggougou/sensevox 自行获取源码再运行本脚本。）

应用 9 处改动：
  1) 单次录音上限 30s → 120s
  2) 新增 get_app_dir()（冻结后定位 .exe 同级目录；非冻结时用脚本目录）
  3) 新增 TRANSCRIPT_CONFIG_FILE 常量
  4) 新增 TRANSCRIPT_CONFIG_PATH 常量
  5) __init__ 里读 transcript_config 默认 True
  6) perform_record_and_transcribe 后调用 append_transcript()
  7+8) process_text 保留标点 + 新增 append_transcript() 方法
  9) __init__ 末尾 run_initial_checks 接住返回值 + 自动 wx.CallAfter(on_start_listening)

用法：  python apply_mods.py path/to/sensevox.py
幂等：已打过补丁会跳过对应改动。
"""
import sys


# 改动定义：(说明, old_text, new_text) - 全部字符串严格匹配，保证幂等
EDITS = [
    (
        "1) 录音上限 30->120s",
        'MAX_RECORD_SECONDS = 30.0  # 防止热键卡死导致无限录音',
        'MAX_RECORD_SECONDS = 120.0  # 单次录音上限（原 30s → 120s）'
    ),
    (
        "2) 新增 get_app_dir()",
        '    return os.path.join(base_path, "assets", relative_path)\n\n\nMODEL_DIR_BASE = "sensevoicesmallonnx"',
        '    return os.path.join(base_path, "assets", relative_path)\n\n\n'
        'def get_app_dir():\n'
        '    """运行目录：冻结后取 .exe 所在目录（用于转写记录等用户产物，确保落在安装目录而非临时目录）。"""\n'
        "    if getattr(sys, 'frozen', False):\n"
        '        return os.path.dirname(sys.executable)\n'
        '    try:\n'
        '        return os.path.dirname(os.path.abspath(__file__))\n'
        '    except NameError:\n'
        '        return os.path.abspath(".")\n\n\n'
        'MODEL_DIR_BASE = "sensevoicesmallonnx"'
    ),
    (
        "3) 新增 TRANSCRIPT_CONFIG_FILE 常量",
        'OPENCC_CONFIG_FILE = "opencc_config.txt"\nOPENCC_ENABLED_FILE = "opencc_enabled.txt"',
        'OPENCC_CONFIG_FILE = "opencc_config.txt"\n'
        'OPENCC_ENABLED_FILE = "opencc_enabled.txt"\n'
        'TRANSCRIPT_CONFIG_FILE = "transcript_config.txt"'
    ),
    (
        "4) 新增 TRANSCRIPT_CONFIG_PATH 常量",
        'OPENCC_ENABLED_PATH = get_asset_path(OPENCC_ENABLED_FILE)',
        'OPENCC_ENABLED_PATH = get_asset_path(OPENCC_ENABLED_FILE)\n'
        'TRANSCRIPT_CONFIG_PATH = get_asset_path(TRANSCRIPT_CONFIG_FILE)'
    ),
    (
        "5) __init__ 读 transcript_enabled",
        '        initial_opencc_config = self.load_setting(OPENCC_CONFIG_PATH, OPENCC_OPTIONS[0])',
        '        initial_opencc_config = self.load_setting(OPENCC_CONFIG_PATH, OPENCC_OPTIONS[0])\n'
        '        self.transcript_enabled = self.load_setting(TRANSCRIPT_CONFIG_PATH, "true").lower() == "true"'
    ),
    (
        "6) 调用 append_transcript",
        '                    self.type_text(processed_text)',
        '                    self.append_transcript(processed_text)\n'
        '                    self.type_text(processed_text)'
    ),
    (
        "7+8) process_text 保留标点 + 新增 append_transcript",
        '    def process_text(self, text):\n'
        '        if not isinstance(text, str):\n'
        '            return text\n'
        '        punctuation_count = sum(1 for char in text if char in all_punctuation)\n'
        '        if punctuation_count <= 1:\n'
        '            return text.translate(str.maketrans(\'\', \'\', all_punctuation))\n'
        '        return text',
        '    def process_text(self, text):\n'
        '        # 改造：完全保留标点，去除上游"短句删尾标点"逻辑\n'
        '        if not isinstance(text, str):\n'
        '            return text\n'
        '        return text\n'
        '\n'
        '    def append_transcript(self, text):\n'
        '        """把最终落地文本按天追加到 转写记录/YYYY-MM-DD.md（即时写入+flush，UTF-8）。"""\n'
        '        if not getattr(self, \'transcript_enabled\', True):\n'
        '            return\n'
        '        if not text or not text.strip():\n'
        '            return\n'
        '        try:\n'
        '            import datetime\n'
        '            now = datetime.datetime.now()\n'
        '            tdir = os.path.join(get_app_dir(), "转写记录")\n'
        '            os.makedirs(tdir, exist_ok=True)\n'
        '            fpath = os.path.join(tdir, now.strftime("%Y-%m-%d") + ".md")\n'
        '            is_new = not os.path.exists(fpath)\n'
        '            with open(fpath, \'a\', encoding=\'utf-8\') as f:\n'
        '                if is_new:\n'
        '                    f.write(f"# {now.strftime(\'%Y-%m-%d\')} 转写记录\\n\\n")\n'
        '                f.write(f"- [{now.strftime(\'%H:%M:%S\')}] {text.strip()}\\n")\n'
        '                f.flush()\n'
        '        except Exception as e:\n'
        '            self.log(f"写转写记录失败: {e}", "WARNING")'
    ),
    (
        "9) __init__ 末尾自启 listener",
        '        self.run_initial_checks()\n        self.update_ui_state()',
        '        # 接住 checks 返回值，确保只在全过时自启\n'
        '        checks_ok = self.run_initial_checks()\n'
        '        self.update_ui_state()\n'
        '        # 启动后自动激活 listener，不用手动点 Start\n'
        '        if checks_ok:\n'
        '            wx.CallAfter(self.on_start_listening, None)'
    ),
    (
        "10) 启动即 Hide 到托盘 + X 按钮拦截为隐藏",
        '    frame = MyFrame()\n    frame.Show()\n    app.MainLoop()',
        '    frame = MyFrame()\n'
        '    frame.Bind(wx.EVT_CLOSE, lambda e: frame.Hide())  # X 拦截为隐藏\n'
        '    frame.Hide()  # 启动即完全隐藏到系统托盘\n'
        '    tray = SensevoxTrayIcon(frame)\n'
        '    frame._tray = tray  # 持引用防 GC\n'
        '    app.MainLoop()'
    ),
    (
        "11a) import wx.adv（托盘所需）",
        'import wx\nimport ctypes',
        'import wx\nimport wx.adv\nimport ctypes'
    ),
    (
        "11b) 插入 SensevoxTrayIcon 类",
        "if __name__ == '__main__':\n    app = wx.App(False)",
        'class SensevoxTrayIcon(wx.adv.TaskBarIcon):\n'
        '    """系统托盘图标：双击切换窗口可见性，右键菜单含退出。"""\n'
        '    ID_TOGGLE = wx.NewIdRef()\n'
        '    ID_EXIT = wx.NewIdRef()\n'
        '\n'
        '    def __init__(self, frame):\n'
        '        super().__init__()\n'
        '        self.frame = frame\n'
        '        icon = wx.ArtProvider.GetIcon(wx.ART_INFORMATION, wx.ART_OTHER, (16, 16))\n'
        '        self.SetIcon(icon, "sensevox")\n'
        '        self.Bind(wx.adv.EVT_TASKBAR_LEFT_DCLICK, self.on_toggle)\n'
        '        self.Bind(wx.EVT_MENU, self.on_toggle, id=self.ID_TOGGLE)\n'
        '        self.Bind(wx.EVT_MENU, self.on_exit, id=self.ID_EXIT)\n'
        '\n'
        '    def CreatePopupMenu(self):\n'
        '        m = wx.Menu()\n'
        '        m.Append(self.ID_TOGGLE, "显示/隐藏窗口")\n'
        '        m.AppendSeparator()\n'
        '        m.Append(self.ID_EXIT, "退出 sensevox")\n'
        '        return m\n'
        '\n'
        '    def on_toggle(self, event):\n'
        '        if self.frame.IsShown():\n'
        '            self.frame.Hide()\n'
        '        else:\n'
        '            self.frame.Show()\n'
        '            self.frame.Iconize(False)\n'
        '            self.frame.Raise()\n'
        '\n'
        '    def on_exit(self, event):\n'
        '        self.RemoveIcon()\n'
        '        wx.CallAfter(self.frame.Destroy)\n'
        '\n'
        '\n'
        "if __name__ == '__main__':\n"
        '    app = wx.App(False)'
    ),
    (
        "12) 自绘托盘图标（绿底白 S，替代 stock i 图标）",
        '        icon = wx.ArtProvider.GetIcon(wx.ART_INFORMATION, wx.ART_OTHER, (16, 16))\n'
        '        self.SetIcon(icon, "sensevox")',
        '        self.SetIcon(self._make_icon(), "sensevox")\n'
        '\n'
        '    @staticmethod\n'
        '    def _make_icon():\n'
        '        """运行时画 32x32 绿底白 S 图标（零外部资源依赖）。"""\n'
        '        bmp = wx.Bitmap(32, 32)\n'
        '        dc = wx.MemoryDC(bmp)\n'
        '        dc.SetBackground(wx.Brush(wx.Colour(0, 180, 80)))\n'
        '        dc.Clear()\n'
        '        dc.SetTextForeground(wx.WHITE)\n'
        '        font = wx.Font(22, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD)\n'
        '        dc.SetFont(font)\n'
        '        w, h = dc.GetTextExtent("S")\n'
        '        dc.DrawText("S", (32 - w) // 2, (32 - h) // 2)\n'
        '        dc.SelectObject(wx.NullBitmap)\n'
        '        icon = wx.Icon()\n'
        '        icon.CopyFromBitmap(bmp)\n'
        '        return icon'
    ),
]


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    path = sys.argv[1]
    print(f"读取: {path}")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    orig = src
    applied = 0
    skipped = 0

    for desc, old, new in EDITS:
        if new in src:
            print(f"  ⊘ 跳过 {desc}（已应用）")
            skipped += 1
            continue
        if old not in src:
            print(f"  ❌ 错误 {desc}: 找不到 old 文本")
            print(f"     上游 sensevox.py 版本可能变了，本脚本需要更新。")
            sys.exit(2)
        src = src.replace(old, new, 1)
        applied += 1
        print(f"  ✅ 应用 {desc}")

    if src == orig:
        print(f"\n无改动（全部已应用）。")
        return

    with open(path, 'w', encoding='utf-8') as f:
        f.write(src)
    print(f"\n写回: {path}")
    print(f"统计：应用 {applied} 处，跳过 {skipped} 处。")


if __name__ == '__main__':
    main()
