# ══════════════════════════════════════════════════════════════════════
#  对账.ps1 —— 参考答案里的每题脚本，真跑一遍，和文档里印的输出逐字比
# ══════════════════════════════════════════════════════════════════════
#
#  为什么要有这个脚本（`学习规定-AI.md` §1 证据纪律）：
#
#  【自检】最容易犯的错，不是"代码写错"，是**印上去的输出来自记忆而不是实跑**。
#  2026-09-22 就抓到过一次真事：附录里 `"abc".splits(",")` 的报错原文，
#  我凭印象写成 `...has no attribute 'splits'`，而 3.14 实际还会补一句
#  `. Did you mean: 'split'?` —— **两张表都标着"实跑抓下来的"，却有一条是编的。**
#
#  这个脚本把"抽脚本 → 真跑 → 逐字比"固定下来，人工不用再手打一遍。
#
#  用法：
#    .\对账.ps1                # 查全部课次
#    .\对账.ps1 第六课          # 只查一课
#    .\对账.ps1 -详细           # 不一致时把逐行差异也打出来（默认就打）
#
#  查什么：
#    · 只查**常规题**（题号形如 `a1`/`b2`/`h3`）—— I1/I2/I3 是特殊题，
#      结构不一样（坏代码/好代码/没有脚本），**本脚本不碰**
#    · 每题的**学生脚本**（参考答案里紧跟题号的那个 ```python 块）
#    · 每题的**期望输出**（答案里的【自检】或"实际输出"块）
#    · 若该课有正文，**再拿正文里同题的输出块比一遍**（三方一致）
#
#  退出码：0 = 全部一致；1 = 有不一致或跑挂了
#
#  ⚠️ 本文件必须存成 **UTF-8 带 BOM**：PowerShell 5.1 读无 BOM 的 UTF-8 会按 ANSI 解，
#     中文的字节会吃掉后面的引号 → `Unexpected token`。
#     改完记得：`[System.IO.File]::WriteAllText($p,$t,(New-Object System.Text.UTF8Encoding($true)))`
# ══════════════════════════════════════════════════════════════════════

