# GSE Knox Agent

Samsung Knox MDM Agent for GSE Enterprise Platform tablet management.

## 🎯 Overview

The GSE Knox Agent is a Cordova-based Android application that runs on Samsung tablets to enable remote device management through the GSE Enterprise Platform. It uses Samsung Knox SDK for enterprise-grade device control.

## 🚀 Features

### Device Control
- ✅ Lock/Unlock device
- ✅ Factory reset (wipe)
- ✅ Remote reboot
- ✅ Screenshot capture
- ✅ Kiosk mode enforcement

### Application Management
- ✅ Install/Uninstall apps
- ✅ Enable/Disable apps
- ✅ App whitelist/blacklist
- ✅ Monitor installed applications

### Policy Enforcement
- ✅ Camera control
- ✅ USB debugging control
- ✅ Device restrictions
- ✅ Security policies
- ✅ Network policies

### Real-time Communication
- ✅ WebSocket connection to GSE MDM Server
- ✅ Command execution
- ✅ Status reporting
- ✅ Heartbeat monitoring

## 📋 Requirements

### Hardware
- Samsung Galaxy Tab (Android 5.0+)
- Knox-enabled device
- Internet connectivity (WiFi/Cellular)

### Software
- Node.js 16+ 
- Cordova CLI 12+
- Android SDK (if building locally)

### Server
- GSE Enterprise Platform
- Supabase database
- WebSocket support

## 🛠️ Development Setup

### 1. Install Dependencies

```bash
cd knox-agent
npm install
```

### 2. Add Cordova Platform

```bash
npm run add-platform
```

### 3. Install Plugins

```bash
npm run add-plugins
```

### 4. Configure Knox

1. Get Samsung Knox license key
2. Update `config.xml` with your license key
3. Configure Knox Configure profile

## 🏗️ Building

### Debug Build
```bash
npm run build-debug
```

### Release Build
```bash
npm run build
```

### Run on Device
```bash
npm run run
```

## 📱 Knox Configure Setup

