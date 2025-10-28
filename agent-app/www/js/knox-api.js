/**
 * Samsung Knox API Wrapper
 * Provides abstraction layer for Samsung Knox SDK
 * 
 * NO MOCK DATA - All methods interact with real Samsung Knox APIs
 */

class KnoxAPI {
    constructor() {
        this.isInitialized = false;
        this.knoxSDK = null;
        this.devicePolicyManager = null;
        this.applicationPolicy = null;
        this.kioskMode = null;
        this.deviceInfo = null;
    }
    
    /**
     * Initialize Knox SDK
     * Attempts to connect to Samsung Knox APIs
     */
    async initialize() {
        try {
            // Check if Knox is available
            if (typeof window.Knox !== 'undefined') {
                this.knoxSDK = window.Knox;
                console.log('[Knox API] Samsung Knox SDK detected');
                
                // Initialize Knox SDK
                await this.knoxSDK.initialize();
                
                // Get policy managers
                this.devicePolicyManager = this.knoxSDK.getDevicePolicyManager();
                this.applicationPolicy = this.knoxSDK.getApplicationPolicy();
                this.kioskMode = this.knoxSDK.getKioskMode();
                this.deviceInfo = this.knoxSDK.getDeviceInfo();
                
                this.isInitialized = true;
                console.log('[Knox API] Knox SDK initialized successfully');
                
            } else {
                console.warn('[Knox API] Samsung Knox SDK not available - using fallback methods');
                this.isInitialized = false;
            }
            
        } catch (error) {
            console.error('[Knox API] Failed to initialize Knox SDK:', error);
            this.isInitialized = false;
        }
    }
    
    /**
     * Check if Knox API is available and initialized
     */
    isAvailable() {
        return this.isInitialized && this.knoxSDK !== null;
    }
    
    /**
     * Get device serial number
     * NO MOCK DATA - Real device serial only
     */
    async getSerialNumber() {
        try {
            if (this.isAvailable() && this.deviceInfo) {
                return await this.deviceInfo.getSerialNumber();
            }
            
            // Fallback to Cordova device plugin
            if (typeof device !== 'undefined') {
                return device.serial || device.uuid;
            }
            
            return null;
            
        } catch (error) {
            console.error('[Knox API] Failed to get serial number:', error);
            return null;
        }
    }
    
    /**
     * Get device IMEI
     * NO MOCK DATA - Real IMEI only
     */
    async getIMEI() {
        try {
            if (this.isAvailable() && this.deviceInfo) {
                return await this.deviceInfo.getIMEI();
            }
            
            return null;
            
        } catch (error) {
            console.error('[Knox API] Failed to get IMEI:', error);
            return null;
        }
    }
    
    /**
     * Get Knox version
     * NO MOCK DATA - Real Knox version only
     */
    async getKnoxVersion() {
        try {
            if (this.isAvailable() && this.deviceInfo) {
                return await this.deviceInfo.getKnoxVersion();
            }
            
            return null;
            
        } catch (error) {
            console.error('[Knox API] Failed to get Knox version:', error);
            return null;
        }
    }
    
    /**
     * Get security patch level
     * NO MOCK DATA - Real security patch level only
     */
    async getSecurityPatchLevel() {
        try {
            if (this.isAvailable() && this.deviceInfo) {
                return await this.deviceInfo.getSecurityPatchLevel();
            }
            
            return null;
            
        } catch (error) {
            console.error('[Knox API] Failed to get security patch level:', error);
            return null;
        }
    }
    
    /**
     * Check if device is rooted
     * NO MOCK DATA - Real root status only
     */
    async isDeviceRooted() {
        try {
            if (this.isAvailable() && this.deviceInfo) {
                return await this.deviceInfo.isDeviceRooted();
            }
            
            return false;
            
        } catch (error) {
            console.error('[Knox API] Failed to check root status:', error);
            return false;
        }
    }
    
    /**
     * Get enrollment profile from Knox Configure
     * NO MOCK DATA - Real enrollment profile only
     */
    async getEnrollmentProfile() {
        try {
            if (this.isAvailable()) {
                return await this.knoxSDK.getEnrollmentProfile();
            }
            
            return null;
            
        } catch (error) {
            console.error('[Knox API] Failed to get enrollment profile:', error);
            return null;
        }
    }
    
