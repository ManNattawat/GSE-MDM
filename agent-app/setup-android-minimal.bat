@echo off
echo ========================================
echo Android SDK Minimal Setup (No Android Studio)
echo ========================================
echo.

echo This script will help you setup Android SDK without Android Studio
echo.
echo Step 1: Download Command Line Tools
echo ========================================
echo.
echo 1. Go to: https://developer.android.com/studio#command-tools
echo 2. Download "Command line tools only" for Windows
echo 3. File size: ~100MB (NOT the 4GB Android Studio!)
echo 4. Save to Downloads folder
echo.
pause

echo.
echo Step 2: Extract and Setup
echo ========================================
echo.

REM Create Android directory
if not exist "C:\Android" mkdir C:\Android
if not exist "C:\Android\cmdline-tools" mkdir C:\Android\cmdline-tools
if not exist "C:\Android\cmdline-tools\latest" mkdir C:\Android\cmdline-tools\latest

echo ✅ Created C:\Android\cmdline-tools\latest\
echo.
echo Now extract the downloaded ZIP file to:
echo    C:\Android\cmdline-tools\latest\
echo.
echo The structure should be:
echo    C:\Android\cmdline-tools\latest\bin\
echo    C:\Android\cmdline-tools\latest\lib\
echo.
pause

echo.
echo Step 3: Set Environment Variables
echo ========================================
echo.

REM Set ANDROID_HOME
setx ANDROID_HOME "C:\Android"
echo ✅ Set ANDROID_HOME=C:\Android

REM Add to PATH
setx PATH "%PATH%;C:\Android\cmdline-tools\latest\bin;C:\Android\platform-tools"
echo ✅ Added to PATH

echo.
echo Step 4: Install Required SDK Components
echo ========================================
echo.
echo After restarting PowerShell, run these commands:
echo.
echo   sdkmanager "platform-tools"
echo   sdkmanager "platforms;android-33"  
echo   sdkmanager "build-tools;33.0.0"
echo.
echo Total download: ~500MB (much better than 4GB!)
echo.

echo Step 5: Build Knox Agent
echo ========================================
echo.
echo After SDK setup, you can build:
echo   cordova build android --debug
echo.

echo ========================================
echo ✅ Setup Instructions Complete!
echo ========================================
echo.
echo IMPORTANT: 
echo 1. Restart PowerShell after running this script
echo 2. Run the sdkmanager commands above
echo 3. Then try building Knox Agent again
echo.
pause
