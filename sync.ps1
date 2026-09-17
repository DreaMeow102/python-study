# ============================================================
#  一键同步：提交 + 推送
#  用法：
#     .\sync.ps1                    自动生成提交说明（时间戳）
#     .\sync.ps1 "第二课写完"        用你给的说明
#  也可以直接双击同目录的 sync.cmd
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
$changes = git status --porcelain
if (-not $changes) {
    Write-Host "[=] 没有需要提交的改动。" -ForegroundColor Yellow
} else {
    if (-not $Message) {
        $Message = "更新 " + (Get-Date -Format 'yyyy-MM-dd HH:mm')
    }
    git add -A
    git commit -m $Message | Out-Null
    Write-Host "[+] 已提交：$Message" -ForegroundColor Green
}

# ---------- 3. 推送 ----------
Write-Host "[>] 正在推送到 GitHub ..." -ForegroundColor Cyan
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] 推送成功。" -ForegroundColor Green
} else {
    Write-Host "[X] 推送失败。常见原因：" -ForegroundColor Red
    Write-Host "    1. 代理没开（最常见）" -ForegroundColor Red
    Write-Host "    2. SSH 公钥没加到 GitHub" -ForegroundColor Red
    exit 1
}
