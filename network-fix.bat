@echo off
setlocal EnableExtensions
title LAKBAY LOKAL - network and firewall fix

rem ============================================================
rem  Run this after switching to a NEW network
rem  (router, phone hotspot, laptop hotspot).
rem
rem  It re-applies the firewall rules for the current network so
rem  the phone can always reach the server. Safe to run any time.
rem
rem  No commands to type - it asks for admin by itself.
rem ============================================================

cd /d "%~dp0"

rem ---------- self-elevate once ----------
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator permission for the firewall...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b 0
)

if not exist "%~dp0scripts\network-check.ps1" (
    echo [ERROR] scripts\network-check.ps1 is missing.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\network-check.ps1"
set "RESULT=%ERRORLEVEL%"

rem If the server answered, bake the address that was just written to .env.local
rem into the web bundle and copy it into the Android project. This is what makes
rem the app work even on networks that block UDP broadcast.
if "%RESULT%"=="0" (
    echo.
    echo Rebuilding the app with the address above...
    set "LAKBAY_NO_PAUSE=1"
    call "%~dp0android-sync.bat"
    set "LAKBAY_NO_PAUSE="
    if errorlevel 1 (
        echo [WARN] The rebuild failed - run android-sync.bat manually.
    ) else (
        echo [OK] App rebuilt. Reinstall the APK to pick up the new address:
        echo      run-app.bat
    )
) else (
    echo.
    echo Skipping the rebuild because the server did not answer.
    echo Start start-server.bat first, then run this again.
)

echo ============================================================
if "%RESULT%"=="0" (
    echo  Done. You can leave this window open or close it.
) else (
    echo  Finished with warnings - read the output above.
)
echo ============================================================
echo.
pause
exit /b %RESULT%
