# 🏗️ Knox Agent Build Instructions

**สำหรับ Samsung Knox Agent - ไม่ใช้ Android Studio**

## 📋 Prerequisites

### 1. Install Node.js
```bash
# Download from nodejs.org
# Version: 18.x or higher
node --version  # Should show v18.x.x
npm --version   # Should show 9.x.x
```

### 2. Install Cordova CLI
```bash
npm install -g cordova@12.0.0
cordova --version  # Should show 12.0.0
```

### 3. Install Java JDK (for Android builds)
```bash
# Download OpenJDK 11 or 17
# Set JAVA_HOME environment variable
echo $JAVA_HOME  # Should point to JDK installation
```

### 4. Android SDK (Minimal Setup)
```bash
# Option 1: Install Android Studio (full)
# Option 2: Command line tools only (minimal)

# Download command line tools from developer.android.com
# Extract to: C:\Android\cmdline-tools\latest\
# Set ANDROID_HOME=C:\Android
# Add to PATH: %ANDROID_HOME%\cmdline-tools\latest\bin
```

## 🚀 Build Process

### Step 1: Setup Project
```bash
cd D:\projects\GSE-Enterprise-Platform\knox-agent

# Install dependencies
npm install

# Add Android platform
npm run add-platform
# or manually: cordova platform add android

# Install plugins
npm run add-plugins
# or manually:
# cordova plugin add cordova-plugin-device
# cordova plugin add cordova-plugin-network-information
# cordova plugin add cordova-plugin-geolocation
# cordova plugin add cordova-plugin-websocket
```

### Step 2: Configure Knox License
```bash
# Edit config.xml
# Replace YOUR_KNOX_LICENSE_KEY with actual license from Samsung
<preference name="KnoxLicenseKey" value="YOUR_KNOX_LICENSE_KEY" />
```

### Step 3: Add Images
```bash
# Add required images to www/img/
# - gse-logo.png (40x40px)
# - icon.png (512x512px)
# - splash.png (1080x1920px)
```

### Step 4: Build APK

#### Debug Build (for testing)
```bash
npm run build-debug
# or: cordova build android --debug

# Output: platforms/android/app/build/outputs/apk/debug/app-debug.apk
```

#### Release Build (for production)
```bash
npm run build
# or: cordova build android --release

# Output: platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk
```

## 🔐 APK Signing (Production)

### Step 1: Generate Keystore (One Time)
```bash
keytool -genkey -v -keystore gse-knox.keystore -alias gse-knox -keyalg RSA -keysize 2048 -validity 10000

# Enter details:
# - Password: [secure password]
# - Name: GSE Enterprise Platform
# - Organization: GSE
# - Country: TH
```

### Step 2: Sign APK
```bash
# Navigate to APK directory
cd platforms/android/app/build/outputs/apk/release/

# Sign APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ../../../../../../../../gse-knox.keystore app-release-unsigned.apk gse-knox

# Align APK (optimize)
zipalign -v 4 app-release-unsigned.apk gse-knox-agent-v1.0.0.apk
```

### Step 3: Verify Signature
```bash
jarsigner -verify -verbose -certs gse-knox-agent-v1.0.0.apk
```

## 📦 Alternative Build Methods

### Method 1: GitHub Actions (Automated)
```yaml
# .github/workflows/build-knox-agent.yml
name: Build Knox Agent APK

on:
  push:
    branches: [ main ]
    paths: [ 'knox-agent/**' ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '11'
        
    - name: Setup Android SDK
      uses: android-actions/setup-android@v2
      
    - name: Install Cordova
      run: npm install -g cordova@12.0.0
      
    - name: Build APK
      run: |
        cd knox-agent
        npm install
        cordova platform add android
        cordova plugin add cordova-plugin-device
        cordova plugin add cordova-plugin-network-information
        cordova plugin add cordova-plugin-geolocation
        cordova build android --release
        
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: knox-agent-apk
        path: knox-agent/platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk
```

### Method 2: Docker Build
```dockerfile
# Dockerfile
FROM node:18

# Install Java
RUN apt-get update && apt-get install -y openjdk-11-jdk

# Install Android SDK
ENV ANDROID_HOME=/opt/android-sdk
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip && \
    unzip commandlinetools-linux-8512546_latest.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest

ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# Install Cordova
RUN npm install -g cordova@12.0.0

# Accept Android licenses
RUN yes | sdkmanager --licenses

# Install required SDK components
RUN sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

WORKDIR /app
COPY knox-agent/ .

RUN npm install && \
    cordova platform add android && \
    cordova plugin add cordova-plugin-device && \
    cordova plugin add cordova-plugin-network-information && \
    cordova plugin add cordova-plugin-geolocation && \
    cordova build android --release

CMD ["cp", "platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk", "/output/"]
```

