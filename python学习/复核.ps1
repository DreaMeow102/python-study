# ══════════════════════════════════════════════════════════════════════
#  复核.ps1 —— 跑你写的参考解，和「独立写下的正确答案」比，绿的才写进答案
# ══════════════════════════════════════════════════════════════════════
#
#  ⛔ 它不读任何文档。只读 .py 文件。
#
#  为什么一定要比：
#     真跑只能证明「这份代码能跑」，**不能**证明「这份代码答对了」。
#     没有比对的脚本生成答案，会产出一个**带着"实测"光环的错答案**——
#     比手写的错答案更坏，因为手写的还会被怀疑，"实测"的不会。
#
#  ── 文件约定（每题一个 .py）──────────────────────────────────────────
#
#     第X课\参考\a1.py
#
#     # @输入          ← 可选。要喂给 stdin 的行，一行一条（不写 = 没有输入）
#     # 407
#     # @预期          ← 必须。**我认为这题的正确答案**（独立于代码写下，不是抄代码的输出）
#     # 各位数字之和：11
#     # @结束          ← 必须。这行之下才是代码
#     n = int(input())
#     …
#
#     ⚠️ **参考解里不要写 `input()` 的提示符**，写裸的 `input()`。
#        重定向之后提示符会和后面的输出挤在一起，没法逐行比。
#        （题面里画提示符没关系 —— 那是给学生看的交互示意。）
#
#     ⚠️ `@预期` 是**独立写下**的。抄代码的输出等于没比。
#
#  ── 三种结果 ────────────────────────────────────────────────────────
#
#     绿  = 实跑 == 预期        → 这题可以写进答案
#     红  = 实跑 != 预期 / 跑挂  → **要么代码错，要么我判断错，都得查**
#     缺头 = 没有 @预期 或 @结束 → 这份文件不合格
#
#     ⛔ **只有绿的题才写进答案。** 红的不许写 —— 那等于把"没查清的"当"实测过的"发出去。
#
#  ── 用法 ────────────────────────────────────────────────────────────
#
#     .\复核.ps1                跑全部课次，只核对
#     .\复核.ps1 第六课          只跑一个课次
#     .\复核.ps1 -写答案         核对 + 把**绿的题**写成 第X课-参考答案.md
#
#  退出码：0 = 全绿；1 = 有红或缺头
#
#  ⚠️ 本文件必须存成 UTF-8 with BOM（PS 5.1 读无 BOM 的 UTF-8 会按 ANSI 解，中文全乱）
# ══════════════════════════════════════════════════════════════════════

param(
    [string]$课 = '',
    [switch]$写答案
)

$ErrorActionPreference = 'Stop'
$根 = $PSScriptRoot
$python = 'C:\Users\Administrator\AppData\Local\Python\pythoncore-3.14-64\python.exe'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$绿 = 0; $红 = 0; $缺头 = 0; $扫到 = 0
$坏清单 = @()

if (-not (Test-Path $python)) { Write-Host "找不到 Python：$python" -ForegroundColor Red; exit 1 }

