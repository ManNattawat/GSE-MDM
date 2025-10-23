/**
 * WebSocket Client for GSE Knox Agent
 * Handles real-time communication with GSE MDM Server
 * 
 * NO MOCK DATA - Real WebSocket communication only
 */

class WebSocketClient {
    constructor(url, options = {}) {
        this.url = url;
        this.options = {
            onConnect: options.onConnect || (() => {}),
            onDisconnect: options.onDisconnect || (() => {}),
            onMessage: options.onMessage || (() => {}),
            onError: options.onError || (() => {}),
            reconnectInterval: options.reconnectInterval || 5000,
            maxReconnectAttempts: options.maxReconnectAttempts || 10,
            heartbeatInterval: options.heartbeatInterval || 30000
        };
        
        this.websocket = null;
        this.isConnected = false;
        this.reconnectAttempts = 0;
        this.reconnectTimer = null;
        this.heartbeatTimer = null;
        this.lastPong = null;
        
        // Bind methods
        this.connect = this.connect.bind(this);
        this.disconnect = this.disconnect.bind(this);
        this.send = this.send.bind(this);
        this.onOpen = this.onOpen.bind(this);
        this.onClose = this.onClose.bind(this);
        this.onMessage = this.onMessage.bind(this);
        this.onError = this.onError.bind(this);
    }
    
    /**
     * Connect to WebSocket server
     * NO MOCK DATA - Real WebSocket connection only
     */
    async connect() {
        try {
            console.log('[WebSocket] Connecting to:', this.url);
            
            // Close existing connection if any
            if (this.websocket) {
                this.websocket.close();
            }
            
            // Create new WebSocket connection
            this.websocket = new WebSocket(this.url);
            
            // Set up event handlers
            this.websocket.onopen = this.onOpen;
            this.websocket.onclose = this.onClose;
            this.websocket.onmessage = this.onMessage;
            this.websocket.onerror = this.onError;
            
            return new Promise((resolve, reject) => {
                const timeout = setTimeout(() => {
                    reject(new Error('WebSocket connection timeout'));
                }, 10000);
                
                this.websocket.onopen = (event) => {
                    clearTimeout(timeout);
                    this.onOpen(event);
                    resolve();
                };
                
                this.websocket.onerror = (event) => {
                    clearTimeout(timeout);
                    this.onError(event);
                    reject(new Error('WebSocket connection failed'));
                };
            });
            
        } catch (error) {
            console.error('[WebSocket] Connection failed:', error);
            throw error;
        }
    }
    
    /**
     * Disconnect from WebSocket server
     */
    disconnect() {
        console.log('[WebSocket] Disconnecting...');
        
        this.isConnected = false;
        
        // Clear timers
        if (this.reconnectTimer) {
            clearTimeout(this.reconnectTimer);
            this.reconnectTimer = null;
        }
        
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
        
        // Close WebSocket
        if (this.websocket) {
            this.websocket.close(1000, 'Client disconnect');
            this.websocket = null;
        }
    }
    
    /**
     * Send message to server
     * NO MOCK DATA - Real message sending only
     */
    send(message) {
        if (!this.isConnected || !this.websocket) {
            console.warn('[WebSocket] Cannot send message - not connected');
            return false;
        }
        
        try {
            if (typeof message === 'object') {
                message = JSON.stringify(message);
            }
            
            this.websocket.send(message);
            console.log('[WebSocket] Message sent:', message.substring(0, 100) + (message.length > 100 ? '...' : ''));
            return true;
            
        } catch (error) {
            console.error('[WebSocket] Failed to send message:', error);
            return false;
        }
    }
    
    /**
     * Handle WebSocket open event
     */
    onOpen(event) {
        console.log('[WebSocket] Connected successfully');
        
        this.isConnected = true;
        this.reconnectAttempts = 0;
        this.lastPong = Date.now();
        
        // Start heartbeat
        this.startHeartbeat();
        
        // Notify callback
        this.options.onConnect(event);
    }
    
    /**
     * Handle WebSocket close event
     */
    onClose(event) {
        console.log('[WebSocket] Connection closed:', event.code, event.reason);
        
        this.isConnected = false;
        
        // Stop heartbeat
        this.stopHeartbeat();
        
        // Notify callback
        this.options.onDisconnect(event);
        
        // Attempt reconnection if not intentional close
        if (event.code !== 1000 && this.reconnectAttempts < this.options.maxReconnectAttempts) {
            this.scheduleReconnect();
        }
    }
    
