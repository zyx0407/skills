# 架构图 skill · 使用说明（给人看的）

把"系统/产品结构"画成**一页纸色图**的小工具包：纯 HTML+SVG、零依赖、出 PNG 可直接贴文档或发聊天。
既给 AI 助手当 skill 用，也可以完全手动用。

## 目录

```
architecture-diagram/
├─ SKILL.md                    ← 给 AI 助手看的操作手册（前置检查/工作流/口径/坑/边界）
├─ README.md                   ← 本文件
├─ LICENSE                     ← MIT
├─ references/rules.md         ← 规矩全文：12 条、评审 10 问、两套配色、命名约定
├─ assets/template.html        ← 空白模板（三列＋底条＋图例），复制即用
├─ assets/example-web-app.html ← 通用示例（虚构小工具站，带"数据在跑"的流动点）
├─ assets/_shots/*.png         ← 两张现成预览图
└─ scripts/
   ├─ lint.ps1                 ← 机器自检（Windows）
   ├─ render.ps1               ← 出图（Windows）
   ├─ render.sh                ← 出图（macOS / Linux）
   └─ render.mjs               ← 出图（Node 16+，全平台通用）
```

## 安装

- **给 AI 助手**：整个文件夹放进 `~/.dsh/skills/`（或其它被扫描的 skill 根目录），说"画个架构图"即可。
- **自己用**：不需要安装。复制 `assets/template.html` → 改内容 → 跑出图脚本。

## 三步上手

```bash
# 1. 复制模板
cp assets/template.html ./index.html
# 2. 改标题、三列、框、连线（纯文本编辑，改文字即可）
# 3. 自检 + 出图
powershell -ExecutionPolicy Bypass -File scripts/lint.ps1 -Html ./index.html
powershell -ExecutionPolicy Bypass -File scripts/render.ps1 -Html ./index.html
```

## 平台支持

| 平台 | 自检 | 出图 | 说明 |
| --- | --- | --- | --- |
| Windows | `lint.ps1` | `render.ps1` | 自动找 Edge / Chrome |
| macOS | — | `render.sh` 或 `node render.mjs` | 自动找 Chrome / Edge / Chromium |
| Linux | — | `render.sh` 或 `node render.mjs` | 自动找 google-chrome / chromium |
| 任意 + Node 16+ | — | `node render.mjs` | 最通用；无第三方依赖 |

出图参数：`-W/-H`（尺寸，默认 1400×760）、`-Scale 2`（2 倍图）。输出默认 `_shots\<同名>.png`。

## 常见问题

- **出图空白/超时**：`--screenshot` 必须绝对路径，且每轮换新 `--user-data-dir`；脚本已处理。
- **中文变方块**：装中文字体（Microsoft YaHei / Noto Sans SC），或改模板的 `--sans`。
- **一屏放不下**：拆成两张（结构一张、数据流一张），别缩字号硬塞。
- **想要动效**：默认静态；明确要求才加"连线流动点"（示例里有），静态导出加 `?still=1`。
- **想要自动布局**：这不是 Mermaid/D2，坐标是手摆的——优点是版式可控，缺点是改图要动坐标。

## 许可与来源

MIT，见 `LICENSE`（Copyright 2026 zyx0407）。

写法上参考了：C4 model 与评审清单、D2 的声明式思路、Mermaid 的形状语义、Grafana Loki 架构文档的分步写法——**只借鉴思路，未复制任何代码**。

## 一句话原则

**图是地图，不是海报**：一屏、一色、每条箭头都说话。
