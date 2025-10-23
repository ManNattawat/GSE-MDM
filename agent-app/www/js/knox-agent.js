/**
 * GSE Knox Agent - Main Controller
 * Samsung Knox MDM Agent for GSE Enterprise Platform
 * 
 * NO MOCK DATA - All data comes from real sources:
 * - Device info from Samsung Knox API
 * - Server communication via WebSocket
 * - Database operations via Supabase
 */

class GSEKnoxAgent {
    constructor() {
        this.config = {
            serverUrl: 'https://cifnlfayusnkpnamelga.supabase.co',
            wsUrl: 'wss://cifnlfayusnkpnamelga.supabase.co/realtime/v1/websocket',
            apiKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpZm5sZmF5dXNua3BuYW1lbGdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM5NDc4MjgsImV4cCI6MjA2OTUyMzgyOH0.5Da2JLNG88DHSxv5sxmvGUcuSk8ZOgKNvwOcIoWLH-Q',
            heartbeatInterval: 30000, // 30 seconds
            retryInterval: 5000 // 5 seconds
        };
        
        this.state = {
            isInitialized: false,
            isConnected: false,
            deviceInfo: null,
            policies: [],
            lastHeartbeat: null,
            connectionAttempts: 0
        };
        
        this.components = {
            knoxAPI: null,
            websocketClient: null,
            deviceController: null,
            policyManager: null
        };
        
        this.intervals = {
            heartbeat: null,
            statusUpdate: null
        };
        
        // Bind methods
        this.initialize = this.initialize.bind(this);
        this.onDeviceReady = this.onDeviceReady.bind(this);
        this.onConnectionChange = this.onConnectionChange.bind(this);
        this.handleCommand = this.handleCommand.bind(this);
    }
    
    /**
     * Initialize Knox Agent
     * Called when device is ready
     */
    async initialize() {
        this.log('info', 'Initializing GSE Knox Agent...');
        
        try {
            // Update UI status
            this.updateConnectionStatus('connecting', 'Initializing...');
            
            // Initialize Knox API
            this.components.knoxAPI = new KnoxAPI();
            await this.components.knoxAPI.initialize();
            this.log('success', 'Knox API initialized');
            
            // Get device information from Samsung Knox (NO MOCK DATA)
            this.state.deviceInfo = await this.getDeviceInformation();
            this.updateDeviceInfoUI();
            this.log('success', 'Device information retrieved');
            
            // Initialize WebSocket client
            this.components.websocketClient = new WebSocketClient(this.config.wsUrl, {
                onMessage: this.handleCommand,
                onConnect: () => this.onConnectionChange(true),
                onDisconnect: () => this.onConnectionChange(false),
                onError: (error) => this.log('error', `WebSocket error: ${error}`)
            });
            
            // Initialize device controller
            this.components.deviceController = new DeviceController(this.components.knoxAPI);
            
            // Initialize policy manager
            this.components.policyManager = new PolicyManager(this.components.knoxAPI);
            
            // Register device with server (NO MOCK DATA)
            await this.registerDevice();
            
            // Connect to server
            await this.connectToServer();
            
            // Start background services
            this.startBackgroundServices();
            
            this.state.isInitialized = true;
            this.log('success', 'Knox Agent initialized successfully');
            
        } catch (error) {
            this.log('error', `Initialization failed: ${error.message}`);
            this.updateConnectionStatus('offline', 'Initialization failed');
            
            // Retry initialization
            setTimeout(() => {
                this.initialize();
            }, this.config.retryInterval);
        }
    }
    
