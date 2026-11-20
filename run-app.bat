@echo off
setlocal EnableExtensions
title LAKBAY LOKAL - build, install and run

rem ===========================================================================
rem  One-click: refresh the web bundle, rebuild the APK, install, launch.
rem
rem  Usage:
rem     run-app.bat          full pipeline (web build + sync + APK + install)
rem     run-app.bat fast     skip the web build (only APK + install)
rem     run-app.bat demo     offline demo build (no server needed)
rem
rem  Always rebuilds the APK. A stale APK keeps the OLD JS bundle, which is how
rem  a feature that exists in the code can look like it is missing on the phone.
rem ===========================================================================

cd /d "%~dp0"

set "ADB=E:\Android\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"

set "APK=android\app\build\outputs\apk\debug\app-debug.apk"
set "APP_ID=ph.lakbaylokal.app"
set "JAVA_HOME=C:\Users\Administrator\.jdks\temurin-21"

set "ARG=%~1"
set "FAST="
if /i "%ARG%"=="fast" set "FAST=1"
set "SYNC_ARGS="
if /i "%ARG%"=="demo" set "SYNC_ARGS=demo"

echo ============================================================
echo   LAKBAY LOKAL - run on a connected device
echo ============================================================
echo.

echo [1/4] Connected devices:
"%ADB%" devices
echo.

if not defined FAST (
    echo [2/4] Refreshing the web bundle...
    set "LAKBAY_NO_PAUSE=1"
    call "%~dp0android-sync.bat" %SYNC_ARGS%
    set "LAKBAY_NO_PAUSE="
    if errorlevel 1 (
        echo [ERROR] android-sync failed.
        pause
        exit /b 1
    )
) else (
    echo [2/4] Skipped web build ^(fast mode^).
)

echo.
echo [3/4] Building the APK...
if not exist "%JAVA_HOME%" (
    echo [ERROR] JDK 21 not found at %JAVA_HOME%
    echo         Install Temurin 21 or edit JAVA_HOME in this file.
    pause
    exit /b 1
)
pushd "%~dp0android"
call gradlew.bat assembleDebug --no-daemon
set "GRADLE_RESULT=%ERRORLEVEL%"
popd

if not "%GRADLE_RESULT%"=="0" (
    echo.
    echo [ERROR] Gradle build failed - read the output above.
    pause
    exit /b 1
)

if not exist "%APK%" (
    echo [ERROR] APK not found after the build.
    pause
    exit /b 1
)

echo.
echo [4/4] Installing and launching...
"%ADB%" -d install -r "%APK%" 2>nul
if errorlevel 1 "%ADB%" -e install -r "%APK%"
if errorlevel 1 (
    echo.
    echo Install failed. If the phone shows "unauthorized", unlock it and tap
    echo "Allow USB debugging", then run this file again.
    pause
    exit /b 1
)

"%ADB%" -d shell am force-stop %APP_ID% 2>nul
"%ADB%" -d shell am start -n %APP_ID%/.MainActivity 2>nul
if errorlevel 1 (
    "%ADB%" -e shell am force-stop %APP_ID% >nul 2>&1
    "%ADB%" -e shell am start -n %APP_ID%/.MainActivity
)

echo.
echo Done - the app should be opening on the device.
echo.
if not defined SYNC_ARGS (
    echo NOTE: normal build. The API server must be running:
    echo           start-server.bat
)
echo.
pause
