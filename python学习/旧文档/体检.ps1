# 体检.ps1 —— 学习项目文档一致性检查
#
#   用法：  pwsh -File 体检.ps1
#   结果：  全绿退出码 0；有 ❌ 退出码 1
#
# 为什么存在：
#   学习项目没有"测试套件"，真相来源是"学生学会没有"——那个跑不了。
#   但文档之间的一致性是可以跑的。这份脚本就是学习项目的 test/。
#   第五课那三笔欠账（速查漏循环 / 清单漏两行 / 课次表与规则九冲突），
#   全部属于下面这四类，机器一秒能查出来。
#
# 什么时候跑：
#   出题前（约定.md 附 D 第 0 项），把输出贴进 备忘.md 的会话条目。
#
# ⚠️ 本文件必须存成「UTF-8 with BOM」。
#   Windows PowerShell 读无 BOM 的 UTF-8 会按 ANSI 解，中文全变乱码、脚本直接报
#   Unexpected token。改完这个文件如果中文输出变乱，就是 BOM 被编辑器吃掉了。
#   补 BOM：  $p='体检.ps1'; $c=Get-Content $p -Raw -Encoding UTF8
#             Set-Content $p $c -Encoding UTF8 -NoNewline      # 5.1 会带 BOM
#             Set-Content $p $c -Encoding utf8BOM -NoNewline   # 7+ 用这个

param([switch]$短)   # -短 = 只打异常行 + 汇总（省 token）
$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# ── 已交付给学生的文件不追改名（避免他按旧名找不到）──────────────────
# 依据：模板.md §一 ·「已交付给学生的文件不追改名」。只报警告、不算失败。
#
# ① 批改名不符规范（应叫 `第X课-作业批改.md`）
$已知例外 = @(
    '第四课-批改.md',
    '第五课-批改.md',
    '复习一-批改.md'
)
# ② 正文用了描述性名字的，以及规范外的新类型（问答档）
$允许额外 = @(
    '第一课-让程序跑起来.md',
    '第二课-数字文本与f-string.md',
    '第一课-风格与习惯问答.md'
)

# ── 引用标的稳定「键」（2026-09-22 加）────────────────────────────────
# 【为什么要有键】检查项的**序号会随增删漂移**。2026-09-22 删掉旧检查 3 之后，
#   全库 5 处 `检查 N` 静默指错了一位 —— 而本脚本**自己发现不了**，因为没人查"检查号"。
# 【约定】文档里引用检查项写 **`体检.ps1` 检查「键」**，不写序号。
#   本表是唯一权威；加/删/改检查项 → **同时改这里 + `学习规定-AI.md` §6.0 那张表**。
$检查名 = @(
    '知识点 ID',     # 1
    '课次表',        # 2
    '命名规范',      # 3
    '交叉引用',      # 4
    '引用标',        # 5
    '体量',          # 6
    '出题抄例题',    # 7
    '文档地图',      # 8
    '题序'           # 9
)

# ── 规则编号（旧编号）─────────────────────────────────────────────────
# 重构把「规则一~十二」改成了 `学习规定-AI.md` 的 §N.M，但**已交付给学生的课次文件**
# 仍大量引用旧编号 —— 改那些文件是改教学内容，代价大于收益。
# 所以旧编号**不废除，改成"必须登记在册"**：权威登记表在 `学习规定-AI.md` §📇。
# 用了一个没登记的号（例：规则十三）= 引用悬空 → 报红。
$规则名 = @('规则一','规则二','规则三','规则四','规则五','规则六',
            '规则七','规则八','规则九','规则十','规则十一','规则十二')

# 只追加的历史流水：旧条目里的旧编号/旧检查号是**史实**，不参与下面的校验。
$历史流水 = @('备忘.md')

$失败 = 0
$警告 = 0
$通过 = 0

function 标题($t) { Write-Host "`n$t" -ForegroundColor Cyan }
function 好($t)   { $script:通过++; if (-not $短) { Write-Host "  [OK]   $t" -ForegroundColor Green } }
function 坏($t)   { Write-Host "  [!!]   $t" -ForegroundColor Red;     $script:失败++ }
function 警($t)   { Write-Host "  [警告] $t" -ForegroundColor Yellow;  $script:警告++ }

Write-Host "`n=== 学习项目体检 · $(Get-Date -Format 'yyyy-MM-dd HH:mm') ===" -ForegroundColor White