param(
    [string]$课 = '',
    [switch]$响亮      # 默认静音：只打异常 + 汇总（省 token）。想看每题就加 -响亮
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

# 解释器：先认这台机器上记着的那一个；**换了机器 / 升级了 Python** 就退回 PATH 上的 python。
# 为什么不写死一个就完事：路径一变脚本直接红，而那个"红"会被误读成"文档有问题"。
$python = 'C:\Users\Administrator\AppData\Local\Python\pythoncore-3.14-64\python.exe'
if (-not (Test-Path $python)) {
    $回退 = Get-Command python -ErrorAction SilentlyContinue
    if ($回退) {
        $python = $回退.Source
        Write-Host "⚠ 记着的那条 Python 路径不在了，改用 PATH 上的：$python" -ForegroundColor Yellow
    }
}

# ── 覆盖账本（2026-09-22 加）──────────────────────────────────────────
# 【为什么要有】本脚本原先**静默跳过**抽不到题的文件夹，汇总照样打"绿"——
#   `真题实战\` 就是这样：答案文件叫 `真题实战一-参考答案.md`，而脚本按 `$名-参考答案.md` 拼串，
#   找不到 → `continue`，还错报成"已知例外：第一课"。**"绿"掩盖了"没查"。**
# 【现在的规矩】① 用通配找答案文件；② 抽不到题**一定说出来**；
#   ③ 除非该文件夹在下面的 `$已知不覆盖` 里**有名有姓**，否则算**失败**（红）。
$已知不覆盖 = @{ '第一课' = '没有单独的 `*-参考答案.md`（习题自检内联在正文里）' }
$未覆盖 = @()
$总通用 = 0
$总通用跳过 = 0

function 好($t) { if ($响亮) { Write-Host "  [OK]   $t" -ForegroundColor Green } }
function 坏($t) { Write-Host "  [!!]   $t" -ForegroundColor Red; $script:失败++ }
function 平($t) { if ($响亮) { Write-Host "  [--]   $t" -ForegroundColor DarkGray } }
function 标($t) { Write-Host ''; Write-Host $t -ForegroundColor Cyan }

$失败 = 0
$总题数 = 0
$总一致 = 0
$总整理 = 0

function 归一([string]$s) {
    if ($null -eq $s) { return '' }
    return ($s -replace "`r`n", "`n").TrimEnd("`n")
}

# 抽一题：返回 @{ 脚本 = ...; 期望 = ... }
function 抽题([string]$文, [string]$id) {
    # ⚠️ 题号标题的层级别搞混：
    #   **参考答案**里是 `## A1 ·`（两个 #），**正文**里是 `### A1 ·`（三个 #）。
    #   所以这里 `#{2,4}` 两头都吃。题号大小写不敏感（文档写 A1，脚本内部用小写 a1）。
    #
    # ⚠️ 断句不能只看"以 # 开头"：代码块里的注释（`# word[0] = "B"`、`# ValueError: ...`）
    #   也以 `# ` 开头，会把题目从中间切断（2026-09-22 实测：a1/d3/e1 就因为注释抽不到）。
    #   所以**只认已知的标题形态**：`X1 ·` / `X 组` / `★` / `讲解` / `附录` / `交作业` / `第 N 节`。
    $标题 = '^#{1,4} (?:(?:[A-H]|I|[甲乙丙丁])\d?(?= ?[·组])|★|讲解|附录|交作业|第 ?\d+ ?节)'
    $pat = '(?ims)^#{2,4} ' + $id + ' · .*?(?=' + $标题 + '|\z)'
    $m = [regex]::Match($文, $pat)
    if (-not $m.Success) { return $null }
    $seg = $m.Value

    # 特殊题（改错题 / 读代码 / 读官方文档）**不查**：
    #   它们的结构是"坏代码 + 正确答案"或"只读不跑"，没有"一个能跑的脚本 + 一份【自检】"这个配对。
    #   （2026-09-22 实测：第五课 F2 是改错题，被当成常规题抽出来跑，报了个假红。）
    $标题行 = ($seg -split "`n")[0]
    if ($标题行 -match '改错|读代码|读官方文档|读文档') { return $null }

    $sm = [regex]::Match($seg, '(?s)```python\r?\n(.*?)```')
    if (-not $sm.Success) { return $null }

    # 期望输出的标记：第六课用【自检】，第二~五课用"实际输出"。
    # 标记行和代码块之间**允许夹几行说明**：`(?:(?!```)[^\r\n]*\r?\n)*?` 只吃非围栏行，
    # 既不会跳过真正的围栏，又能容忍"（整理过：……）"这类**跨行**的批注。
    $夹注 = '(?:(?!```)[^\r\n]*\r?\n)*?'
    $om = [regex]::Match($seg, '(?s)(?:\*\*【自检】\*\*|\*\*实际输出\*\*|\*\*实际输出：\*\*)[^\r\n]*\r?\n+' + $夹注 + '```\r?\n(.*?)```')
    if (-not $om.Success) {
        # 兜底：紧跟"实际输出"字样的那个非 python 块
        $om = [regex]::Match($seg, '(?s)实际输出[^\r\n]*\r?\n+' + $夹注 + '```\r?\n(.*?)```')
    }
    if (-not $om.Success) { return $null }

    # ⚠️ 约定（和 `体检.ps1` 里那个「（拟）」同一个套路）：
    #   有的题**故意展示报错**（例：第二课 B2 的 `int("24.5")`、第三课 B3 的越界），
    #   文档把 traceback **整理成一行**印出来，那不是"原样跑的输出"，但对学生是对的。
    #   这种块，标记行里写**「（整理过）」**，本脚本就跳过它，只在报告里说明一句。
    $整理过 = ($om.Value -match '整理过')

    return @{ 脚本 = $sm.Groups[1].Value; 期望 = $om.Groups[1].Value; 整理过 = $整理过 }
}

if (-not (Test-Path $python)) {
    坏 "找不到 Python：$python（先确认解释器路径没变）"
    exit 1
}

# ── 通用兜底抽取（2026-09-22 加）──────────────────────────────────────
# 给**不用 `A1` 编号**的答案文件用（例：`真题实战一-参考答案.md` 是"第 1 题 / 第 2 题"）。
# 判据**保守**：三条全中才算一题；任何一条不中就记进"跳过"计数，**绝不猜**：
#   ① 该段里**恰好一个** ```python 块
#   ② 段内有紧跟"【自检】/ 实际输出 / 运行结果"字样的围栏输出块
#   ③ 代码里**没有 `input(`** —— 要 stdin 的题跑不出确定输出，只能人工
# 为什么值得写：不写的话，`真题实战\` 里那几道**本来能自动对账**的题永远没人验。
function 抽题_通用([string]$文) {
    $题 = New-Object System.Collections.Generic.List[hashtable]
    foreach ($s in [regex]::Matches($文, '(?ms)^## .*?(?=^## |\z)')) {
        $seg = $s.Value
        $py = [regex]::Matches($seg, '(?s)```python\r?\n(.*?)```')
        if ($py.Count -ne 1) { continue }
        $代码 = $py[0].Groups[1].Value
        $夹注 = '(?:(?!```)[^\r\n]*\r?\n)*?'
        $om = [regex]::Match($seg, '(?s)(?:\*\*【自检】\*\*|实际输出|运行结果)[^\r\n]*\r?\n+' + $夹注 + '```\r?\n(.*?)```')
        if (-not $om.Success) { $script:总通用跳过++; continue }
        if ($代码 -match 'input\s*\(') { $script:总通用跳过++; continue }
        $题.Add(@{
            名     = (($seg -split "`n")[0]).Trim()
            脚本   = $代码
            期望   = $om.Groups[1].Value
            整理过 = ($om.Value -match '整理过')
        })
    }
    return $题
}

# 跑一题：`$临时` / `$python` / `$utf8` 取自脚本作用域。
function 实跑比对([string]$id, [string]$代码, [string]$期望原文) {
    $f = Join-Path $临时 "$id.py"
    [System.IO.File]::WriteAllText($f, $代码, $utf8)
    $o = Join-Path $临时 "$id.out"
    $e = Join-Path $临时 "$id.err"
    # ⚠️ 不能用 `& $python ... 2>&1 | Out-File`：
    #   本脚本开头是 $ErrorActionPreference='Stop'，而 PowerShell 会把**原生命令的 stderr**
    #   当错误记录抛出来 —— 只要学生脚本里有任何 WARNING / traceback，整个对账就当场中断
    #   （2026-09-22 实测：跑到第二课 b1 就崩）。用 Start-Process 重定向到文件绕开这层语义。
    Start-Process -FilePath $python -ArgumentList @('-X', 'utf8', $f) `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $o -RedirectStandardError $e | Out-Null
    $实跑 = ''
    if (Test-Path $o) { $实跑 += [System.IO.File]::ReadAllText($o, $utf8) }
    if ((Test-Path $e) -and (Get-Item $e).Length -gt 0) {
        $实跑 += [System.IO.File]::ReadAllText($e, $utf8)
    }
    $期望 = 归一 $期望原文
    $得到 = 归一 $实跑
    return @{ 一致 = ($得到 -eq $期望); 期望 = $期望; 得到 = $得到 }
}

$临时 = Join-Path $env:TEMP ('dsh_duizhang_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory $临时 | Out-Null

try {
    $课次 = @(Get-ChildItem $root -Directory |
         Where-Object { $_.Name -match '^(第[一二三四五六七八九十]+课|复习[一二三四五六七八九十]+|真题实战.*)$' } |
         Sort-Object Name)
    if ($课) { $课次 = @($课次 | Where-Object { $_.Name -eq $课 }) }

    Write-Host ''
    Write-Host '═══ 对账 · 参考答案脚本实跑 ↔ 文档里印的输出 ═══' -ForegroundColor Cyan

    foreach ($d in $课次) {
        $名 = $d.Name
        $正文路径 = Join-Path $d.FullName "$名-正文.md"

        标 "───── $名 ─────"

        # 答案文件用**通配**找，不拼 `$名-参考答案.md` ——
        # `真题实战\` 里那份叫 `真题实战一-参考答案.md`，拼串找不到它（见文件头的覆盖账本）。
        $答案候选 = @(Get-ChildItem $d.FullName -File -Filter '*-参考答案.md' -ErrorAction SilentlyContinue)
        if ($答案候选.Count -eq 0) {
            if ($已知不覆盖.ContainsKey($名)) {
                平 "$名 跳过（已知不覆盖：$($已知不覆盖[$名])）"
            }
            else {
                $未覆盖 += "$名 —— 找不到任何 *-参考答案.md 文件"
                坏 "$名 没有参考答案文件，却也不在「已知不覆盖」名单里"
            }
            continue
        }
        $答案路径 = $答案候选[0].FullName

        $答案 = [System.IO.File]::ReadAllText($答案路径, $utf8)
        $正文 = $null
        if (Test-Path $正文路径) { $正文 = [System.IO.File]::ReadAllText($正文路径, $utf8) }

        $题号 = @()
        foreach ($g in 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h') {
            for ($i = 1; $i -le 6; $i++) { $题号 += "$g$i" }
        }
        # 复习课用「甲/乙/丙」编号（复习一：甲6+乙4+丙3；复习二同）
        foreach ($g in '甲', '乙', '丙') {
            for ($i = 1; $i -le 6; $i++) { $题号 += "$g$i" }
        }

        $本课题 = 0; $本课一致 = 0
        foreach ($id in $题号) {
            $t = 抽题 $答案 $id
            if ($null -eq $t) { continue }
            $本课题++; $总题数++

            if ($t.整理过) {
                $总整理++
                平 "$id 文档标了「（整理过）」—— 故意展示报错，不是原样跑的输出，跳过"
                continue
            }

            $r = 实跑比对 $id $t.脚本 $t.期望
            $一致 = $r.一致
            $期望 = $r.期望
            $得到 = $r.得到

            $正文一致 = $null
            if ($正文) {
                $tb = 抽题 $正文 $id
                if ($null -ne $tb) { $正文一致 = ((归一 $tb.期望) -eq $期望) }
            }

            if ($一致 -and ($正文一致 -ne $false)) {
                $本课一致++; $总一致++
                好 "$id"
            }
            else {
                if (-not $一致) {
                    坏 "$id 实跑 ≠ 答案里印的输出"
                    Write-Host '         ---- 文档印的 ----' -ForegroundColor DarkYellow
                    ($期望 -split "`n") | ForEach-Object { Write-Host "         |$_" -ForegroundColor DarkYellow }
                    Write-Host '         ---- 真跑出来 ----' -ForegroundColor DarkRed
                    ($得到 -split "`n") | ForEach-Object { Write-Host "         |$_" -ForegroundColor DarkRed }
                }
                if ($正文一致 -eq $false) {
                    坏 "$id 正文里印的输出 ≠ 答案里印的输出"
                }
            }
        }

        if ($本课题 -gt 0) { 好 "$名 一致 $本课一致 / $本课题"; continue }

        # ── `A1` 编号一题都没抽到 → 试通用兜底（例：`真题实战\`）────────
        $通用 = @(抽题_通用 $答案)
        if ($通用.Count -eq 0) {
            $未覆盖 += "$名 —— 答案文件在，但 A1 编号和通用抽取都拿不到题"
            坏 "$名 抽不到任何可自动对账的题（答案文件是有的）"
            continue
        }
        $本通用一致 = 0
        $i = 0
        foreach ($t in $通用) {
            $i++
            $本课题++; $总题数++; $总通用++
            if ($t.整理过) { $总整理++; 平 "$($t.名) 标了「（整理过）」—— 跳过"; continue }
            $r = 实跑比对 "T$i" $t.脚本 $t.期望
            if ($r.一致) { $本通用一致++; $总一致++; 好 "$($t.名)" }
            else {
                坏 "$($t.名) 实跑 ≠ 答案里印的输出"
                Write-Host '         ---- 文档印的 ----' -ForegroundColor DarkYellow
                ($r.期望 -split "`n") | ForEach-Object { Write-Host "         |$_" -ForegroundColor DarkYellow }
                Write-Host '         ---- 真跑出来 ----' -ForegroundColor DarkRed
                ($r.得到 -split "`n") | ForEach-Object { Write-Host "         |$_" -ForegroundColor DarkRed }
            }
        }
        好 "$名 通用抽取：一致 $本通用一致 / $($通用.Count)"
    }
}
finally {
    Remove-Item $临时 -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host '══════════════════════════════════════════' -ForegroundColor Cyan
if ($未覆盖.Count -gt 0) {
    Write-Host "⚠ 未覆盖（有答案却对不了账）$($未覆盖.Count) 处 —— 这些**不是'对过了'，是'没对'**：" -ForegroundColor Yellow
    foreach ($x in $未覆盖) { Write-Host "   · $x" -ForegroundColor Yellow }
}
Write-Host ("  覆盖账：共 {0} 个文件夹 · 声明不覆盖 {1} 个 · 未覆盖 {2} 个 · 通用兜底抽到 {3} 题（另有 {4} 段含代码但不可自动对账）" -f `
    $课次.Count, $已知不覆盖.Count, $未覆盖.Count, $总通用, $总通用跳过) -ForegroundColor DarkGray
if ($失败 -eq 0) {
    Write-Host "=== 结果：绿 === 实跑与文档逐字一致 $总一致 / $总题数（另有 $总整理 题标了「（整理过）」，已跳过）" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "=== 结果：红 === 不一致 $失败 处（共抽 $总题数 题，一致 $总一致）" -ForegroundColor Red
    exit 1
}