```bash
# Build with Docker
docker build -t knox-agent-builder .
docker run -v $(pwd)/output:/output knox-agent-builder
```

### Method 3: Online Build Services

#### PhoneGap Build (Adobe)
1. Create account at build.phonegap.com
2. Upload project ZIP
3. Build APK online
4. Download signed APK

#### Ionic Appflow
1. Create account at ionic.io
2. Connect GitHub repository
3. Configure build pipeline
4. Automatic builds on commit

## 🧪 Testing

### Browser Testing (Limited)
```bash
cd knox-agent
npx http-server www -p 8080
# Open: http://localhost:8080
# Note: Knox features won't work in browser
```

### Device Testing
```bash
# Install on connected device
adb install platforms/android/app/build/outputs/apk/debug/app-debug.apk

# Enable device admin
adb shell dpm set-device-admin com.gse.knox.agent/.KnoxDeviceAdminReceiver

# View logs
adb logcat | grep "Knox Agent"
```

### Emulator Testing
```bash
# Create Android emulator
avd create -n knox-test -k "system-images;android-33;google_apis;x86_64"

# Start emulator
emulator -avd knox-test

# Install APK
adb install app-debug.apk
```

## 🔧 Troubleshooting

### Common Build Errors

#### 1. "ANDROID_HOME not set"
```bash
# Windows
set ANDROID_HOME=C:\Android
set PATH=%PATH%;%ANDROID_HOME%\cmdline-tools\latest\bin

# Linux/Mac
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

#### 2. "Java not found"
```bash
# Check Java installation
java -version
javac -version

# Set JAVA_HOME
# Windows: set JAVA_HOME=C:\Program Files\Java\jdk-11.0.x
# Linux: export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
```

#### 3. "Cordova platform not found"
```bash
# Remove and re-add platform
cordova platform remove android
cordova platform add android@12.0.0
```

#### 4. "Plugin not found"
```bash
# Remove and re-add plugins
cordova plugin remove cordova-plugin-device
cordova plugin add cordova-plugin-device@2.1.0
```

#### 5. "Build failed - missing SDK"
```bash
# Install required SDK components
sdkmanager "platforms;android-33"
sdkmanager "build-tools;33.0.0"
sdkmanager "platform-tools"
```

### Knox-Specific Issues

#### 1. "Knox license invalid"
- Get valid license from Samsung Knox Portal
- Update config.xml with correct license key
- Ensure device supports Knox

#### 2. "Device admin not enabled"
```bash
# Enable manually
adb shell dpm set-device-admin com.gse.knox.agent/.KnoxDeviceAdminReceiver

# Or via app settings
Settings > Security > Device administrators > Enable Knox Agent
```

## 📊 Build Output

### File Structure
```
platforms/android/app/build/outputs/apk/
├── debug/
│   └── app-debug.apk              # Debug APK (for testing)
└── release/
    ├── app-release-unsigned.apk   # Unsigned release APK
    └── gse-knox-agent-v1.0.0.apk  # Signed release APK (after signing)
```

### APK Information
```bash
# Check APK details
aapt dump badging gse-knox-agent-v1.0.0.apk

# APK size (should be < 10MB)
ls -lh gse-knox-agent-v1.0.0.apk

# Permissions
aapt dump permissions gse-knox-agent-v1.0.0.apk
```

## 🚀 Deployment

### Knox Configure Deployment
1. Upload APK to Knox Configure portal
2. Create deployment profile with APK URL
3. Generate QR codes for enrollment
4. Distribute to Samsung tablets

### Manual Deployment
```bash
# Install on multiple devices
for device in $(adb devices | grep -v "List" | awk '{print $1}'); do
  adb -s $device install gse-knox-agent-v1.0.0.apk
  adb -s $device shell am start -n com.gse.knox.agent/.MainActivity
done
```

## ✅ Build Checklist

- [ ] Node.js 18+ installed
- [ ] Cordova CLI installed
- [ ] Java JDK installed
- [ ] Android SDK configured
- [ ] Knox license key added
- [ ] Images added to www/img/
- [ ] Server URLs configured
- [ ] Debug build successful
- [ ] Release build successful
- [ ] APK signed for production
- [ ] Device testing completed
- [ ] Knox features verified

**Status:** 🎯 Ready for Knox SDK Integration and Testing