# ── 读文件 ────────────────────────────────────────────────────────────
# ⚠️ `语法速查.md` 已于 2026-09-22 作废（扔进 `旧文档\`）：学生从不打开它，
#    语法范围以 `进度.md` §1 为唯一依据。原来读它、校验它覆盖声明的「检查 3」一并删除。
$进度路径 = Join-Path $root '进度.md'
$易错路径 = Join-Path $root '易错点台账.md'
foreach ($p in @($进度路径, $易错路径)) {
    if (-not (Test-Path $p)) { Write-Host "缺文件：$p" -ForegroundColor Red; exit 2 }
}
$进度 = Get-Content $进度路径 -Raw -Encoding UTF8
$易错 = Get-Content $易错路径 -Raw -Encoding UTF8

# ══════════════════════════════════════════════════════════════════════
标题 '检查 1／9 · 知识点 ID 交叉校验（易错点台账 ↔ 进度.md §2）'
# ══════════════════════════════════════════════════════════════════════
$定义 = [regex]::Matches($进度, '(?m)^\|\s*\**\s*(\d+\.\d+)\s*\**\s*\|') |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$引用 = [regex]::Matches($易错, '【归属】([^\r\n]*)') |
        ForEach-Object { $_.Groups[1].Value } |
        ForEach-Object { [regex]::Matches($_, '(?<!§)\d+\.\d+') } |   # 排除 §6.2 这种节号
        ForEach-Object { $_.Value } | Sort-Object -Unique

if ($定义.Count -eq 0) { 坏 '进度.md §2 里没解析到任何 ID —— 表格格式变了吗？' }
else {
    好 "进度.md §2 定义了 $($定义.Count) 个知识点 ID"
    $缺失 = @($引用 | Where-Object { $定义 -notcontains $_ })
    if ($缺失.Count -gt 0) {
        坏 "易错点台账.md 引用了但进度.md 没有的 ID：$($缺失 -join ', ')（→ 进度.md §2 漏了一行）"
    } else {
        好 "易错点台账.md 引用的 $($引用.Count) 个 ID 全部能查到"
    }
}

# ══════════════════════════════════════════════════════════════════════
标题 '检查 2／9 · 课次表 ↔ 实际文件夹'
# ══════════════════════════════════════════════════════════════════════
# 解析课次表：名字 -> 状态（最后一格）
#   只取 §3 那一节 —— 否则 §7 分数趋势表（| 第一课 | 87 |）会把状态覆盖掉
$课次区 = $进度
if ($进度 -match '(?s)#\s*§3\s*课次表(.*?)(?=\r?\n#\s*§|\z)') { $课次区 = $Matches[1] }
$课次表 = @{}
foreach ($line in ($课次区 -split "`r?`n")) {
    if ($line -match '^\|\s*\*{0,2}\s*(第[一二三四五六七八九十]+课|复习[一二三四五六七八九十]+)\s*\*{0,2}\s*\|(.+)$') {
        $名 = $Matches[1]
        # @() 必须加：只剩一格时管道返回标量字符串，$格[-1] 会退化成"取最后一个字符"
        $格 = @(($Matches[2] -split '\|') | Where-Object { $_ -match '\S' })
        if ($格.Count -gt 0) { $课次表[$名] = ($格[-1] -replace '\*', '').Trim() }
    }
}
if ($课次表.Count -eq 0) { 坏 '进度.md §3 课次表没解析到行 —— 表格式变了吗？' }
else { 好 "课次表解析到 $($课次表.Count) 行" }

$文件夹 = Get-ChildItem $root -Directory |
          Where-Object { $_.Name -match '^(第[一二三四五六七八九十]+课|复习[一二三四五六七八九十]+)$' } |
          Sort-Object Name