$临时 = Join-Path $env:TEMP ('复核_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory $临时 | Out-Null

function 归一([string]$s) {
    if ($null -eq $s) { return '' }
    return ($s -replace "`r`n", "`n").TrimEnd("`n")
}

# ── 拆一个参考解文件 ─────────────────────────────────────────────────
function 拆解([string]$路径) {
    $ls = [regex]::Split([System.IO.File]::ReadAllText($路径, $utf8), "(?<=\n)")
    $模式 = ''; $输入 = @(); $预期 = @(); $码起 = -1
    for ($i = 0; $i -lt $ls.Count; $i++) {
        $l = $ls[$i].TrimEnd("`r", "`n")
        if ($l -match '^#\s*@结束') { $码起 = $i + 1; break }
        if ($l -match '^#\s*@输入') { $模式 = '输入'; continue }
        if ($l -match '^#\s*@预期') { $模式 = '预期'; continue }
        if ($模式 -eq '输入') { $输入 += ($l -replace '^#\s?', '') }
        elseif ($模式 -eq '预期') { $预期 += ($l -replace '^#\s?', '') }
    }
    if ($码起 -lt 0) { return $null }
    if ($预期.Count -eq 0) { return $null }
    $代码 = ''
    if ($码起 -lt $ls.Count) { $代码 = ($ls[$码起..($ls.Count - 1)] -join '') }
    return @{ 输入 = ($输入 -join "`n"); 预期 = ($预期 -join "`n"); 代码 = $代码 }
}

# ── 跑一段代码（可带 stdin） ─────────────────────────────────────────
function 跑([string]$代码, [string]$输入) {
    $f = Join-Path $临时 'x.py'
    [System.IO.File]::WriteAllText($f, $代码, $utf8)
    $o = Join-Path $临时 'x.out'; $e = Join-Path $临时 'x.err'
    if (Test-Path $o) { Remove-Item $o -Force }
    if (Test-Path $e) { Remove-Item $e -Force }
    $参数 = @{ FilePath = $python; ArgumentList = @('-X', 'utf8', $f); NoNewWindow = $true; Wait = $true; PassThru = $true
               RedirectStandardOutput = $o; RedirectStandardError = $e }
    if ($输入) {
        $i = Join-Path $临时 'x.in'
        $喂 = $输入
        if (-not $喂.EndsWith("`n")) { $喂 += "`n" }
        [System.IO.File]::WriteAllText($i, $喂, $utf8)
        $参数['RedirectStandardInput'] = $i
    }
    $p = Start-Process @参数
    $s = ''
    if (Test-Path $o) { $s += [System.IO.File]::ReadAllText($o, $utf8) }
    if ((Test-Path $e) -and (Get-Item $e).Length -gt 0) { $s += [System.IO.File]::ReadAllText($e, $utf8) }
    return @{ 退出 = $p.ExitCode; 输出 = $s }
}

# ── 找课次 ───────────────────────────────────────────────────────────
$课次 = @(Get-ChildItem $根 -Directory | Where-Object { $_.Name -ne '旧文档' } | Sort-Object Name)
if ($课) { $课次 = @($课次 | Where-Object { $_.Name -eq $课 }) }

Write-Host ''
Write-Host '═══ 复核 · 实跑 ↔ 我写下的正确答案 ═══' -ForegroundColor Cyan

$答案段 = @{}

foreach ($d in $课次) {
    $参考目录 = Join-Path $d.FullName '参考'
    if (-not (Test-Path $参考目录)) { continue }
    $文件 = @(Get-ChildItem $参考目录 -File -Filter *.py | Sort-Object Name)
    if ($文件.Count -eq 0) { continue }

    Write-Host ''
    Write-Host ("───── {0}（{1} 题）─────" -f $d.Name, $文件.Count) -ForegroundColor Cyan

    $本课段 = @()
    foreach ($f in $文件) {
        $id = $f.BaseName.ToUpper()
        $扫到++
        $t = 拆解 $f.FullName
        if ($null -eq $t) {
            Write-Host ("  [缺头] {0} —— 没有 # @预期 或 # @结束" -f $id) -ForegroundColor Magenta
            $缺头++; $坏清单 += "$($d.Name)\$($f.Name)（缺头）"; continue
        }
        $r = 跑 $t.代码 $t.输入
        $真 = 归一 $r.输出
        $期 = 归一 $t.预期

        if ($r.退出 -ne 0) {
            Write-Host ("  [红]   {0} 跑挂了（退出码 {1}）" -f $id, $r.退出) -ForegroundColor Red
            $真 -split "`n" | ForEach-Object { Write-Host "         |$_" -ForegroundColor DarkRed }
            $红++; $坏清单 += "$($d.Name)\$($f.Name)（跑挂）"
        }
        elseif ($真 -eq $期) {
            Write-Host ("  [绿]   {0}" -f $id) -ForegroundColor Green
            $绿++
            $块 = "## $id`n`n"
            if ($t.输入) { $块 += "**输入**（依次喂给 stdin）：" + ($t.输入 -replace "`n", ' / ') + "`n`n" }
            $块 += '```python' + "`n" + $t.代码.TrimEnd("`r", "`n") + "`n" + '```' + "`n`n"
            $块 += '**【自检】**' + "`n`n" + '```' + "`n" + $真 + "`n" + '```' + "`n"
            $本课段 += $块
        }
        else {
            Write-Host ("  [红]   {0} 实跑 ≠ 我写下的正确答案" -f $id) -ForegroundColor Red
            Write-Host '         --我写的答案--' -ForegroundColor DarkYellow
            $期 -split "`n" | ForEach-Object { Write-Host "         |$_" -ForegroundColor DarkYellow }
            Write-Host '         --真跑出来--' -ForegroundColor DarkRed
            $真 -split "`n" | ForEach-Object { Write-Host "         |$_" -ForegroundColor DarkRed }
            $红++; $坏清单 += "$($d.Name)\$($f.Name)（不符）"
        }
    }
    if ($本课段.Count -gt 0) { $答案段[$d.Name] = $本课段 }
}

# ── 写答案（只写绿的） ───────────────────────────────────────────────
if ($写答案) {
    Write-Host ''
    if ($答案段.Count -eq 0) {
        Write-Host '  没有绿题，一个字都没写。' -ForegroundColor Yellow
    }
    foreach ($名 in ($答案段.Keys | Sort-Object)) {
        $目标 = Join-Path (Join-Path $根 $名) "$名-参考答案.md"
        if (Test-Path $目标) {
            $旧数 = ([regex]::Matches([System.IO.File]::ReadAllText($目标, $utf8), '(?m)^## ')).Count
            if ($答案段[$名].Count -lt $旧数) {
                Write-Host ("  拒写 {0}：新版只有 {1} 题，旧文件里有 {2} 题 —— 会砍掉内容。" -f "$名-参考答案.md", $答案段[$名].Count, $旧数) -ForegroundColor Red
                $红++; $坏清单 += "$名-参考答案.md（拒写：题数会变少）"
                continue
            }
        }
        $文 = "# $名 参考答案`n`n> **只有代码和实测输出** —— 由 ``复核.ps1`` 跑出来，且已核对我写下的答案。`n`n---`n`n"
        $文 += ($答案段[$名] -join "`n---`n`n")
        [System.IO.File]::WriteAllText($目标, $文, $utf8)
        Write-Host ("  写出 {0}（{1} 题，只有绿的）" -f (Join-Path $名 "$名-参考答案.md"), $答案段[$名].Count) -ForegroundColor Gray
    }
    if ($红 -gt 0 -or $缺头 -gt 0) {
        Write-Host ("  ⚠️ 有 {0} 题红的 / {1} 题缺头，**没写进答案** —— 那些还没查清。" -f $红, $缺头) -ForegroundColor Yellow
    }
}

Remove-Item $临时 -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '══════════════════════════════════════════' -ForegroundColor Cyan
if ($扫到 -eq 0) {
    Write-Host '=== 结果：空 === 一个参考解都没找到（第X课\参考\*.py）' -ForegroundColor Yellow
    Write-Host '      ⚠️ 这不是"绿"——什么都没查。' -ForegroundColor Yellow
    exit 1
}
if ($红 -eq 0 -and $缺头 -eq 0) {
    Write-Host ("=== 结果：绿 === 实跑符合答案 {0} 题" -f $绿) -ForegroundColor Green
    exit 0
}
else {
    Write-Host ("=== 结果：红 === 绿 {0} · 红 {1} · 缺头 {2}" -f $绿, $红, $缺头) -ForegroundColor Red
    foreach ($x in $坏清单) { Write-Host "      · $x" -ForegroundColor DarkRed }
    exit 1
}
