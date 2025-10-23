-- GSE-MDM Database Schema
-- สร้าง Schema สำหรับระบบ Mobile Device Management

-- สร้าง Schema mdm
CREATE SCHEMA IF NOT EXISTS mdm;

-- เปิดใช้งาน UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. ตาราง devices (เครื่อง Tablet)
-- =============================================
CREATE TABLE mdm.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id TEXT UNIQUE NOT NULL,                    -- Device ID ที่ unique
    serial_number TEXT,                                -- Serial number ของเครื่อง
    branch_code TEXT NOT NULL,                         -- รหัสสาขา
    assigned_user TEXT,                                -- ผู้ใช้ที่ได้รับมอบหมาย
    model TEXT,                                        -- รุ่นเครื่อง (Galaxy Tab S9, etc.)
    android_version TEXT,                              -- เวอร์ชัน Android
    agent_version TEXT,                                -- เวอร์ชัน Agent App
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'offline', 'locked', 'wiped', 'error')),
    last_seen TIMESTAMPTZ,                             -- ครั้งล่าสุดที่ติดต่อ
    registered_at TIMESTAMPTZ DEFAULT NOW(),           -- วันที่ลงทะเบียน
    metadata JSONB DEFAULT '{}',                       -- ข้อมูลเพิ่มเติม
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- สร้าง Index สำหรับ performance
CREATE INDEX idx_devices_device_id ON mdm.devices(device_id);
CREATE INDEX idx_devices_branch_code ON mdm.devices(branch_code);
CREATE INDEX idx_devices_status ON mdm.devices(status);
CREATE INDEX idx_devices_last_seen ON mdm.devices(last_seen);

-- =============================================
-- 4. ตาราง policies (นโยบาย)
-- =============================================
CREATE TABLE mdm.policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,                                -- ชื่อนโยบาย
    description TEXT,                                  -- คำอธิบาย
    config JSONB NOT NULL DEFAULT '{}',               -- การตั้งค่านโยบาย
    is_active BOOLEAN DEFAULT true,                    -- สถานะใช้งาน
    created_by TEXT,                                   -- ผู้สร้าง
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ตัวอย่าง config structure:
-- {
--   "allowlist": ["com.gse.pwa", "jp.naver.line.android"],
--   "kiosk_mode": true,
--   "disable_screenshot": true,
--   "disable_usb": true,
--   "disable_install": true,
--   "restrict_settings": true,
--   "lock_screen_timeout": 300,
--   "wifi_restrictions": true,
--   "bluetooth_restrictions": true
-- }

CREATE INDEX idx_policies_name ON mdm.policies(name);
CREATE INDEX idx_policies_is_active ON mdm.policies(is_active);

-- =============================================
-- 2. ตาราง provisioning_tokens (QR Tokens สำหรับลงทะเบียน)
-- =============================================
CREATE TABLE mdm.provisioning_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token TEXT UNIQUE NOT NULL,                            -- Token ที่ encode ใน QR
    branch_code TEXT NOT NULL,                             -- รหัสสาขา
    policy_id UUID REFERENCES mdm.policies(id),            -- นโยบายเริ่มต้น
    expires_at TIMESTAMPTZ NOT NULL,                       -- วันหมดอายุ
    used BOOLEAN DEFAULT FALSE,                            -- ใช้แล้วหรือยัง
    created_by TEXT,                                       -- ผู้สร้าง
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_provisioning_tokens_token ON mdm.provisioning_tokens(token);
CREATE INDEX idx_provisioning_tokens_branch_code ON mdm.provisioning_tokens(branch_code);
CREATE INDEX idx_provisioning_tokens_expires_at ON mdm.provisioning_tokens(expires_at);
CREATE INDEX idx_provisioning_tokens_used ON mdm.provisioning_tokens(used);

-- =============================================
-- 3. ตาราง device_enrollments (การลงทะเบียนเครื่อง)
-- =============================================
CREATE TABLE mdm.device_enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id TEXT NOT NULL,                               -- Device UUID จาก agent
    serial_number TEXT,                                    -- Serial number
    branch_code TEXT NOT NULL,                             -- รหัสสาขา
    policy_id UUID REFERENCES mdm.policies(id),            -- นโยบายที่ apply
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'rejected', 'expired')),
    registered_at TIMESTAMPTZ DEFAULT NOW(),               -- วันที่ลงทะเบียน
    last_seen_at TIMESTAMPTZ,                              -- ครั้งล่าสุดที่ติดต่อ
    provisioning_token_id UUID REFERENCES mdm.provisioning_tokens(id),
    error_message TEXT,                                    -- ข้อความ error (ถ้ามี)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_device_enrollments_device_id ON mdm.device_enrollments(device_id);