foreach ($d in $文件夹) {
    $名 = $d.Name
    $状态 = if ($课次表.ContainsKey($名)) { $课次表[$名] } else { $null }

    # 四件套
    # 正文 = 不是 批改 / 参考答案 / 清单 / 问答 的那个 .md（命名见 约定.md 附 A）
    $正文 = @(Get-ChildItem $d.FullName -File -Filter *.md -ErrorAction SilentlyContinue |
              Where-Object { $_.BaseName -notmatch '批改$|参考答案$|^_|问答$' })
    $批改 = @(Get-ChildItem $d.FullName -File -Filter *.md -ErrorAction SilentlyContinue |
              Where-Object { $_.BaseName -match '批改$' })
    $答案 = @(Get-ChildItem $d.FullName -File -Filter *.md -ErrorAction SilentlyContinue |
              Where-Object { $_.BaseName -match '参考答案$' })
    $代码 = @()
    if (Test-Path (Join-Path $d.FullName 'code')) {
        $代码 = @(Get-ChildItem (Join-Path $d.FullName 'code') -File -Filter *.py -ErrorAction SilentlyContinue)
    }
    $勾 = @()
    $勾 += if ($正文.Count) { '正文✓' } else { '正文✗' }
    $勾 += if ($批改.Count) { '批改✓' } else { '批改✗' }
    $勾 += if ($答案.Count) { '答案✓' } elseif ($名 -eq '第一课') { '答案—(例外)' } else { '答案✗' }
    $勾 += if ($代码.Count) { "code✓($($代码.Count)py)" } else { 'code空' }
    $行 = "  {0,-8} {1,-48} 表:{2}" -f $名, ($勾 -join ' '), $(if ($状态) { $状态 } else { '【不在课次表里】' })

    # 约定.md 附 A 例外：第一课没有单独的参考答案（习题自检内联在正文里）
    $答案必需 = ($名 -ne '第一课')
    if (-not $状态) { Write-Host $行 -ForegroundColor Yellow; 警 "$名 这个文件夹不在课次表里" }
    elseif ($状态 -match '✅') {
        $齐 = ($批改.Count -gt 0) -and ($代码.Count -gt 0) -and ((-not $答案必需) -or ($答案.Count -gt 0))
        if ($齐) { Write-Host $行 -ForegroundColor Green; 好 "$名 表说已通过，件齐" }
        else { Write-Host $行 -ForegroundColor Red; 坏 "$名 表说『已通过』，但缺件（批改/答案/code）" }
    }
    else { Write-Host $行 -ForegroundColor Gray; 好 "$名 状态为未完成，件不齐属正常" }
}
# 表里有、磁盘上没有的
# ⚠️ `⬜ 待写` 的行**本来就是"还没建"**。对它报警 = 一条**永久假黄**，
#    而长期黄灯会训练读者忽略警告（2026-09-22 实测：`第七课 ⬜ 待写` 一直在响）。
#    所以只对**已开动**的行（✅ / 🔄 / ⚠️）要求文件夹存在。
foreach ($名 in $课次表.Keys) {
    if (Test-Path (Join-Path $root $名)) { continue }
    $状态 = $课次表[$名]
    if ($状态 -match '⬜|待写') { 好 "$名 表说还没写，文件夹未建（正常）" }
    else { 警 "课次表里有『$名』（状态：$状态），但磁盘上没有这个文件夹" }
}

# ══════════════════════════════════════════════════════════════════════
标题 '检查 3／9 · 命名规范 ↔ 实际文件名'
# ══════════════════════════════════════════════════════════════════════
foreach ($d in $文件夹) {
    $名 = $d.Name
    $允许 = @("$名-正文.md", "$名-作业批改.md", "$名-参考答案.md") + $允许额外
    $实际 = @(Get-ChildItem $d.FullName -File -Filter *.md | Select-Object -ExpandProperty Name)
    $不认 = @($实际 | Where-Object { $允许 -notcontains $_ })
    # 非 .md 的散件：课次文件夹里只该有「三份 md + code\ 目录」，别的都是临时产物
    # （2026-09-22 补：原先只扫 *.md，子模型丢在 第六课\ 的 4 个 _audit_*.py 一个都没报，却打出了 [OK]）
    $散件 = @(Get-ChildItem $d.FullName -File | Where-Object { $_.Extension -ne '.md' } | Select-Object -ExpandProperty Name)
    if ($不认.Count -eq 0 -and $散件.Count -eq 0) { 好 "$名 文件名全部符合规范" }
    else {
        foreach ($f in $不认) {
            if ($已知例外 -contains $f) { 警 "$名\$f 不符规范（已知例外，冻结不追改）" }
            else { 坏 "$名\$f 不符规范 → 应为 $名-作业批改.md 之类" }
        }
        if ($散件.Count -gt 0) {
            警 ("$名 里有 $($散件.Count) 个非 md 散件（不属于课次文件夹）：" + ($散件 -join ', '))
        }
    }
}

