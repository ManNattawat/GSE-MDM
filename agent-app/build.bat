@echo off
echo ========================================
echo GSE Knox Agent - Build Script
echo ========================================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found. Please install Node.js 18+ first.
    echo Download from: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js found: 
node --version

REM Check if Cordova is installed
cordova --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Installing Cordova CLI...
    npm install -g cordova@12.0.0
    if %errorlevel% neq 0 (
        echo ERROR: Failed to install Cordova CLI
        pause
        exit /b 1
    )
)

echo ✅ Cordova found:
cordova --version

echo.
echo ========================================
echo Building Knox Agent APK...
echo ========================================

REM Install dependencies
echo.
echo 📦 Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

REM Add Android platform if not exists
echo.
echo 📱 Adding Android platform...
call cordova platform add android
if %errorlevel% neq 0 (
    echo WARNING: Android platform may already exist
)

REM Install plugins
echo.
echo 🔌 Installing plugins...
call cordova plugin add cordova-plugin-device
call cordova plugin add cordova-plugin-network-information
call cordova plugin add cordova-plugin-geolocation
call cordova plugin add cordova-plugin-websocket

REM Build debug APK
echo.
echo 🔨 Building debug APK...
call cordova build android --debug
if %errorlevel% neq 0 (
    echo ERROR: Failed to build debug APK
    pause
    exit /b 1
)

REM Build release APK
echo.
echo 🔨 Building release APK...
call cordova build android --release
if %errorlevel% neq 0 (
    echo ERROR: Failed to build release APK
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ BUILD SUCCESSFUL!
echo ========================================
echo.
echo 📱 APK Files Created:
echo.
echo DEBUG APK:
echo   platforms\android\app\build\outputs\apk\debug\app-debug.apk
echo.
echo RELEASE APK (unsigned):
echo   platforms\android\app\build\outputs\apk\release\app-release-unsigned.apk
echo.
echo ========================================
echo Next Steps:
echo ========================================
echo.
echo 1. For testing: Use app-debug.apk
echo 2. For production: Sign app-release-unsigned.apk
echo 3. Install on Samsung tablet: adb install app-debug.apk
echo.
echo ⚠️  Note: Knox features require Samsung Knox license key
echo    Update config.xml with your Knox license before production use
echo.

REM Check if APK files exist
if exist "platforms\android\app\build\outputs\apk\debug\app-debug.apk" (
    echo ✅ Debug APK: FOUND
) else (
    echo ❌ Debug APK: NOT FOUND
)

if exist "platforms\android\app\build\outputs\apk\release\app-release-unsigned.apk" (
    echo ✅ Release APK: FOUND
) else (
    echo ❌ Release APK: NOT FOUND
)

echo.
echo Press any key to exit...
pause >nul
