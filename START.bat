@echo off
title VortexDQ AI
cd /d "%~dp0"
setlocal EnableDelayedExpansion
color 0A

echo.
echo   ██╗   ██╗ ██████╗ ██████╗ ████████╗███████╗██╗  ██╗██████╗  ██████╗
echo   ██║   ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝██╔══██╗██╔═══██╗
echo   ██║   ██║██║   ██║██████╔╝   ██║   █████╗   ╚███╔╝ ██║  ██║██║   ██║
echo   ╚██╗ ██╔╝██║   ██║██╔══██╗   ██║   ██╔══╝   ██╔██╗ ██║  ██║██║▄▄ ██║
echo    ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗██╔╝ ██╗██████╔╝╚██████╔╝
echo     ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═════╝  ╚══▀▀═╝
echo.
echo                         vortexdq.com
echo   ════════════════════════════════════════════════════════════════
echo.

REM ═══════════════════════════════════════════════════════════════
REM  STEP 1 — Node.js
REM ═══════════════════════════════════════════════════════════════
echo   [1/4] Node.js...
node --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo         Not found. Installing via winget...
    winget install OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements >nul 2>nul
    REM Refresh PATH with common install locations
    for %%p in (
        "C:\Program Files\nodejs"
        "%APPDATA%\nvm\current"
        "%LOCALAPPDATA%\Programs\nodejs"
    ) do if exist "%%~p\node.exe" set "PATH=%%~p;%PATH%"
    node --version >nul 2>nul
    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo   [ERROR] Could not auto-install Node.js.
        echo   Please install manually from: https://nodejs.org
        echo   Then re-run this file.
        echo.
        pause & exit /b 1
    )
)
for /f "delims=" %%v in ('node --version 2^>nul') do set NODE_VER=%%v
echo         OK  %NODE_VER%

REM ═══════════════════════════════════════════════════════════════
REM  STEP 2 — llama-server
REM ═══════════════════════════════════════════════════════════════
echo   [2/4] llama-server...

REM Check existing build first
set SERVER_EXE=
if exist "build\bin\llama-server.exe"  set SERVER_EXE=build\bin\llama-server.exe
if exist "bin\llama-server.exe"        set SERVER_EXE=bin\llama-server.exe
if exist "llama-server.exe"            set SERVER_EXE=llama-server.exe

if defined SERVER_EXE (
    echo         OK  %SERVER_EXE%
    goto :HAS_SERVER
)

echo         Not found. Downloading pre-built binary...
echo         This may take a few minutes depending on your connection.
echo.

REM Download latest Windows AVX2 build from GitHub
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try { $r=(Invoke-WebRequest 'https://api.github.com/repos/ggml-org/llama.cpp/releases/latest' -UseBasicParsing -TimeoutSec 30|ConvertFrom-Json); $a=$r.assets|Where-Object{$_.name -match 'bin-win-avx2-x64.*zip'}|Select-Object -First 1; if(!$a){$a=$r.assets|Where-Object{$_.name -match 'bin-win-avx-x64.*zip'}|Select-Object -First 1}; if(!$a){$a=$r.assets|Where-Object{$_.name -match 'win.*x64.*zip'}|Select-Object -First 1}; if($a){Write-Host ('Downloading '+$a.name+'...'); Invoke-WebRequest $a.browser_download_url -OutFile 'llama-win.zip' -UseBasicParsing} else {Write-Error 'No Windows build found'} } catch { Write-Error $_.Exception.Message }" 2>&1

if not exist "llama-win.zip" (
    echo.
    echo   [ERROR] Could not download llama-server.
    echo   Please build manually: see setup-all.bat
    echo   Or download from: https://github.com/ggml-org/llama.cpp/releases
    echo.
    pause & exit /b 1
)

echo         Extracting...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path 'llama-win.zip' -DestinationPath 'llama-bin' -Force" >nul 2>nul
del "llama-win.zip" >nul 2>nul

REM Find the exe in extracted folder
for /r "llama-bin" %%f in (llama-server.exe) do (
    copy "%%f" "llama-server.exe" >nul 2>nul
    REM Copy any DLLs next to it
    for %%d in ("%%~dpf*.dll") do copy "%%d" "." >nul 2>nul
)
rmdir /s /q "llama-bin" >nul 2>nul

if not exist "llama-server.exe" (
    echo   [ERROR] Could not find llama-server.exe in download.
    pause & exit /b 1
)
set SERVER_EXE=llama-server.exe
echo         OK  llama-server.exe

:HAS_SERVER

REM ═══════════════════════════════════════════════════════════════
REM  STEP 3 — AI Model
REM ═══════════════════════════════════════════════════════════════
echo   [3/4] AI model...
if not exist "models" mkdir models

set MODEL_FILE=models\Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf
if exist "%MODEL_FILE%" (
    echo         OK  Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf
    goto :HAS_MODEL
)

echo         Not found. Downloading (~4.8 GB — grab a coffee!)
echo.
curl.exe -L --progress-bar ^
  -o "%MODEL_FILE%" ^
  "https://huggingface.co/mradermacher/Qwen2.5-Coder-7B-Abliterated-GGUF/resolve/main/Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   [ERROR] Model download failed. Check your internet connection and try again.
    if exist "%MODEL_FILE%" del "%MODEL_FILE%"
    pause & exit /b 1
)
echo         Download complete!

:HAS_MODEL

REM ═══════════════════════════════════════════════════════════════
REM  STEP 4 — Launch
REM ═══════════════════════════════════════════════════════════════
echo   [4/4] Starting servers...

REM Detect threads: half logical cores, min 4, max 8
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value 2^>nul') do set CORES=%%i
if not defined CORES set CORES=8
if "%CORES%"=="" set CORES=8
set /a THREADS=%CORES%/2
if %THREADS% LSS 4 set THREADS=4
if %THREADS% GTR 8 set THREADS=8

REM Kill any previous instances
taskkill /f /im llama-server.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
timeout /t 1 /nobreak >nul

start /B "" "%SERVER_EXE%" ^
    -m "%MODEL_FILE%" ^
    --port 8080 --host 127.0.0.1 ^
    -c 16384 -t %THREADS% -tb %THREADS% -b 512 ^
    --path "." --log-disable >nul 2>nul

start /B "" node agent-server.js >nul 2>nul

echo.
echo   ════════════════════════════════════════════════════════════════
echo   Loading model on %THREADS% threads — this takes 1-3 minutes...
echo   Browser will open automatically when ready.
echo   ════════════════════════════════════════════════════════════════
echo.

set /a DOT=0
:WAIT
timeout /t 2 /nobreak >nul
curl.exe -s http://127.0.0.1:8080/v1/models 2>nul | findstr /C:"\"id\"" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    set /a DOT=!DOT!+1
    set DOTS=
    for /l %%i in (1,1,!DOT!) do set DOTS=!DOTS!.
    if !DOT! GTR 20 set DOT=0
    echo   Waiting!DOTS!
    goto :WAIT
)

start http://127.0.0.1:8080

echo.
echo   ════════════════════════════════════════════════════════════════
echo    READY ^>  http://127.0.0.1:8080
echo   ════════════════════════════════════════════════════════════════
echo.
echo   Close this window to stop VortexDQ AI.
echo.
pause >nul

taskkill /f /im llama-server.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
echo   Stopped. Goodbye!
timeout /t 2 /nobreak >nul