# ══════════════════════════════════════════════════════════════════════
标题 '检查 4／9 · 交叉引用有效性（引用的文件到底在不在）'
# ══════════════════════════════════════════════════════════════════════
# 查「根目录活文档」之间的 `X.md` / `X.ps1` 引用。
# 跳过：带路径分隔符的（旧文档\ / 第六课\ 之类）、课次/复习/真题文件、外来文档。
# 约定：**反引号包起来的 = 必须存在的引用**；**计划中的文件要加「（拟）」**（例：`新文档.md`（拟））。
$已作废 = @('约定.md', '约定-教师.md', '流水.md', '学习规则.md', '语法速查.md', '语法速查-报错.md')
$引用表 = @{}
foreach ($f in (Get-ChildItem $root -File -Filter *.md)) {
    if ($f.Name -eq 'AI 工作方法.md') { continue }          # 外来项目文档，不参与
    $txt = Get-Content $f.FullName -Raw -Encoding UTF8
    foreach ($m in [regex]::Matches($txt, '`([^`\\/\r\n]+\.(md|ps1))`\s*(（拟）)?')) {
        if ($m.Groups[3].Success) { continue }              # 标了「（拟）」= 计划中的文件，不算引用
        $t = $m.Groups[1].Value
        if ($t -match '^(第|复习|_|真题|-)') { continue }
        # 通配符不是文件名（例：正文里写 `*.md` 指"所有 md"）——不查，否则 Test-Path 会被通配符匹配到，报出假的 [OK]
        # （2026-09-22 补：备忘里一句 `*.md` 让检查 4 打出「[OK] *.md 存在」）
        if ($t -match '[\*\?]') { continue }
        # 「尖括号 = 占位符」抑制器（2026-09-22 补）：文档里要说明"格式长这样"的时候写
        # `<文件名>.md`，那是**示例，不是引用**。和「（拟）」同一个套路。
        if ($t -match '[<>]') { continue }
        if (-not $引用表.ContainsKey($t)) { $引用表[$t] = @() }
        if ($引用表[$t] -notcontains $f.Name) { $引用表[$t] += $f.Name }
    }
}
$悬空 = @(); $作废引用 = @()
foreach ($t in ($引用表.Keys | Sort-Object)) {
    if (Test-Path (Join-Path $root $t)) { 好 "$t 存在（被 $($引用表[$t].Count) 份文档引用）" }
    elseif ($已作废 -contains $t) { $作废引用 += "$t  ← $($引用表[$t] -join ', ')" }
    else { $悬空 += "$t  ← $($引用表[$t] -join ', ')" }
}
if ($悬空.Count -gt 0) { foreach ($x in $悬空) { 坏 "悬空引用（文件不存在）：$x" } }
else { 好 '没有悬空引用' }
if ($作废引用.Count -gt 0) {
    foreach ($x in $作废引用) { 警 "指向已作废文件：$x" }
    Write-Host '         （历史叙述里提到作废文件是可以的；**若是操作指令，就要改成活文档**）' -ForegroundColor DarkYellow
}

# ══════════════════════════════════════════════════════════════════════
标题 '检查 5／9 · 引用标有效性（X.md §N / 检查「键」/ 规则N 指到的东西真的存在吗）'
# ══════════════════════════════════════════════════════════════════════
# 检查 4 只管"文件在不在"，管不了"节号在不在"。
# 真实事故：写 学习规定-AI 时引用了 `模板.md §六`，而 §六 当时是"自查清单"、不是会话流水。
$活 = Get-ChildItem $root -File -Filter *.md | Where-Object { $_.Name -ne 'AI 工作方法.md' }
$节标记 = @{}
foreach ($f in $活) {
    $set = New-Object System.Collections.Generic.HashSet[string]
    foreach ($line in (Get-Content $f.FullName -Encoding UTF8)) {
        if ($line -notmatch '^#{1,6}\s') { continue }
        $h = ($line -replace '^#{1,6}\s*', '') -replace '^§\s*', ''
        if ($h -match '^([0-9〇一二三四五六七八九十]+(?:\.[0-9]+)?)') { [void]$set.Add($Matches[1]) }
    }
    $节标记[$f.Name] = $set
}
$节失败 = 0
foreach ($f in $活) {
    $txt = Get-Content $f.FullName -Raw -Encoding UTF8
    foreach ($m in [regex]::Matches($txt, '`([^`\\/\r\n]+\.md)`\s*§\s*([0-9〇一二三四五六七八九十]+(?:\.[0-9]+)?)')) {
        $目标 = $m.Groups[1].Value
        $mk = $m.Groups[2].Value
        if (-not (Test-Path (Join-Path $root $目标))) { continue }      # 那是检查 4 的事
        if (-not $节标记.ContainsKey($目标)) { continue }
        if (-not $节标记[$目标].Contains($mk)) {
            坏 "$($f.Name) 引用 $目标 §$mk —— 但 $目标 里没有这一节"
            $节失败++
        }
    }
}
if ($节失败 -eq 0) { 好 '所有「X.md §N」引用都能对上节号' }

