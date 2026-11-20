@echo off
setlocal EnableExtensions EnableDelayedExpansion
title LAKBAY LOKAL - API server

rem ============================================================
rem  One-click server. Everything below is automatic:
rem    - asks for admin (needed for firewall rules)
rem    - creates the Python environment + installs dependencies
rem    - creates server\.env with a generated JWT secret
rem    - creates the database and loads the sample data
rem    - opens the firewall for this machine's local subnet only
rem    - starts the API and prints the address for the phone
rem  No manual commands for the client.
rem ============================================================

rem ---------- self-elevate once ----------
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator permission to configure the firewall...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b 0
)

cd /d "%~dp0"
set "ROOT=%~dp0"
set "SERVER=%ROOT%server"
set "PY=%SERVER%\.venv\Scripts\python.exe"

echo ============================================================
echo   LAKBAY LOKAL - starting the API server
echo ============================================================
echo.

rem ---------- Python environment ----------
rem A .venv folder can exist and still be useless: it may have been copied from
rem another machine (broken interpreter path) or created without installing the
rem requirements. Checking only for the folder is what produced
rem "No module named uvicorn". Verify an actual dependency instead.
echo [1/4] Checking the Python environment...
set "ENV_OK="

if exist "%PY%" (
    "%PY%" -c "import uvicorn" >nul 2>&1
    if not errorlevel 1 set "ENV_OK=1"
)

if defined ENV_OK (
    echo       Python environment ready.
) else (
    if exist "%PY%" (
        echo       Environment found but dependencies are missing - installing...
        "%PY%" -m pip install --quiet -r "%SERVER%\requirements.txt" >nul 2>&1
        "%PY%" -c "import uvicorn" >nul 2>&1
        if not errorlevel 1 set "ENV_OK=1"
    )
)

pushd "%SERVER%"

if not defined ENV_OK (
  echo [0/3] Rebuilding the Python environment from scratch...
  REM Pick a SUPPORTED interpreter explicitly.
  REM `py -3` returns the NEWEST Python, which on a fresh machine can be 3.14.
  REM The pinned pydantic-core has no cp314 wheel, so pip falls back to building
  REM it with Rust and fails with "linker link.exe not found". Prefer 3.11-3.13.
  set "PYLAUNCH="
  for %%V in (3.11 3.12 3.13) do (
    if not defined PYLAUNCH (
      py -%%V -c "import sys" >nul 2>&1 && set "PYLAUNCH=py -%%V"
    )
  )
  if not defined PYLAUNCH (
    where python >nul 2>&1 && set "PYLAUNCH=python"
  )
  if not defined PYLAUNCH (
    echo [ERROR] Python 3.11-3.13 was not found on this computer.
    echo         Install it from https://www.python.org/downloads/
    echo         and tick "Add python.exe to PATH", then run this file again.
    echo.
    pause
    exit /b 1
  )

  if exist ".venv" rmdir /s /q ".venv"
  !PYLAUNCH! -m venv .venv
  if errorlevel 1 (
    echo [ERROR] Could not create the Python environment.
    pause
    exit /b 1
  )

  REM Refuse an interpreter that cannot install the pinned wheels.
  "%PY%" -c "import sys; sys.exit(0 if sys.version_info[:2] <= (3, 13) else 1)" >nul 2>&1
  if errorlevel 1 (
    for /f "delims=" %%V in ('"%PY%" -c "import sys; print(sys.version.split()[0])"') do set "PYVER=%%V"
    echo.
    echo [ERROR] This machine used Python !PYVER! for the environment.
    echo         LAKBAY LOKAL needs Python 3.11, 3.12 or 3.13.
    echo         Python 3.14 has no prebuilt wheels for the pinned dependencies
    echo         pydantic-core, so pip tries to compile them with Rust and fails.
    echo.
    echo         Install Python 3.12 from https://www.python.org/downloads/
    echo         then delete server\.venv and run this file again.
    echo.
    rmdir /s /q ".venv" 2>nul
    pause
    exit /b 1
  )

  "%PY%" -m pip install --quiet --upgrade pip >nul 2>&1
  "%PY%" -m pip install --quiet -r requirements.txt
  "%PY%" -c "import uvicorn" >nul 2>&1
  if errorlevel 1 (
    echo.
    echo [ERROR] Dependencies could not be installed.
    echo         Usual cause: the Python version is not supported by the pinned
    echo         packages, or there is no internet connection.
    echo         Try Python 3.12, then delete server\.venv and run this again.
    echo.
    rmdir /s /q ".venv" 2>nul
    pause
    exit /b 1
  )
)

popd

rem ---------- server\.env ----------
if not exist "%SERVER%\.env" (
    echo [2/4] Creating server\.env with a generated JWT secret...
    copy /y "%SERVER%\.env.example" "%SERVER%\.env" >nul
    for /f %%S in ('%PY% -c "import secrets;print(secrets.token_hex(32))"') do set "SECRET=%%S"
    powershell -NoProfile -Command "$p='%SERVER%\.env'; $t=[IO.File]::ReadAllText($p); $t=$t -replace '(?m)^JWT_SECRET_KEY=.*$','JWT_SECRET_KEY=%SECRET%'; [IO.File]::WriteAllText($p,$t,(New-Object Text.UTF8Encoding($false)))"
) else (
    echo [2/4] server\.env already exists.
)

rem ---------- database + sample data ----------
echo [3/4] Preparing the database and sample data...
pushd "%SERVER%"
"%PY%" -m scripts.seed_dev >nul 2>&1
popd

rem ---------- firewall ----------
echo [4/4] Opening the firewall for this local network...
powershell -NoProfile -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "foreach ($r in @(@{n='LAKBAY API (TCP 8000)';p='TCP';port=8000}, @{n='LAKBAY Discovery (UDP 37020)';p='UDP';port=37020})) {" ^
  "  Get-NetFirewallRule -DisplayName $r.n | Remove-NetFirewallRule;" ^
  "  New-NetFirewallRule -DisplayName $r.n -Direction Inbound -Protocol $r.p -LocalPort $r.port -Action Allow -RemoteAddress LocalSubnet -Profile Any | Out-Null }"
echo       Firewall rules ready (local subnet only).

echo.
echo ============================================================
echo   Server address
echo ============================================================
echo.
echo   On this PC      : http://127.0.0.1:8000/docs
echo   From a phone on the same Wi-Fi or hotspot:
powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^127\.|^169\.254\.' -and $_.InterfaceAlias -notmatch 'vEthernet|WSL|Loopback|OpenVPN|TAP' } | ForEach-Object { '     http://' + $_.IPAddress + ':8000    (' + $_.InterfaceAlias + ')' }"
echo.
echo   The phone finds this automatically - no IP entry needed.
echo.
echo   This ONE process also answers discovery on UDP 37020,
echo   so there is no separate "discovery" window to watch for.
echo   Keep this window open. Press Ctrl+C to stop.
echo ============================================================
echo.

pushd "%SERVER%"
"%PY%" -m uvicorn app.main:app --host 0.0.0.0 --port 8000
popd

echo.
echo Server stopped (exit code %ERRORLEVEL%).
echo If this closed right after starting, read the message above.
echo.
pause
