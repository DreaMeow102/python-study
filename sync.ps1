# ============================================================
#  一键同步：提交 + 推送到两个远程（GitHub + AtomGit）
#  用法：
#     .\sync.ps1                    自动生成提交说明（时间戳）
#     .\sync.ps1 "第二课写完"        用你给的说明
#  也可以直接双击同目录的 sync.cmd
# ============================================================
#
# ⚠️⚠️ 本文件必须带 UTF-8 BOM。⚠️⚠️
#    PowerShell 5.1 在【无 BOM】时按 GBK 读这个文件，
#    中文的 UTF-8 字节会吃掉字符串的结束引号 → 整个脚本语法报错。
#    （2026-09-22 实际踩过：编辑后 BOM 被去掉，脚本直接不能跑。）
#
#    改完这个文件后，务必补回 BOM：
#      $p = '.\sync.ps1'
#      $t = [IO.File]::ReadAllText($p, (New-Object Text.UTF8Encoding($false)))
#      [IO.File]::WriteAllText($p, $t, (New-Object Text.UTF8Encoding($true)))
#    验证：前三个字节应该是 EF BB BF
#
# ============================================================

param([string]$Message = "")

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

# ---------- 0. 检查 ----------
if (-not (Test-Path '.git')) {
    Write-Host "[X] 当前目录不是 git 仓库：$PSScriptRoot" -ForegroundColor Red
    exit 1
}

# ---------- 1. 检查能不能连上 GitHub ----------
# 注意：不要只检查本地代理端口。代理可能运行在 TUN 模式下（不监听本地端口），
# 那样端口检查会误报。直接测 GitHub 本身才准确。
$canReach = $false
try {
    $canReach = Test-NetConnection github.com -Port 22 -InformationLevel Quiet -WarningAction SilentlyContinue
} catch {}

if (-not $canReach) {
    # 直连不通时，再看看代理端口在不在，给出更有针对性的提示
    $proxyAlive = $false
    try {
        $proxyAlive = Test-NetConnection 127.0.0.1 -Port 7993 -InformationLevel Quiet -WarningAction SilentlyContinue
    } catch {}

    Write-Host "[!] 警告：连不上 github.com:22，推送大概率会失败。" -ForegroundColor Yellow
    if ($proxyAlive) {
        Write-Host "    代理端口 7993 在监听，但仍连不上 GitHub —— 检查代理工具本身是否正常工作。" -ForegroundColor Yellow
    } else {
        Write-Host "    代理端口 7993 也没在监听。请先启动代理工具。" -ForegroundColor Yellow
    }
    Write-Host "    （如果你用的是 TUN 模式，可以忽略端口提示。）" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------- 2. 提交 ----------
# ⚠️ 不要用 git add -A（2026-09-22 踩过两次）
#    -A 会把工作区里"任何"未跟踪文件都扫进来——包括你暂时不想进仓库的私人文件。
#    改成"显式白名单"：只加下面这个项目文件夹 + 已跟踪文件的修改/删除。
#    以后新增项目文件夹，往 $projectDirs 里加一行。
$projectDirs = @('python学习')

$changes = git status --porcelain
if (-not $changes) {
    Write-Host "[=] 没有需要提交的改动。" -ForegroundColor Yellow
} else {
    if (-not $Message) {
        $Message = "更新 " + (Get-Date -Format 'yyyy-MM-dd HH:mm')
    }

    foreach ($d in $projectDirs) {
        if (Test-Path -LiteralPath $d) { git add -- $d }
    }
    git add -u          # 已跟踪文件的「修改」和「删除」（不会加新文件）

    # ★ 先把暂存清单打出来，再提交 —— 这样你能当场发现"不想进仓库的东西被扫进来了"
    $staged = git diff --cached --name-status
    if (-not $staged) {
        Write-Host "[=] 暂存后没有实际改动，跳过提交。" -ForegroundColor Yellow
    } else {
        Write-Host "[i] 即将提交这些改动（觉得不对就按 Ctrl+C）：" -ForegroundColor DarkGray
        $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        git commit -m $Message | Out-Null
        Write-Host "[+] 已提交：$Message" -ForegroundColor Green
    }
}

# ---------- 3. 推送（两个远程：GitHub + AtomGit）----------
#   origin  = GitHub   git@github-pythonstudy:DreaMeow102/python-study.git
#   atomgit = AtomGit  git@atomgit-pythonstudy:YN4/python-study.git
# 两个远程用**不同的钥匙**（Host 别名在 ~/.ssh/config 里分开）。
# 钥匙对应关系、公钥原文、指纹：见 D:\studydemo\密钥-GitHub.txt / 密钥-AtomGit.txt
$远程表 = @(
    @{ 名 = 'GitHub';  远程 = 'origin'  },
    @{ 名 = 'AtomGit'; 远程 = 'atomgit' }
)

$失败数 = 0
foreach ($r in $远程表) {
    if (-not (git remote | Where-Object { $_ -eq $r.远程 })) {
        Write-Host ("[!] 跳过 {0}：本仓库没配 `"{1}`" 这个远程" -f $r.名, $r.远程) -ForegroundColor Yellow
        continue
    }
    Write-Host ("[>] 推送到 {0} ..." -f $r.名) -ForegroundColor Cyan
    git push $r.远程 main
    if ($LASTEXITCODE -eq 0) {
        Write-Host ("[OK] {0} 推送成功。" -f $r.名) -ForegroundColor Green
    } else {
        Write-Host ("[X] {0} 推送失败。" -f $r.名) -ForegroundColor Red
        $失败数 = $失败数 + 1
    }
}

if ($失败数 -gt 0) {
    Write-Host ""
    Write-Host "[X] 有远程推送失败。常见原因：" -ForegroundColor Red
    Write-Host "    1. 代理没开（GitHub 最常见）" -ForegroundColor Red
    Write-Host "    2. 那把钥匙没注册，或者没勾「写入权限」" -ForegroundColor Red
    Write-Host "       → 看 D:\studydemo\密钥-GitHub.txt / 密钥-AtomGit.txt" -ForegroundColor Red
    exit 1
}