CREATE INDEX idx_device_enrollments_branch_code ON mdm.device_enrollments(branch_code);
CREATE INDEX idx_device_enrollments_status ON mdm.device_enrollments(status);
CREATE INDEX idx_device_enrollments_provisioning_token ON mdm.device_enrollments(provisioning_token_id);

-- =============================================
-- 3. ตาราง device_policies (ผูกเครื่องกับนโยบาย)
-- =============================================
CREATE TABLE mdm.device_policies (
    device_id UUID REFERENCES mdm.devices(id) ON DELETE CASCADE,
    policy_id UUID REFERENCES mdm.policies(id) ON DELETE CASCADE,
    applied_at TIMESTAMPTZ DEFAULT NOW(),              -- วันที่ใช้
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'applied', 'failed', 'reverted')),
    error_message TEXT,                                -- ข้อความ error (ถ้ามี)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (device_id, policy_id)
);

CREATE INDEX idx_device_policies_device_id ON mdm.device_policies(device_id);
CREATE INDEX idx_device_policies_policy_id ON mdm.device_policies(policy_id);
CREATE INDEX idx_device_policies_status ON mdm.device_policies(status);

-- =============================================
-- 4. ตาราง commands (คำสั่งระยะไกล)
-- =============================================
CREATE TABLE mdm.commands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES mdm.devices(id) ON DELETE CASCADE,
    command_type TEXT NOT NULL CHECK (command_type IN ('lock', 'unlock', 'wipe', 'reboot', 'update', 'policy_update', 'status_check')),
    payload JSONB DEFAULT '{}',                        -- ข้อมูลคำสั่ง
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'executed', 'failed', 'cancelled')),
    issued_by TEXT NOT NULL,                           -- ผู้สั่งงาน
    issued_at TIMESTAMPTZ DEFAULT NOW(),               -- วันที่สั่ง
    sent_at TIMESTAMPTZ,                               -- วันที่ส่ง
    executed_at TIMESTAMPTZ,                           -- วันที่ทำ
    result JSONB DEFAULT '{}',                         -- ผลลัพธ์
    error_message TEXT,                                -- ข้อความ error
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_commands_device_id ON mdm.commands(device_id);
CREATE INDEX idx_commands_command_type ON mdm.commands(command_type);
CREATE INDEX idx_commands_status ON mdm.commands(status);
CREATE INDEX idx_commands_issued_at ON mdm.commands(issued_at);

-- =============================================
-- 5. ตาราง logs (บันทึกการทำงาน)
-- =============================================
CREATE TABLE mdm.logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES mdm.devices(id) ON DELETE CASCADE,
    level TEXT NOT NULL CHECK (level IN ('debug', 'info', 'warning', 'error', 'critical')),
    message TEXT NOT NULL,                             -- ข้อความ log
    category TEXT,                                     -- หมวดหมู่ (policy, command, sync, error)
    metadata JSONB DEFAULT '{}',                      -- ข้อมูลเพิ่มเติม
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_logs_device_id ON mdm.logs(device_id);
CREATE INDEX idx_logs_level ON mdm.logs(level);
CREATE INDEX idx_logs_category ON mdm.logs(category);
CREATE INDEX idx_logs_created_at ON mdm.logs(created_at);

