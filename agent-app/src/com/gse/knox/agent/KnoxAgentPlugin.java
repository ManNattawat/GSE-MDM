package com.gse.knox.agent;

import android.app.Activity;
import android.app.AppOpsManager;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.content.pm.PackageManager;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import androidx.core.app.NotificationManagerCompat;

/**
 * Cordova bridge for MDM features that do not rely on Samsung Knox.
 * Provides access to DevicePolicyManager and helper intents for user consent flows.
 */
public class KnoxAgentPlugin extends CordovaPlugin {

    private DevicePolicyManager devicePolicyManager;
    private ComponentName adminComponent;

    @Override
    protected void pluginInitialize() {
        super.pluginInitialize();
        Context context = cordova.getActivity().getApplicationContext();
        devicePolicyManager = (DevicePolicyManager) context.getSystemService(Context.DEVICE_POLICY_SERVICE);
        adminComponent = new ComponentName(context, GseDeviceAdminReceiver.class);
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "initialize":
                handleInitialize(callbackContext);
                return true;
            case "isAdminActive":
                handleIsAdminActive(callbackContext);
                return true;
            case "isDeviceOwner":
                handleIsDeviceOwner(callbackContext);
                return true;
            case "lockNow":
                handleLockNow(callbackContext);
                return true;
            case "wipeDevice":
                handleWipeDevice(callbackContext, args);
                return true;
            case "rebootDevice":
                handleRebootDevice(callbackContext);
                return true;
            case "setLockTaskPackages":
                handleSetLockTaskPackages(args, callbackContext);
                return true;
            case "startLockTask":
                handleStartLockTask(callbackContext);
                return true;
            case "stopLockTask":
                handleStopLockTask(callbackContext);
                return true;
            case "setCameraDisabled":
                handleSetCameraDisabled(args, callbackContext);
                return true;
            case "setUserRestriction":
                handleSetUserRestriction(args, callbackContext);
                return true;
            case "openSettings":
                handleOpenSettings(args, callbackContext);
                return true;
            case "getPermissionStatuses":
                handleGetPermissionStatuses(callbackContext);
                return true;
            default:
                return false;
        }
    }

    private void handleInitialize(CallbackContext callbackContext) {
        if (!ensureDevicePolicy(callbackContext)) {
            return;
        }

        JSONObject result = new JSONObject();
        try {
            result.put("isAdminActive", devicePolicyManager.isAdminActive(adminComponent));
            result.put("isDeviceOwner", isDeviceOwnerApp());
            callbackContext.success(result);
        } catch (JSONException e) {
            callbackContext.error("Failed to build initialization response: " + e.getMessage());
        }
    }

    private void handleIsAdminActive(CallbackContext callbackContext) {
        if (!ensureDevicePolicy(callbackContext)) {
            return;
        }
        boolean isActive = devicePolicyManager.isAdminActive(adminComponent);
        PluginResult result = new PluginResult(PluginResult.Status.OK, isActive);
        callbackContext.sendPluginResult(result);
    }

    private void handleIsDeviceOwner(CallbackContext callbackContext) {
        PluginResult result = new PluginResult(PluginResult.Status.OK, isDeviceOwnerApp());
        callbackContext.sendPluginResult(result);
    }

    private void handleLockNow(CallbackContext callbackContext) {
        if (!ensureAdminActive(callbackContext)) {
            return;
        }
        devicePolicyManager.lockNow();
        callbackContext.success();
    }

    private void handleWipeDevice(CallbackContext callbackContext, JSONArray args) throws JSONException {
        if (!ensureAdminActive(callbackContext)) {
            return;
        }

        int wipeFlags = 0;
        if (args != null && args.length() > 0) {
            wipeFlags = args.optInt(0, 0);
        }
        devicePolicyManager.wipeData(wipeFlags);
        callbackContext.success();
    }

    private void handleRebootDevice(CallbackContext callbackContext) {
        if (!ensureAdminActive(callbackContext)) {
            return;
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            callbackContext.error("Device reboot requires Android N or higher");
            return;
        }
        if (!isDeviceOwnerApp()) {
            callbackContext.error("Reboot requires device owner status");
            return;
        }
        try {
            devicePolicyManager.reboot(adminComponent);
            callbackContext.success();
        } catch (SecurityException ex) {
            callbackContext.error("Failed to reboot device: " + ex.getMessage());
        }
    }

    private void handleSetLockTaskPackages(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (!ensureAdminActive(callbackContext)) {
            return;
        }
        if (!isDeviceOwnerApp()) {
            callbackContext.error("Setting lock task packages requires device owner status");
            return;
        }
        List<String> packages = new ArrayList<>();
        if (args != null && args.length() > 0) {
            JSONArray packagesArg = args.getJSONArray(0);
            for (int i = 0; i < packagesArg.length(); i++) {
                packages.add(packagesArg.getString(i));
            }
        }
        devicePolicyManager.setLockTaskPackages(adminComponent, packages.toArray(new String[0]));
        callbackContext.success();
    }

    private void handleStartLockTask(CallbackContext callbackContext) {
        if (!ensureAdminActive(callbackContext)) {
            return;
        }
        Activity activity = cordova.getActivity();
        cordova.getActivity().runOnUiThread(() -> {
            try {
                activity.startLockTask();
                callbackContext.success();
            } catch (IllegalStateException ex) {
                callbackContext.error("Failed to start lock task: " + ex.getMessage());
            }
        });
    }

    private void handleStopLockTask(CallbackContext callbackContext) {
        Activity activity = cordova.getActivity();
        cordova.getActivity().runOnUiThread(() -> {
            try {
                activity.stopLockTask();
                callbackContext.success();
            } catch (IllegalStateException ex) {
                callbackContext.error("Failed to stop lock task: " + ex.getMessage());
            }
        });
    }

    private void handleSetCameraDisabled(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (!ensureAdminActive(callbackContext)) {
            return;
        }
        boolean disabled = args != null && args.optBoolean(0, false);
        devicePolicyManager.setCameraDisabled(adminComponent, disabled);
        callbackContext.success();
    }

    private void handleSetUserRestriction(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (!ensureAdminActive(callbackContext)) {
            return;
        }
        if (args == null || args.length() < 2) {
            callbackContext.error("Restriction name and enabled flag are required");
            return;
        }
        String restriction = args.getString(0);
        boolean enabled = args.getBoolean(1);

        if (enabled) {
            devicePolicyManager.addUserRestriction(adminComponent, restriction);
        } else {
            devicePolicyManager.clearUserRestriction(adminComponent, restriction);
        }
        callbackContext.success();
    }

    private void handleOpenSettings(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args == null || args.length() == 0) {
            callbackContext.error("Settings action required");
            return;
        }
        String settingsTarget = args.getString(0);
        Intent intent = buildSettingsIntent(settingsTarget);
        if (intent == null) {
            callbackContext.error("Unknown settings target: " + settingsTarget);
            return;
        }

        Activity activity = cordova.getActivity();
        activity.runOnUiThread(() -> {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                activity.startActivity(intent);
                callbackContext.success();
            } catch (Exception ex) {
                callbackContext.error("Failed to open settings: " + ex.getMessage());
            }
        });
    }

    private void handleGetPermissionStatuses(CallbackContext callbackContext) {
        Context context = cordova.getActivity().getApplicationContext();
        JSONObject statuses = new JSONObject();
        try {
            statuses.put("deviceAdmin", devicePolicyManager != null && devicePolicyManager.isAdminActive(adminComponent));
            statuses.put("deviceOwner", isDeviceOwnerApp());
            statuses.put("usageAccess", hasUsageAccess(context));
            statuses.put("notificationAccess", hasNotificationAccess(context));
            statuses.put("installPackages", canInstallUnknownSources(context));
            callbackContext.success(statuses);
        } catch (JSONException e) {
            callbackContext.error("Failed to collect permission statuses: " + e.getMessage());
        }
    }

    private Intent buildSettingsIntent(String target) {
        switch (target) {
            case "device_admin":
                Intent adminIntent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN);
                adminIntent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent);
                return adminIntent;
            case "usage_access":
                return new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
            case "notification_access":
                return new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
            case "accessibility":
                return new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
            case "install_packages":
                Intent installIntent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES);
                installIntent.setData(Uri.parse("package:" + cordova.getActivity().getPackageName()));
                return installIntent;
            case "media_projection":
                return new Intent(Settings.ACTION_CAST_SETTINGS);
            default:
                return null;
        }
    }

    private boolean ensureDevicePolicy(CallbackContext callbackContext) {
        if (devicePolicyManager == null) {
            callbackContext.error("DevicePolicyManager unavailable");
            return false;
        }
        return true;
    }

    private boolean ensureAdminActive(CallbackContext callbackContext) {
        if (!ensureDevicePolicy(callbackContext)) {
            return false;
        }
        if (!devicePolicyManager.isAdminActive(adminComponent)) {
            callbackContext.error("Device admin not active");
            return false;
        }
        return true;
    }

    private boolean isDeviceOwnerApp() {
        Context context = cordova.getActivity().getApplicationContext();
        return devicePolicyManager != null && devicePolicyManager.isDeviceOwnerApp(context.getPackageName());
    }

    private boolean hasUsageAccess(Context context) {
        AppOpsManager appOps = (AppOpsManager) context.getSystemService(Context.APP_OPS_SERVICE);
        if (appOps == null) {
            return false;
        }
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), context.getPackageName());
        if (mode == AppOpsManager.MODE_DEFAULT) {
            return context.checkCallingOrSelfPermission(android.Manifest.permission.PACKAGE_USAGE_STATS) == PackageManager.PERMISSION_GRANTED;
        }
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    private boolean hasNotificationAccess(Context context) {
        return NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.getPackageName());
    }

    private boolean canInstallUnknownSources(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return context.getPackageManager().canRequestPackageInstalls();
        }
        return Settings.Secure.getInt(context.getContentResolver(), Settings.Secure.INSTALL_NON_MARKET_APPS, 0) == 1;
    }
}
