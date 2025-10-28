/**
 * Native control bridge for the GSE agent.
 * Wraps Cordova exec calls to the KnoxAgentPlugin so JS can interact
 * with DevicePolicyManager-driven features without Samsung Knox.
 */
(function (global) {
    const exec = (action, args = []) => new Promise((resolve, reject) => {
        if (typeof cordova === 'undefined') {
            reject(new Error('Cordova runtime not available'));
            return;
        }
        cordova.exec(resolve, reject, 'KnoxAgentPlugin', action, args);
    });

    const nativeControls = {
        initialize: () => exec('initialize'),
        isAdminActive: () => exec('isAdminActive'),
        isDeviceOwner: () => exec('isDeviceOwner'),
        lockNow: () => exec('lockNow'),
        wipeDevice: (flags = 0) => exec('wipeDevice', [flags]),
        rebootDevice: () => exec('rebootDevice'),
        setLockTaskPackages: (packages = []) => exec('setLockTaskPackages', [packages]),
        startLockTask: () => exec('startLockTask'),
        stopLockTask: () => exec('stopLockTask'),
        setCameraDisabled: (disabled = true) => exec('setCameraDisabled', [disabled]),
        setUserRestriction: (restriction, enabled) => exec('setUserRestriction', [restriction, enabled]),
        openSettings: (target) => exec('openSettings', [target]),
        getPermissionStatuses: () => exec('getPermissionStatuses')
    };

    global.nativeControls = nativeControls;
})(window);
