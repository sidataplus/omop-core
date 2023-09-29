@echo off
setlocal enabledelayedexpansion

REM Determine the script's current directory
for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

REM Define the service names
set "POSTGRES_SERVICE=crosspipe-pg"
set "BASHCLI_SERVICE=crosspipe-cli"

REM Check for the correct number of arguments
if "%~#" lss "1" goto :Usage
if "%~#" gtr "3" goto :Usage

REM Extract the command (up, stop, or down)
set "COMMAND=%~1"
shift

REM Initialize flags
set "VOLUME_FLAG="

REM Check for additional flags
:ParseFlags
if /i "%~1"=="-v" (
  set "VOLUME_FLAG=-v"
  shift
  goto :ParseFlags
)

REM Function to start the services
:start_services
echo Starting PostgreSQL in detached mode...
podman-compose -f "%SCRIPT_DIR%\crosspipe-compose.yaml" up -d %POSTGRES_SERVICE%

echo Starting Bash CLI in the foreground...
podman-compose -f "%SCRIPT_DIR%\crosspipe-compose.yaml" up %BASHCLI_SERVICE%
goto :EOF

REM Function to stop the services
:stop_services
echo Stopping PostgreSQL...
podman-compose -f "%SCRIPT_DIR%\crosspipe-compose.yaml" stop %POSTGRES_SERVICE%

echo Stopping Bash CLI...
podman-compose -f "%SCRIPT_DIR%\crosspipe-compose.yaml" stop %BASHCLI_SERVICE%
goto :EOF

REM Function to stop and remove volumes (if -v flag is used)
:down_services
echo Stopping and removing containers...
podman-compose -f "%SCRIPT_DIR%\crosspipe-compose.yaml" down %VOLUME_FLAG%

if "%VOLUME_FLAG%"=="-v" (
  echo Removing volumes...
  podman-compose -f "%SCRIPT_DIR%\crosspipe-compose.yaml" down -v
)

goto :EOF

REM Usage information
:Usage
echo Usage: %~nx0 ^<up^|stop^|down^> [-v] [options]
exit /b 1
