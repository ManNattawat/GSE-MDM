-- GSE-MDM Database Functions
-- ฟังก์ชันสำหรับการทำงานของระบบ MDM

-- =============================================
-- 1. ฟังก์ชันสร้าง Provisioning Token (QR Code)
-- =============================================
CREATE OR REPLACE FUNCTION mdm.create_provisioning_token(
    p_branch_code TEXT,
    p_policy_id UUID,
    p_expires_in_hours INTEGER DEFAULT 168 -- 7 days
)
RETURNS TABLE(token TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_token TEXT;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Generate random token
    v_token := encode(gen_random_bytes(32), 'hex');
    v_expires_at := NOW() + (p_expires_in_hours || ' hours')::INTERVAL;
    
    -- Insert token
    INSERT INTO mdm.provisioning_tokens (token, branch_code, policy_id, expires_at, created_by)
    VALUES (v_token, p_branch_code, p_policy_id, v_expires_at, auth.uid()::TEXT);
    
    RETURN QUERY SELECT v_token, v_expires_at;
END;
$$;

-- =============================================
-- 2. ฟังก์ชันตรวจสอบและใช้ Provisioning Token
-- =============================================
CREATE OR REPLACE FUNCTION mdm.validate_provisioning_token(
    p_token TEXT,
    p_device_id TEXT,
    p_serial_number TEXT DEFAULT NULL
)
RETURNS TABLE(
    valid BOOLEAN,
    branch_code TEXT,
    policy_id UUID,
    enrollment_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_token_record mdm.provisioning_tokens%ROWTYPE;
    v_enrollment_id UUID;
BEGIN
    -- Check if token exists and is valid
    SELECT * INTO v_token_record
    FROM mdm.provisioning_tokens
    WHERE token = p_token 
    AND used = FALSE 
    AND expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::TEXT, NULL::UUID, NULL::UUID;
        RETURN;
    END IF;
    
    -- Mark token as used
    UPDATE mdm.provisioning_tokens
    SET used = TRUE
    WHERE id = v_token_record.id;
    
    -- Create device enrollment
    INSERT INTO mdm.device_enrollments (device_id, serial_number, branch_code, policy_id, status, provisioning_token_id)
    VALUES (p_device_id, p_serial_number, v_token_record.branch_code, v_token_record.policy_id, 'pending', v_token_record.id)
    RETURNING id INTO v_enrollment_id;
    
    RETURN QUERY SELECT TRUE, v_token_record.branch_code, v_token_record.policy_id, v_enrollment_id;
END;
$$;

-- =============================================
-- 3. ฟังก์ชัน Activate Device Enrollment
-- =============================================
CREATE OR REPLACE FUNCTION mdm.activate_device_enrollment(
    p_enrollment_id UUID,
    p_device_name TEXT DEFAULT NULL,
    p_model TEXT DEFAULT NULL,
    p_os_version TEXT DEFAULT NULL,
    p_knox_version TEXT DEFAULT NULL,
    p_user_id TEXT DEFAULT NULL
)
RETURNS mdm.devices
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_enrollment mdm.device_enrollments%ROWTYPE;
    v_device mdm.devices;
BEGIN
    -- Get enrollment details
    SELECT * INTO v_enrollment
    FROM mdm.device_enrollments
    WHERE id = p_enrollment_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Enrollment not found or already processed';
    END IF;
    
    -- Update enrollment status
    UPDATE mdm.device_enrollments
    SET status = 'active', last_seen_at = NOW()
    WHERE id = p_enrollment_id;
    
    -- Create device record
    INSERT INTO mdm.devices (
        device_uuid, serial_number, device_name, model, 
        os_version, knox_version, branch_code, user_id, 
        status, policy_id, enrollment_id
    )
    VALUES (
        v_enrollment.device_id, v_enrollment.serial_number, p_device_name, p_model,
        p_os_version, p_knox_version, v_enrollment.branch_code, p_user_id,
        'active', v_enrollment.policy_id, p_enrollment_id
    )
    RETURNING * INTO v_device;
    
    -- Apply initial policy
    INSERT INTO mdm.device_policies (device_id, policy_id, status)
    VALUES (v_device.id, v_enrollment.policy_id, 'applied');
    
    -- Log activation
    INSERT INTO mdm.logs (device_id, level, message, category)
    VALUES (v_device.id, 'info', 'Device activated via QR provisioning', 'enrollment');
    
    RETURN v_device;
END;
$$;

-- =============================================
-- 4. ฟังก์ชันลงทะเบียนเครื่องใหม่ (Legacy)
-- =============================================
CREATE OR REPLACE FUNCTION mdm.register_device(
    p_device_id TEXT,
    p_serial TEXT,
    p_branch TEXT,
    p_model TEXT,
    p_android_version TEXT,
    p_agent_version TEXT DEFAULT '1.0.0'
) RETURNS UUID AS $$
DECLARE
    device_uuid UUID;
BEGIN
    -- ตรวจสอบว่า device_id มีอยู่แล้วหรือไม่
    SELECT id INTO device_uuid 
    FROM mdm.devices 
    WHERE device_id = p_device_id;
    
    IF device_uuid IS NOT NULL THEN
        -- อัปเดตข้อมูลเครื่องที่มีอยู่
        UPDATE mdm.devices SET
            serial_number = p_serial,
            branch_code = p_branch,
            model = p_model,
            android_version = p_android_version,
            agent_version = p_agent_version,
            status = 'active',
            last_seen = NOW(),
            updated_at = NOW()
        WHERE id = device_uuid;
        
        RETURN device_uuid;
    ELSE
        -- สร้างเครื่องใหม่
        INSERT INTO mdm.devices (
            device_id, serial_number, branch_code, model, 
            android_version, agent_version, status, last_seen
        ) VALUES (
            p_device_id, p_serial, p_branch, p_model, 
            p_android_version, p_agent_version, 'active', NOW()
        ) RETURNING id INTO device_uuid;
        
        -- บันทึก log
        INSERT INTO mdm.logs (device_id, level, message, category)
        VALUES (device_uuid, 'info', 'Device registered successfully', 'registration');
        
        RETURN device_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 2. ฟังก์ชันดึง Policy ที่ต้อง Apply
-- =============================================
CREATE OR REPLACE FUNCTION mdm.get_device_policies(p_device_id UUID)
RETURNS TABLE(
    policy_id UUID,
    policy_name TEXT,
    policy_config JSONB,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as policy_id,
        p.name as policy_name,
        p.config as policy_config,
        COALESCE(dp.status, 'pending') as status
    FROM mdm.policies p
    LEFT JOIN mdm.device_policies dp ON p.id = dp.policy_id AND dp.device_id = p_device_id
    WHERE p.is_active = true
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 3. ฟังก์ชันดึงคำสั่งที่รอ Execute
-- =============================================
CREATE OR REPLACE FUNCTION mdm.get_pending_commands(p_device_id UUID)
RETURNS TABLE(
    command_id UUID,
    command_type TEXT,
    payload JSONB,
    issued_by TEXT,
    issued_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as command_id,
        c.command_type,
        c.payload,
        c.issued_by,
        c.issued_at
    FROM mdm.commands c
    WHERE c.device_id = p_device_id 
    AND c.status = 'pending'
    ORDER BY c.issued_at ASC;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 4. ฟังก์ชันอัปเดตสถานะคำสั่ง
-- =============================================
CREATE OR REPLACE FUNCTION mdm.update_command_status(
    p_command_id UUID,
    p_status TEXT,
    p_result JSONB DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    command_exists BOOLEAN;
BEGIN
    -- ตรวจสอบว่า command มีอยู่หรือไม่
    SELECT EXISTS(SELECT 1 FROM mdm.commands WHERE id = p_command_id) INTO command_exists;
    
    IF NOT command_exists THEN
        RETURN FALSE;
    END IF;
    
    -- อัปเดตสถานะคำสั่ง
    UPDATE mdm.commands SET
        status = p_status,
        result = COALESCE(p_result, result),
        error_message = COALESCE(p_error_message, error_message),
        executed_at = CASE WHEN p_status = 'executed' THEN NOW() ELSE executed_at END,
        sent_at = CASE WHEN p_status = 'sent' THEN NOW() ELSE sent_at END,
        updated_at = NOW()
    WHERE id = p_command_id;
    
    -- บันทึก log
    INSERT INTO mdm.logs (device_id, level, message, category, metadata)
    SELECT 
        device_id,
        CASE 
            WHEN p_status = 'executed' THEN 'info'
            WHEN p_status = 'failed' THEN 'error'
            ELSE 'info'
        END,
        'Command ' || p_status || ': ' || command_type,
        'command',
        jsonb_build_object('command_id', p_command_id, 'result', p_result)
    FROM mdm.commands 
    WHERE id = p_command_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 5. ฟังก์ชันอัปเดตสถานะเครื่อง
-- =============================================
CREATE OR REPLACE FUNCTION mdm.update_device_status(
    p_device_id UUID,
    p_battery_level INTEGER DEFAULT NULL,
    p_storage_used BIGINT DEFAULT NULL,
    p_storage_total BIGINT DEFAULT NULL,
    p_memory_used BIGINT DEFAULT NULL,
    p_memory_total BIGINT DEFAULT NULL,
    p_wifi_connected BOOLEAN DEFAULT NULL,
    p_bluetooth_enabled BOOLEAN DEFAULT NULL,
    p_location_enabled BOOLEAN DEFAULT NULL,
    p_camera_enabled BOOLEAN DEFAULT NULL,
    p_microphone_enabled BOOLEAN DEFAULT NULL,
    p_usb_debugging BOOLEAN DEFAULT NULL,
    p_developer_options BOOLEAN DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    device_exists BOOLEAN;
BEGIN
    -- ตรวจสอบว่า device มีอยู่หรือไม่
    SELECT EXISTS(SELECT 1 FROM mdm.devices WHERE id = p_device_id) INTO device_exists;
    
    IF NOT device_exists THEN
        RETURN FALSE;
    END IF;
    
    -- อัปเดตสถานะเครื่อง
    INSERT INTO mdm.device_status (
        device_id, battery_level, storage_used, storage_total,
        memory_used, memory_total, wifi_connected, bluetooth_enabled,
        location_enabled, camera_enabled, microphone_enabled,
        usb_debugging, developer_options, last_updated
    ) VALUES (
        p_device_id, p_battery_level, p_storage_used, p_storage_total,
        p_memory_used, p_memory_total, p_wifi_connected, p_bluetooth_enabled,
        p_location_enabled, p_camera_enabled, p_microphone_enabled,
        p_usb_debugging, p_developer_options, NOW()
    ) ON CONFLICT (device_id) DO UPDATE SET
        battery_level = COALESCE(EXCLUDED.battery_level, device_status.battery_level),
        storage_used = COALESCE(EXCLUDED.storage_used, device_status.storage_used),
        storage_total = COALESCE(EXCLUDED.storage_total, device_status.storage_total),
        memory_used = COALESCE(EXCLUDED.memory_used, device_status.memory_used),
        memory_total = COALESCE(EXCLUDED.memory_total, device_status.memory_total),
        wifi_connected = COALESCE(EXCLUDED.wifi_connected, device_status.wifi_connected),
        bluetooth_enabled = COALESCE(EXCLUDED.bluetooth_enabled, device_status.bluetooth_enabled),
        location_enabled = COALESCE(EXCLUDED.location_enabled, device_status.location_enabled),
        camera_enabled = COALESCE(EXCLUDED.camera_enabled, device_status.camera_enabled),
        microphone_enabled = COALESCE(EXCLUDED.microphone_enabled, device_status.microphone_enabled),
        usb_debugging = COALESCE(EXCLUDED.usb_debugging, device_status.usb_debugging),
        developer_options = COALESCE(EXCLUDED.developer_options, device_status.developer_options),
        last_updated = NOW();
    
    -- อัปเดต last_seen ในตาราง devices
    UPDATE mdm.devices SET
        last_seen = NOW(),
        updated_at = NOW()
    WHERE id = p_device_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 6. ฟังก์ชันสร้างคำสั่งใหม่
-- =============================================
CREATE OR REPLACE FUNCTION mdm.create_command(
    p_device_id UUID,
    p_command_type TEXT,
    p_payload JSONB DEFAULT '{}',
    p_issued_by TEXT DEFAULT 'system'
) RETURNS UUID AS $$
DECLARE
    command_uuid UUID;
    device_exists BOOLEAN;
BEGIN
    -- ตรวจสอบว่า device มีอยู่หรือไม่
    SELECT EXISTS(SELECT 1 FROM mdm.devices WHERE id = p_device_id) INTO device_exists;
    
    IF NOT device_exists THEN
        RAISE EXCEPTION 'Device not found: %', p_device_id;
    END IF;
    
    -- สร้างคำสั่งใหม่
    INSERT INTO mdm.commands (device_id, command_type, payload, issued_by)
    VALUES (p_device_id, p_command_type, p_payload, p_issued_by)
    RETURNING id INTO command_uuid;
    
    -- บันทึก log
    INSERT INTO mdm.logs (device_id, level, message, category, metadata)
    VALUES (p_device_id, 'info', 'Command created: ' || p_command_type, 'command', 
            jsonb_build_object('command_id', command_uuid, 'command_type', p_command_type));
    
    RETURN command_uuid;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 7. ฟังก์ชัน Assign Policy ให้เครื่อง
-- =============================================
CREATE OR REPLACE FUNCTION mdm.assign_policy(
    p_device_id UUID,
    p_policy_id UUID,
    p_issued_by TEXT DEFAULT 'system'
) RETURNS BOOLEAN AS $$
DECLARE
    device_exists BOOLEAN;
    policy_exists BOOLEAN;
BEGIN
    -- ตรวจสอบว่า device และ policy มีอยู่หรือไม่
    SELECT EXISTS(SELECT 1 FROM mdm.devices WHERE id = p_device_id) INTO device_exists;
    SELECT EXISTS(SELECT 1 FROM mdm.policies WHERE id = p_policy_id AND is_active = true) INTO policy_exists;
    
    IF NOT device_exists THEN
        RAISE EXCEPTION 'Device not found: %', p_device_id;
    END IF;
    
    IF NOT policy_exists THEN
        RAISE EXCEPTION 'Policy not found or inactive: %', p_policy_id;
    END IF;
    
    -- Assign policy (upsert)
    INSERT INTO mdm.device_policies (device_id, policy_id, status)
    VALUES (p_device_id, p_policy_id, 'pending')
    ON CONFLICT (device_id, policy_id) DO UPDATE SET
        status = 'pending',
        applied_at = NOW(),
        updated_at = NOW();
    
    -- บันทึก log
    INSERT INTO mdm.logs (device_id, level, message, category, metadata)
    VALUES (p_device_id, 'info', 'Policy assigned', 'policy', 
            jsonb_build_object('policy_id', p_policy_id, 'assigned_by', p_issued_by));
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 8. ฟังก์ชันบันทึก Log
-- =============================================
CREATE OR REPLACE FUNCTION mdm.log_event(
    p_device_id UUID,
    p_level TEXT,
    p_message TEXT,
    p_category TEXT DEFAULT 'general',
    p_metadata JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
    log_uuid UUID;
BEGIN
    INSERT INTO mdm.logs (device_id, level, message, category, metadata)
    VALUES (p_device_id, p_level, p_message, p_category, p_metadata)
    RETURNING id INTO log_uuid;
    
    RETURN log_uuid;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 9. ฟังก์ชันดึงสถิติเครื่อง
-- =============================================
CREATE OR REPLACE FUNCTION mdm.get_device_stats()
RETURNS TABLE(
    total_devices BIGINT,
    active_devices BIGINT,
    offline_devices BIGINT,
    locked_devices BIGINT,
    pending_devices BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_devices,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active_devices,
        COUNT(CASE WHEN status = 'offline' THEN 1 END) as offline_devices,
        COUNT(CASE WHEN status = 'locked' THEN 1 END) as locked_devices,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_devices
    FROM mdm.devices;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 10. ฟังก์ชันดึงสถิติคำสั่ง
-- =============================================
CREATE OR REPLACE FUNCTION mdm.get_command_stats(p_hours INTEGER DEFAULT 24)
RETURNS TABLE(
    total_commands BIGINT,
    pending_commands BIGINT,
    executed_commands BIGINT,
    failed_commands BIGINT,
    lock_commands BIGINT,
    wipe_commands BIGINT,
    reboot_commands BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_commands,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_commands,
        COUNT(CASE WHEN status = 'executed' THEN 1 END) as executed_commands,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_commands,
        COUNT(CASE WHEN command_type = 'lock' THEN 1 END) as lock_commands,
        COUNT(CASE WHEN command_type = 'wipe' THEN 1 END) as wipe_commands,
        COUNT(CASE WHEN command_type = 'reboot' THEN 1 END) as reboot_commands
    FROM mdm.commands
    WHERE created_at > NOW() - INTERVAL '1 hour' * p_hours;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 11. ฟังก์ชัน Cleanup ข้อมูลเก่า
-- =============================================
CREATE OR REPLACE FUNCTION mdm.cleanup_old_data(p_days INTEGER DEFAULT 30)
RETURNS TABLE(
    deleted_logs BIGINT,
    deleted_commands BIGINT,
    deleted_audit_logs BIGINT
) AS $$
DECLARE
    logs_count BIGINT;
    commands_count BIGINT;
    audit_count BIGINT;
BEGIN
    -- ลบ logs เก่า
    DELETE FROM mdm.logs 
    WHERE created_at < NOW() - INTERVAL '1 day' * p_days;
    GET DIAGNOSTICS logs_count = ROW_COUNT;
    
    -- ลบ commands ที่เสร็จสิ้นแล้ว
    DELETE FROM mdm.commands 
    WHERE status IN ('executed', 'failed', 'cancelled') 
    AND created_at < NOW() - INTERVAL '1 day' * p_days;
    GET DIAGNOSTICS commands_count = ROW_COUNT;
    
    -- ลบ audit logs เก่า
    DELETE FROM mdm.audit_logs 
    WHERE created_at < NOW() - INTERVAL '1 day' * p_days;
    GET DIAGNOSTICS audit_count = ROW_COUNT;
    
    RETURN QUERY SELECT logs_count, commands_count, audit_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 12. ฟังก์ชันตรวจสอบ Health
-- =============================================
CREATE OR REPLACE FUNCTION mdm.health_check()
RETURNS TABLE(
    status TEXT,
    message TEXT,
    details JSONB
) AS $$
DECLARE
    device_count BIGINT;
    offline_count BIGINT;
    error_count BIGINT;
BEGIN
    -- นับจำนวนเครื่องทั้งหมด
    SELECT COUNT(*) INTO device_count FROM mdm.devices;
    
    -- นับจำนวนเครื่องที่ offline
    SELECT COUNT(*) INTO offline_count 
    FROM mdm.devices 
    WHERE last_seen < NOW() - INTERVAL '1 hour';
    
    -- นับจำนวน error logs ใน 1 ชั่วโมงที่ผ่านมา
    SELECT COUNT(*) INTO error_count 
    FROM mdm.logs 
    WHERE level = 'error' 
    AND created_at > NOW() - INTERVAL '1 hour';
    
    -- กำหนดสถานะ
    IF error_count > 10 THEN
        RETURN QUERY SELECT 'error'::TEXT, 'High error rate detected'::TEXT, 
                    jsonb_build_object('device_count', device_count, 'offline_count', offline_count, 'error_count', error_count);
    ELSIF offline_count > device_count * 0.5 THEN
        RETURN QUERY SELECT 'warning'::TEXT, 'High offline device count'::TEXT, 
                    jsonb_build_object('device_count', device_count, 'offline_count', offline_count, 'error_count', error_count);
    ELSE
        RETURN QUERY SELECT 'healthy'::TEXT, 'System is healthy'::TEXT, 
                    jsonb_build_object('device_count', device_count, 'offline_count', offline_count, 'error_count', error_count);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 13. Grant Permissions สำหรับ Functions
-- =============================================

-- Grant execute permissions to service role
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA mdm TO service_role;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION mdm.get_device_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION mdm.get_command_stats(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION mdm.health_check() TO authenticated;

-- =============================================
-- Functions Creation Complete
-- =============================================

-- ข้อมูลสรุป
SELECT 
    'GSE-MDM Functions Created Successfully' as status,
    COUNT(*) as function_count
FROM information_schema.routines 
WHERE routine_schema = 'mdm' 
AND routine_type = 'FUNCTION';
