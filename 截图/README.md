# 截图 · 无头出图

把网页截成图，供人工比对。**不是**随手 `msedge --screenshot`——那样出的图尺寸会偏、空白页会静默成功。

## 是什么

`shot.py`：给一个 URL 和一个尺寸，出一张**像素精确**的图，并且能判断「这张图是不是空白/坏图」。

## 怎么用

```bash
python shot.py --url "http://127.0.0.1:5199/index.html?theme=day" --out out.png --w 1440 --h 900
```

可选：`--wait 毫秒`（额外等渲染）、`--budget 毫秒`（虚拟时间预算）。

## 它替你挡掉的坑（都是真踩过的）

| 坑 | 现象 | 处理 |
| --- | --- | --- |
| `--window-size` 与实际视口差 | 出图比预期窄 30px、矮 95px | 内部按实测把窗口补偿回 `w+30` / `h+95`，再用探针复核视口 |
| 视口最小 504px | 想要 390 宽，实际按 504 布局 | 窄屏自动套一层 iframe 外壳，并在 URL 上加 `still=1` 冻结动画 |
| `--virtual-time-budget` 太短 | 截图截在半截动画上 | 预算取 `wait + 1500` 的下限 |
| 页面白屏也"成功" | 拿到一张纯白图，误以为样式没生效 | 用 Pillow 算灰度标准差，低于阈值判空白，重试至多 3 次后退出码 1 |
| 临时 profile 堆积 | `%TEMP%` 涨到 GB 级 | 无论成功失败都删 profile |

## 依赖

- Python 3（`Pillow`）
- Edge 或 Chrome（默认找 Edge：`C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`）

## 边界

- 只负责「出图 + 判定空白」，不负责比对差异。
- 有动画/视频的页面，截到哪一帧不确定；要稳定就用页面自带的冻结参数（如 `?still=1`）。
- 无头模式下 iframe 里的 `setTimeout`/`rAF` 不随虚拟时间推进——需要计时的断言别放 iframe 里做。
