@echo off
setlocal EnableExtensions
title LAKBAY LOKAL - fix Android Studio stale app id

cd /d "%~dp0"

echo ============================================================
echo   FIX: "Activity class {io.ionic.starter/...} does not exist"
echo ============================================================
echo.
echo This wipes Android Studio's cached Gradle model for this project
echo and rebuilds it from the current files (appId ph.lakbaylokal.app).
echo It also regenerates the Capacitor Android plugin files, because those
echo are git-ignored and missing on a fresh clone.
echo.
echo   IMPORTANT: CLOSE ANDROID STUDIO FIRST.
echo   (This script will close it for you after you press a key.)
echo.
pause

echo.
echo [1/6] Stopping Android Studio and Gradle daemons...
taskkill /IM studio64.exe /F >nul 2>&1
pushd "%~dp0android"
call gradlew.bat --stop >nul 2>&1
popd

echo [2/6] Removing project caches (.idea, .gradle, build outputs)...
rmdir /s /q "android\.idea" 2>nul
rmdir /s /q "android\.gradle" 2>nul
rmdir /s /q "android\build" 2>nul
rmdir /s /q "android\app\build" 2>nul
rmdir /s /q "android\capacitor-cordova-android-plugins" 2>nul

echo [3/6] Removing Android Studio's external build cache (safe to regenerate)...
for /d %%D in ("%LOCALAPPDATA%\Google\AndroidStudio*") do (
    rmdir /s /q "%%D\system\external_build_system" 2>nul
)

echo [4/6] Building the web app and regenerating the Android plugins...
where npm >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm was not found. Install Node.js, then run this again.
    pause
    exit /b 1
)
set "LAKBAY_NO_PAUSE=1"
call "%~dp0android-sync.bat"
set "SYNC_RESULT=%ERRORLEVEL%"
set "LAKBAY_NO_PAUSE="
if not "%SYNC_RESULT%"=="0" (
    echo.
    echo [ERROR] The web build or "npx cap sync android" failed.
    pause
    exit /b 1
)

if not exist "android\capacitor-cordova-android-plugins" (
    echo.
    echo [ERROR] Capacitor still did not generate the Android plugins folder.
    echo         Run "npx cap sync android" manually and read its output.
    pause
    exit /b 1
)

echo.
echo [5/6] Rebuilding from scratch with JDK 21...
if exist "C:\Users\Administrator\.jdks\temurin-21" (
    set "JAVA_HOME=C:\Users\Administrator\.jdks\temurin-21"
)
pushd "%~dp0android"
call gradlew.bat assembleDebug --no-daemon
set "BUILD_RESULT=%ERRORLEVEL%"
popd

echo.
echo [6/6] Verifying the built APK package name...
set "AAPT="
for /d %%B in ("E:\Android\build-tools\*") do set "AAPT=%%B\aapt.exe"
if exist "%AAPT%" (
    "%AAPT%" dump badging "android\app\build\outputs\apk\debug\app-debug.apk" 2>nul | findstr /b "package:"
    "%AAPT%" dump badging "android\app\build\outputs\apk\debug\app-debug.apk" 2>nul | findstr /b "launchable-activity:"
)

echo.
if "%BUILD_RESULT%"=="0" (
    echo SUCCESS. Reopen Android Studio on E:\AndroidProjects\lakbay\android
    echo and let Gradle sync finish before pressing Run.
) else (
    echo BUILD FAILED - read the Gradle output above.
)
echo.
pause