-- =============================================
-- 6. ตาราง device_status (สถานะเครื่อง)
-- =============================================
CREATE TABLE mdm.device_status (
    device_id UUID PRIMARY KEY REFERENCES mdm.devices(id) ON DELETE CASCADE,
    battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
    storage_used BIGINT,                               -- พื้นที่ใช้ (bytes)
    storage_total BIGINT,                              -- พื้นที่ทั้งหมด (bytes)
    memory_used BIGINT,                                -- RAM ใช้ (bytes)
    memory_total BIGINT,                               -- RAM ทั้งหมด (bytes)
    wifi_connected BOOLEAN DEFAULT false,
    bluetooth_enabled BOOLEAN DEFAULT false,
    location_enabled BOOLEAN DEFAULT false,
    camera_enabled BOOLEAN DEFAULT false,
    microphone_enabled BOOLEAN DEFAULT false,
    usb_debugging BOOLEAN DEFAULT false,
    developer_options BOOLEAN DEFAULT false,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 7. ตาราง audit_logs (บันทึกการตรวจสอบ)
-- =============================================
CREATE TABLE mdm.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,                             -- ผู้ทำการ
    action TEXT NOT NULL,                              -- การกระทำ
    resource_type TEXT,                                -- ประเภททรัพยากร
    resource_id UUID,                                  -- ID ของทรัพยากร
    old_values JSONB,                                  -- ค่าเดิม
    new_values JSONB,                                  -- ค่าใหม่
    ip_address INET,                                   -- IP address
    user_agent TEXT,                                   -- User agent
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON mdm.audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON mdm.audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON mdm.audit_logs(created_at);

-- =============================================
-- 8. ตาราง app_versions (เวอร์ชันแอป)
-- =============================================
CREATE TABLE mdm.app_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    app_name TEXT NOT NULL,                            -- ชื่อแอป
    version TEXT NOT NULL,                             -- เวอร์ชัน
    version_code INTEGER,                              -- Version code
    download_url TEXT,                                 -- URL ดาวน์โหลด
    file_size BIGINT,                                  -- ขนาดไฟล์
    checksum TEXT,                                     -- Checksum
    is_active BOOLEAN DEFAULT true,                    -- สถานะใช้งาน
    release_notes TEXT,                                -- หมายเหตุการอัปเดต
    created_by TEXT,                                   -- ผู้สร้าง
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_app_versions_app_name ON mdm.app_versions(app_name);
CREATE INDEX idx_app_versions_is_active ON mdm.app_versions(is_active);

-- =============================================
-- 9. Functions สำหรับอัปเดต updated_at
-- =============================================
CREATE OR REPLACE FUNCTION mdm.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- สร้าง Triggers สำหรับอัปเดต updated_at
CREATE TRIGGER update_device_enrollments_updated_at BEFORE UPDATE ON mdm.device_enrollments
    FOR EACH ROW EXECUTE FUNCTION mdm.update_updated_at_column();

CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON mdm.devices
    FOR EACH ROW EXECUTE FUNCTION mdm.update_updated_at_column();

CREATE TRIGGER update_policies_updated_at BEFORE UPDATE ON mdm.policies
    FOR EACH ROW EXECUTE FUNCTION mdm.update_updated_at_column();

CREATE TRIGGER update_device_policies_updated_at BEFORE UPDATE ON mdm.device_policies
    FOR EACH ROW EXECUTE FUNCTION mdm.update_updated_at_column();

CREATE TRIGGER update_commands_updated_at BEFORE UPDATE ON mdm.commands
    FOR EACH ROW EXECUTE FUNCTION mdm.update_updated_at_column();

-- =============================================
-- 10. RLS (Row Level Security) Policies
-- =============================================

-- เปิด RLS สำหรับทุกตาราง
ALTER TABLE mdm.provisioning_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.device_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.device_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.device_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm.app_versions ENABLE ROW LEVEL SECURITY;

-- Policy สำหรับ Service Role (Agent App)
CREATE POLICY "Service role can manage all data" ON mdm.provisioning_tokens
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.device_enrollments
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.devices
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.policies
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.device_policies
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.commands
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.logs
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.device_status
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.audit_logs
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON mdm.app_versions
    FOR ALL USING (auth.role() = 'service_role');

-- Policy สำหรับ Authenticated Users (Dashboard)
CREATE POLICY "Authenticated users can view all data" ON mdm.provisioning_tokens
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.device_enrollments
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.devices
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.policies
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.device_policies
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.commands
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.logs
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.device_status
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.audit_logs
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view all data" ON mdm.app_versions
    FOR SELECT USING (auth.role() = 'authenticated');

-- =============================================
-- 11. Views สำหรับ Dashboard (ทั้งหมดอยู่ใน public schema)
-- =============================================

-- View สำหรับ Device Summary
CREATE OR REPLACE VIEW public.device_summary AS
SELECT 
    d.id,
    d.device_id,
    d.serial_number,
    d.branch_code,
    d.assigned_user,
    d.model,
    d.android_version,
    d.agent_version,
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
LEFT JOIN mdm.device_status ds ON d.id = ds.device_id;

-- View สำหรับ Policy Summary
CREATE OR REPLACE VIEW public.policy_summary AS
SELECT 
    p.id,
    p.name,
    p.description,
    p.is_active,
    p.created_at,
    COUNT(dp.device_id) as device_count,
    COUNT(CASE WHEN dp.status = 'applied' THEN 1 END) as applied_count,
    COUNT(CASE WHEN dp.status = 'failed' THEN 1 END) as failed_count
FROM mdm.policies p
LEFT JOIN mdm.device_policies dp ON p.id = dp.policy_id
GROUP BY p.id, p.name, p.description, p.is_active, p.created_at;

-- View สำหรับ Policies (read-only access)
CREATE OR REPLACE VIEW public.policies AS
SELECT * FROM mdm.policies;

-- View สำหรับ Commands (read-only access)
CREATE OR REPLACE VIEW public.commands AS
SELECT * FROM mdm.commands;

-- View สำหรับ Logs (read-only access)
CREATE OR REPLACE VIEW public.logs AS
SELECT * FROM mdm.logs;

-- View สำหรับ Provisioning Tokens (read-only access)
CREATE OR REPLACE VIEW public.provisioning_tokens AS
SELECT * FROM mdm.provisioning_tokens;

-- Grant permissions for all public views
GRANT SELECT ON public.device_summary TO authenticated;
GRANT SELECT ON public.device_summary TO anon;
GRANT SELECT ON public.policy_summary TO authenticated;
GRANT SELECT ON public.policy_summary TO anon;
GRANT SELECT ON public.policies TO authenticated;
GRANT SELECT ON public.policies TO anon;
GRANT SELECT ON public.commands TO authenticated;
GRANT SELECT ON public.commands TO anon;
GRANT SELECT ON public.logs TO authenticated;
GRANT SELECT ON public.logs TO anon;
GRANT SELECT ON public.provisioning_tokens TO authenticated;
GRANT SELECT ON public.provisioning_tokens TO anon;

-- =============================================
-- 12. Sample Data (สำหรับ Testing)
-- =============================================

-- หมายเหตุ: ไม่ต้องใส่ sample policies เพราะใช้ Policy Builder สร้างเอง

-- Insert sample app version
INSERT INTO mdm.app_versions (app_name, version, version_code, download_url, file_size, checksum, release_notes, created_by) VALUES
('GSE-MDM-Agent', '1.0.0', 1, 'https://example.com/agent-v1.0.0.apk', 10485760, 'sha256:abc123...', 'Initial release', 'system')
ON CONFLICT DO NOTHING;

-- =============================================
-- 13. Comments และ Documentation
-- =============================================

COMMENT ON SCHEMA mdm IS 'Schema สำหรับระบบ Mobile Device Management (MDM)';
COMMENT ON TABLE mdm.devices IS 'ตารางเก็บข้อมูลเครื่อง Tablet';
COMMENT ON TABLE mdm.policies IS 'ตารางเก็บนโยบายการควบคุมเครื่อง';
COMMENT ON TABLE mdm.device_policies IS 'ตารางผูกเครื่องกับนโยบาย';
COMMENT ON TABLE mdm.commands IS 'ตารางเก็บคำสั่งระยะไกล';
COMMENT ON TABLE mdm.logs IS 'ตารางบันทึกการทำงาน';
COMMENT ON TABLE mdm.device_status IS 'ตารางสถานะเครื่องแบบ real-time';
COMMENT ON TABLE mdm.audit_logs IS 'ตารางบันทึกการตรวจสอบ';
COMMENT ON TABLE mdm.app_versions IS 'ตารางเวอร์ชันแอปพลิเคชัน';

-- =============================================
-- 14. Grant Permissions
-- =============================================

-- Grant permissions to authenticated users
GRANT USAGE ON SCHEMA mdm TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA mdm TO authenticated;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA mdm TO authenticated;

-- Grant permissions to service role
GRANT ALL ON SCHEMA mdm TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA mdm TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA mdm TO service_role;

-- =============================================
-- Schema Creation Complete
-- =============================================

-- ข้อมูลสรุป
SELECT 
    'GSE-MDM Schema Created Successfully' as status,
    COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'mdm';
