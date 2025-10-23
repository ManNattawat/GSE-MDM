-- =============================================
-- GSE-MDM Schema v2.0 (ไม่มี Policies)
-- แนวคิด: เก็บ config ไว้ที่อุปกรณ์โดยตรง
-- =============================================

-- =============================================
-- 1. Schema และ Extensions
-- =============================================

CREATE SCHEMA IF NOT EXISTS mdm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 2. ตาราง devices (เก็บ config ด้วย)
-- =============================================

CREATE TABLE mdm.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id TEXT UNIQUE NOT NULL,                    -- Device ID ที่ unique
    serial_number TEXT,                                -- Serial number ของเครื่อง
    branch_code TEXT NOT NULL,                         -- รหัสสาขา
    assigned_user TEXT,                                -- ผู้ใช้ที่ได้รับมอบหมาย
    model TEXT,                                        -- รุ่นเครื่อง (Galaxy Tab S9, etc.)
    android_version TEXT,                              -- เวอร์ชัน Android
    agent_version TEXT,                                -- เวอร์ชัน MDM Agent
    
    -- 🆕 Device Configuration (เดิมอยู่ใน policies)
    config JSONB NOT NULL DEFAULT '{
        "allowlist": ["com.gse.mdm"],
        "disable_screenshot": false,
        "disable_usb": false,
        "disable_install": false,
        "disable_camera": false,
        "disable_bluetooth": false,
        "kiosk_mode": false
    }'::jsonb,
    
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'offline', 'locked', 'wiped', 'error')),
    last_seen TIMESTAMPTZ,                             -- ออนไลน์ล่าสุด
    registered_at TIMESTAMPTZ DEFAULT NOW(),           -- วันที่ลงทะเบียน
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- สร้าง Index สำหรับ performance
CREATE INDEX idx_devices_device_id ON mdm.devices(device_id);
CREATE INDEX idx_devices_branch_code ON mdm.devices(branch_code);
CREATE INDEX idx_devices_status ON mdm.devices(status);
CREATE INDEX idx_devices_last_seen ON mdm.devices(last_seen);
CREATE INDEX idx_devices_config ON mdm.devices USING GIN (config);

-- =============================================
-- 3. ตาราง device_status (Real-time status)
-- =============================================

CREATE TABLE mdm.device_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES mdm.devices(id) ON DELETE CASCADE,
    battery_level INTEGER,                             -- % แบตเตอรี่
    storage_used BIGINT,                               -- พื้นที่ใช้ไป (bytes)
    storage_total BIGINT,                              -- พื้นที่ทั้งหมด (bytes)
    wifi_connected BOOLEAN,                            -- เชื่อมต่อ WiFi หรือไม่
    bluetooth_enabled BOOLEAN,                         -- เปิด Bluetooth หรือไม่
    location_enabled BOOLEAN,                          -- เปิด GPS หรือไม่
    camera_enabled BOOLEAN,                            -- เปิดกล้องหรือไม่
    microphone_enabled BOOLEAN,                        -- เปิดไมค์หรือไม่
    usb_debugging BOOLEAN,                             -- เปิด USB Debugging หรือไม่
    developer_options BOOLEAN,                         -- เปิด Developer Options หรือไม่
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(device_id)
);

CREATE INDEX idx_device_status_device_id ON mdm.device_status(device_id);

-- =============================================
-- 4. ตาราง provisioning_tokens (สำหรับ QR Code)
-- =============================================

CREATE TABLE mdm.provisioning_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token TEXT UNIQUE NOT NULL,                            -- Token ที่ encode ใน QR
    branch_code TEXT NOT NULL,                             -- รหัสสาขา
    
    -- 🆕 Config ที่จะ apply ให้อุปกรณ์ (ไม่ใช้ policy_id แล้ว)
    config JSONB NOT NULL DEFAULT '{
        "allowlist": ["com.gse.mdm"],
        "disable_screenshot": false,
        "disable_usb": false,
        "disable_install": false,
        "disable_camera": false,
        "disable_bluetooth": false,
        "kiosk_mode": false
    }'::jsonb,
    
    expires_at TIMESTAMPTZ NOT NULL,                       -- วันหมดอายุ
    used BOOLEAN DEFAULT FALSE,                            -- ใช้แล้วหรือยัง
    used_at TIMESTAMPTZ,                                   -- วันที่ใช้
    created_by TEXT,                                       -- ผู้สร้าง
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_provisioning_tokens_token ON mdm.provisioning_tokens(token);
CREATE INDEX idx_provisioning_tokens_branch_code ON mdm.provisioning_tokens(branch_code);
CREATE INDEX idx_provisioning_tokens_expires_at ON mdm.provisioning_tokens(expires_at);
CREATE INDEX idx_provisioning_tokens_used ON mdm.provisioning_tokens(used);

