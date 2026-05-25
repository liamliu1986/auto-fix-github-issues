@echo off
REM auto-fix-github-issues skill - Main execution script (Windows)
REM This script is invoked by the /auto-fix-issues command

setlocal enabledelayedexpansion

set "SKILL_DIR=%USERPROFILE%\.claude\skills\auto-fix-github-issues"
set "CONFIG_FILE=%SKILL_DIR%\config.json"
set "STATE_DIR=%USERPROFILE%\.claude\state\auto-fix-github-issues"

where gh >nul 2>nul
if errorlevel 1 (
    echo Error: GitHub CLI (gh) is not installed
    exit /b 1
)

where jq >nul 2>nul
if errorlevel 1 (
    echo Error: jq is not installed
    exit /b 1
)

if not exist "%CONFIG_FILE%" (
    echo Error: config.json not found at %CONFIG_FILE%
    exit /b 1
)

for /f "usebackq tokens=*" %%i in (`jq -r ".enabled" "%CONFIG_FILE%"`) do set "enabled=%%i"
if not "%enabled%"=="true" (
    echo auto-fix-github-issues is disabled in config.json
    exit /b 0
)

echo [auto-fix-github-issues] Starting...

REM Get enabled repositories
for /f "usebackq tokens=*" %%r in (`jq -r ".repositories[] | select(.enabled == true) | \"%%(.owner)/%%(.repo)\"" "%CONFIG_FILE%"`) do (
    echo.
    echo === Processing %%r ===

    for /f "usebackq tokens=1,2 delims=/" %%a in ("%%r") do (
        set "owner=%%a"
        set "repo_name=%%b"

        for /f "usebackq tokens=*" %%i in (`gh issue list --repo "%%r" --state open --json number,title,body,createdAt --limit 50 2^>nul`) do (
            echo %%i
        )
    )
)

echo.
echo [auto-fix-github-issues] Scan complete
endlocal