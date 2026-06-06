@echo off
title VortexDQ AI
cd /d "%~dp0"
color 0A

REM ── Unblock self + siblings (removes Windows SmartScreen MOTW flag) ──
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-ChildItem -Path '%~dp0' -Filter '*.bat' | Unblock-File -ErrorAction SilentlyContinue; ^
   Get-ChildItem -Path '%~dp0' -Filter '*.js'  | Unblock-File -ErrorAction SilentlyContinue; ^
   Get-ChildItem -Path '%~dp0' -Filter '*.html' | Unblock-File -ErrorAction SilentlyContinue" >nul 2>nul

echo.
echo   VortexDQ AI
echo   vortexdq.com
echo   ============================================================
echo.

REM ═══════════════════════════════════════════════════════════════
REM  STEP 1 ^— Node.js
REM ═══════════════════════════════════════════════════════════════
echo   [1/4] Node.js...
node --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo         Not found. Installing via winget...
    winget install OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements >nul 2>nul
    for %%p in (
        "C:\Program Files\nodejs"
        "%LOCALAPPDATA%\Programs\nodejs"
    ) do if exist "%%~p\node.exe" set "PATH=%%~p;%PATH%"
    node --version >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo   [ERROR] Could not auto-install Node.js.
        echo   Please install manually: https://nodejs.org
        echo   Then re-run this file.
        echo.
        pause & exit /b 1
    )
)
for /f "delims=" %%v in ('node --version 2^>nul') do set NODE_VER=%%v
echo         OK  %NODE_VER%

REM ═══════════════════════════════════════════════════════════════
REM  STEP 2 ^— llama-server
REM ═══════════════════════════════════════════════════════════════
echo   [2/4] llama-server...

set SERVER_EXE=
if exist "build\bin\llama-server.exe"  set SERVER_EXE=build\bin\llama-server.exe
if exist "bin\llama-server.exe"        set SERVER_EXE=bin\llama-server.exe
if exist "llama-server.exe"            set SERVER_EXE=llama-server.exe

if defined SERVER_EXE (
    echo         OK  %SERVER_EXE%
    goto :HAS_SERVER
)

echo         Not found. Fetching latest release tag...

REM Get the latest release tag from GitHub (plain curl + findstr, no PowerShell JSON tricks)
curl -s --max-time 15 "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest" -o "%TEMP%\llama_release.json" 2>nul
if not exist "%TEMP%\llama_release.json" goto :DL_FAIL

REM Extract the tag_name value ("b9538" etc.) from the JSON
for /f "tokens=2 delims=:, " %%t in ('findstr /C:"\"tag_name\"" "%TEMP%\llama_release.json"') do (
    set RAW_TAG=%%t
)
REM Strip surrounding quotes from the tag
set LLAMA_TAG=%RAW_TAG:"=%
del "%TEMP%\llama_release.json" >nul 2>nul

if not defined LLAMA_TAG goto :DL_FAIL

echo         Downloading llama-%LLAMA_TAG%-bin-win-cpu-x64.zip...

REM Direct URL — naming is predictable: llama-{tag}-bin-win-cpu-x64.zip
curl.exe -L --progress-bar ^
  -o "llama-win.zip" ^
  "https://github.com/ggml-org/llama.cpp/releases/download/%LLAMA_TAG%/llama-%LLAMA_TAG%-bin-win-cpu-x64.zip"

if not exist "llama-win.zip" goto :DL_FAIL
for %%F in ("llama-win.zip") do if %%~zF LSS 1000000 goto :DL_FAIL

echo         Extracting...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path 'llama-win.zip' -DestinationPath 'llama-bin' -Force" >nul 2>nul
del "llama-win.zip" >nul 2>nul

for /r "llama-bin" %%f in (llama-server.exe) do (
    copy "%%f" "llama-server.exe" >nul 2>nul
    for %%d in ("%%~dpf*.dll") do copy "%%d" "." >nul 2>nul
)
rmdir /s /q "llama-bin" >nul 2>nul

if not exist "llama-server.exe" goto :DL_FAIL
set SERVER_EXE=llama-server.exe
echo         OK  llama-server.exe
goto :HAS_SERVER

:DL_FAIL
echo.
echo   [ERROR] Could not download llama-server automatically.
echo.
echo   Fix options:
echo     1. Download manually from:
echo        https://github.com/ggml-org/llama.cpp/releases/latest
echo        Get the file: llama-XXXXX-bin-win-cpu-x64.zip
echo        Extract llama-server.exe into this folder.
echo     2. Then re-run START.bat.
echo.
pause & exit /b 1

:HAS_SERVER

REM ═══════════════════════════════════════════════════════════════
REM  STEP 3 ^— AI Model
REM ═══════════════════════════════════════════════════════════════
echo   [3/4] AI model...
if not exist "models" mkdir models

set MODEL_FILE=models\Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf
if exist "%MODEL_FILE%" (
    echo         OK  Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf
    goto :HAS_MODEL
)

echo         Not found. Downloading ~4.8 GB (grab a coffee)...
echo.
curl.exe -L --progress-bar ^
  -o "%MODEL_FILE%" ^
  "https://huggingface.co/mradermacher/Qwen2.5-Coder-7B-Abliterated-GGUF/resolve/main/Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   [ERROR] Model download failed. Check your connection and try again.
    if exist "%MODEL_FILE%" del "%MODEL_FILE%"
    pause & exit /b 1
)
echo         Download complete!

:HAS_MODEL

REM ═══════════════════════════════════════════════════════════════
REM  STEP 4 ^— Launch
REM ═══════════════════════════════════════════════════════════════
echo   [4/4] Starting servers...

REM Detect threads: half logical cores, min 4 max 8
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value 2^>nul') do set CORES=%%i
if not defined CORES set CORES=8
if "%CORES%"=="" set CORES=8
set /a THREADS=%CORES%/2
if %THREADS% LSS 4 set THREADS=4
if %THREADS% GTR 8 set THREADS=8

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
echo   ============================================================
echo   Loading model on %THREADS% threads ^(1-3 minutes^)...
echo   Browser opens automatically when ready.
echo   ============================================================
echo.

set DOTS=
set DOT_N=0
:WAIT
timeout /t 2 /nobreak >nul
curl.exe -s http://127.0.0.1:8080/v1/models 2>nul | findstr /C:"\"id\"" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    set /a DOT_N=DOT_N+1
    if %DOT_N% GTR 30 set DOT_N=0
    echo   Still loading... (%DOT_N% checks)
    goto :WAIT
)

start http://127.0.0.1:8080

echo.
echo   ============================================================
echo    READY  ^>  http://127.0.0.1:8080
echo   ============================================================
echo.
echo   Close this window to stop VortexDQ AI.
echo.
pause >nul

taskkill /f /im llama-server.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
echo   Stopped. Goodbye!
timeout /t 2 /nobreak >nul
