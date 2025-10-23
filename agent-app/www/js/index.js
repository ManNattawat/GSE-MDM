/**
 * GSE Knox Agent - Main Entry Point
 * Initializes the Knox Agent when device is ready
 * 
 * NO MOCK DATA - All initialization uses real device and server data
 */

document.addEventListener('deviceready', onDeviceReady, false);

/**
 * Device ready event handler
 * Called when Cordova/PhoneGap is fully loaded
 */
function onDeviceReady() {
    console.log('[Knox Agent] Device ready - initializing Knox Agent...');
    
    try {
        // Initialize Knox Agent
        if (window.knoxAgent) {
            window.knoxAgent.initialize().catch(error => {
                console.error('[Knox Agent] Initialization failed:', error);
                showErrorMessage('Knox Agent initialization failed: ' + error.message);
            });
        } else {
            throw new Error('Knox Agent not found');
        }
        
        // Set up global error handlers
        setupErrorHandlers();
        
        // Set up UI event listeners
        setupUIEventListeners();
        
        // Set up app lifecycle handlers
        setupAppLifecycleHandlers();
        
        console.log('[Knox Agent] Main initialization completed');
        
    } catch (error) {
        console.error('[Knox Agent] Failed to initialize:', error);
        showErrorMessage('Failed to initialize Knox Agent: ' + error.message);
    }
}

/**
 * Set up global error handlers
 */
function setupErrorHandlers() {
    // Handle uncaught JavaScript errors
    window.addEventListener('error', function(event) {
        console.error('[Knox Agent] Uncaught error:', event.error);
        
        if (window.knoxAgent && window.knoxAgent.components.websocketClient) {
            window.knoxAgent.components.websocketClient.sendErrorReport(event.error, {
                type: 'uncaught_error',
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno
            });
        }
    });
    
    // Handle unhandled promise rejections
    window.addEventListener('unhandledrejection', function(event) {
        console.error('[Knox Agent] Unhandled promise rejection:', event.reason);
        
        if (window.knoxAgent && window.knoxAgent.components.websocketClient) {
            window.knoxAgent.components.websocketClient.sendErrorReport(
                new Error(event.reason), 
                { type: 'unhandled_promise_rejection' }
            );
        }
    });
}

/**
 * Set up UI event listeners
 */
function setupUIEventListeners() {
    // Refresh status button
    const refreshButton = document.querySelector('[onclick="knoxAgent.checkStatus()"]');
    if (refreshButton) {
        refreshButton.addEventListener('click', function(e) {
            e.preventDefault();
            if (window.knoxAgent) {
                window.knoxAgent.checkStatus();
            }
        });
    }
    
    // Sync policies button
    const syncButton = document.querySelector('[onclick="knoxAgent.syncPolicies()"]');
    if (syncButton) {
        syncButton.addEventListener('click', function(e) {
            e.preventDefault();
            if (window.knoxAgent) {
                window.knoxAgent.syncPoliciesManual();
            }
        });
    }
    
    // Report issue button
    const reportButton = document.querySelector('[onclick="knoxAgent.reportIssue()"]');
    if (reportButton) {
        reportButton.addEventListener('click', function(e) {
            e.preventDefault();
            if (window.knoxAgent) {
                window.knoxAgent.reportIssue();
            }
        });
    }
    
    // Handle back button (Android)
    document.addEventListener('backbutton', function(e) {
        e.preventDefault();
        
        // Ask user if they want to exit
        if (confirm('Are you sure you want to exit Knox Agent?')) {
            navigator.app.exitApp();
        }
    }, false);
    
    // Handle menu button (Android)
    document.addEventListener('menubutton', function(e) {
        showOptionsMenu();
    }, false);
}

/**
 * Set up app lifecycle handlers
 */
function setupAppLifecycleHandlers() {
    // App pause (going to background)
    document.addEventListener('pause', function() {
        console.log('[Knox Agent] App paused');
        
        if (window.knoxAgent) {
            // Send status update before going to background
            window.knoxAgent.sendDeviceStatus();
        }
    }, false);
    
    // App resume (coming from background)
    document.addEventListener('resume', function() {
        console.log('[Knox Agent] App resumed');
        
        if (window.knoxAgent) {
            // Check connection and sync when resuming
            setTimeout(() => {
                window.knoxAgent.checkStatus();
                window.knoxAgent.syncPoliciesManual();
            }, 1000);
        }
    }, false);
    
    // Network status changes
    document.addEventListener('online', function() {
        console.log('[Knox Agent] Network online');
        
        if (window.knoxAgent && !window.knoxAgent.state.isConnected) {
            // Try to reconnect when network comes back
            setTimeout(() => {
                window.knoxAgent.connectToServer();
            }, 2000);
        }
    }, false);
    
    document.addEventListener('offline', function() {
        console.log('[Knox Agent] Network offline');
        showStatusMessage('Network connection lost', 'warning');
    }, false);
}