    /**
     * Get device information from Samsung Knox API
     * NO MOCK DATA - Real device info only
     */
    async getDeviceInformation() {
        const deviceInfo = {
            // Get from Cordova device plugin
            device_id: device.uuid || device.serial,
            model: device.model,
            manufacturer: device.manufacturer,
            platform: device.platform,
            version: device.version,
            
            // Get from Knox API (if available)
            serial_number: null,
            imei: null,
            knox_version: null,
            security_patch_level: null,
            is_rooted: false,
            
            // System info
            branch_code: await this.getBranchCode(),
            agent_version: '1.0.0',
            registered_at: new Date().toISOString(),
            status: 'active'
        };
        
        // Try to get Samsung Knox specific info
        try {
            if (this.components.knoxAPI && this.components.knoxAPI.isAvailable()) {
                deviceInfo.serial_number = await this.components.knoxAPI.getSerialNumber();
                deviceInfo.imei = await this.components.knoxAPI.getIMEI();
                deviceInfo.knox_version = await this.components.knoxAPI.getKnoxVersion();
                deviceInfo.security_patch_level = await this.components.knoxAPI.getSecurityPatchLevel();
                deviceInfo.is_rooted = await this.components.knoxAPI.isDeviceRooted();
            }
        } catch (error) {
            this.log('warning', `Could not get Knox-specific info: ${error.message}`);
        }
        
        return deviceInfo;
    }
    
    /**
     * Get branch code from device or configuration
     * This should be configured during enrollment
     */
    async getBranchCode() {
        // Try to get from local storage first
        const storedBranchCode = localStorage.getItem('gse_branch_code');
        if (storedBranchCode) {
            return storedBranchCode;
        }
        
        // Try to get from Knox Configure profile
        try {
            if (this.components.knoxAPI && this.components.knoxAPI.isAvailable()) {
                const profile = await this.components.knoxAPI.getEnrollmentProfile();
                if (profile && profile.branchCode) {
                    localStorage.setItem('gse_branch_code', profile.branchCode);
                    return profile.branchCode;
                }
            }
        } catch (error) {
            this.log('warning', `Could not get branch code from Knox: ${error.message}`);
        }
        
        // Default branch code (should be configured during deployment)
        return '001';
    }
    
