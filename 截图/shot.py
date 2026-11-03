#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
本机出图（自检版）—— 替代直接喊 msedge --screenshot

为什么要有这个：直接用 --screenshot 会出现「一会儿能用一会儿失灵」，成因有四类，
本工具逐条处理（2026-11-04 实测，详见 私域\\记忆库\\memory\\本机-无头浏览器.md）：

  1. --window-size 不可信：实测 width 少 30px、height 少 95px，且最小宽约 504px
     → 这里自动补偿，并在出图后用探针回读 innerWidth/innerHeight 校验，不符就重拍
  2. --virtual-time-budget 必须大于页面最慢的定时器：预算不够就拍到动画中间帧
     → 这里把预算下限抬到 wait_ms+1500，并默认带 --force-device-scale-factor=1
  3. 窄于 504px 的视口只能套 iframe 外壳；但 iframe 内的 setTimeout/rAF 在
     virtual time 下不推进 → 窄屏默认追加 still=1（落终态），并显式警告
  4. Chromium 往 stderr 喷 GPU/更新日志，PowerShell 会当成 NativeCommandError
     → 本工具只看 exit code 与产物本身，stderr 只留前 200 字做参考

出图后自检：文件存在、字节数达标、图像不是纯色（按灰度标准差判断），
失败自动换新 profile 重拍，最多 3 次。每次结束都删 profile（TEMP 里那 214 个
残留目录就是这么攒起来的）。

用法:
  python shot.py --url "http://127.0.0.1:5187/index.html?theme=day&still=1" --out "F:\\工作区\\成品\\门面站\\_预览\\x.png"
  python shot.py --url ... --out ... --w 390 --h 844          # 自动套 iframe 外壳
  python shot.py --url ... --out ... --budget 6000 --wait 1200 --retries 3
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import uuid

EDGE_CANDIDATES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
]
MIN_VIEWPORT = 504          # 无头浏览器视口最小宽（实测）
W_OFFSET, H_OFFSET = 30, 95  # --window-size 与真实视口的实测差值


def find_browser():
    for p in EDGE_CANDIDATES:
        if os.path.exists(p):
            return p
    raise SystemExit("没找到 Edge/Chrome")


