# 架构图自检：把"评审 10 问"里能机器查的部分查掉（Windows PowerShell 5.1+ / pwsh 7）
# 用法：lint.ps1 -Html .\index.html    （有问题退出码 1）
param(
  [Parameter(Mandatory = $true)][string]$Html
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Html)) { throw "找不到 HTML：$Html" }
$t = [IO.File]::ReadAllText((Resolve-Path $Html).Path, [Text.Encoding]::UTF8)
$errors = New-Object System.Collections.Generic.List[string]
$warns = New-Object System.Collections.Generic.List[string]

function Err([string]$s) { $errors.Add($s) }
function Warn([string]$s) { $warns.Add($s) }

# ---- 1. 画布尺寸 ----
$cw = 1400; $ch = 0
if ($t -match '(?s)\.canvas\s*\{[^}]*?width:\s*(\d+)px;\s*height:\s*(\d+)px') {
  $cw = [int]$Matches[1]; $ch = [int]$Matches[2]
} else { Err '找不到 .canvas 的 width/height' }
if ($ch -and ($ch -lt 600 -or $ch -gt 1200)) { Warn "画布高度 $ch 不在建议区间 700–920" }
if ($t -match 'viewBox="0 0 (\d+) (\d+)"') {
  if ([int]$Matches[1] -ne $cw -or [int]$Matches[2] -ne $ch) { Err "svg viewBox=$($Matches[1])x$($Matches[2]) 与画布 ${cw}x${ch} 不一致" }
} else { Warn 'svg 没写 viewBox' }

# ---- 2. 标题三件套 / 图例 ----
if ($t -notmatch 'class="h1"') { Err '缺标题 .h1' }
elseif ($t -notmatch '(?s)class="h1"[^>]*>([^<]*)<span') { Err '标题缺副题 <span>' }
elseif (($Matches[1] -split '·').Count -lt 2) { Warn '标题建议写「主题 · 副题」' }
if ($t -notmatch 'class="legend"') { Err '缺图例 .legend' }
if ($t -match 'class="box dashed"' -and $t -notmatch '虚线' -and ($t -notmatch '(?s)class="legend".*?class="dash"')) { Warn '有虚线框但图例没解释"虚线"' }

# ---- 3. 框：必须有标题行/说明行，且在画布内、互不重叠 ----
$boxes = @()
foreach ($m in [regex]::Matches($t, '<div class="box(?<dash>[^"]*)" style="(?<style>[^"]*)"')) {
  $st = $m.Groups['style'].Value
  $l = 0; $tp = 0; $w = 0; $h = 0
  if ($st -match 'left:\s*(\d+)px') { $l = [int]$Matches[1] }
  if ($st -match 'top:\s*(\d+)px') { $tp = [int]$Matches[1] }
  if ($st -match 'width:\s*(\d+)px') { $w = [int]$Matches[1] }
  if ($st -match 'height:\s*(\d+)px') { $h = [int]$Matches[1] }
  $boxes += [pscustomobject]@{ Left = $l; Top = $tp; W = $w; H = $h; Dashed = ($m.Groups['dash'].Value -match 'dashed') }
}
if ($boxes.Count -eq 0) { Err '一个 .box 都没找到' }
$tCount = ([regex]::Matches($t, '<div class="t">')).Count
$sCount = ([regex]::Matches($t, '<div class="s">')).Count
if ($tCount -lt $boxes.Count) { Err "有 $($boxes.Count) 个框，但只有 $tCount 个标题行 .t" }
if ($sCount -lt $boxes.Count) { Warn "有 $($boxes.Count) 个框，说明行 .s 只有 $sCount 个" }
foreach ($b in $boxes) {
  if ($b.Left -lt 0 -or $b.Top -lt 0) { Err "框越界（left=$($b.Left) top=$($b.Top)）" }
  if ($cw -and ($b.Left + $b.W -gt $cw)) { Err "框右边越界：left=$($b.Left) + width=$($b.W) > 画布宽 $cw" }
  if ($ch -and ($b.Top + $b.H -gt $ch)) { Err "框下边越界：top=$($b.Top) + height=$($b.H) > 画布高 $ch" }
}
for ($i = 0; $i -lt $boxes.Count; $i++) {
  for ($j = $i + 1; $j -lt $boxes.Count; $j++) {
    $a = $boxes[$i]; $b = $boxes[$j]
    $ix = [Math]::Min($a.Left + $a.W, $b.Left + $b.W) - [Math]::Max($a.Left, $b.Left)
    $iy = [Math]::Min($a.Top + $a.H, $b.Top + $b.H) - [Math]::Max($a.Top, $b.Top)
    if ($ix -gt 1 -and $iy -gt 1) { Err "两个框重叠：($($a.Left),$($a.Top)) 与 ($($b.Left),$($b.Top))" }
  }
}

# ---- 4. 连线：箭头引用存在、每条线有标记、标签数量够 ----
$markerIds = @()
foreach ($m in [regex]::Matches($t, '<marker\s+id="([^"]+)"')) { $markerIds += $m.Groups[1].Value }
$wires = 0; $noArrow = 0
foreach ($m in [regex]::Matches($t, '<path(?<attrs>[^>]*?)/>')) {
  $attrs = $m.Groups['attrs'].Value
  if ($attrs -notmatch 'stroke="') { continue }          # 跳过 defs 里的箭头形状
  if ($attrs -match 'class="bus"') { continue }          # 纯连接总线，不算箭头
  $wires++
  if ($attrs -notmatch 'marker-end="url\(#([^)]+)\)"') { $noArrow++ }
  elseif ($markerIds -notcontains $Matches[1]) { Err "箭头引用了不存在的 marker：#$($Matches[1])" }
}
if ($wires -eq 0) { Warn '没找到连线 path' }
if ($noArrow -gt 0) { Err "有 $noArrow 条连线没有箭头（marker-end 缺失）" }
$lblCount = ([regex]::Matches($t, 'class="lbl"')).Count
if ($wires -gt 0 -and $lblCount -lt $wires) { Warn "连线 $wires 条，但线上标签只有 $lblCount 个（每条箭头都该有标签）" }

# ---- 5. 流动点只能在 .flow 里 ----
$circleCount = ([regex]::Matches($t, '<circle')).Count
$flowCircles = ([regex]::Matches($t, '(?s)<g class="flow".*?</g>')).Count
if ($circleCount -gt 0 -and $flowCircles -eq 0) { Warn '有 circle，但没放进 <g class="flow">' }

# ---- 输出 ----
Write-Host ("自检：{0}" -f (Split-Path -Leaf $Html))
Write-Host ("  框 {0} 个 · 连线 {1} 条 · 标签 {2} 个 · 圆点 {3} 个" -f $boxes.Count, $wires, $lblCount, $circleCount)
foreach ($w in $warns) { Write-Host ("  [提示] " + $w) }
foreach ($e in $errors) { Write-Host ("  [错误] " + $e) }
if ($errors.Count -gt 0) { Write-Host ("结果：不通过（错误 {0} · 提示 {1}）" -f $errors.Count, $warns.Count); exit 1 }
Write-Host ("结果：通过（提示 {0}）" -f $warns.Count)
exit 0