### 1. Create Knox Configure Account
1. Go to [samsungknox.com](https://samsungknox.com)
2. Create organization account
3. Set up Knox Configure profile

### 2. Create Deployment Profile

```json
{
  "knox": {
    "version": "3.0",
    "enrollment": {
      "serverUrl": "https://cifnlfayusnkpnamelga.supabase.co",
      "branchCode": "{{BRANCH_CODE}}"
    },
    "applications": [
      {
        "packageName": "com.gse.knox.agent",
        "downloadUrl": "https://your-server.com/knox-agent.apk",
        "autoInstall": true,
        "required": true
      }
    ],
    "restrictions": {
      "cameraDisabled": true,
      "usbDebuggingDisabled": true,
      "installUnknownSources": false
    },
    "kioskMode": {
      "enabled": true,
      "allowedPackages": ["com.gse.pos", "com.gse.knox.agent"]
    }
  }
}
```

### 3. Generate QR Code
- Knox Configure generates QR code
- Tablet scans QR code for enrollment
- Automatic app installation and configuration

## 🔧 Configuration

### Server Configuration
Update `www/js/knox-agent.js`:

```javascript
this.config = {
    serverUrl: 'https://your-supabase-url.supabase.co',
    wsUrl: 'wss://your-supabase-url.supabase.co/realtime/v1/websocket',
    apiKey: 'your-supabase-anon-key'
};
```

### Branch Code Configuration
Set branch code during enrollment or in local storage:

```javascript
localStorage.setItem('gse_branch_code', '001');
```

## 📊 Architecture

```
┌─────────────────────┐    WebSocket    ┌──────────────────┐
│   GSE MDM Server    │ ←──────────────→ │   Knox Agent     │
│  (Supabase + UI)    │                 │  (This App)      │
└─────────────────────┘                 └──────────────────┘
         │                                       │
         │                                       │
    ┌────▼────┐                             ┌────▼────┐
    │Database │                             │Samsung  │
    │(19 MDM  │                             │Knox SDK │
    │ Tables) │                             │         │
    └─────────┘                             └─────────┘
```

## 📁 Project Structure

```
knox-agent/
├── www/                    # Web assets
│   ├── index.html         # Main UI
│   ├── css/
│   │   └── index.css      # Styles
│   ├── js/
│   │   ├── knox-agent.js  # Main controller
│   │   ├── knox-api.js    # Knox SDK wrapper
│   │   ├── websocket-client.js
│   │   ├── device-controller.js
│   │   ├── policy-manager.js
│   │   └── index.js       # Entry point
│   └── img/               # Images
├── config.xml             # Cordova configuration
├── package.json           # Dependencies
└── README.md              # This file
```

## 🔐 Security

### Knox Permissions
- Device admin privileges
- Knox advanced security
- Application management
- Kiosk mode control

### Data Security
- **NO MOCK DATA** - All data is real
- Encrypted WebSocket communication
- Secure device registration
- Real-time command verification

## 🚀 Deployment

### 1. Build APK
```bash
npm run build
```

### 2. Sign APK (Production)
```bash
# Generate keystore (one time)
keytool -genkey -v -keystore gse-knox.keystore -alias gse-knox -keyalg RSA -keysize 2048 -validity 10000

# Sign APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore gse-knox.keystore app-release-unsigned.apk gse-knox

# Align APK
zipalign -v 4 app-release-unsigned.apk gse-knox-agent.apk
```

### 3. Deploy via Knox Configure
1. Upload APK to Knox Configure
2. Create deployment profile
3. Generate QR codes for tablets
4. Distribute QR codes to branches

### 4. Manual Installation (Testing)
```bash
adb install gse-knox-agent.apk
adb shell dpm set-device-admin com.gse.knox.agent/.KnoxDeviceAdminReceiver
```

## 🧪 Testing

### Browser Testing (Limited)
```bash
# Serve files for browser testing
npx http-server www -p 8080
```

**Note:** Knox features won't work in browser, but UI can be tested.

### Device Testing
```bash
npm run run
```

## 📝 API Reference

### Knox Agent Methods
- `initialize()` - Initialize agent
- `lockDevice()` - Lock device
- `unlockDevice()` - Unlock device
- `wipeDevice()` - Factory reset
- `enableKioskMode(apps)` - Enable kiosk mode
- `sendDeviceStatus()` - Send status to server

### WebSocket Messages
- `DEVICE_REGISTRATION` - Register device
- `DEVICE_STATUS` - Status update
- `COMMAND_RESULT` - Command response
- `HEARTBEAT` - Keep-alive

## 🐛 Troubleshooting

### Common Issues

1. **Knox SDK not available**
   - Ensure device supports Knox
   - Check Knox license key
   - Verify device admin permissions

2. **WebSocket connection failed**
   - Check internet connectivity
   - Verify server URL
   - Check firewall settings

3. **Device registration failed**
   - Verify Supabase credentials
   - Check branch code configuration
   - Ensure database tables exist

### Debug Logs
- Check browser console (F12)
- Use `adb logcat` for device logs
- Monitor WebSocket traffic

## 📞 Support

- **Documentation:** See GSE Enterprise Platform docs
- **Issues:** Report via GitHub issues
- **Contact:** GSE Enterprise Platform team

## 📄 License

© 2025 GSE Enterprise Platform. All rights reserved.

---

## 🎯 Next Steps

1. **Complete Knox SDK Integration**
   - Add Samsung Knox license
   - Test on real Samsung tablet
   - Verify all Knox APIs work

2. **Server Integration**
   - Test WebSocket connection
   - Verify database operations
   - Test command execution

3. **Knox Configure Setup**
   - Create organization account
   - Build deployment profiles
   - Generate QR codes

4. **Production Deployment**
   - Sign APK for production
   - Deploy via Knox Configure
   - Train users on enrollment

**Status:** 🔄 Development Complete - Ready for Knox SDK Integration
