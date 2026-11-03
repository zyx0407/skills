#!/usr/bin/env node
// 通用出图（Node 16+；Windows / macOS / Linux 通用）
// 用法：node render.mjs <index.html> [out.png] [宽] [高] [倍数]
import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { pathToFileURL } from 'node:url'

const [, , htmlArg, outArg, wArg = '1400', hArg = '760', scaleArg = '1'] = process.argv
if (!htmlArg) {
  console.error('用法: node render.mjs <index.html> [out.png] [宽] [高] [倍数]')
  process.exit(2)
}
const html = path.resolve(htmlArg)
if (!existsSync(html)) {
  console.error('找不到 HTML：' + html)
  process.exit(1)
}
const out = outArg
  ? path.resolve(outArg)
  : path.join(path.dirname(html), '_shots', path.basename(html, '.html') + '.png')
mkdirSync(path.dirname(out), { recursive: true })

function candidates() {
  const win = process.env.ProgramFiles || 'C:\\Program Files'
  const win86 = process.env['ProgramFiles(x86)'] || 'C:\\Program Files (x86)'
  if (process.platform === 'win32') {
    return [
      win + '\\Microsoft\\Edge\\Application\\msedge.exe',
      win86 + '\\Microsoft\\Edge\\Application\\msedge.exe',
      win + '\\Google\\Chrome\\Application\\chrome.exe',
      win86 + '\\Google\\Chrome\\Application\\chrome.exe',
    ]
  }
  if (process.platform === 'darwin') {
    return [
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
      '/Applications/Chromium.app/Contents/MacOS/Chromium',
    ]
  }
  return [
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    '/usr/bin/microsoft-edge',
    '/snap/bin/chromium',
  ]
}
const browser = candidates().find((p) => p && existsSync(p))
if (!browser) {
  console.error('没找到 Chrome / Edge / Chromium；请安装其一，或改用 render.ps1 / render.sh')
  process.exit(1)
}

const ud = mkdtempSync(path.join(tmpdir(), 'arch-shot-'))
const args = [
  '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-sandbox',
  `--force-device-scale-factor=${scaleArg}`,
  `--user-data-dir=${ud}`,
  '--virtual-time-budget=3000',
  `--window-size=${wArg},${hArg}`,
  `--screenshot=${out}`,
  pathToFileURL(html).href,
]
try {
  spawnSync(browser, args, { stdio: 'ignore' })
} finally {
  try { rmSync(ud, { recursive: true, force: true }) } catch {}
}
if (!existsSync(out)) {
  console.error('出图失败：' + out)
  process.exit(1)
}
console.log('已出图：' + out)
