# 一键出图：把架构图 HTML 渲染成 PNG（Edge/Chrome 无头，自动找浏览器）
# 用法：
#   render.ps1 -Html .\index.html                      # 输出到同目录 _shots\index.png
#   render.ps1 -Html .\index.html -Out .\shot.png      # 指定输出
#   render.ps1 -Html .\index.html -W 1400 -H 700       # 指定画布尺寸
#   render.ps1 -Html .\index.html -Scale 2             # 2 倍图
# 注意：--screenshot 必须给绝对路径；每轮换新的 user-data-dir（复用会撞锁）
param(
  [Parameter(Mandatory = $true)][string]$Html,
  [string]$Out = '',
  [int]$W = 1400,
  [int]$H = 760,
  [double]$Scale = 1,
  [int]$Budget = 3000
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Html)) { throw "找不到 HTML：$Html" }
$Html = (Resolve-Path $Html).Path
if (-not $Out) {
  $dir = Split-Path -Parent $Html
  $Out = Join-Path $dir ('_shots\' + [IO.Path]::GetFileNameWithoutExtension($Html) + '.png')
}
$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force $outDir | Out-Null }

$candidates = @(
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
)
$browser = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $browser) { throw '没找到 Edge / Chrome；请在脚本里改成你的浏览器路径。' }

$url = 'file:///' + ($Html -replace '\\', '/')
$ud = Join-Path $env:TEMP ('arch-shot-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
if (Test-Path $Out) { Remove-Item $Out -Force }
$args = @(
  '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-sandbox',
  "--force-device-scale-factor=$Scale",
  "--user-data-dir=$ud",
  "--virtual-time-budget=$Budget",
  "--window-size=$W,$H",
  "--screenshot=$Out",
  $url
)
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $browser @args 2>$null | Out-Null
$ErrorActionPreference = $prevEap
for ($i = 0; $i -lt 40 -and -not (Test-Path $Out); $i++) { Start-Sleep -Milliseconds 250 }
Remove-Item $ud -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path $Out) { Write-Host ("已出图：{0}" -f $Out) } else { throw "出图失败：$Out" }
