# 技能库 · Skills

[English](README.en.md) · 简体中文

把日常真在用的工具抽成「拿走就能跑」的 skill：一个目录一款，带说明、带脚本。

仓库地址：<https://github.com/zyx0407/skills>

## 里面有什么

| 技能 | 干什么 | 依赖 |
| --- | --- | --- |
| [`截图/`](截图/) | 把网页出成**像素精确**的截图，并自动判断是不是白屏/坏图；失败会重试 | Python 3 + Pillow + Edge/Chrome |
| [`架构图/`](架构图/) | 把系统、数据流、上线边界画成一张纸色架构图（纯 HTML+SVG，零依赖），带模板与自检脚本 | 浏览器；渲染脚本另需 Node 或 PowerShell |

## 怎么用

```bash
# 截图
python 截图/shot.py --url "http://127.0.0.1:8080/" --out cover.png --w 1440 --h 900

# 架构图：复制模板改内容，再用自带脚本出图
#   架构图/assets/template.html   → 另存为你的图
#   架构图/scripts/render.ps1     → 渲染成 PNG（Windows）
#   架构图/scripts/render.sh      → 渲染成 PNG（macOS / Linux）
```

每个目录里的 `README.md` 写了更细的用法、参数和踩过的坑。

## 已知边界

- 都按 Windows 环境验证过；macOS / Linux 需要改脚本里的浏览器路径。
- 截图不负责"比对差异"，只负责出图与判定空白。
- 架构图是给人看的静态图，不生成可交互图表。

## 许可

[MIT](LICENSE)。文中的个人信息、域名、截图仅作示例，替换成你自己的。