# ── 5b · `体检.ps1` 检查「键」是否登记在册 ────────────────────────────
# 检查 5a 只认 `X.md §N`。它管不了"检查项序号"——而序号恰恰漂移过一次（见文件头的 $检查名）。
$键失败 = 0; $键引用 = 0
foreach ($f in $活) {
    $txt = Get-Content $f.FullName -Raw -Encoding UTF8
    foreach ($m in [regex]::Matches($txt, '检查「([^」\r\n]+)」')) {
        if ($m.Groups[1].Value -match '[<>]') { continue }   # 占位符（`检查「<键名>」`），不是引用
        $键引用++
        if ($检查名 -notcontains $m.Groups[1].Value) {
            坏 "$($f.Name) 引用了 检查「$($m.Groups[1].Value)」 —— 没有这个键（权威表在「学习规定-AI.md」§6.0）"
            $键失败++
        }
    }
}
if ($键失败 -eq 0) { 好 "检查「键」引用 $键引用 处，全部对得上" }

# ── 5c · 规则编号是否登记在册（权威表：`学习规定-AI.md` §📇）──────────
# 只查"用了个没登记的号"，**不要求**把旧编号改成 §N.M ——
# 已交付给学生的课次文件保持原样，靠那张对照表解析。
$规失败 = 0; $规引用 = 0
foreach ($f in $活) {
    if ($历史流水 -contains $f.Name) { continue }
    $txt = Get-Content $f.FullName -Raw -Encoding UTF8
    foreach ($m in [regex]::Matches($txt, '规则[一二三四五六七八九十]+')) {
        $规引用++
        if ($规则名 -notcontains $m.Value) {
            坏 "$($f.Name) 用了「$($m.Value)」 —— 没登记在「学习规定-AI.md」的「规则编号对照」里"
            $规失败++
        }
    }
}
if ($规失败 -eq 0) { 好 "规则编号引用 $规引用 处，全部已登记" }

# ── 5d · 还在用会漂移的「检查 N」序号 → 警告（改用「键」）─────────────
# 只认**操作型**写法：`` `体检.ps1` 检查 4 ``。历史叙述里的"删掉旧检查 3"不算。
foreach ($f in $活) {
    if ($历史流水 -contains $f.Name) { continue }
    $txt = Get-Content $f.FullName -Raw -Encoding UTF8
    $序 = [regex]::Matches($txt, '体检\.ps1.{0,2}检查\s*[0-9]+')
    if ($序.Count -gt 0) {
        警 "$($f.Name) 有 $($序.Count) 处「检查 N」序号引用 —— 序号会漂移，改成 检查「<键名>」"
    }
}

# ══════════════════════════════════════════════════════════════════════
标题 '检查 6／9 · 文档体量（不判红，只让它可见）'
# ══════════════════════════════════════════════════════════════════════
# 为什么查这个 —— AI 的"吃力"分三层：
#   ① 读不进（硬）：单文件 > 2000 行，一次 read 读不完
#   ② 读得进但记不住（中，**最危险**）：读入 > 60K token 后，长文档中段被跳过。
#      **这不报错** —— 表现为"规则明明写着，AI 就是没照做"。
#      第五课三笔欠账就是这么来的：`语法速查` 的维护说明埋在 700 行文档末尾，没被读到。
#   ③ 每次重读（软）：热集每课全读。
#
# ⚠️ 本项**只报警告、不判红** —— 体量是"能力边界"，不是"一致性错误"。
# 阈值与处置办法：学习规定-AI.md §9。
$行上限   = 2000      # read 工具默认一次最多 2000 行
$行警戒   = 800
$热集警戒 = 60000     # 字符
$备忘警戒 = 500       # 行
$热集名单 = @('进度.md', '易错点台账.md')   # 教师每课全读的两份（语法速查.md 是学生写代码时查的，不算）

