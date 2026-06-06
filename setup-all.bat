@echo off
title VortexDQ AI
cd /d "%~dp0"

echo ============================================
echo  VortexDQ AI - One Click
echo ============================================
echo.

REM Check if VS environment is active; if not, auto-detect
where cl.exe >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [Finding Visual Studio...]
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
    ) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
    ) else if exist "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
    ) else (
        echo [ERROR] Visual Studio Build Tools not found.
    echo Install from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
    echo Select "Desktop development with C++".
    pause
    exit /b 1
)
)

:BUILD
if exist "build\bin\llama-server.exe" goto :DOWNLOAD

echo [Building...]
if not exist "build" mkdir build
cd build
cmake .. -DCMAKE_GENERATOR="Ninja" -DLLAMA_BUILD_SERVER=ON -DLLAMA_BUILD_TOOLS=ON -DLLAMA_BUILD_UI=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_APP=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Configuring...
    cmake .. -DCMAKE_GENERATOR="Ninja" -DLLAMA_BUILD_SERVER=ON -DLLAMA_BUILD_TOOLS=ON -DLLAMA_BUILD_UI=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_APP=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release
    pause
    exit /b 1
)
cmake --build . --config Release >nul
    if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Building...
    cmake --build . --config Release
        pause
        exit /b 1
    )
cd ..
echo [Build OK]

:DOWNLOAD
if not exist "models" mkdir models
if not exist "models\Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf" (
    echo [Downloading model ~4.8 GB...]
    curl.exe -L -# -o "models\Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf" ^
      "https://huggingface.co/mradermacher/Qwen2.5-Coder-7B-Abliterated-GGUF/resolve/main/Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf"
    if %ERRORLEVEL% NEQ 0 (
        echo [Download failed]
        pause
        exit /b 1
    )
)

REM Use half the logical CPU cores, capped at 8, minimum 4
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value 2^>nul') do set CORES=%%i
if not defined CORES set CORES=8
if %CORES% LSS 1 set CORES=8
set /a THREADS=%CORES%/2
if %THREADS% LSS 4 set THREADS=4
if %THREADS% GTR 8 set THREADS=8

echo [Starting AI server on %THREADS% threads...]
start /B "" "build\bin\llama-server.exe" ^
    -m "models\Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf" ^
    --port 8080 --host 127.0.0.1 ^
    -c 16384 -t %THREADS% -tb %THREADS% -b 512 ^
    --path "." --log-disable >nul 2>nul

echo [Starting agent server...]
start /B "" node agent-server.js >nul 2>nul

echo [Waiting for model to finish loading - this takes 1-3 minutes...]
:WAIT
timeout /t 3 /nobreak >nul
curl.exe -s http://127.0.0.1:8080/v1/models 2>nul | findstr /C:"\"id\"" >nul 2>nul
if %ERRORLEVEL% NEQ 0 goto :WAIT
echo [Model loaded! Opening browser...]
start http://127.0.0.1:8080

echo.
echo ============================================
echo  READY: http://127.0.0.1:8080
echo ============================================
echo  Close this window to stop the server.
echo.
pause >nul
taskkill /f /im llama-server.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul

