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

# ---------- 1. 检查代理（GitHub 直连不通，必须走代理）----------
$proxyAlive = $false
try {
    $proxyAlive = Test-NetConnection 127.0.0.1 -Port 7993 -InformationLevel Quiet -WarningAction SilentlyContinue
} catch {}

if (-not $proxyAlive) {
    Write-Host "[!] 警告：本地代理 127.0.0.1:7993 没有在监听。" -ForegroundColor Yellow
    Write-Host "    GitHub 直连不通，推送大概率会失败。请先启动代理工具。" -ForegroundColor Yellow
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
