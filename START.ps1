# VortexDQ AI - Launcher
# vortexdq.com

$ErrorActionPreference = "Stop"

try {

Set-Location $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "VortexDQ AI"

# Unblock all files in this folder
Get-ChildItem -Path $PSScriptRoot -File | Unblock-File -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  VortexDQ AI  -  vortexdq.com" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host ""

# ── STEP 1: Node.js ───────────────────────────────────────────────────
Write-Host "  [1/4] Node.js..." -NoNewline
$nodeOk = $false
try { $v = node --version 2>$null; $nodeOk = $true } catch {}

if ($nodeOk) {
    Write-Host "  OK  $v" -ForegroundColor Green
} else {
    Write-Host "  Not found. Installing via winget..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    $env:PATH = "C:\Program Files\nodejs;$env:PATH"
    try { $v = node --version 2>$null; $nodeOk = $true } catch {}
    if (-not $nodeOk) {
        throw "Node.js install failed. Download from https://nodejs.org then re-run."
    }
    Write-Host "  OK  $v" -ForegroundColor Green
}

# ── STEP 2: llama-server ──────────────────────────────────────────────
Write-Host "  [2/4] llama-server..." -NoNewline

$serverExe = $null
foreach ($p in @("build\bin\llama-server.exe","bin\llama-server.exe","llama-server.exe")) {
    if (Test-Path $p) { $serverExe = $p; break }
}

if ($serverExe) {
    Write-Host "  OK  $serverExe" -ForegroundColor Green
} else {
    Write-Host "  Not found. Downloading..." -ForegroundColor Yellow

    $tag = (Invoke-RestMethod "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest").tag_name
    $zipName = "llama-$tag-bin-win-cpu-x64.zip"
    $url = "https://github.com/ggml-org/llama.cpp/releases/download/$tag/$zipName"

    Write-Host "  Downloading $zipName..." -ForegroundColor DarkGray
    Invoke-WebRequest $url -OutFile "llama-win.zip" -UseBasicParsing

    Write-Host "  Extracting..." -ForegroundColor DarkGray
    Expand-Archive -Path "llama-win.zip" -DestinationPath "llama-bin" -Force
    Remove-Item "llama-win.zip" -Force

    $found = Get-ChildItem -Path "llama-bin" -Recurse -Filter "llama-server.exe" | Select-Object -First 1
    if (-not $found) { throw "llama-server.exe not found in downloaded zip." }

    Copy-Item $found.FullName "llama-server.exe" -Force
    Get-ChildItem $found.DirectoryName -Filter "*.dll" | ForEach-Object {
        Copy-Item $_.FullName "." -Force -ErrorAction SilentlyContinue
    }
    Remove-Item "llama-bin" -Recurse -Force -ErrorAction SilentlyContinue

    $serverExe = "llama-server.exe"
    Write-Host "  OK  llama-server.exe" -ForegroundColor Green
}

# ── STEP 3: Model ─────────────────────────────────────────────────────
Write-Host "  [3/4] AI model..." -NoNewline

if (-not (Test-Path "models")) { New-Item -ItemType Directory -Path "models" | Out-Null }
$modelFile = "models\Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf"

if (Test-Path $modelFile) {
    Write-Host "  OK  Qwen2.5-Coder-7B-Abliterated" -ForegroundColor Green
} else {
    Write-Host "  Not found. Downloading ~4.8 GB..." -ForegroundColor Yellow
    Write-Host "  (Takes 10-30 min on first run)" -ForegroundColor DarkGray
    $modelUrl = "https://huggingface.co/mradermacher/Qwen2.5-Coder-7B-Abliterated-GGUF/resolve/main/Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf"
    & curl.exe -L --progress-bar -o $modelFile $modelUrl
    if ($LASTEXITCODE -ne 0) {
        if (Test-Path $modelFile) { Remove-Item $modelFile -Force }
        throw "Model download failed. Check your internet connection and try again."
    }
    Write-Host "  Download complete!" -ForegroundColor Green
}

# ── STEP 4: Launch ────────────────────────────────────────────────────
Write-Host "  [4/4] Starting servers..." -ForegroundColor White

$cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
$threads = [Math]::Max(4, [Math]::Min(8, [int]($cores / 2)))

Stop-Process -Name "llama-server" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$llamaArgs = "-m `"$modelFile`" --port 8080 --host 127.0.0.1 -c 16384 -t $threads -tb $threads -b 512 --path `"$PSScriptRoot`" --log-disable"
Start-Process -FilePath $serverExe -ArgumentList $llamaArgs -WindowStyle Hidden

Start-Process -FilePath "node" -ArgumentList "agent-server.js" -WindowStyle Hidden -WorkingDirectory $PSScriptRoot

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host "  Loading model on $threads threads (1-3 minutes)..." -ForegroundColor Cyan
Write-Host "  Browser opens automatically when ready." -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host ""

$checks = 0
while ($true) {
    Start-Sleep -Seconds 2
    $checks++
    try {
        $r = Invoke-WebRequest "http://127.0.0.1:8080/v1/models" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        if ($r.Content -match '"id"') { break }
    } catch {}
    Write-Host "  Waiting... ($checks)" -ForegroundColor DarkGray
}

Start-Process "http://127.0.0.1:8080"

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host "   READY  >  http://127.0.0.1:8080" -ForegroundColor Green
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Press Enter to stop VortexDQ AI." -ForegroundColor DarkGray
Read-Host

Stop-Process -Name "llama-server" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Write-Host "  Stopped. Goodbye!" -ForegroundColor DarkGray

} catch {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host "  ERROR: $_" -ForegroundColor Red
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to close"
}
