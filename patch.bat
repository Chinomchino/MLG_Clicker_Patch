@echo off
setlocal enabledelayedexpansion

:: MLG Clicker - Preservation Patch Script (Windows)
:: Fixes broken Google Play license verification on abandoned game
:: Fixes ad orientation and rendering bugs on modern Android
:: Original game by Quantum Games / Flexus Games - all rights reserved
:: Patch maintained for preservation purposes - takedown requests honoured

set APKTOOL_VERSION=2.9.3
set SIGNER_VERSION=1.3.0
set APKTOOL_JAR=apktool_%APKTOOL_VERSION%.jar
set SIGNER_JAR=uber-apk-signer-%SIGNER_VERSION%.jar
set APKTOOL_URL=https://github.com/iBotPeaches/Apktool/releases/download/v%APKTOOL_VERSION%/%APKTOOL_JAR%
set SIGNER_URL=https://github.com/patrickfav/uber-apk-signer/releases/download/v%SIGNER_VERSION%/%SIGNER_JAR%

if "%~1"=="" (
    set INPUT_APK=mlg-clicker.apk
) else (
    set INPUT_APK=%~1
)

set OUT_DIR=mlgclicker_out
set PATCHED_APK=mlgclicker_patched.apk
set LOGFILE=patch_log.txt
set HELPER=%~dp0patch_helper.ps1

:: Initialise log
echo MLG Clicker Preservation Patch - Log > "%LOGFILE%"
echo Run: %DATE% %TIME% >> "%LOGFILE%"
echo Input APK: %INPUT_APK% >> "%LOGFILE%"
echo. >> "%LOGFILE%"

echo.
echo   MLG Clicker Preservation Patch
echo   Original game (c) Quantum Games / Flexus Games
echo   Log: %LOGFILE%
echo.

goto :skip_log_fn
:log
    echo %~1
    echo %~1 >> "%LOGFILE%"
    exit /b 0
:skip_log_fn

:: ---------------------------------------------------------------
:: Check helper script exists
:: ---------------------------------------------------------------
if not exist "%HELPER%" (
    call :log "[x] patch_helper.ps1 not found next to patch.bat"
    call :log "    Make sure both files are in the same folder."
    exit /b 1
)

:: ---------------------------------------------------------------
:: Check input APK
:: ---------------------------------------------------------------
if not exist "%INPUT_APK%" (
    call :log "[x] Input APK not found: %INPUT_APK%"
    call :log "    Usage: patch.bat [path-to-apk]"
    exit /b 1
)
call :log "[+] Input APK found: %INPUT_APK%"

:: ---------------------------------------------------------------
:: Check Java
:: ---------------------------------------------------------------
java -version >nul 2>&1
if errorlevel 1 (
    call :log "[x] Java not found. Please install JDK 8 or higher."
    exit /b 1
)
call :log "[+] Java found"

:: ---------------------------------------------------------------
:: Download apktool if missing
:: ---------------------------------------------------------------
if not exist "%APKTOOL_JAR%" (
    call :log "[!] %APKTOOL_JAR% not found, downloading..."
    powershell -Command "Invoke-WebRequest -Uri '%APKTOOL_URL%' -OutFile '%APKTOOL_JAR%'"
    if errorlevel 1 (
        call :log "[x] Failed to download %APKTOOL_JAR%"
        call :log "    Download manually from: %APKTOOL_URL%"
        exit /b 1
    )
    call :log "[+] Downloaded %APKTOOL_JAR%"
) else (
    call :log "[+] %APKTOOL_JAR% already present, skipping download"
)

:: ---------------------------------------------------------------
:: Download uber-apk-signer if missing
:: ---------------------------------------------------------------
if not exist "%SIGNER_JAR%" (
    call :log "[!] %SIGNER_JAR% not found, downloading..."
    powershell -Command "Invoke-WebRequest -Uri '%SIGNER_URL%' -OutFile '%SIGNER_JAR%'"
    if errorlevel 1 (
        call :log "[x] Failed to download %SIGNER_JAR%"
        call :log "    Download manually from: %SIGNER_URL%"
        exit /b 1
    )
    call :log "[+] Downloaded %SIGNER_JAR%"
) else (
    call :log "[+] %SIGNER_JAR% already present, skipping download"
)

:: ---------------------------------------------------------------
:: Clean output dir
:: ---------------------------------------------------------------
if exist "%OUT_DIR%" (
    call :log "[!] Output directory exists, removing..."
    rmdir /s /q "%OUT_DIR%"
)

:: ---------------------------------------------------------------
:: Decompile
:: ---------------------------------------------------------------
call :log "[+] Decompiling APK..."
java -jar "%APKTOOL_JAR%" d "%INPUT_APK%" -o "%OUT_DIR%" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    call :log "[x] apktool decompile failed - see log for details"
    exit /b 1
)
call :log "[+] Decompile complete"

:: ---------------------------------------------------------------
:: PATCH 1: Remove license check call
:: ---------------------------------------------------------------
call :log "[+] Patch 1/2: Removing license verification call..."
powershell -ExecutionPolicy Bypass -File "%HELPER%" -Action license -LogFile "%LOGFILE%" -OutDir "%OUT_DIR%"
if errorlevel 1 (
    call :log "[x] Patch 1 failed - see log for details"
    exit /b 1
)

:: ---------------------------------------------------------------
:: PATCH 2: Fix ad activity orientation in manifest
:: ---------------------------------------------------------------
call :log "[+] Patch 2/2: Locking ad activity orientations to portrait..."
powershell -ExecutionPolicy Bypass -File "%HELPER%" -Action orientation -LogFile "%LOGFILE%" -OutDir "%OUT_DIR%"
if errorlevel 1 (
    call :log "[x] Patch 2 failed - see log for details"
    exit /b 1
)

:: ---------------------------------------------------------------
:: Recompile
:: ---------------------------------------------------------------
call :log "[+] Recompiling APK..."
java -jar "%APKTOOL_JAR%" b "%OUT_DIR%" -o "%PATCHED_APK%" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    call :log "[x] apktool build failed - see log for details"
    exit /b 1
)
call :log "[+] Recompile complete"

:: ---------------------------------------------------------------
:: Sign
:: ---------------------------------------------------------------
call :log "[+] Signing APK..."
java -jar "%SIGNER_JAR%" -a "%PATCHED_APK%" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    call :log "[x] Signing failed - see log for details"
    exit /b 1
)
call :log "[+] Signing complete"

:: ---------------------------------------------------------------
:: Find signed output
:: ---------------------------------------------------------------
set SIGNED=
for %%f in (mlgclicker_patched*aligned*signed*.apk) do set SIGNED=%%f

if "%SIGNED%"=="" (
    call :log "[x] Could not find signed APK output"
    exit /b 1
)

call :log "[+] Output APK: %SIGNED%"

echo.
echo [+] All done!
echo.
echo   Patches applied:
echo     1. License verification call removed (dead server)
echo     2. Ad activity orientation locked to portrait
echo.
echo   Output:  %SIGNED%
echo   Log:     %LOGFILE%
echo.
echo   Install with:
echo     adb uninstall com.quantumgames.mlg
echo     adb install "%SIGNED%"
echo.

echo. >> "%LOGFILE%"
echo --- COMPLETED SUCCESSFULLY --- >> "%LOGFILE%"

endlocal
