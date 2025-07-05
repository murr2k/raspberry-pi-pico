@echo off
setlocal enabledelayedexpansion

REM ========================================
REM WSL2 Hybrid Pico Flash Script
REM ========================================
REM This script builds in WSL2 and flashes from Windows
REM to work around WSL2 USB limitations

echo.
echo 🚀 WSL2 Hybrid Raspberry Pi Pico Flash Script
echo ==============================================

REM Parse command line arguments
set TARGET=blinky
set BUILD_ONLY=false
set PICO_DRIVE=D:

:parse_args
if "%~1"=="" goto done_parsing
if "%~1"=="-t" (
    set TARGET=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--target" (
    set TARGET=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="-d" (
    set PICO_DRIVE=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--drive" (
    set PICO_DRIVE=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="-b" (
    set BUILD_ONLY=true
    shift
    goto parse_args
)
if "%~1"=="--build-only" (
    set BUILD_ONLY=true
    shift
    goto parse_args
)
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help
echo Unknown option: %~1
goto show_help

:done_parsing

echo Target: %TARGET%
echo Pico Drive: %PICO_DRIVE%
echo.

REM Set paths
set WSL_PROJECT_PATH=/home/murr2k/projects/agentic/ruv-swarm/raspberry-pi-pico
set BUILD_DIR=%WSL_PROJECT_PATH%/examples/c/build
set UF2_FILE=%BUILD_DIR%/%TARGET%.uf2
set WINDOWS_UF2_PATH=\\wsl$\Ubuntu%UF2_FILE%

echo 🔨 Building %TARGET% in WSL2...
echo ===============================

REM Build in WSL2
wsl bash -c "cd %WSL_PROJECT_PATH%/examples/c && make build TARGET=%TARGET%"

if %errorlevel% neq 0 (
    echo.
    echo ❌ Build failed in WSL2
    echo Check the build output above for errors
    exit /b 1
)

echo.
echo ✅ Build successful!

REM Check if UF2 file exists
if not exist "%WINDOWS_UF2_PATH%" (
    echo.
    echo ❌ UF2 file not found: %WINDOWS_UF2_PATH%
    echo Build may have failed or wrong target specified
    exit /b 1
)

REM Get file size for verification
for %%A in ("%WINDOWS_UF2_PATH%") do set UF2_SIZE=%%~zA
echo UF2 file size: %UF2_SIZE% bytes

if "%BUILD_ONLY%"=="true" (
    echo.
    echo ✅ Build-only mode complete
    echo UF2 file ready at: %WINDOWS_UF2_PATH%
    exit /b 0
)

echo.
echo 📱 Preparing to flash Pico...
echo =============================

REM Check if Pico drive exists
if not exist "%PICO_DRIVE%\" (
    echo.
    echo ⚠️  Pico not found at %PICO_DRIVE%
    echo.
    echo Please ensure:
    echo 1. Pico is connected via USB
    echo 2. BOOTSEL button was held while connecting
    echo 3. Pico appears as drive %PICO_DRIVE% in Windows Explorer
    echo.
    echo Available drives:
    for /f "tokens=1" %%D in ('wmic logicaldisk get caption ^| findstr ":"') do echo   %%D
    echo.
    set /p RETRY="Press Enter to retry, or type 'exit' to quit: "
    if /i "!RETRY!"=="exit" exit /b 1
    goto done_parsing
)

echo ✅ Pico found at %PICO_DRIVE%

REM Verify it's a Pico (look for INFO_UF2.TXT)
if exist "%PICO_DRIVE%\INFO_UF2.TXT" (
    echo ✅ Confirmed Pico in BOOTSEL mode
    
    REM Show Pico info
    echo.
    echo 📋 Pico Information:
    type "%PICO_DRIVE%\INFO_UF2.TXT" 2>nul | findstr /i "board\|family\|version" 2>nul || echo   [INFO_UF2.TXT not readable]
) else (
    echo ⚠️  Warning: INFO_UF2.TXT not found - may not be a Pico in BOOTSEL mode
    set /p CONTINUE="Continue anyway? (y/N): "
    if /i not "!CONTINUE!"=="y" exit /b 1
)

echo.
echo 🚀 Flashing firmware...
echo ======================

REM Copy UF2 file to Pico
echo Copying %TARGET%.uf2 to Pico...
copy "%WINDOWS_UF2_PATH%" "%PICO_DRIVE%\" >nul

if %errorlevel% equ 0 (
    echo.
    echo ✅ Flash successful!
    echo 🎉 %TARGET% firmware has been flashed to your Pico
    echo.
    echo The Pico should automatically:
    echo   1. Reboot from BOOTSEL mode
    echo   2. Start running your new firmware
    echo   3. Disappear from Windows Explorer
    echo.
    echo If using stdio USB, the Pico may reappear as a serial device.
) else (
    echo.
    echo ❌ Flash failed!
    echo Check:
    echo   - Pico is still in BOOTSEL mode
    echo   - Drive %PICO_DRIVE% is writable
    echo   - USB connection is stable
    exit /b 1
)

echo.
echo 📊 Flash Summary:
echo ================
echo Target: %TARGET%
echo Firmware: %UF2_SIZE% bytes
echo Flashed to: %PICO_DRIVE%
echo Status: SUCCESS ✅

goto end

:show_help
echo.
echo WSL2 Hybrid Pico Flash Script
echo =============================
echo.
echo This script builds Raspberry Pi Pico firmware in WSL2 and flashes
echo it from Windows to work around WSL2 USB limitations.
echo.
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   -t, --target NAME      Target to build (default: blinky)
echo   -d, --drive DRIVE      Pico drive letter (default: D:)
echo   -b, --build-only       Build only, don't flash
echo   -h, --help             Show this help
echo.
echo Examples:
echo   %~nx0                           # Build and flash blinky
echo   %~nx0 -t temperature            # Build and flash temperature
echo   %~nx0 -t blinky -d E:           # Flash to E: drive
echo   %~nx0 -b -t temperature         # Build only, don't flash
echo.
echo Prerequisites:
echo   - WSL2 with Ubuntu/Debian
echo   - Pico SDK and build environment in WSL2
echo   - Pico connected in BOOTSEL mode
echo.

:end
pause