/**
 * Show error message to user
 */
function showErrorMessage(message) {
    // Update status in UI
    const statusText = document.getElementById('statusText');
    const statusDot = document.getElementById('statusDot');
    
    if (statusText && statusDot) {
        statusText.textContent = 'Error: ' + message;
        statusDot.className = 'status-dot offline';
    }
    
    // Add to log
    const logContainer = document.getElementById('logContainer');
    if (logContainer) {
        const logEntry = document.createElement('div');
        logEntry.className = 'log-entry error';
        logEntry.innerHTML = `
            <span class="log-time">${new Date().toLocaleTimeString()}</span>
            <span class="log-message">ERROR: ${message}</span>
        `;
        logContainer.insertBefore(logEntry, logContainer.firstChild);
    }
    
    console.error('[Knox Agent] Error:', message);
}

/**
 * Show status message to user
 */
function showStatusMessage(message, type = 'info') {
    const logContainer = document.getElementById('logContainer');
    if (logContainer) {
        const logEntry = document.createElement('div');
        logEntry.className = `log-entry ${type}`;
        logEntry.innerHTML = `
            <span class="log-time">${new Date().toLocaleTimeString()}</span>
            <span class="log-message">${message}</span>
        `;
        logContainer.insertBefore(logEntry, logContainer.firstChild);
        
        // Keep only last 50 entries
        while (logContainer.children.length > 50) {
            logContainer.removeChild(logContainer.lastChild);
        }
    }
}

/**
 * Show options menu
 */
function showOptionsMenu() {
    const options = [
        'Refresh Status',
        'Sync Policies', 
        'View Logs',
        'Report Issue',
        'About'
    ];
    
    // Simple menu implementation
    let menuText = 'Knox Agent Options:\n\n';
    options.forEach((option, index) => {
        menuText += `${index + 1}. ${option}\n`;
    });
    
    const choice = prompt(menuText + '\nEnter option number (1-5):');
    
    if (choice && window.knoxAgent) {
        switch (choice) {
            case '1':
                window.knoxAgent.checkStatus();
                break;
            case '2':
                window.knoxAgent.syncPoliciesManual();
                break;
            case '3':
                showLogDetails();
                break;
            case '4':
                window.knoxAgent.reportIssue();
                break;
            case '5':
                showAboutDialog();
                break;
        }
    }
}

/**
 * Show detailed logs
 */
function showLogDetails() {
    const logContainer = document.getElementById('logContainer');
    if (logContainer) {
        const logs = Array.from(logContainer.children).map(entry => {
            const time = entry.querySelector('.log-time').textContent;
            const message = entry.querySelector('.log-message').textContent;
            return `${time}: ${message}`;
        }).join('\n');
        
        alert('Recent Logs:\n\n' + logs);
    }
}

/**
 * Show about dialog
 */
function showAboutDialog() {
    const deviceInfo = window.knoxAgent ? window.knoxAgent.state.deviceInfo : null;
    
    let aboutText = 'GSE Knox Agent\n';
    aboutText += 'Version: 1.0.0\n';
    aboutText += 'Build: ' + new Date().toISOString().split('T')[0] + '\n\n';
    
    if (deviceInfo) {
        aboutText += 'Device Information:\n';
        aboutText += `Device ID: ${deviceInfo.device_id}\n`;
        aboutText += `Model: ${deviceInfo.model}\n`;
        aboutText += `Android: ${deviceInfo.version}\n`;
        aboutText += `Branch: ${deviceInfo.branch_code}\n`;
        aboutText += `Knox: ${deviceInfo.knox_version || 'N/A'}\n`;
    }
    
    aboutText += '\n© 2025 GSE Enterprise Platform';
    
    alert(aboutText);
}

/**
 * Handle app initialization timeout
 */
setTimeout(function() {
    if (!window.knoxAgent || !window.knoxAgent.state.isInitialized) {
        console.warn('[Knox Agent] Initialization timeout - may be running in browser');
        
        // If running in browser (for testing), show a warning
        if (typeof device === 'undefined') {
            showStatusMessage('Running in browser mode - Knox features not available', 'warning');
            
            // Initialize with limited functionality for testing
            if (window.knoxAgent) {
                window.knoxAgent.state.deviceInfo = {
                    device_id: 'browser-test-' + Date.now(),
                    model: 'Browser',
                    version: 'Web',
                    branch_code: '001',
                    status: 'testing'
                };
                
                window.knoxAgent.updateDeviceInfoUI();
                window.knoxAgent.updateConnectionStatus('offline', 'Browser mode');
            }
        }
    }
}, 10000); // 10 second timeout

/**
 * Export functions for global access
 */
window.knoxAgentUI = {
    showErrorMessage: showErrorMessage,
    showStatusMessage: showStatusMessage,
    showOptionsMenu: showOptionsMenu,
    showAboutDialog: showAboutDialog
};

console.log('[Knox Agent] Main script loaded');
