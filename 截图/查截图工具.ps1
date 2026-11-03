<#
查询 / 修复 Windows 自带截图（Win+Shift+S · 截图工具 Snipping Tool）

2026-11-04 定位到的真凶：**Nahimic（A-Volute 音效）** —— 它的 Nahimic3 / nahimicNotifSys
进程一在跑，截图工具就起得来但遮罩不弹（`SnipOverlayRootWindow` 不可见）；杀掉这两个进程后
遮罩立刻正常，连测两次复现。

用法：
  powershell -ExecutionPolicy Bypass -File 查截图工具.ps1           # 只体检
  powershell -ExecutionPolicy Bypass -File 查截图工具.ps1 -Fix      # 杀 Nahimic＋清残留＋重启并验证遮罩
  powershell -ExecutionPolicy Bypass -File 查截图工具.ps1 -Snip     # 直接出一次截图（先清 Nahimic）

判定口径：
  · SnipOverlayRootWindow 可见＝遮罩正常；只剩 Windows.UI.Core.CoreWindow visible=False ＝ 没弹出来
  · Nahimic 进程在跑 → 直接杀（不影响声音，只丢音效增强）
#>
param([switch]$Fix, [switch]$Snip)

$ErrorActionPreference = 'Continue'
function Line($s) { Write-Host $s }

Add-Type @"
using System;using System.Text;using System.Collections.Generic;using System.Runtime.InteropServices;
public class SnipW {
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  public delegate bool EnumWindowsProc(IntPtr h, IntPtr l);
  public static bool OverlayVisible() {
    bool ok = false;
    EnumWindows((h, l) => {
      var sb = new StringBuilder(256); GetClassName(h, sb, 256);
      if (sb.ToString() == "SnipOverlayRootWindow" && IsWindowVisible(h)) ok = true;
      return true;
    }, IntPtr.Zero);
    return ok;
  }
}
"@ -ErrorAction SilentlyContinue

function Kill-Nahimic {
  $n = @(Get-Process Nahimic3, nahimicNotifSys -ErrorAction SilentlyContinue)
  if ($n.Count -gt 0) {
    $n | Stop-Process -Force -ErrorAction SilentlyContinue
    Line ("  已结束 Nahimic 进程 {0} 个（不影响声音，只丢音效增强）" -f $n.Count)
    Start-Sleep -Milliseconds 800
  } else { Line '  Nahimic 没在跑' }
}

function Test-Overlay([string]$tag) {
  Get-Process SnippingTool -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 600
  Start-Process 'ms-screenclip:'
  Start-Sleep -Seconds 3
  $ok = [SnipW]::OverlayVisible()
  Line ("  [{0}] 遮罩可见 = {1}" -f $tag, $ok)
  Get-Process SnippingTool -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  return $ok
}

if ($Snip) {
  Line '=== 出一次截图（先清 Nahimic，再唤起遮罩）==='
  Kill-Nahimic
  Get-Process SnippingTool -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 500
  Start-Process 'ms-screenclip:'
  Start-Sleep -Seconds 2
  if ([SnipW]::OverlayVisible()) { Line '  遮罩已弹出，直接框选' }
  else { Line '  ⚠️ 遮罩仍没弹 —— 跑一次 -Fix，或查火绒拦截' }
  return
}

Line '=== 1. 系统 ==='
$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
Line ("  {0} · {1} · build {2}.{3}" -f $cv.ProductName, $cv.DisplayVersion, $cv.CurrentBuild, $cv.UBR)

Line '=== 2. 应用包 ==='
$pkg = Get-AppxPackage -Name '*ScreenSketch*' -ErrorAction SilentlyContinue
if ($pkg) { Line ("  {0} {1} · 状态 {2}" -f $pkg.Name, $pkg.Version, $pkg.Status) } else { Line '  ⚠️ 没装截图工具' }

Line '=== 3. 运行实例 ==='
$procs = @(Get-Process SnippingTool -ErrorAction SilentlyContinue)
Line ("  实例数: {0}" -f $procs.Count)
foreach ($p in $procs) {
  $age = if ($p.StartTime) { [int]((Get-Date) - $p.StartTime).TotalMinutes } else { -1 }
  Line ("   PID {0} 存活 {1} 分钟" -f $p.Id, $age)
}

Line '=== 4. 抢热键 / 拦截图 ==='
$pat = 'huorong|HipsTray|360|kingsoft|ToDesk|Sunlogin|AnyDesk|Nexus|Nahimic|Razer|Snipaste|ShareX|PixPin'
$found = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match $pat } | Sort-Object ProcessName -Unique
if ($found) { foreach ($f in $found) { Line ("  · {0}" -f $f.ProcessName) } } else { Line '  没发现' }

Line '=== 5. 遮罩自检 ==='
$ok = Test-Overlay 'bare'
if (-not $ok) { Line '  ⚠️ 遮罩没弹出 —— 很可能就是 Nahimic，用 -Fix 修' }

if ($Fix) {
  Line '=== 修复 ==='
  Kill-Nahimic
  $ok2 = Test-Overlay 'after-fix'
  if ($ok2) {
    Line '  ✅ 修好了。重启后 Nahimic 会自己回来，届时再跑一次 -Fix，或永久关掉它：'
    Line '    ① 设置 → 应用 → 已安装的应用 → Nahimic → 卸载（只丢音效增强）'
    Line '    ② 任务计划程序 → 禁用 NahimicTask32 / NahimicTask64'
    Line '    ③ 服务 → Nahimic service → 启动类型改「手动」'
  } else {
    Line '  ⚠️ 仍不行：先临时退出火绒测一次；再不行就「设置 → 应用 → 截图工具 → 高级选项 → 重置」。'
  }
}