    /**
     * Handle WebSocket message event
     * NO MOCK DATA - Real message handling only
     */
    onMessage(event) {
        try {
            const message = event.data;
            console.log('[WebSocket] Message received:', message.substring(0, 100) + (message.length > 100 ? '...' : ''));
            
            // Handle ping/pong for heartbeat
            if (message === 'ping') {
                this.send('pong');
                return;
            }
            
            if (message === 'pong') {
                this.lastPong = Date.now();
                return;
            }
            
            // Parse JSON message
            let parsedMessage;
            try {
                parsedMessage = JSON.parse(message);
            } catch (parseError) {
                console.warn('[WebSocket] Failed to parse message as JSON:', parseError);
                parsedMessage = message;
            }
            
            // Notify callback
            this.options.onMessage(parsedMessage);
            
        } catch (error) {
            console.error('[WebSocket] Error handling message:', error);
            this.options.onError(error);
        }
    }
    
    /**
     * Handle WebSocket error event
     */
    onError(event) {
        console.error('[WebSocket] Error occurred:', event);
        this.options.onError(event);
    }
    
    /**
     * Schedule reconnection attempt
     */
    scheduleReconnect() {
        if (this.reconnectTimer) {
            clearTimeout(this.reconnectTimer);
        }
        
        this.reconnectAttempts++;
        const delay = Math.min(
            this.options.reconnectInterval * Math.pow(2, this.reconnectAttempts - 1),
            30000 // Max 30 seconds
        );
        
        console.log(`[WebSocket] Reconnecting in ${delay/1000} seconds (attempt ${this.reconnectAttempts}/${this.options.maxReconnectAttempts})`);
        
        this.reconnectTimer = setTimeout(() => {
            this.connect().catch(error => {
                console.error('[WebSocket] Reconnection failed:', error);
            });
        }, delay);
    }
    
    /**
     * Start heartbeat mechanism
     */
    startHeartbeat() {
        this.stopHeartbeat(); // Clear any existing heartbeat
        
        this.heartbeatTimer = setInterval(() => {
            if (this.isConnected) {
                // Check if we received pong recently
                const timeSinceLastPong = Date.now() - this.lastPong;
                
                if (timeSinceLastPong > this.options.heartbeatInterval * 2) {
                    console.warn('[WebSocket] Heartbeat timeout - connection may be dead');
                    this.websocket.close(1006, 'Heartbeat timeout');
                    return;
                }
                
                // Send ping
                this.send('ping');
            }
        }, this.options.heartbeatInterval);
    }
    
    /**
     * Stop heartbeat mechanism
     */
    stopHeartbeat() {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
    }
    
    /**
     * Get connection status
     */
    getStatus() {
        return {
            connected: this.isConnected,
            reconnectAttempts: this.reconnectAttempts,
            lastPong: this.lastPong,
            readyState: this.websocket ? this.websocket.readyState : WebSocket.CLOSED
        };
    }
    
    /**
     * Send device registration message
     * NO MOCK DATA - Real device registration only
     */
    sendDeviceRegistration(deviceInfo) {
        const message = {
            type: 'DEVICE_REGISTRATION',
            payload: deviceInfo,
            timestamp: new Date().toISOString()
        };
        
        return this.send(message);
    }
    
    /**
     * Send device status update
     * NO MOCK DATA - Real device status only
     */
    sendDeviceStatus(statusInfo) {
        const message = {
            type: 'DEVICE_STATUS',
            payload: statusInfo,
            timestamp: new Date().toISOString()
        };
        
        return this.send(message);
    }
    
    /**
     * Send command result
     * NO MOCK DATA - Real command results only
     */
    sendCommandResult(commandId, result, error = null) {
        const message = {
            type: 'COMMAND_RESULT',
            payload: {
                command_id: commandId,
                result: result,
                error: error,
                timestamp: new Date().toISOString()
            }
        };
        
        return this.send(message);
    }
    
    /**
     * Send heartbeat message
     */
    sendHeartbeat(deviceId) {
        const message = {
            type: 'HEARTBEAT',
            payload: {
                device_id: deviceId,
                timestamp: new Date().toISOString()
            }
        };
        
        return this.send(message);
    }
    
    /**
     * Send policy sync request
     * NO MOCK DATA - Real policy sync only
     */
    sendPolicySyncRequest(deviceId) {
        const message = {
            type: 'POLICY_SYNC_REQUEST',
            payload: {
                device_id: deviceId,
                timestamp: new Date().toISOString()
            }
        };
        
        return this.send(message);
    }
    
    /**
     * Send log message to server
     * NO MOCK DATA - Real log data only
     */
    sendLog(level, message, category = 'general') {
        const logMessage = {
            type: 'DEVICE_LOG',
            payload: {
                level: level,
                message: message,
                category: category,
                timestamp: new Date().toISOString()
            }
        };
        
        return this.send(logMessage);
    }
    
    /**
     * Send error report
     * NO MOCK DATA - Real error data only
     */
    sendErrorReport(error, context = {}) {
        const errorMessage = {
            type: 'ERROR_REPORT',
            payload: {
                error: {
                    message: error.message,
                    stack: error.stack,
                    name: error.name
                },
                context: context,
                timestamp: new Date().toISOString()
            }
        };
        
        return this.send(errorMessage);
    }
}
