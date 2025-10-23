@echo off
setlocal enabledelayedexpansion

echo =================================================
echo Checking for files larger than 50 MB...
echo =================================================
echo.

set /a limit=50 * 1024 * 1024
set found=0

for /r .\ %%F in (*) do (
    if %%~zF GTR !limit! (
        set /a size_mb=%%~zF / 1024 / 1024
        echo [!!] Large File Found: %%F (!size_mb! MB)
        set found=1
    )
)

echo.
if !found! == 1 (
    echo -------------------------------------------------
    echo WARNING: Found large files listed above.
    echo Please remove them or add them to .gitignore before committing.
    echo -------------------------------------------------
) else (
    echo =================================================
    echo OK: No files larger than 50 MB found.
    echo You are safe to commit and push.
    echo =================================================
)

pause
