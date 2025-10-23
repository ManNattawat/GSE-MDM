@echo off
echo ========================================
echo Clean Up Repository Before Push
echo ========================================
echo.

echo Step 1: Resetting last commit...
git reset HEAD~1
echo ✅ Last commit reset.

echo.
echo Step 2: Removing large folders from disk...
if exist "agent-app-backup" (
    rmdir /s /q "agent-app-backup"
    echo ✅ Removed agent-app-backup/
)
if exist "android-sdk" (
    rmdir /s /q "android-sdk"
    echo ✅ Removed android-sdk/
)

echo.
echo Step 3: Updating .gitignore...
echo # Ignored large files and folders >> .gitignore
echo agent-app-backup/ >> .gitignore
echo android-sdk/ >> .gitignore
echo *.jar >> .gitignore
echo *.zip >> .gitignore
echo ✅ .gitignore updated.

echo.
echo Step 4: Staging changes for new commit...
git add .

echo.
echo ========================================
echo ✅ Cleanup complete! Ready to commit and push.
echo ========================================
echo.
echo Now, run these commands:
echo.
echo   git commit -m "Final cleanup: Remove large files and update gitignore"
echo   git push origin main
echo.
pause
