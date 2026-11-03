---
name: architecture-diagram
description: 把系统、产品、流程画成一张"纸色三列"架构图 / 结构图 / 流程图：纯 HTML+SVG、零依赖、1400 宽；附 12 条规矩、评审 10 问、可复制模板、一键出图与自检脚本（Windows / macOS / Linux）。用于把结构、数据流、上线与边界整理成一页视觉稿，讲解或交接。
whenToUse: 用户说"画个架构图 / 结构图 / 流程图 / 一张图讲清"时；需要把系统组成、数据流向、上线路径与边界整理成图时；交付给他人前做结构说明时。
---

# 架构图 / 结构图

一张图只讲一个 scope：**左列外部/用户、中列本体/核心、右列数据/上线/运维、底条边界/验收/现状**。纯静态 HTML+SVG，改文字不用懂代码，出图一条命令。

## 前置检查

1. **浏览器**：Edge / Chrome / Chromium 任一（出图用 headless 模式）。
2. **运行时**：Windows 用 PowerShell 5.1+；macOS/Linux 用 bash 或 Node 16+。
3. **无依赖**：纯 HTML/CSS/SVG，不需要 npm 包、不需要联网、不需要构建。
4. **字体**：系统需有中文无衬线（Microsoft YaHei / Noto Sans SC 等）；缺了会回退，版式仍成立。

## 工作流

### 第一步：选版式

复制 `assets/template.html` 到目标的 `架构图\index.html`。一张图只保留一个 scope（用户视角 / 部署机器 / 数据流），别混。

### 第二步：填内容

| 位置 | 写什么 |
| --- | --- |
| 标题 `.h1` | `主题 · 副题`，后面 `<span>` 加日期/版本 |
| 列头 `.g` | 该列语义，例：`外部 · 用户` |
| 框 `.box` | `.t` 是什么（14px）＋ `.s` 干什么/技术选型（10px 灰字） |
| 边框 | 实线＝已落地；虚线＝外部 / 计划 / 只读可选 |

### 第三步：连线与标签

- 在 `<svg class="wires">` 里用 `<path>` 连框，每条线必须有 `marker-end` 箭头；
- 每条线配一个 `.lbl` 标签，写"谁把什么给谁"（读数据 / 推送 / 点进 / 验收）；
- 实线＝同步直连；虚线＝异步 / 定时 / 可选 / 只读。

### 第四步：自检（必跑）

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File scripts/lint.ps1 -Html .\index.html
```

检查：标题与图例、框的数量与说明行、框越界/重叠、箭头 marker 引用、缺箭头的线、标签数量、流动点是否包在 `.flow` 里。退出码 0＝通过，1＝有错误（按输出逐条改）。

### 第五步：出图（三选一）

| 平台 | 命令 |
| --- | --- |
| Windows | `powershell -ExecutionPolicy Bypass -File scripts/render.ps1 -Html .\index.html` |
| macOS / Linux | `bash scripts/render.sh ./index.html` |
| 通用（Node 16+） | `node scripts/render.mjs ./index.html` |

可选参数：`-W/-H`（画布尺寸，默认 1400×760）；`-Scale 2`（2 倍图，手机看更清楚）。输出默认 `_shots\<同名>.png`。

### 第六步：交付前

1. 过一遍评审 10 问（`references/rules.md` 第三节）；
2. **默认静态，不加动效**；他明确要"数据在跑"时才加流动点（见示例），静态导出/打印用 `index.html?still=1`；
3. 图下配 3–5 条 key facts（条数、到期日、版本、白名单）。

## 关键口径

| 口径 | 默认值 | 说明 |
| --- | --- | --- |
| 画布 | 1400 × 700–920 | 一屏读完，超了拆图 |
| 字号 | 标题 15 / 框题 14 / 说明 10 / 线上标签 9.5 | 单位 px |
| 配色 | 纸色（`references/rules.md` 第四节） | 深灰备选 |
| 强调色 | 琥珀 `#b08a3e` | 只标"当前 / 待办 / 风险" |
| 线 | 1px，箭头 7px | 实线同步，虚线异步 |
| 文件 | `<主题>\架构图\index.html` ＋ `_shots\*.png` | 一主题一目录，改版覆盖同名 |

## 常见坑

- **出图空白 / 超时**：`--screenshot` 必须是绝对路径；每轮换新的 `--user-data-dir`（复用会撞单例锁）。
- **viewBox 和画布尺寸不一致**：lint 会报；改一处时另一处也要改。
- **框重叠 / 越界**：坐标手摆的常见问题；先跑 lint 再出图。
- **箭头没标签**：评审必查项，lint 会提示。
- **虚线框没在图例解释**：lint 提示；图例必须说明虚线含义。
- **中文变方块**：装中文字体，或把 `--sans` 改成系统里有的字体。
- **流动点乱跑**：只能放进 `<g class="flow">`；静态导出加 `?still=1`。
- **路径带空格**：给 `-Html` 参数整体加引号。

## 边界

- 它是**地图不是海报**：不做装饰性渐变/投影、不用多种强调色、不混 scope。
- **不做自动布局**（不是 Mermaid / D2）：坐标手调，适合数量不多、需要长期维护的图。
- 只覆盖**结构与数据流**；时序图、状态机、泳道流程请用别的工具。
- **默认静态**：不加任何动效，可截图、可打印、可贴文档。
- **不做交互**（悬停高亮 / 分步播放 / 自动播放）；只有用户明确要"数据在跑"时才加流动点，其余一律不做。
- 不自带字体、不打包浏览器：只依赖你机器上的 Edge/Chrome。

## 文件与许可

| 文件 | 用途 |
| --- | --- |
| `assets/template.html` | 空白模板（三列＋底条＋图例），复制即用 |
| `assets/example-web-app.html` | 通用示例（虚构小工具站，含流动点与 `?still=1`） |
| `references/rules.md` | 规矩全文：12 条、评审 10 问、两套配色、命名约定 |
| `scripts/lint.ps1` | 机器自检（Windows） |
| `scripts/render.ps1` / `render.sh` / `render.mjs` | 一键出图（Windows / unix / 通用） |
| `README.md` | 给人看的安装与使用说明 |
| `LICENSE` | MIT（Copyright 2026 zyx0407） |

参考写法（只借鉴思路，未复制代码）：C4 model 与评审清单、D2 声明式、Mermaid 形状语义、Grafana Loki 架构文档的分步写法。
