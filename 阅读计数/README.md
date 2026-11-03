# 阅读计数 · 静态站接真实阅读数

静态站在 GitHub Pages 上，没有后端；想把「阅读 N」做成真数，就得有个能自增的地方。
这个技能＝**一台自己的服务器 + 一个小服务 + 前端一次 fetch**。

## 结构

| 层 | 文件 | 说明 |
| --- | --- | --- |
| 服务 | `app.py` | Python 标准库 HTTP 服务，sqlite 存数，只监听 `127.0.0.1:8092` |
| 托管 | `views.service` | systemd 单元，开机自启、崩了自动重启 |
| 入口 | `nginx-api.conf` | nginx 反代 `api.<域名>:443` → 本机 8092，证书用 acme.sh |
| 前端 | `views.js` | 页面取数/计数，失败静默降级显示「—」 |

## 接口

```
GET  /views?slug=xxx        → {"slug":"xxx","n":123}
POST /views  {"slug":"xxx"} → {"slug":"xxx","n":124,"counted":true}
```

- 同一 IP + 同一 slug **10 分钟只算一次**（防刷新灌数）；
- **不存 IP**，库表只有 `slug / n / updated`；
- CORS 白名单写死在 `ALLOW`，别的站调不动。

## 页面怎么接

```html
<!-- 显示 -->
<span>阅读 <b class="vn" data-views="rebuild">—</b></span>
<!-- 计数：给 body 打标，脚本进页面时 POST 一次 -->
<body data-views-post="rebuild">
<script src="assets/views.js"></script>
```

取不到数就保持「—」，绝不因为接口挂了把页面搞坏。

## 边界

- 防刷只做到「IP+slug 时间窗」，没有账号体系，被分布式刷还是能刷；对个人站够用。
- 数只在这台服务器上，**没有异地备份**——服务器没了数就没了（可接受，也可以加每日 dump）。
- 需要服务器 443 端口在云厂商安全组里放行；这一步通常要人工点。