def iframe_shell(url, w, h, bg):
    """窄屏外壳：外层窗口给足宽度，视口由 iframe 精确钉死"""
    path = os.path.join(tempfile.gettempdir(), "shot-shell-%s.html" % uuid.uuid4().hex[:8])
    html = (
        '<!DOCTYPE html><html><body style="margin:0;background:%s">'
        '<iframe src="%s" style="width:%dpx;height:%dpx;border:0;display:block"></iframe>'
        "</body></html>" % (bg, url.replace("&", "&amp;"), w, h)
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write(html)
    return path


def image_ok(path, min_bytes=2000, min_std=2.0):
    """产物自检：存在 / 够大 / 不是纯色"""
    if not os.path.exists(path):
        return False, "没生成文件"
    size = os.path.getsize(path)
    if size < min_bytes:
        return False, "只有 %d B（疑似空白页）" % size
    try:
        from PIL import Image, ImageStat
    except ImportError:
        return True, "%d B（无 Pillow，跳过纯色检查）" % size
    try:
        im = Image.open(path).convert("L")
        std = ImageStat.Stat(im).stddev[0]
    except Exception as e:  # noqa: BLE001
        return False, "打不开图：%s" % e
    if std < min_std:
        return False, "纯色图（灰度标准差 %.2f）" % std
    return True, "%d B（标准差 %.1f）" % (size, std)


def shoot_once(browser, target, out, win_w, win_h, budget):
    prof = os.path.join(tempfile.gettempdir(), "shot-prof-%s" % uuid.uuid4().hex[:8])
    cmd = [
        browser, "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--no-first-run", "--no-default-browser-check", "--no-sandbox",
        "--force-device-scale-factor=1",
        "--user-data-dir=" + prof,
        "--window-size=%d,%d" % (win_w, win_h),
        "--virtual-time-budget=%d" % budget,
        "--screenshot=" + out,
        target,
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=90)
        err = (proc.stderr or "").strip().splitlines()
        tail = err[-1][:200] if err else ""
        return proc.returncode, tail
    except subprocess.TimeoutExpired:
        return -1, "超时 90s"
    finally:
        shutil.rmtree(prof, ignore_errors=True)


def probe_viewport(browser, target, win_w=1500, win_h=900):
    """回读真实视口，用于校验 --window-size 补偿是否正确"""
    prof = os.path.join(tempfile.gettempdir(), "shot-prof-%s" % uuid.uuid4().hex[:8])
    probe = os.path.join(tempfile.gettempdir(), "shot-vp-%s.html" % uuid.uuid4().hex[:8])
    with open(probe, "w", encoding="utf-8") as f:
        f.write('<html><body><script>document.title="VP "+innerWidth+" "+innerHeight;'
                "</script></body></html>")
    try:
        cmd = [browser, "--headless=new", "--disable-gpu", "--no-first-run",
               "--user-data-dir=" + prof, "--virtual-time-budget=1500",
               "--window-size=%d,%d" % (win_w, win_h),
               "--dump-dom", "file:///" + probe.replace("\\", "/")]
        out = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60).stdout
        for line in out.splitlines():
            if "VP " in line:
                import re
                m = re.search(r"VP (\d+) (\d+)", out)
                if m:
                    return int(m.group(1)), int(m.group(2))
    except Exception:  # noqa: BLE001
        pass
    finally:
        shutil.rmtree(prof, ignore_errors=True)
        try:
            os.remove(probe)
        except OSError:
            pass
    return None, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--w", type=int, default=1440)
    ap.add_argument("--h", type=int, default=900)
    ap.add_argument("--budget", type=int, default=0, help="0=自动（wait+1500）")
    ap.add_argument("--wait", type=int, default=2500, help="留给页面定时器的时间")
    ap.add_argument("--retries", type=int, default=3)
    ap.add_argument("--narrow-still", type=int, default=1, help="窄屏自动加 still=1")
    a = ap.parse_args()

    browser = find_browser()
    out = os.path.abspath(a.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    report = {"url": a.url, "out": out, "attempts": [], "warnings": []}

    narrow = a.w < MIN_VIEWPORT
    target = a.url
    if narrow:
        if a.narrow_still and "still=1" not in target:
            target += ("&" if "?" in target else "?") + "still=1"
            report["warnings"].append("窄屏(<%dpx)：已追加 still=1 —— iframe 里的定时器在 virtual time 下不推进" % MIN_VIEWPORT)
        shell = iframe_shell(target, a.w, a.h, "#ffffff")
        real_target = "file:///" + shell.replace("\\", "/")
        win_w, win_h = a.w, a.h          # 外壳按真实尺寸给窗口，内容靠 iframe 钉死
    else:
        real_target = target
        win_w, win_h = a.w + W_OFFSET, a.h + H_OFFSET
        shell = None

    budget = a.budget or (a.wait + 1500)
    report["budget_ms"] = budget

    ok = False
    for i in range(1, a.retries + 1):
        t0 = time.time()
        try:
            os.remove(out)
        except OSError:
            pass
        code, tail = shoot_once(browser, real_target, out, win_w, win_h, budget)
        # 无头浏览器「先退出后落盘」
        for _ in range(20):
            if os.path.exists(out):
                break
            time.sleep(0.2)
        good, why = image_ok(out)
        report["attempts"].append({"n": i, "exit": code, "ms": int((time.time() - t0) * 1000),
                                   "ok": good, "why": why, "stderr_tail": tail})
        if good:
            ok = True
            break
    if shell:
        try:
            os.remove(shell)
        except OSError:
            pass

    if not narrow:
        vw, vh = probe_viewport(browser, target, win_w, win_h)
        if vw:
            report["viewport"] = {"w": vw, "h": vh, "asked": [a.w, a.h]}
            if abs(vw - a.w) > 2 or abs(vh - a.h) > 2:
                report["warnings"].append("视口与目标差 %+d/%+d px（--window-size 补偿需重算）"
                                          % (vw - a.w, vh - a.h))
    report["ok"] = ok
    print(json.dumps(report, ensure_ascii=False, indent=2))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
