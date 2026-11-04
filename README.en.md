# Skills

[简体中文](README.md) · English

Small tools I actually use every day, pulled out into "clone and run" skills: one directory per skill, each with its own README and scripts.

Repository → <https://github.com/zyx0407/skills>

## What's inside

| Skill | What it does | Dependencies |
| --- | --- | --- |
| [`截图/`](截图/) (screenshots) | **Pixel-accurate** screenshots of a web page, with automatic blank / broken-image detection and retries | Python 3 + Pillow + Edge or Chrome |
| [`架构图/`](架构图/) (architecture diagrams) | Draws systems, data flows and deployment boundaries as a paper-coloured architecture diagram (pure HTML + SVG, zero dependencies), with templates and a self-check script | A browser; the render script also needs Node or PowerShell |

Directory names are in Chinese: `截图` means screenshots, `架构图` means architecture diagrams.

## Usage

```bash
# Screenshots
python 截图/shot.py --url "http://127.0.0.1:8080/" --out cover.png --w 1440 --h 900

# Architecture diagram: copy the template, edit it, then render with the bundled script
#   架构图/assets/template.html   → save as your own diagram
#   架构图/scripts/render.ps1     → render to PNG (Windows)
#   架构图/scripts/render.sh      → render to PNG (macOS / Linux)
```

Each directory has its own `README.md` with more detail: parameters, and the pitfalls I hit.

## Known limits

- Verified on Windows; on macOS / Linux you have to change the browser path in the scripts.
- The screenshot skill does not diff against a baseline — it only captures and judges whether a page is blank or broken.
- The architecture diagram is a static picture for people to read; it does not produce an interactive chart.

## License

[MIT](LICENSE). Personal details, domains and screenshots in this repository are examples only — replace them with your own.