-- =============================================
-- 5. ตาราง device_enrollments (บันทึกการลงทะเบียน)
-- =============================================

CREATE TABLE mdm.device_enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id TEXT NOT NULL,                               -- Device UUID จาก agent
    serial_number TEXT,                                    -- Serial number
    branch_code TEXT NOT NULL,                             -- รหัสสาขา
    
    -- 🆕 Config ที่ใช้ตอนลงทะเบียน (เก็บไว้เพื่อ audit)
    config JSONB NOT NULL,
    
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'rejected', 'expired')),
    registered_at TIMESTAMPTZ DEFAULT NOW(),               -- วันที่ลงทะเบียน
    approved_at TIMESTAMPTZ,                               -- วันที่อนุมัติ
    approved_by TEXT,                                      -- ผู้อนุมัติ
    provisioning_token_id UUID REFERENCES mdm.provisioning_tokens(id),
    metadata JSONB,                                        -- ข้อมูลเพิ่มเติม
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_device_enrollments_device_id ON mdm.device_enrollments(device_id);
CREATE INDEX idx_device_enrollments_branch_code ON mdm.device_enrollments(branch_code);
CREATE INDEX idx_device_enrollments_status ON mdm.device_enrollments(status);
CREATE INDEX idx_device_enrollments_provisioning_token ON mdm.device_enrollments(provisioning_token_id);

-- =============================================
-- 6. ตาราง commands (คำสั่งระยะไกล)
-- =============================================

CREATE TABLE mdm.commands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES mdm.devices(id) ON DELETE CASCADE,
    command_type TEXT NOT NULL CHECK (command_type IN ('lock', 'unlock', 'reboot', 'wipe', 'update_config', 'status_check')),
    
    -- 🆕 สำหรับ update_config ใช้ payload เก็บ config ใหม่
    payload JSONB,                                         -- ข้อมูลเพิ่มเติมของคำสั่ง
    
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'executed', 'failed')),
    created_by TEXT,                                       -- ผู้สร้างคำสั่ง
    created_at TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ,                                   -- วันที่ส่งคำสั่ง
    executed_at TIMESTAMPTZ,                               -- วันที่ execute
    result JSONB,                                          -- ผลลัพธ์
    error_message TEXT                                     -- ข้อความ error (ถ้ามี)
);

CREATE INDEX idx_commands_device_id ON mdm.commands(device_id);
CREATE INDEX idx_commands_status ON mdm.commands(status);
CREATE INDEX idx_commands_created_at ON mdm.commands(created_at);

-- =============================================
-- 7. ตาราง logs (บันทึกการทำงาน)
-- =============================================

CREATE TABLE mdm.logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES mdm.devices(id) ON DELETE CASCADE,
    level TEXT NOT NULL CHECK (level IN ('debug', 'info', 'warning', 'error', 'critical')),
    category TEXT NOT NULL,                                -- หมวดหมู่ log (device_status, policy, command, sync, error)
    message TEXT NOT NULL,
    metadata JSONB,                                        -- ข้อมูลเพิ่มเติม
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_logs_device_id ON mdm.logs(device_id);
CREATE INDEX idx_logs_level ON mdm.logs(level);
CREATE INDEX idx_logs_category ON mdm.logs(category);
CREATE INDEX idx_logs_created_at ON mdm.logs(created_at);

-- =============================================
-- 8. ตาราง audit_logs (บันทึกการตรวจสอบ)
-- =============================================

CREATE TABLE mdm.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT,                                          -- ผู้ใช้ที่ทำการเปลี่ยนแปลง
    action TEXT NOT NULL,                                  -- การกระทำ (create, update, delete, execute)
    resource_type TEXT NOT NULL,                           -- ประเภททรัพยากร (device, command, config)
    resource_id TEXT,                                      -- ID ของทรัพยากร
    changes JSONB,                                         -- การเปลี่ยนแปลง (before/after)
    ip_address TEXT,                                       -- IP address
    user_agent TEXT,                                       -- User agent
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON mdm.audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource_type ON mdm.audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON mdm.audit_logs(created_at);

-- =============================================
-- 9. ตาราง app_versions (เวอร์ชันแอปพลิเคชัน)
-- =============================================

