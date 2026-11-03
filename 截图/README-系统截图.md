# 截图 · 系统截图（Win+Shift+S）体检与修复

Windows 自带截图「一会能用一会失灵」，多数不是软件坏了。

## 真凶（2026-11-04 在我们机器上实测出来的）

**Nahimic（A-Volute 音效软件）** 的 `Nahimic3` / `nahimicNotifSys` 进程在跑时，
截图工具**起得来但不弹遮罩**——按 Win+Shift+S 像没反应。

| 条件 | 遮罩窗口（`SnipOverlayRootWindow`） |
| --- | --- |
| Nahimic 进程在跑 | 不可见（只有一个隐藏的 `Windows.UI.Core.CoreWindow`） |
| 杀掉这两个进程 | 可见，连测两次都正常 |

## 怎么用

```powershell
powershell -ExecutionPolicy Bypass -File 查截图工具.ps1        # 只体检
powershell -ExecutionPolicy Bypass -File 查截图工具.ps1 -Fix   # 杀 Nahimic + 清残留 + 验证遮罩
powershell -ExecutionPolicy Bypass -File 查截图工具.ps1 -Snip  # 直接出一次截图（先清 Nahimic）
```

## 判定口径

- `SnipOverlayRootWindow` 可见＝遮罩正常；
- 只剩 `Windows.UI.Core.CoreWindow` 可见=False ＝ 没弹出来；
- `SnippingTool` 实例 >1 或存活很久却无窗口 → 残留，会吞热键。

## 治本（需要管理员）

1. 设置 → 应用 → 卸载 Nahimic（只丢音效增强）；
2. 或在「任务计划程序」禁用 `NahimicTask32` / `NahimicTask64`；
3. 或把 `Nahimic service` 启动类型改成「手动」。

## 边界

- 只处理「进程/残留/遮罩」这层；显卡驱动级抓屏故障它修不了。
- 杀 Nahimic 不影响出声，只丢音效增强。
