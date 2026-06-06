# VortexDQ AI — Launcher
# Right-click this file -> "Run with PowerShell"
# vortexdq.com

Set-Location $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "VortexDQ AI"

# ── Unblock everything in this folder so Windows stops blocking them ──
Get-ChildItem -Path $PSScriptRoot -File | Unblock-File -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  VortexDQ AI  —  vortexdq.com" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host ""

# ── STEP 1: Node.js ───────────────────────────────────────────────────
Write-Host "  [1/4] Node.js..." -NoNewline
try {
    $v = & node --version 2>$null
    Write-Host "  OK  $v" -ForegroundColor Green
} catch {
    Write-Host "  Not found. Installing..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    $env:PATH = "C:\Program Files\nodejs;$env:PATH"
    try {
        $v = & node --version 2>$null
        Write-Host "  OK  $v" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "  [ERROR] Node.js install failed. Download from: https://nodejs.org" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
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

    # Get latest release tag
    try {
        $release = Invoke-RestMethod "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest" -TimeoutSec 20
        $tag = $release.tag_name
    } catch {
        Write-Host ""
        Write-Host "  [ERROR] Could not reach GitHub: $_" -ForegroundColor Red
        Write-Host "  Download manually: https://github.com/ggml-org/llama.cpp/releases/latest" -ForegroundColor Yellow
        Write-Host "  Get: llama-XXXXX-bin-win-cpu-x64.zip  ->  extract llama-server.exe here"
        Read-Host "Press Enter to exit"
        exit 1
    }

    $zipName = "llama-$tag-bin-win-cpu-x64.zip"
    $url = "https://github.com/ggml-org/llama.cpp/releases/download/$tag/$zipName"
    Write-Host "  Downloading $zipName..." -ForegroundColor DarkGray

    try {
        Invoke-WebRequest $url -OutFile "llama-win.zip" -UseBasicParsing
    } catch {
        Write-Host ""
        Write-Host "  [ERROR] Download failed: $_" -ForegroundColor Red
        Write-Host "  Download manually from: $url" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }

    Write-Host "  Extracting..." -ForegroundColor DarkGray
    Expand-Archive -Path "llama-win.zip" -DestinationPath "llama-bin" -Force
    Remove-Item "llama-win.zip" -Force

    # Copy exe + DLLs out of extracted subfolder
    Get-ChildItem -Path "llama-bin" -Recurse -Filter "llama-server.exe" | Select-Object -First 1 | ForEach-Object {
        Copy-Item $_.FullName "llama-server.exe" -Force
        Get-ChildItem $_.DirectoryName -Filter "*.dll" | ForEach-Object { Copy-Item $_.FullName "." -Force -ErrorAction SilentlyContinue }
    }
    Remove-Item "llama-bin" -Recurse -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path "llama-server.exe")) {
        Write-Host "  [ERROR] llama-server.exe not found after extraction." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
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
    Write-Host "  (This takes 10-30 minutes on first run)" -ForegroundColor DarkGray
    $modelUrl = "https://huggingface.co/mradermacher/Qwen2.5-Coder-7B-Abliterated-GGUF/resolve/main/Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf"
    try {
        # Use curl.exe for large files — it shows progress and resumes better
        & curl.exe -L --progress-bar -o $modelFile $modelUrl
        if ($LASTEXITCODE -ne 0) { throw "curl exited with $LASTEXITCODE" }
    } catch {
        Write-Host "  [ERROR] Model download failed: $_" -ForegroundColor Red
        if (Test-Path $modelFile) { Remove-Item $modelFile -Force }
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "  Download complete!" -ForegroundColor Green
}

# ── STEP 4: Launch ────────────────────────────────────────────────────
Write-Host "  [4/4] Starting servers..." -ForegroundColor White

# Thread count: half logical cores, min 4 max 8
$cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
$threads = [Math]::Max(4, [Math]::Min(8, [int]($cores / 2)))

# Kill stale instances
Stop-Process -Name "llama-server" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Start llama-server
$llamaArgs = "-m `"$modelFile`" --port 8080 --host 127.0.0.1 -c 16384 -t $threads -tb $threads -b 512 --path `"$PSScriptRoot`" --log-disable"
Start-Process -FilePath $serverExe -ArgumentList $llamaArgs -WindowStyle Hidden

# Start agent server
Start-Process -FilePath "node" -ArgumentList "agent-server.js" -WindowStyle Hidden -WorkingDirectory $PSScriptRoot

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host "  Loading model on $threads threads — usually 1-3 minutes..." -ForegroundColor Cyan
Write-Host "  Browser will open automatically when ready." -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host ""

# Poll until model is ready
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
