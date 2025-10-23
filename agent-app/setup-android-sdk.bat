@echo off
echo ========================================
echo Setup Android SDK for Knox Agent Build
echo ========================================
echo.

echo Step 1: Download Android Command Line Tools
echo ========================================
echo.
echo 1. Go to: https://developer.android.com/studio#command-tools
echo 2. Download "Command line tools only" for Windows (~100MB)
echo 3. Extract to: C:\Android\cmdline-tools\latest\
echo.
pause

echo.
echo Step 2: Set Environment Variables
echo ========================================
setx ANDROID_HOME "C:\Android"
setx ANDROID_SDK_ROOT "C:\Android"
echo ✅ Set ANDROID_HOME and ANDROID_SDK_ROOT

echo.
echo Step 3: Add to PATH
echo ========================================
setx PATH "%PATH%;C:\Android\cmdline-tools\latest\bin;C:\Android\platform-tools"
echo ✅ Added Android tools to PATH

echo.
echo Step 4: Install SDK Components
echo ========================================
echo.
echo After restarting PowerShell, run these commands:
echo.
echo   sdkmanager "platform-tools"
echo   sdkmanager "platforms;android-33"
echo   sdkmanager "build-tools;33.0.0"
echo.
echo Total download: ~500MB
echo.

echo Step 5: Verify Installation
echo ========================================
echo.
echo After SDK installation, test with:
echo   npm run build-debug
echo.

echo ========================================
echo ✅ Setup Instructions Complete!
echo ========================================
echo.
echo IMPORTANT: Restart PowerShell after running this script
echo.
pause