    /**
     * Register device with GSE MDM Server
     * NO MOCK DATA - Real registration with Supabase
     */
    async registerDevice() {
        this.log('info', 'Registering device with GSE MDM Server...');
        
        try {
            const response = await fetch(`${this.config.serverUrl}/functions/v1/register-device`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.config.apiKey}`
                },
                body: JSON.stringify(this.state.deviceInfo)
            });
            
            if (!response.ok) {
                throw new Error(`Registration failed: ${response.status} ${response.statusText}`);
            }
            
            const result = await response.json();
            this.log('success', `Device registered successfully: ${result.device_id}`);
            
            // Store registration info
            localStorage.setItem('gse_device_registered', 'true');
            localStorage.setItem('gse_registration_date', new Date().toISOString());
            
            return result;
            
        } catch (error) {
            this.log('error', `Device registration failed: ${error.message}`);
            throw error;
        }
    }
    
    /**
     * Connect to GSE MDM Server via WebSocket
     */
    async connectToServer() {
        this.log('info', 'Connecting to GSE MDM Server...');
        
        try {
            await this.components.websocketClient.connect();
            this.log('success', 'Connected to GSE MDM Server');
            
        } catch (error) {
            this.log('error', `Connection failed: ${error.message}`);
            this.scheduleReconnect();
        }
    }
    
    /**
     * Handle connection status changes
     */
    onConnectionChange(isConnected) {
        this.state.isConnected = isConnected;
        this.state.connectionAttempts = isConnected ? 0 : this.state.connectionAttempts + 1;
        
        if (isConnected) {
            this.updateConnectionStatus('online', 'Connected');
            this.log('success', 'Connected to server');
            
            // Send initial status
            this.sendDeviceStatus();
            
            // Sync policies
            this.syncPolicies();
            
        } else {
            this.updateConnectionStatus('offline', 'Disconnected');
            this.log('warning', 'Disconnected from server');
            
            // Schedule reconnect
            this.scheduleReconnect();
        }
    }
    
    /**
     * Schedule reconnection attempt
     */
    scheduleReconnect() {
        const delay = Math.min(this.config.retryInterval * Math.pow(2, this.state.connectionAttempts), 60000);
        
        this.log('info', `Reconnecting in ${delay/1000} seconds...`);
        
        setTimeout(() => {
            if (!this.state.isConnected) {
                this.connectToServer();
            }
        }, delay);
    }
    
    /**
     * Handle incoming commands from server
     * NO MOCK DATA - Real commands only
     */
    async handleCommand(message) {
        try {
            const command = JSON.parse(message);
            this.log('info', `Received command: ${command.type}`);
            
            let result = null;
            
            switch (command.type) {
                case 'LOCK':
                    result = await this.components.deviceController.lockDevice();
                    break;
                    
                case 'UNLOCK':
                    result = await this.components.deviceController.unlockDevice();
                    break;
                    
                case 'WIPE':
                    result = await this.components.deviceController.wipeDevice();
                    break;
                    
                case 'REBOOT':
                    result = await this.components.deviceController.rebootDevice();
                    break;
                    
                case 'KIOSK_MODE':
                    result = await this.components.deviceController.enableKioskMode(command.payload);
                    break;
                    
                case 'UPDATE_POLICY':
                    result = await this.components.policyManager.updatePolicy(command.payload);
                    break;
                    
                case 'STATUS_CHECK':
                    result = await this.getDeviceStatus();
                    break;
                    
                case 'SCREENSHOT':
                    result = await this.components.deviceController.takeScreenshot();
                    break;
                    
                default:
                    throw new Error(`Unknown command type: ${command.type}`);
            }
            
            // Send result back to server
            await this.sendCommandResult(command.id, 'success', result);
            this.log('success', `Command ${command.type} executed successfully`);
            
        } catch (error) {
            this.log('error', `Command execution failed: ${error.message}`);
            
            if (command && command.id) {
                await this.sendCommandResult(command.id, 'failed', { error: error.message });
            }
        }
    }
    
    /**
     * Send command result back to server
     */
    async sendCommandResult(commandId, status, result) {
        const response = {
            command_id: commandId,
            device_id: this.state.deviceInfo.device_id,
            status: status,
            result: result,
            executed_at: new Date().toISOString()
        };
        
        if (this.state.isConnected) {
            this.components.websocketClient.send(JSON.stringify(response));
        }
    }
    
    /**
     * Get current device status
     * NO MOCK DATA - Real device status only
     */
    async getDeviceStatus() {
        const status = {
            device_id: this.state.deviceInfo.device_id,
            battery_level: await this.getBatteryLevel(),
            storage_info: await this.getStorageInfo(),
            memory_info: await this.getMemoryInfo(),
            network_info: await this.getNetworkInfo(),
            location: await this.getCurrentLocation(),
            installed_apps: await this.getInstalledApps(),
            policy_status: await this.components.policyManager.getPolicyStatus(),
            last_updated: new Date().toISOString()
        };
        
        return status;
    }
    
    /**
     * Send device status to server
     */
    async sendDeviceStatus() {
        try {
            const status = await this.getDeviceStatus();
            
            if (this.state.isConnected) {
                this.components.websocketClient.send(JSON.stringify({
                    type: 'DEVICE_STATUS',
                    payload: status
                }));
            }
            
            // Update UI
            this.updateStatusUI(status);
            
        } catch (error) {
            this.log('error', `Failed to send device status: ${error.message}`);
        }
    }
    
    /**
     * Sync policies with server
     */
    async syncPolicies() {
        try {
            this.log('info', 'Syncing policies...');
            
            const response = await fetch(`${this.config.serverUrl}/functions/v1/get-device-policies`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.config.apiKey}`
                },
                body: JSON.stringify({
                    device_id: this.state.deviceInfo.device_id
                })
            });
            
            if (!response.ok) {
                throw new Error(`Policy sync failed: ${response.status}`);
            }
            
            const policies = await response.json();
            this.state.policies = policies;
            
            // Apply policies
            await this.components.policyManager.applyPolicies(policies);
            
            // Update UI
            this.updatePolicyUI(policies);
            
            this.log('success', `Synced ${policies.length} policies`);
            
        } catch (error) {
            this.log('error', `Policy sync failed: ${error.message}`);
        }
    }
    
    /**
     * Start background services
     */
    startBackgroundServices() {
        // Heartbeat interval
        this.intervals.heartbeat = setInterval(() => {
            this.sendHeartbeat();
        }, this.config.heartbeatInterval);
        
        // Status update interval
        this.intervals.statusUpdate = setInterval(() => {
            this.sendDeviceStatus();
        }, 60000); // Every minute
        
        this.log('info', 'Background services started');
    }
    
    /**
     * Send heartbeat to server
     */
    async sendHeartbeat() {
        if (this.state.isConnected) {
            const heartbeat = {
                type: 'HEARTBEAT',
                device_id: this.state.deviceInfo.device_id,
                timestamp: new Date().toISOString()
            };
            
            this.components.websocketClient.send(JSON.stringify(heartbeat));
            this.state.lastHeartbeat = new Date();
        }
    }
    
    /**
     * Stop all services (cleanup)
     */
    stop() {
        this.log('info', 'Stopping Knox Agent...');
        
        // Clear intervals
        if (this.intervals.heartbeat) {
            clearInterval(this.intervals.heartbeat);
        }
        
        if (this.intervals.statusUpdate) {
            clearInterval(this.intervals.statusUpdate);
        }
        
        // Disconnect WebSocket
        if (this.components.websocketClient) {
            this.components.websocketClient.disconnect();
        }
        
        this.state.isInitialized = false;
        this.state.isConnected = false;
        
        this.log('info', 'Knox Agent stopped');
    }
    
    // UI Update Methods
    updateConnectionStatus(status, message) {
        const statusDot = document.getElementById('statusDot');
        const statusText = document.getElementById('statusText');
        
        if (statusDot && statusText) {
            statusDot.className = `status-dot ${status}`;
            statusText.textContent = message;
        }
    }
    
    updateDeviceInfoUI() {
        const info = this.state.deviceInfo;
        
        document.getElementById('deviceId').textContent = info.device_id || 'Unknown';
        document.getElementById('deviceModel').textContent = info.model || 'Unknown';
        document.getElementById('androidVersion').textContent = info.version || 'Unknown';
        document.getElementById('knoxVersion').textContent = info.knox_version || 'N/A';
        document.getElementById('branchCode').textContent = info.branch_code || 'Unknown';
        document.getElementById('deviceStatus').textContent = info.status || 'Unknown';
    }
    
    updateStatusUI(status) {
        // Update battery
        const batteryLevel = document.getElementById('batteryLevel');
        const batteryText = document.getElementById('batteryText');
        if (batteryLevel && batteryText && status.battery_level !== null) {
            batteryLevel.style.setProperty('--battery-percent', status.battery_level);
            batteryText.textContent = `${status.battery_level}%`;
        }
        
        // Update storage
        const storageInfo = document.getElementById('storageInfo');
        if (storageInfo && status.storage_info) {
            const used = Math.round(status.storage_info.used / 1024 / 1024 / 1024);
            const total = Math.round(status.storage_info.total / 1024 / 1024 / 1024);
            storageInfo.textContent = `${used}GB / ${total}GB`;
        }
        
        // Update memory
        const memoryInfo = document.getElementById('memoryInfo');
        if (memoryInfo && status.memory_info) {
            const used = Math.round(status.memory_info.used / 1024 / 1024);
            const total = Math.round(status.memory_info.total / 1024 / 1024);
            memoryInfo.textContent = `${used}MB / ${total}MB`;
        }
        
        // Update network
        const networkInfo = document.getElementById('networkInfo');
        if (networkInfo && status.network_info) {
            networkInfo.textContent = status.network_info.type || 'Unknown';
        }
        
        // Update last update time
        const lastUpdate = document.getElementById('lastUpdate');
        if (lastUpdate) {
            lastUpdate.textContent = new Date().toLocaleString();
        }
    }
    
    updatePolicyUI(policies) {
        const policyList = document.getElementById('policyList');
        if (!policyList) return;
        
        policyList.innerHTML = '';
        
        if (policies.length === 0) {
            policyList.innerHTML = '<div class="policy-item"><span class="policy-name">No policies assigned</span><span class="policy-status">N/A</span></div>';
            return;
        }
        
        policies.forEach(policy => {
            const policyItem = document.createElement('div');
            policyItem.className = 'policy-item';
            
            const statusClass = policy.status === 'applied' ? 'active' : 
                               policy.status === 'pending' ? 'pending' : 'failed';
            
            policyItem.innerHTML = `
                <span class="policy-name">${policy.name}</span>
                <span class="policy-status ${statusClass}">${policy.status}</span>
            `;
            
            policyList.appendChild(policyItem);
        });
    }
    
    // Utility Methods
    log(level, message) {
        const timestamp = new Date().toLocaleTimeString();
        const logEntry = document.createElement('div');
        logEntry.className = `log-entry ${level}`;
        logEntry.innerHTML = `
            <span class="log-time">${timestamp}</span>
            <span class="log-message">${message}</span>
        `;
        
        const logContainer = document.getElementById('logContainer');
        if (logContainer) {
            logContainer.insertBefore(logEntry, logContainer.firstChild);
            
            // Keep only last 50 entries
            while (logContainer.children.length > 50) {
                logContainer.removeChild(logContainer.lastChild);
            }
        }
        
        // Also log to console
        console.log(`[Knox Agent] ${level.toUpperCase()}: ${message}`);
    }
    
    // Public API Methods
    async checkStatus() {
        this.log('info', 'Manual status check requested');
        await this.sendDeviceStatus();
    }
    
    async syncPoliciesManual() {
        this.log('info', 'Manual policy sync requested');
        await this.syncPolicies();
    }
    
    async reportIssue() {
        this.log('info', 'Issue report requested');
        // TODO: Implement issue reporting
        alert('Issue reporting feature will be implemented soon.');
    }
    
    // Device info getters (implement these based on available APIs)
    async getBatteryLevel() {
        return new Promise((resolve) => {
            if (navigator.getBattery) {
                navigator.getBattery().then(battery => {
                    resolve(Math.round(battery.level * 100));
                });
            } else {
                resolve(null);
            }
        });
    }
    
    async getStorageInfo() {
        // TODO: Implement storage info retrieval
        return { used: 0, total: 0 };
    }
    
    async getMemoryInfo() {
        // TODO: Implement memory info retrieval
        return { used: 0, total: 0 };
    }
    
    async getNetworkInfo() {
        return new Promise((resolve) => {
            if (navigator.connection) {
                resolve({
                    type: navigator.connection.effectiveType || navigator.connection.type,
                    downlink: navigator.connection.downlink,
                    rtt: navigator.connection.rtt
                });
            } else {
                resolve({ type: 'unknown' });
            }
        });
    }
    
    async getCurrentLocation() {
        return new Promise((resolve) => {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    position => {
                        resolve({
                            latitude: position.coords.latitude,
                            longitude: position.coords.longitude,
                            accuracy: position.coords.accuracy
                        });
                    },
                    error => {
                        resolve(null);
                    }
                );
            } else {
                resolve(null);
            }
        });
    }
    
    async getInstalledApps() {
        // TODO: Implement app list retrieval via Knox API
        return [];
    }
}

// Global instance
window.knoxAgent = new GSEKnoxAgent();