CREATE TABLE mdm.app_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    app_name TEXT NOT NULL,                                -- ชื่อแอป
    version TEXT NOT NULL,                                 -- เวอร์ชัน (e.g., 1.0.0)
    version_code INTEGER NOT NULL,                         -- Version code (e.g., 1)
    download_url TEXT NOT NULL,                            -- URL สำหรับดาวน์โหลด
    file_size BIGINT,                                      -- ขนาดไฟล์ (bytes)
    checksum TEXT,                                         -- Checksum สำหรับตรวจสอบ
    release_notes TEXT,                                    -- Release notes
    is_mandatory BOOLEAN DEFAULT FALSE,                    -- บังคับอัปเดตหรือไม่
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(app_name, version)
);

CREATE INDEX idx_app_versions_app_name ON mdm.app_versions(app_name);

-- =============================================
-- 10. 🆕 ตาราง config_templates (Template Preset)
-- =============================================

CREATE TABLE mdm.config_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,                                    -- ชื่อ template (เช่น "Kiosk Mode สำหรับสาขา")
    description TEXT,                                      -- คำอธิบาย
    config JSONB NOT NULL,                                 -- Config ที่จะใช้
    is_default BOOLEAN DEFAULT FALSE,                      -- เป็น template เริ่มต้นหรือไม่
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_config_templates_name ON mdm.config_templates(name);

-- =============================================
-- 11. Functions
-- =============================================

-- Function สำหรับสร้าง provisioning token
CREATE OR REPLACE FUNCTION mdm.create_provisioning_token(
    p_branch_code TEXT,
    p_config JSONB,
    p_expires_in_hours INTEGER DEFAULT 168
)
RETURNS TABLE (
    token TEXT,
    expires_at TIMESTAMPTZ
) AS $$
DECLARE
    v_token TEXT;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- สร้าง token แบบสุ่ม
    v_token := encode(gen_random_bytes(32), 'base64');
    v_expires_at := NOW() + (p_expires_in_hours || ' hours')::INTERVAL;
    
    -- Insert token
    INSERT INTO mdm.provisioning_tokens (token, branch_code, config, expires_at, created_by)
    VALUES (v_token, p_branch_code, p_config, v_expires_at, current_user)
    RETURNING provisioning_tokens.token, provisioning_tokens.expires_at
    INTO token, expires_at;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Function สำหรับอัปเดต device config
