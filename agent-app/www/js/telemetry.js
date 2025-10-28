(function (global) {
    const reportResult = async (config, data) => {
        if (!config || !config.serverUrl || !config.apiKey) {
            console.warn('[Telemetry] Missing Supabase configuration, skip reporting');
            return;
        }

        try {
            const endpoint = `${config.serverUrl.replace(/\/$/, '')}/rest/v1/device_command_results`;
            const payload = [{
                command_id: data.commandId,
                device_id: data.deviceId,
                status: data.status,
                payload: data.payload ? JSON.stringify(data.payload) : null,
                reported_at: new Date().toISOString()
            }];

            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'apikey': config.apiKey,
                    'Authorization': `Bearer ${config.apiKey}`
                },
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`Supabase insert failed (${response.status}): ${errorText}`);
            }

            console.log('[Telemetry] Result reported to Supabase');
        } catch (error) {
            console.error('[Telemetry] Failed to report result:', error);
        }
    };

    global.telemetry = Object.assign({}, global.telemetry, {
        reportResult
    });
})(window);