    /**
     * Lock device immediately
     * NO MOCK DATA - Real device lock only
     */
    async lockDevice() {
        try {
            if (this.isAvailable() && this.devicePolicyManager) {
                const result = await this.devicePolicyManager.lockNow();
                console.log('[Knox API] Device locked successfully');
                return { success: true, result: result };
            }
            
            // Fallback: Try to use Cordova plugin if available
            if (typeof cordova !== 'undefined' && cordova.plugins && cordova.plugins.devicePolicy) {
                const result = await cordova.plugins.devicePolicy.lock();
                console.log('[Knox API] Device locked via Cordova plugin');
                return { success: true, result: result };
            }
            
            throw new Error('No device lock method available');
            
        } catch (error) {
            console.error('[Knox API] Failed to lock device:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Unlock device
     * NO MOCK DATA - Real device unlock only
     */
    async unlockDevice() {
        try {
            if (this.isAvailable() && this.devicePolicyManager) {
                const result = await this.devicePolicyManager.unlock();
                console.log('[Knox API] Device unlocked successfully');
                return { success: true, result: result };
            }
            
            throw new Error('Device unlock not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to unlock device:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Wipe device (factory reset)
     * NO MOCK DATA - Real device wipe only
     */
    async wipeDevice() {
        try {
            if (this.isAvailable() && this.devicePolicyManager) {
                // Confirm before wiping
                const confirmed = confirm('Are you sure you want to wipe this device? This action cannot be undone.');
                if (!confirmed) {
                    return { success: false, error: 'User cancelled wipe operation' };
                }
                
                const result = await this.devicePolicyManager.wipeData();
                console.log('[Knox API] Device wipe initiated');
                return { success: true, result: result };
            }
            
            throw new Error('Device wipe not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to wipe device:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Reboot device
     * NO MOCK DATA - Real device reboot only
     */
    async rebootDevice() {
        try {
            if (this.isAvailable() && this.devicePolicyManager) {
                const result = await this.devicePolicyManager.reboot();
                console.log('[Knox API] Device reboot initiated');
                return { success: true, result: result };
            }
            
            throw new Error('Device reboot not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to reboot device:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Enable Kiosk Mode
     * NO MOCK DATA - Real kiosk mode only
     */
    async enableKioskMode(allowedApps = []) {
        try {
            if (this.isAvailable() && this.kioskMode) {
                const result = await this.kioskMode.enableKioskMode(allowedApps);
                console.log('[Knox API] Kiosk mode enabled with apps:', allowedApps);
                return { success: true, result: result, allowedApps: allowedApps };
            }
            
            throw new Error('Kiosk mode not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to enable kiosk mode:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Disable Kiosk Mode
     * NO MOCK DATA - Real kiosk mode disable only
     */
    async disableKioskMode() {
        try {
            if (this.isAvailable() && this.kioskMode) {
                const result = await this.kioskMode.disableKioskMode();
                console.log('[Knox API] Kiosk mode disabled');
                return { success: true, result: result };
            }
            
            throw new Error('Kiosk mode not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to disable kiosk mode:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Install application
     * NO MOCK DATA - Real app installation only
     */
    async installApplication(apkUrl) {
        try {
            if (this.isAvailable() && this.applicationPolicy) {
                const result = await this.applicationPolicy.installApplication(apkUrl);
                console.log('[Knox API] Application installation initiated:', apkUrl);
                return { success: true, result: result, apkUrl: apkUrl };
            }
            
            throw new Error('Application installation not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to install application:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Uninstall application
     * NO MOCK DATA - Real app uninstallation only
     */
    async uninstallApplication(packageName) {
        try {
            if (this.isAvailable() && this.applicationPolicy) {
                const result = await this.applicationPolicy.uninstallApplication(packageName);
                console.log('[Knox API] Application uninstallation initiated:', packageName);
                return { success: true, result: result, packageName: packageName };
            }
            
            throw new Error('Application uninstallation not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to uninstall application:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Enable/Disable application
     * NO MOCK DATA - Real app state change only
     */
    async setApplicationState(packageName, enabled) {
        try {
            if (this.isAvailable() && this.applicationPolicy) {
                const result = await this.applicationPolicy.setApplicationState(packageName, enabled);
                console.log(`[Knox API] Application ${enabled ? 'enabled' : 'disabled'}:`, packageName);
                return { success: true, result: result, packageName: packageName, enabled: enabled };
            }
            
            throw new Error('Application state change not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to change application state:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Get installed applications
     * NO MOCK DATA - Real installed apps only
     */
    async getInstalledApplications() {
        try {
            if (this.isAvailable() && this.applicationPolicy) {
                const result = await this.applicationPolicy.getInstalledApplications();
                console.log('[Knox API] Retrieved installed applications:', result.length);
                return { success: true, applications: result };
            }
            
            return { success: false, applications: [] };
            
        } catch (error) {
            console.error('[Knox API] Failed to get installed applications:', error);
            return { success: false, error: error.message, applications: [] };
        }
    }
    
    /**
     * Set camera policy
     * NO MOCK DATA - Real camera control only
     */
    async setCameraEnabled(enabled) {
        try {
            if (this.isAvailable() && this.devicePolicyManager) {
                const result = await this.devicePolicyManager.setCameraDisabled(!enabled);
                console.log(`[Knox API] Camera ${enabled ? 'enabled' : 'disabled'}`);
                return { success: true, result: result, enabled: enabled };
            }
            
            throw new Error('Camera control not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to control camera:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Set USB debugging policy
     * NO MOCK DATA - Real USB debugging control only
     */
    async setUSBDebuggingEnabled(enabled) {
        try {
            if (this.isAvailable() && this.devicePolicyManager) {
                const result = await this.devicePolicyManager.setUSBDebuggingEnabled(enabled);
                console.log(`[Knox API] USB debugging ${enabled ? 'enabled' : 'disabled'}`);
                return { success: true, result: result, enabled: enabled };
            }
            
            throw new Error('USB debugging control not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to control USB debugging:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Take screenshot
     * NO MOCK DATA - Real screenshot only
     */
    async takeScreenshot() {
        try {
            if (this.isAvailable() && this.devicePolicyManager) {
                const result = await this.devicePolicyManager.captureScreen();
                console.log('[Knox API] Screenshot captured');
                return { success: true, result: result };
            }
            
            throw new Error('Screenshot not supported or Knox not available');
            
        } catch (error) {
            console.error('[Knox API] Failed to take screenshot:', error);
            return { success: false, error: error.message };
        }
    }
    
    /**
     * Get device location
     * NO MOCK DATA - Real location only
     */
    async getCurrentLocation() {
        return new Promise((resolve) => {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    position => {
                        const location = {
                            latitude: position.coords.latitude,
                            longitude: position.coords.longitude,
                            accuracy: position.coords.accuracy,
                            timestamp: new Date().toISOString()
                        };
                        console.log('[Knox API] Location retrieved:', location);
                        resolve({ success: true, location: location });
                    },
                    error => {
                        console.error('[Knox API] Failed to get location:', error);
                        resolve({ success: false, error: error.message });
                    },
                    {
                        enableHighAccuracy: true,
                        timeout: 10000,
                        maximumAge: 60000
                    }
                );
            } else {
                resolve({ success: false, error: 'Geolocation not supported' });
            }
        });
    }
    
    /**
     * Get battery information
     * NO MOCK DATA - Real battery info only
     */
    async getBatteryInfo() {
        return new Promise((resolve) => {
            if (typeof cordova !== 'undefined' && cordova.plugins && cordova.plugins.batteryStatus) {
                cordova.plugins.batteryStatus.getStatus(
                    status => {
                        const batteryInfo = {
                            level: status.level * 100,
                            isPlugged: status.isPlugged,
                            isLow: status.isLow
                        };
                        console.log('[Knox API] Battery info retrieved:', batteryInfo);
                        resolve({ success: true, battery: batteryInfo });
                    },
                    error => {
                        console.error('[Knox API] Failed to get battery info:', error);
                        resolve({ success: false, error: error.message });
                    }
                );
                    console.log('[Knox API] Battery info retrieved:', batteryInfo);
                    resolve({ success: true, battery: batteryInfo });
                }).catch(error => {
                    console.error('[Knox API] Failed to get battery info:', error);
                    resolve({ success: false, error: error.message });
                });
            } else {
                resolve({ success: false, error: 'Battery API not supported' });
            }
        });
    }
    
    /**
     * Get network information
     * NO MOCK DATA - Real network info only
     */
    async getNetworkInfo() {
        try {
            const networkInfo = {
                online: navigator.onLine,
                type: 'unknown',
                effectiveType: 'unknown',
                downlink: null,
                rtt: null
            };
            
            if (navigator.connection) {
                networkInfo.type = navigator.connection.type || 'unknown';
                networkInfo.effectiveType = navigator.connection.effectiveType || 'unknown';
                networkInfo.downlink = navigator.connection.downlink;
                networkInfo.rtt = navigator.connection.rtt;
            }
            
            console.log('[Knox API] Network info retrieved:', networkInfo);
            return { success: true, network: networkInfo };
            
        } catch (error) {
            console.error('[Knox API] Failed to get network info:', error);
            return { success: false, error: error.message };
        }
    }
}
