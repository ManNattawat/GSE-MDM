/**
 * Device Controller for GSE Knox Agent
 * Handles device control operations via Samsung Knox API
 * 
 * NO MOCK DATA - All operations use real Samsung Knox APIs
 */

class DeviceController {
    constructor(knoxAPI) {
        this.knoxAPI = knoxAPI;
        this.isInitialized = false;
        
        this.initialize();
    }
    
    /**
     * Initialize device controller
     */
    async initialize() {
        try {
            console.log('[Device Controller] Initializing...');
            
            if (!this.knoxAPI) {
                throw new Error('Knox API not provided');
            }
            
            this.isInitialized = true;
            console.log('[Device Controller] Initialized successfully');
            
        } catch (error) {
            console.error('[Device Controller] Initialization failed:', error);
            this.isInitialized = false;
        }
    }
    
    /**
     * Lock device immediately
     * NO MOCK DATA - Real device lock via Knox API
     */
    async lockDevice() {
        try {
            console.log('[Device Controller] Locking device...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const result = await this.knoxAPI.lockDevice();
            
            if (result.success) {
                console.log('[Device Controller] Device locked successfully');
                return {
                    success: true,
                    action: 'lock',
                    timestamp: new Date().toISOString(),
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to lock device');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to lock device:', error);
            return {
                success: false,
                action: 'lock',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Unlock device
     * NO MOCK DATA - Real device unlock via Knox API
     */
    async unlockDevice() {
        try {
            console.log('[Device Controller] Unlocking device...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const result = await this.knoxAPI.unlockDevice();
            
            if (result.success) {
                console.log('[Device Controller] Device unlocked successfully');
                return {
                    success: true,
                    action: 'unlock',
                    timestamp: new Date().toISOString(),
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to unlock device');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to unlock device:', error);
            return {
                success: false,
                action: 'unlock',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Wipe device (factory reset)
     * NO MOCK DATA - Real device wipe via Knox API
     */
    async wipeDevice() {
        try {
            console.log('[Device Controller] Wiping device...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            // Additional confirmation for destructive action
            const confirmed = confirm(
                'WARNING: This will completely wipe the device and cannot be undone. ' +
                'All data will be lost. Are you absolutely sure?'
            );
            
            if (!confirmed) {
                return {
                    success: false,
                    action: 'wipe',
                    error: 'User cancelled wipe operation',
                    timestamp: new Date().toISOString()
                };
            }
            
            const result = await this.knoxAPI.wipeDevice();
            
            if (result.success) {
                console.log('[Device Controller] Device wipe initiated successfully');
                return {
                    success: true,
                    action: 'wipe',
                    timestamp: new Date().toISOString(),
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to wipe device');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to wipe device:', error);
            return {
                success: false,
                action: 'wipe',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Reboot device
     * NO MOCK DATA - Real device reboot via Knox API
     */
    async rebootDevice() {
        try {
            console.log('[Device Controller] Rebooting device...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const result = await this.knoxAPI.rebootDevice();
            
            if (result.success) {
                console.log('[Device Controller] Device reboot initiated successfully');
                return {
                    success: true,
                    action: 'reboot',
                    timestamp: new Date().toISOString(),
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to reboot device');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to reboot device:', error);
            return {
                success: false,
                action: 'reboot',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Enable Kiosk Mode
     * NO MOCK DATA - Real kiosk mode via Knox API
     */
    async enableKioskMode(config = {}) {
        try {
            console.log('[Device Controller] Enabling kiosk mode...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const allowedApps = config.allowedApps || ['com.gse.pos'];
            const result = await this.knoxAPI.enableKioskMode(allowedApps);
            
            if (result.success) {
                console.log('[Device Controller] Kiosk mode enabled successfully');
                return {
                    success: true,
                    action: 'enable_kiosk',
                    timestamp: new Date().toISOString(),
                    config: {
                        allowedApps: allowedApps,
                        ...config
                    },
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to enable kiosk mode');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to enable kiosk mode:', error);
            return {
                success: false,
                action: 'enable_kiosk',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Disable Kiosk Mode
     * NO MOCK DATA - Real kiosk mode disable via Knox API
     */
    async disableKioskMode() {
        try {
            console.log('[Device Controller] Disabling kiosk mode...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const result = await this.knoxAPI.disableKioskMode();
            
            if (result.success) {
                console.log('[Device Controller] Kiosk mode disabled successfully');
                return {
                    success: true,
                    action: 'disable_kiosk',
                    timestamp: new Date().toISOString(),
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to disable kiosk mode');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to disable kiosk mode:', error);
            return {
                success: false,
                action: 'disable_kiosk',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Take screenshot
     * NO MOCK DATA - Real screenshot via Knox API
     */
    async takeScreenshot() {
        try {
            console.log('[Device Controller] Taking screenshot...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const result = await this.knoxAPI.takeScreenshot();
            
            if (result.success) {
                console.log('[Device Controller] Screenshot taken successfully');
                return {
                    success: true,
                    action: 'screenshot',
                    timestamp: new Date().toISOString(),
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to take screenshot');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to take screenshot:', error);
            return {
                success: false,
                action: 'screenshot',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Install application
     * NO MOCK DATA - Real app installation via Knox API
     */
    async installApplication(apkUrl) {
        try {
            console.log('[Device Controller] Installing application:', apkUrl);
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            if (!apkUrl) {
                throw new Error('APK URL is required');
            }
            
            const result = await this.knoxAPI.installApplication(apkUrl);
            
            if (result.success) {
                console.log('[Device Controller] Application installation initiated successfully');
                return {
                    success: true,
                    action: 'install_app',
                    timestamp: new Date().toISOString(),
                    apkUrl: apkUrl,
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to install application');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to install application:', error);
            return {
                success: false,
                action: 'install_app',
                error: error.message,
                apkUrl: apkUrl,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Uninstall application
     * NO MOCK DATA - Real app uninstallation via Knox API
     */
    async uninstallApplication(packageName) {
        try {
            console.log('[Device Controller] Uninstalling application:', packageName);
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            if (!packageName) {
                throw new Error('Package name is required');
            }
            
            const result = await this.knoxAPI.uninstallApplication(packageName);
            
            if (result.success) {
                console.log('[Device Controller] Application uninstallation initiated successfully');
                return {
                    success: true,
                    action: 'uninstall_app',
                    timestamp: new Date().toISOString(),
                    packageName: packageName,
                    result: result.result
                };
            } else {
                throw new Error(result.error || 'Failed to uninstall application');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to uninstall application:', error);
            return {
                success: false,
                action: 'uninstall_app',
                error: error.message,
                packageName: packageName,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Enable/Disable application
     * NO MOCK DATA - Real app state change via Knox API
     */
    async setApplicationState(packageName, enabled) {
        try {
            console.log(`[Device Controller] ${enabled ? 'Enabling' : 'Disabling'} application:`, packageName);
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            if (!packageName) {
                throw new Error('Package name is required');
            }
            
            const result = await this.knoxAPI.setApplicationState(packageName, enabled);
            
            if (result.success) {
                console.log(`[Device Controller] Application ${enabled ? 'enabled' : 'disabled'} successfully`);
                return {
                    success: true,
                    action: 'set_app_state',
                    timestamp: new Date().toISOString(),
                    packageName: packageName,
                    enabled: enabled,
                    result: result.result
                };
            } else {
                throw new Error(result.error || `Failed to ${enabled ? 'enable' : 'disable'} application`);
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to change application state:', error);
            return {
                success: false,
                action: 'set_app_state',
                error: error.message,
                packageName: packageName,
                enabled: enabled,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Set camera policy
     * NO MOCK DATA - Real camera control via Knox API
     */
    async setCameraEnabled(enabled) {
        try {
            console.log(`[Device Controller] ${enabled ? 'Enabling' : 'Disabling'} camera...`);
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const result = await this.knoxAPI.setCameraEnabled(enabled);
            
            if (result.success) {
                console.log(`[Device Controller] Camera ${enabled ? 'enabled' : 'disabled'} successfully`);
                return {
                    success: true,
                    action: 'set_camera',
                    timestamp: new Date().toISOString(),
                    enabled: enabled,
                    result: result.result
                };
            } else {
                throw new Error(result.error || `Failed to ${enabled ? 'enable' : 'disable'} camera`);
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to control camera:', error);
            return {
                success: false,
                action: 'set_camera',
                error: error.message,
                enabled: enabled,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Set USB debugging policy
     * NO MOCK DATA - Real USB debugging control via Knox API
     */
    async setUSBDebuggingEnabled(enabled) {
        try {
            console.log(`[Device Controller] ${enabled ? 'Enabling' : 'Disabling'} USB debugging...`);
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const result = await this.knoxAPI.setUSBDebuggingEnabled(enabled);
            
            if (result.success) {
                console.log(`[Device Controller] USB debugging ${enabled ? 'enabled' : 'disabled'} successfully`);
                return {
                    success: true,
                    action: 'set_usb_debugging',
                    timestamp: new Date().toISOString(),
                    enabled: enabled,
                    result: result.result
                };
            } else {
                throw new Error(result.error || `Failed to ${enabled ? 'enable' : 'disable'} USB debugging`);
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to control USB debugging:', error);
            return {
                success: false,
                action: 'set_usb_debugging',
                error: error.message,
                enabled: enabled,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Get current device status
     * NO MOCK DATA - Real device status via Knox API
     */
    async getDeviceStatus() {
        try {
            console.log('[Device Controller] Getting device status...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const [batteryInfo, networkInfo, locationInfo] = await Promise.all([
                this.knoxAPI.getBatteryInfo(),
                this.knoxAPI.getNetworkInfo(),
                this.knoxAPI.getCurrentLocation()
            ]);
            
            const status = {
                battery: batteryInfo.success ? batteryInfo.battery : null,
                network: networkInfo.success ? networkInfo.network : null,
                location: locationInfo.success ? locationInfo.location : null,
                timestamp: new Date().toISOString()
            };
            
            console.log('[Device Controller] Device status retrieved successfully');
            return {
                success: true,
                status: status
            };
            
        } catch (error) {
            console.error('[Device Controller] Failed to get device status:', error);
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Get installed applications
     * NO MOCK DATA - Real app list via Knox API
     */
    async getInstalledApplications() {
        try {
            console.log('[Device Controller] Getting installed applications...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const result = await this.knoxAPI.getInstalledApplications();
            
            if (result.success) {
                console.log(`[Device Controller] Retrieved ${result.applications.length} installed applications`);
                return {
                    success: true,
                    applications: result.applications,
                    timestamp: new Date().toISOString()
                };
            } else {
                throw new Error(result.error || 'Failed to get installed applications');
            }
            
        } catch (error) {
            console.error('[Device Controller] Failed to get installed applications:', error);
            return {
                success: false,
                error: error.message,
                applications: [],
                timestamp: new Date().toISOString()
            };
        }
    }
    
    /**
     * Execute custom command
     * NO MOCK DATA - Real command execution via Knox API
     */
    async executeCustomCommand(command, parameters = {}) {
        try {
            console.log('[Device Controller] Executing custom command:', command);
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            let result;
            
            switch (command) {
                case 'get_device_info':
                    result = await this.getDeviceStatus();
                    break;
                    
                case 'get_installed_apps':
                    result = await this.getInstalledApplications();
                    break;
                    
                case 'set_camera':
                    result = await this.setCameraEnabled(parameters.enabled);
                    break;
                    
                case 'set_usb_debugging':
                    result = await this.setUSBDebuggingEnabled(parameters.enabled);
                    break;
                    
                case 'install_app':
                    result = await this.installApplication(parameters.apkUrl);
                    break;
                    
                case 'uninstall_app':
                    result = await this.uninstallApplication(parameters.packageName);
                    break;
                    
                case 'set_app_state':
                    result = await this.setApplicationState(parameters.packageName, parameters.enabled);
                    break;
                    
                default:
                    throw new Error(`Unknown command: ${command}`);
            }
            
            console.log('[Device Controller] Custom command executed successfully');
            return result;
            
        } catch (error) {
            console.error('[Device Controller] Failed to execute custom command:', error);
            return {
                success: false,
                action: 'custom_command',
                command: command,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
}
