import './telemetry.js';
import './knox-api.js';
import './websocket-client.js';
import './device-controller.js';
import './policy-manager.js';
import './knox-agent.js';
import './onboarding.js';

const onDeviceReady = () => {
    console.log('[Knox Agent] Device ready - initializing Knox Agent...');

    try {
        const agent = window.knoxAgent;
        if (!agent) {
            throw new Error('Knox Agent not found');
        }

        agent.initialize().catch((error) => {
            console.error('[Knox Agent] Initialization failed:', error);
            showErrorMessage('Knox Agent initialization failed: ' + error.message);
        });

        setupErrorHandlers(agent);
        setupUIEventListeners(agent);
        setupAppLifecycleHandlers(agent);

        console.log('[Knox Agent] Main initialization completed');
    } catch (error) {
        console.error('[Knox Agent] Failed to initialize:', error);
        showErrorMessage('Failed to initialize Knox Agent: ' + error.message);
    }
};

const setupErrorHandlers = (agent) => {
    window.addEventListener('error', (event) => {
        console.error('[Knox Agent] Uncaught error:', event.error);

        if (agent?.components?.websocketClient) {
            agent.components.websocketClient.sendErrorReport(event.error, {
                type: 'uncaught_error',
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
            });
        }
    });

    window.addEventListener('unhandledrejection', (event) => {
        console.error('[Knox Agent] Unhandled promise rejection:', event.reason);

        if (agent?.components?.websocketClient) {
            agent.components.websocketClient.sendErrorReport(
                event.reason instanceof Error ? event.reason : new Error(event.reason),
                { type: 'unhandled_promise_rejection' },
            );
        }
    });
};

const setupUIEventListeners = (agent) => {
    const withAgent = (handler) => (event) => {
        event.preventDefault();
        handler(agent);
    };

    const refreshButton = document.querySelector('[data-action="refresh-status"]');
    if (refreshButton) {
        refreshButton.addEventListener('click', withAgent((ag) => ag.checkStatus()));
    }

    const syncButton = document.querySelector('[data-action="sync-policies"]');
    if (syncButton) {
        syncButton.addEventListener('click', withAgent((ag) => ag.syncPoliciesManual()));
    }

    const reportButton = document.querySelector('[data-action="report-issue"]');
    if (reportButton) {
        reportButton.addEventListener('click', withAgent((ag) => ag.reportIssue()));
    }

    document.addEventListener('backbutton', (event) => {
        event.preventDefault();
        if (confirm('ต้องการออกจาก Knox Agent หรือไม่?')) {
            navigator.app.exitApp();
        }
    });

    document.addEventListener('menubutton', showOptionsMenu);
};

const setupAppLifecycleHandlers = (agent) => {
    document.addEventListener('pause', () => {
        console.log('[Knox Agent] App paused');
        agent?.sendDeviceStatus();
    });

    document.addEventListener('resume', () => {
        console.log('[Knox Agent] App resumed');
        if (!agent) return;
        setTimeout(() => {
            agent.checkStatus();
            agent.syncPoliciesManual();
        }, 1000);
    });

    document.addEventListener('online', () => {
        console.log('[Knox Agent] Network online');
        if (!agent?.state?.isConnected) {
            setTimeout(() => agent?.connectToServer(), 2000);
        }
    });

    document.addEventListener('offline', () => {
        console.log('[Knox Agent] Network offline');
        showStatusMessage('Network connection lost', 'warning');
    });
};

const showErrorMessage = (message) => {
    const statusText = document.getElementById('statusText');
    const statusDot = document.getElementById('statusDot');

    if (statusText && statusDot) {
        statusText.textContent = 'Error: ' + message;
        statusDot.className = 'status-dot offline';
    }

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
};

const showStatusMessage = (message, type = 'info') => {
    const logContainer = document.getElementById('logContainer');
    if (!logContainer) return;

    const logEntry = document.createElement('div');
    logEntry.className = `log-entry ${type}`;
    logEntry.innerHTML = `
        <span class="log-time">${new Date().toLocaleTimeString()}</span>
        <span class="log-message">${message}</span>
    `;
    logContainer.insertBefore(logEntry, logContainer.firstChild);

    while (logContainer.children.length > 50) {
        logContainer.removeChild(logContainer.lastChild);
    }
};

const showOptionsMenu = () => {
    const options = ['Refresh Status', 'Sync Policies', 'View Logs', 'Report Issue', 'About'];
    const menuText = options.map((option, index) => `${index + 1}. ${option}`).join('\n');
    const choice = prompt(`Knox Agent Options:\n\n${menuText}\n\nEnter option number (1-5):`);

    const agent = window.knoxAgent;
    if (!choice || !agent) return;

    switch (choice) {
        case '1':
            agent.checkStatus();
            break;
        case '2':
            agent.syncPoliciesManual();
            break;
        case '3':
            showLogDetails();
            break;
        case '4':
            agent.reportIssue();
            break;
        case '5':
            showAboutDialog(agent);
            break;
        default:
            break;
    }
};

const showLogDetails = () => {
    const logContainer = document.getElementById('logContainer');
    if (!logContainer) return;

    const logs = Array.from(logContainer.children)
        .map((entry) => {
            const time = entry.querySelector('.log-time')?.textContent || '';
            const message = entry.querySelector('.log-message')?.textContent || '';
            return `${time}: ${message}`;
        })
        .join('\n');

    alert(`Recent Logs:\n\n${logs}`);
};

const showAboutDialog = (agent) => {
    const deviceInfo = agent?.state?.deviceInfo;

    let aboutText = 'GSE Knox Agent\n';
    aboutText += 'Version: 1.0.0\n';
    aboutText += `Build: ${new Date().toISOString().split('T')[0]}\n\n`;

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
};

const initTimeout = setTimeout(() => {
    const agent = window.knoxAgent;
    if (agent?.state?.isInitialized) {
        return;
    }

    console.warn('[Knox Agent] Initialization timeout - may be running in browser');

    if (typeof device === 'undefined' && agent) {
        showStatusMessage('Running in browser mode - Knox features not available', 'warning');

        agent.state.deviceInfo = {
            device_id: `browser-test-${Date.now()}`,
            model: 'Browser',
            version: 'Web',
            branch_code: '001',
            status: 'testing',
        };

        agent.updateDeviceInfoUI();
        agent.updateConnectionStatus('offline', 'Browser mode');
    }
}, 10000);

document.addEventListener('deviceready', onDeviceReady, false);

window.knoxAgentUI = {
    showErrorMessage,
    showStatusMessage,
    showOptionsMenu,
    showAboutDialog,
};

console.log('[Knox Agent] Main script loaded');

export {};
