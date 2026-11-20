@echo off
REM ===========================================================================
REM  android-sync.bat - rebuild the web app and copy it into the Android project
REM
REM  Run this AFTER any change to src/, .env.local, or capacitor.config.ts,
REM  and BEFORE pressing Run in Android Studio.
REM
REM  Android Studio only runs Gradle. It does not run `npm run build` or
REM  `npx cap sync`, so without this step the APK keeps the previous JS bundle
REM  (and the previous API address).
REM
REM  Usage:
REM     android-sync.bat          normal build (talks to the API server)
REM     android-sync.bat demo     offline demo build (no server needed)
REM ===========================================================================
setlocal

cd /d "%~dp0"

if not exist package.json (
  echo [ERROR] package.json not found next to this file.
  pause
  exit /b 1
)

set "MODE=%~1"
if /i "%MODE%"=="demo" (
  set "BUILD_CMD=npm run build:demo"
  set "MODE_LABEL=DEMO (offline, no server needed)"
) else (
  set "BUILD_CMD=npm run build"
  set "MODE_LABEL=NORMAL (needs start-server.bat)"
)

echo ============================================================
echo   LAKBAY LOKAL - sync web build into Android
echo   Mode: %MODE_LABEL%
echo ============================================================
echo.

echo [1/2] Building the web app...
call %BUILD_CMD%
if errorlevel 1 (
  echo.
  echo [ERROR] The web build failed. Fix the error above and run this again.
  pause
  exit /b 1
)

echo.
echo [2/2] Copying the build into android\app\src\main\assets\public ...
call npx cap sync android
if errorlevel 1 (
  echo.
  echo [ERROR] cap sync failed. Run it from the repo root, not from android\.
  pause
  exit /b 1
)

echo.
echo [OK] Android assets are up to date ^(%MODE_LABEL%^).
echo.
echo      Now either:
echo        - press Run in Android Studio, or
echo        - double-click run-app.bat (installs and opens it on the phone)
echo.
echo      Building the APK by hand needs JDK 21:
echo          cd android
echo          set JAVA_HOME=C:\Users\Administrator\.jdks\temurin-21
echo          gradlew.bat assembleDebug --no-daemon
echo.
if not defined LAKBAY_NO_PAUSE pause
exit /b 0