$体量 = @()
foreach ($f in (Get-ChildItem $root -File -Filter *.md | Where-Object { $_.Name -ne 'AI 工作方法.md' })) {
    $体量 += [pscustomobject]@{
        Name  = $f.Name
        Lines = (Get-Content $f.FullName -Encoding UTF8).Count
        Chars = (Get-Content $f.FullName -Raw -Encoding UTF8).Length
    }
}
foreach ($r in ($体量 | Sort-Object Chars -Descending)) {
    if ($短) { continue }   # -短：不打逐文件表，只看下面的热集/合计
    $tag = if ($r.Lines -gt $行上限) { '[!!]  ' } elseif ($r.Lines -gt $行警戒) { '[警告]' } else { '[OK]  ' }
    $色  = if ($r.Lines -gt $行上限) { 'Red' } elseif ($r.Lines -gt $行警戒) { 'Yellow' } else { 'Gray' }
    Write-Host ("  {0} {1,-18} {2,4} 行 {3,7} 字符" -f $tag, $r.Name, $r.Lines, $r.Chars) -ForegroundColor $色
}
$总字符 = ($体量 | Measure-Object Chars -Sum).Sum
$热字符 = ($体量 | Where-Object { $热集名单 -contains $_.Name } | Measure-Object Chars -Sum).Sum
$备忘行 = 0
$备忘项 = @($体量 | Where-Object { $_.Name -eq '备忘.md' })
if ($备忘项.Count -gt 0) { $备忘行 = $备忘项[0].Lines }
Write-Host ('  ' + ('-' * 44))
Write-Host ("  热集（进度 + 易错点）  : {0,7} 字符   警戒 {1}" -f $热字符, $热集警戒)
Write-Host ("  根目录活文档合计        : {0,7} 字符" -f $总字符)