CREATE OR REPLACE FUNCTION mdm.update_device_config(
    p_device_id UUID,
    p_config JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE mdm.devices
    SET config = p_config,
        updated_at = NOW()
    WHERE id = p_device_id;
    
    -- Log การเปลี่ยนแปลง
    INSERT INTO mdm.audit_logs (action, resource_type, resource_id, changes)
    VALUES ('update', 'device_config', p_device_id::TEXT, jsonb_build_object('new_config', p_config));
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function สำหรับ auto-update updated_at
CREATE OR REPLACE FUNCTION mdm.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger สำหรับ devices
CREATE TRIGGER update_devices_updated_at
    BEFORE UPDATE ON mdm.devices
    FOR EACH ROW
    EXECUTE FUNCTION mdm.update_updated_at_column();

-- Trigger สำหรับ config_templates
CREATE TRIGGER update_config_templates_updated_at
    BEFORE UPDATE ON mdm.config_templates
    FOR EACH ROW
    EXECUTE FUNCTION mdm.update_updated_at_column();

-- =============================================
-- 12. Views สำหรับ Dashboard
-- =============================================

-- View: device_summary (รวมข้อมูลอุปกรณ์ + สถานะ + สาขา)
CREATE OR REPLACE VIEW public.device_summary AS
SELECT 
    d.id,
    d.device_id,
    d.serial_number,
    d.branch_code,
    b.name as branch_name,
    b.province as branch_province,
    b.region as branch_region,
    d.assigned_user,
    d.model,
    d.android_version,
    d.agent_version,
    d.config,                                              -- 🆕 แสดง config
    d.status,
    d.last_seen,
    d.registered_at,
    ds.battery_level,
    ds.storage_used,
    ds.storage_total,
    ds.wifi_connected,
    ds.bluetooth_enabled,
    ds.location_enabled,
    ds.camera_enabled,
    ds.microphone_enabled,
    ds.usb_debugging,
    ds.developer_options,
    ds.last_updated,
    CASE 
        WHEN d.last_seen > NOW() - INTERVAL '5 minutes' THEN 'online'
        WHEN d.last_seen > NOW() - INTERVAL '1 hour' THEN 'recent'
        ELSE 'offline'
    END as connection_status
FROM mdm.devices d
LEFT JOIN mdm.device_status ds ON d.id = ds.device_id
LEFT JOIN company.branches b ON b.code = d.branch_code;

-- View: commands (สำหรับ Dashboard)
CREATE OR REPLACE VIEW public.commands AS
SELECT 
    c.id,
    c.device_id,
    d.device_id as device_identifier,
    d.branch_code,
    c.command_type,
    c.payload,
    c.status,
    c.created_by,
    c.created_at,
    c.sent_at,
    c.executed_at,
    c.result,
    c.error_message
FROM mdm.commands c
LEFT JOIN mdm.devices d ON c.device_id = d.id;

-- View: logs (สำหรับ Dashboard)
CREATE OR REPLACE VIEW public.logs AS
SELECT 
    l.id,
    l.device_id,
    d.device_id as device_identifier,
    d.branch_code,
    l.level,
    l.category,
    l.message,
    l.metadata,
    l.created_at
FROM mdm.logs l
LEFT JOIN mdm.devices d ON l.device_id = d.id;

-- View: provisioning_tokens (สำหรับ Dashboard)
CREATE OR REPLACE VIEW public.provisioning_tokens AS
SELECT 
    id,
    token,
    branch_code,
    config,                                                -- 🆕 แสดง config
    expires_at,
    used,
    used_at,
    created_by,
    created_at
FROM mdm.provisioning_tokens;

-- View: config_templates (สำหรับ Dashboard)
CREATE OR REPLACE VIEW public.config_templates AS
SELECT 
    id,
    name,
    description,
    config,
    is_default,
    created_by,
    created_at,
    updated_at
FROM mdm.config_templates;

-- =============================================
-- 13. Grant Permissions
-- =============================================

GRANT USAGE ON SCHEMA mdm TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA mdm TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA mdm TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated, anon;

-- =============================================
-- 14. Sample Config Templates
-- =============================================

INSERT INTO mdm.config_templates (name, description, config, is_default) VALUES
('ค่าเริ่มต้น', 'การตั้งค่าพื้นฐานสำหรับอุปกรณ์ทั่วไป', 
 '{"allowlist": ["com.gse.mdm"], "disable_screenshot": false, "disable_usb": false, "disable_install": false, "disable_camera": false, "disable_bluetooth": false, "kiosk_mode": false}'::jsonb, 
 true),
('Kiosk Mode สำหรับสาขา', 'ล็อคอุปกรณ์ให้ใช้เฉพาะแอปที่กำหนด', 
 '{"allowlist": ["com.gse.mdm", "jp.naver.line.android"], "disable_screenshot": true, "disable_usb": true, "disable_install": true, "disable_camera": false, "disable_bluetooth": false, "kiosk_mode": true}'::jsonb, 
 false),
('ความปลอดภัยสูง', 'สำหรับอุปกรณ์ที่มีข้อมูลสำคัญ', 
 '{"allowlist": ["com.gse.mdm"], "disable_screenshot": true, "disable_usb": true, "disable_install": true, "disable_camera": true, "disable_bluetooth": true, "kiosk_mode": true}'::jsonb, 
 false);

-- =============================================
-- 15. Sample App Version
-- =============================================

INSERT INTO mdm.app_versions (app_name, version, version_code, download_url, file_size, checksum, release_notes, created_by) VALUES
('GSE-MDM-Agent', '1.0.0', 1, 'https://example.com/agent-v1.0.0.apk', 10485760, 'sha256:abc123...', 'Initial release', 'system')
ON CONFLICT DO NOTHING;

-- =============================================
-- 16. Comments
-- =============================================

COMMENT ON SCHEMA mdm IS 'Schema สำหรับระบบ Mobile Device Management (MDM) v2.0';
COMMENT ON TABLE mdm.devices IS 'ตารางเก็บข้อมูลอุปกรณ์ + config (ไม่ใช้ policies แล้ว)';
COMMENT ON TABLE mdm.provisioning_tokens IS 'ตารางเก็บ token สำหรับ QR Code + config';
COMMENT ON TABLE mdm.config_templates IS 'ตารางเก็บ template preset สำหรับโหลดค่ามาตรฐาน';
COMMENT ON TABLE mdm.commands IS 'ตารางเก็บคำสั่งระยะไกล (รวม update_config)';
COMMENT ON TABLE mdm.logs IS 'ตารางบันทึกการทำงาน';
COMMENT ON TABLE mdm.device_status IS 'ตารางสถานะอุปกรณ์แบบ real-time';
COMMENT ON TABLE mdm.audit_logs IS 'ตารางบันทึกการตรวจสอบ';
COMMENT ON TABLE mdm.app_versions IS 'ตารางเวอร์ชันแอปพลิเคชัน';
