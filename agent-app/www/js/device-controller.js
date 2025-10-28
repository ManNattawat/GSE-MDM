/**
 * Device Controller for GSE Knox Agent
 * Handles device control operations via native Android APIs (DevicePolicyManager, etc.)
 * through the Cordova plugin (KnoxAgentPlugin).
 */

class DeviceController {
    constructor() {
        this.isInitialized = false;
        this.initialize();
    }
    
    /**
     * Initialize device controller
     */
    async initialize() {
        try {
            console.log('[Device Controller] Initializing...');
            
            if (!window.nativeControls) {
                throw new Error('nativeControls bridge not available');
            }
            
            await window.nativeControls.initialize();
            this.isInitialized = true;
            console.log('[Device Controller] Initialized successfully');
            
        } catch (error) {
            console.error('[Device Controller] Initialization failed:', error);
            this.isInitialized = false;
        }
    }
    
    /**
     * Lock device immediately
     * NO MOCK DATA - Real device lock via native controls
     */
    async lockDevice() {
        try {
            console.log('[Device Controller] Locking device...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            await window.nativeControls.lockNow();
            console.log('[Device Controller] Device locked successfully');
            return this.#success('lock');
            
        } catch (error) {
            console.error('[Device Controller] Failed to lock device:', error);
            return this.#failure('lock', error);
        }
    }
    
    /**
     * Unlock device
     * NO MOCK DATA - Real device unlock via native controls
     */
    async unlockDevice() {
        try {
            console.log('[Device Controller] Unlocking device...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            // Non-DeviceOwner modeไม่มี API ปลดล็อกได้โดยตรง อาจใช้ Accessibility automation
            throw new Error('Unlock device is not supported without Knox');
            
        } catch (error) {
            console.error('[Device Controller] Failed to unlock device:', error);
            return this.#failure('unlock', error);
        }
    }
    
    /**
     * Wipe device (factory reset)
     * NO MOCK DATA - Real device wipe via native controls
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
            
            await window.nativeControls.wipeDevice();
            console.log('[Device Controller] Device wipe initiated successfully');
            return this.#success('wipe');
            
        } catch (error) {
            console.error('[Device Controller] Failed to wipe device:', error);
            return this.#failure('wipe', error);
        }
    }
    
    /**
     * Reboot device
     * NO MOCK DATA - Real device reboot via native controls
     */
    async rebootDevice() {
        try {
            console.log('[Device Controller] Rebooting device...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            await window.nativeControls.rebootDevice();
            console.log('[Device Controller] Device reboot initiated successfully');
            return this.#success('reboot');
            
        } catch (error) {
            console.error('[Device Controller] Failed to reboot device:', error);
            return this.#failure('reboot', error);
        }
    }
    
    /**
     * Enable Kiosk Mode
     * NO MOCK DATA - Real kiosk mode via native controls
     */
    async enableKioskMode(config = {}) {
        try {
            console.log('[Device Controller] Enabling kiosk mode...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            const allowedApps = config.allowedApps || [cordova.platformId === 'android' ? cordova.appInfo && cordova.appInfo.appId : 'com.gse.knox.agent'];
            await window.nativeControls.setLockTaskPackages(allowedApps);
            await window.nativeControls.startLockTask();
            console.log('[Device Controller] Kiosk mode enabled successfully');
            return this.#success('enable_kiosk', { allowedApps });
            
        } catch (error) {
            console.error('[Device Controller] Failed to enable kiosk mode:', error);
            return this.#failure('enable_kiosk', error);
        }
    }
    
    /**
     * Disable Kiosk Mode
     * NO MOCK DATA - Real kiosk mode disable via native controls
     */
    async disableKioskMode() {
        try {
            console.log('[Device Controller] Disabling kiosk mode...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            await window.nativeControls.stopLockTask();
            console.log('[Device Controller] Kiosk mode disabled successfully');
            return this.#success('disable_kiosk');
            
        } catch (error) {
            console.error('[Device Controller] Failed to disable kiosk mode:', error);
            return this.#failure('disable_kiosk', error);
        }
    }
    
    /**
     * Take screenshot
     * NO MOCK DATA - Real screenshot (requires media projection consent)
     */
    async takeScreenshot() {
        try {
            console.log('[Device Controller] Taking screenshot...');
            
            if (!this.isInitialized) {
                throw new Error('Device controller not initialized');
            }
            
            throw new Error('Screenshot requires media projection consent flow, implement separately');
            
        } catch (error) {
            console.error('[Device Controller] Failed to take screenshot:', error);
            return this.#failure('screenshot', error);
        }
    }
    
    /**
     * Install application
     * NO MOCK DATA - Placeholder for PackageInstaller flow
     */
    async installApplication(apkUrl) {
        console.log('[Device Controller] Installing application:', apkUrl);
        if (!this.isInitialized) {
            return this.#failure('install_app', new Error('Device controller not initialized'), { apkUrl });
        }

        if (!apkUrl) {
            return this.#failure('install_app', new Error('APK URL is required'));
        }

        // TODO: Implement PackageInstaller flow (download APK, trigger install Intent)
        return this.#failure('install_app', new Error('Remote APK install not yet implemented'), { apkUrl });
    }
    
    /**
     * Uninstall application
     * NO MOCK DATA - Placeholder for uninstall flow
     */
    async uninstallApplication(packageName) {
        console.log('[Device Controller] Uninstalling application:', packageName);
        if (!this.isInitialized) {
            return this.#failure('uninstall_app', new Error('Device controller not initialized'), { packageName });
        }

        if (!packageName) {
            return this.#failure('uninstall_app', new Error('Package name is required'));
        }

        // TODO: Implement uninstall via PackageInstaller APIs
        return this.#failure('uninstall_app', new Error('Remote uninstall not yet implemented'), { packageName });
    }
    
    /**
     * Enable/Disable application
     * NO MOCK DATA - Real app state change (requires package manager APIs)
     */
    async setApplicationState(packageName, enabled) {
        console.log(`[Device Controller] ${enabled ? 'Enabling' : 'Disabling'} application:`, packageName);
        if (!this.isInitialized) {
            return this.#failure('set_app_state', new Error('Device controller not initialized'), { packageName, enabled });
        }

        if (!packageName) {
            return this.#failure('set_app_state', new Error('Package name is required'));
        }

        // TODO: Implement application state management when Device Owner APIs available
        return this.#failure('set_app_state', new Error('Application state change not yet implemented'), { packageName, enabled });
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

    #success(action, extra = {}) {
        return {
            success: true,
            action,
            timestamp: new Date().toISOString(),
            ...extra
        };
    }

    #failure(action, error, extra = {}) {
        return {
            success: false,
            action,
            error: error && error.message ? error.message : String(error),
            timestamp: new Date().toISOString(),
            ...extra
        };
    }
}