$超行   = @($体量 | Where-Object { $_.Lines -gt $行上限 })
$中段险 = @($体量 | Where-Object { $_.Lines -gt $行警戒 })
foreach ($r in $超行) { 警 "$($r.Name) $($r.Lines) 行 > $行上限 —— 一次 read 读不完，必须拆（见 §9）" }
if ($超行.Count -eq 0 -and $中段险.Count -gt 0) { 警 "$($中段险.Count) 份文档超过 $行警戒 行 —— 中段有读不到的风险" }
if ($热字符 -gt $热集警戒) { 警 "热集 $热字符 字符 > 警戒 $热集警戒 —— 按 §9『先降分辨率、再拆』" }
if ($备忘行 -gt $备忘警戒) { 警 "备忘.md $备忘行 行 > 警戒 $备忘警戒 —— 归档早期批次到 旧文档\" }
if ($超行.Count -eq 0 -and $中段险.Count -eq 0 -and $热字符 -le $热集警戒 -and $备忘行 -le $备忘警戒) {
    好 ("体量全部在警戒线内（热集距警戒还有 {0} 字符）" -f ($热集警戒 - $热字符))
}

# ── 课次文件夹里的"大块头"（2026-09-22 补）────────────────────────────
# 【为什么补】上面那张表**只扫根目录**，而 `第六课-正文.md` 已经 1600+ 行、
#   比任何一份根文档都长 —— 它不在任何警戒线里，也就没人看见。
# 【为什么只报不判红】"**教学正文该不该有警戒线**"**没有结论**（见 §8 的精神：
#   判不出来的东西，不要用漂亮话填）。所以这里**只让它可见**，不设阈值。
$课外 = @(Get-ChildItem $root -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
          Where-Object { $_.DirectoryName -ne $root -and $_.FullName -notlike '*\旧文档\*' } |
          ForEach-Object {
              [pscustomobject]@{
                  Rel   = $_.FullName.Replace("$root\", '')
                  Lines = (Get-Content $_.FullName -Encoding UTF8).Count
              }
          } | Where-Object { $_.Lines -gt $行警戒 } | Sort-Object Lines -Descending)
if ($课外.Count -eq 0) { 好 "课次文件夹里没有超过 $行警戒 行的文档" }
else {
    # 合成**一行**（不逐个报警）：信息一样，但少烧 token —— 见 学习规定-AI.md §9.0。
    $清单 = ($课外 | Select-Object -First 8 | ForEach-Object { "$($_.Rel) $($_.Lines)行" }) -join ' · '
    if ($课外.Count -gt 8) { $清单 += " · …共 $($课外.Count) 份" }
    警 "课次文稿超过 $行警戒 行的有 $($课外.Count) 份（**不在根目录警戒线内，只报体积**）：$清单"
}

# ══════════════════════════════════════════════════════════════════════
标题 '检查 7／9 · 出题：习题串 ↔ 例题串（§2.2「这题允许抄吗」）'
# ══════════════════════════════════════════════════════════════════════
# 判据（`学习规定-AI.md` §2.2）：**把例题的数字改一改就能过 → 弱**。
# 机器能查的那一半：**习题里用的字符串字面量，和例题里的是不是同一个**。
# 例：C2 曾用 `"xxaxx".strip("x")`，而正文 §3.3 陷阱框逐字就是这一串 → 抄例题。
#
# ⚠️ 这是**警告**不是红：判据还有一半（新组合 / 新边界 / 新场景）机器判不了，
#    偶尔"故意复用同一个串"也合理。它只负责**把候选挑出来给人看**，不替人下结论。
#
# 口径：只在 ```python 块里取 `"..."` / `'...'`，长度 ≥ 3 且不是纯符号；
#       习题区 = 每个「## ★ X 组习题」段 + 「三道特殊题」段；剩下的都算例题区。
function _串([string]$文) {
    $o = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($文, '(?s)```python\r?\n(.*?)```')) {
        foreach ($s in [regex]::Matches($m.Groups[1].Value, '[fFrRbB]{0,2}"([^"\r\n]*)"')) {
            $v = $s.Groups[1].Value.Trim()
            if ($v.Length -ge 3 -and $v -notmatch '^[\s,.:;|=<>!+\-*/\\]+$') { [void]$o.Add($v) }
        }
    }
    return $o
}
foreach ($f in (Get-ChildItem $root -Recurse -File -Filter '*正文.md')) {
    $txt = Get-Content $f.FullName -Raw -Encoding UTF8
    $组 = [regex]::Matches($txt, '(?ms)^## ★ [A-H] 组习题.*?(?=^## ★ |^# )')
    $特 = [regex]::Matches($txt, '(?ms)^# 第 \d+ 节 · 三道特殊题.*?(?=^# 附录|^# 交作业|^# 第 10 节|\z)')
    if ($组.Count -eq 0) { continue }
    $习题 = ''; foreach ($m in $组) { $习题 += $m.Value }; foreach ($m in $特) { $习题 += $m.Value }
    $例题 = $txt; foreach ($m in @($组) + @($特)) { $例题 = $例题.Replace($m.Value, "`n") }
    $a = @(_串 $例题 | Sort-Object -Unique); $b = @(_串 $习题 | Sort-Object -Unique)
    $撞 = @($a | Where-Object { $b -contains $_ })
    if ($撞.Count -eq 0) { 好 "$($f.BaseName) 习题没有照抄例题的字符串" }
    else {
        警 ("{0} 有 {1} 个串**例题和习题都用了** → 逐条核 §2.2：{2}" -f $f.BaseName, $撞.Count, (($撞 | ForEach-Object { '「' + $_ + '」' }) -join ' '))
    }
}
# ══════════════════════════════════════════════════════════════════════
标题 '检查 8／9 · 文档地图完整性（根目录每份 .md 都标过「怎么读」吗）'
# ══════════════════════════════════════════════════════════════════════
# 【为什么查这个】学生 2026-09-22 的要求：文档要能分清"全读 / 不全读"。
#   **做法不是建两个文件夹**（那会让检查 4/6/7 全瞎——它们只扫根目录，会打出假绿），
#   而是**在 `接手.md` §6 的文档地图里给每份文档标一个「怎么读」**。
#   本检查保证：**新加一份文档而没想过它该怎么读 → 报出来**。
#
# 判据（写在地图里）：**全读 = "下一句话"依赖"上一句话"**；每节能独立回答"什么时候查我" → 按节查。
$地图 = Get-Content (Join-Path $root '接手.md') -Raw -Encoding UTF8
$未标 = @()
foreach ($f in (Get-ChildItem $root -File -Filter *.md)) {
    if ($f.Name -eq '接手.md') { continue }      # 地图自己
    if ($地图 -notmatch [regex]::Escape($f.Name)) { $未标 += $f.Name }
}
if ($未标.Count -eq 0) { 好 '根目录每份 .md 都在文档地图里（都标过怎么读）' }
else { 警 ('这些 .md 不在 接手.md §6 文档地图里（= 没人想过它该怎么读）：' + ($未标 -join '、')) }
# ══════════════════════════════════════════════════════════════════════
标题 '检查 9／9 · 出题：习题用到的方法，「专门讲它」的那节排在它前面吗'
# ══════════════════════════════════════════════════════════════════════
# 【为什么查这个】2026-09-22 真实事故：第六课 A1 在第 146 行，却要求学生用 `upper()`——
#   而本课**专门讲 `upper` 的那一节在第 329 行**（题在后面 180 行）。
#   学生做到第一题就卡住："我们教过 upper 吗？"
#
# ⚠️ 这个洞**当时所有检查都是绿的**：
#   · 检查「知识点 ID」查的是"这语法在 `进度.md` §1 点亮了吗" → `upper` 是 4.7，属本课 → 判不超纲
#     **但"本课要教" ≠ "题之前已经教过"**
#   · 检查「出题抄例题」查的是"例题和习题用了同一个**串**" → `"cat"` vs `"lemon"` 串不同 → 不报
#     **它看不见"结构相同"**
#
# 口径：每个「## ★ X 组习题」块里用到的 `x.方法(`，若本课**有某一节标题专门点了它的名**，
#   那一节必须排在题**前面**。没被任何节标题点名的（如 `isdigit` 藏在"## 5.1 四个方法"里）→ 不判，交给人工。
$题序问题 = 0
foreach ($f in (Get-ChildItem $root -Recurse -File -Filter '*正文.md')) {
    $ls = [regex]::Split((Get-Content $f.FullName -Raw -Encoding UTF8), "(?<=\n)")
    $节 = @(); for ($i = 0; $i -lt $ls.Count; $i++) { if ($ls[$i] -match '^## \d+\.\d+') { $节 += $i } }
    $起集 = @(); for ($i = 0; $i -lt $ls.Count; $i++) { if ($ls[$i] -match '^## ★ [A-H] 组习题') { $起集 += $i } }
    if ($起集.Count -eq 0) { continue }
    # ⚠️ 题的**终点**不是"下一组"——正文里**组和节是交错排的**（A组之后紧跟第 2 节的讲义）。
    #    取到下一组，会把整节讲义算进题里 → 满屏假报（2026-09-22 实测：27 条全假）。
    #    正确的终点 = 起点之后**第一个**「节标题」或「第 N 节」或「下一组」，取最早的那个。
    for ($k = 0; $k -lt $起集.Count; $k++) {
        $起 = $起集[$k]; $止 = $ls.Count
        for ($i = $起 + 1; $i -lt $ls.Count; $i++) {
            if ($ls[$i] -match '^## \d+\.\d+' -or $ls[$i] -match '^# 第 \d+ 节' -or $ls[$i] -match '^## ★ [A-H] 组习题') { $止 = $i; break }
        }
        $块 = ($ls[$起..($止 - 1)] -join "`n")
        $用 = @([regex]::Matches($块, '\.([a-z_][a-z0-9_]*)\s*\(') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
        foreach ($mm in $用) {
            $归 = -1
            foreach ($j in $节) { if ($ls[$j] -match ('(?i)\b' + [regex]::Escape($mm) + '\b')) { $归 = $j; break } }
            if ($归 -gt $起) {
                警 ("{0} 第 {1} 行「{2}」用到 `{3}`，但本课专门讲它的那一节在第 {4} 行（**排在题后面**）" -f `
                    $f.BaseName, ($起 + 1), ($ls[$起] -replace '^## ★ ', ''), $mm, ($归 + 1))
                $题序问题++
            }
        }
    }
}
if ($题序问题 -eq 0) { 好 '习题用到的方法，本课都先讲过了' }
$结论 = if ($失败 -eq 0) { '绿' } else { '红' }
$色 = if ($失败 -eq 0) { 'Green' } else { 'Red' }
Write-Host "`n=== 结果：$结论 === 通过 $通过 · 失败 $失败 · 警告 $警告" -ForegroundColor $色
if ($失败 -gt 0) { Write-Host '红了先修，别往下走。' -ForegroundColor Red }
Write-Host ''
exit $(if ($失败 -eq 0) { 0 } else { 1 })
