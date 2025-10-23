-- =============================================
-- Script สำหรับ Expose ตาราง MDM ผ่าน Public Schema
-- เพื่อให้ Dashboard เข้าถึงได้ผ่าน Supabase REST API
-- =============================================
-- 
-- หมายเหตุ: Views ทั้งหมดควรอยู่ใน public schema เพื่อให้
-- Supabase REST API เข้าถึงได้โดยตรง ไม่ต้องระบุ schema prefix
-- =============================================

-- 1. Device Summary View (with device status)
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

-- 2. Policy Summary View (with statistics)
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

-- 3. Policies View (direct table access)
CREATE OR REPLACE VIEW public.policies AS
SELECT * FROM mdm.policies;

-- 4. Commands View (direct table access)
CREATE OR REPLACE VIEW public.commands AS
SELECT * FROM mdm.commands;

-- 5. Logs View (direct table access)
CREATE OR REPLACE VIEW public.logs AS
SELECT * FROM mdm.logs;

-- 6. Provisioning Tokens View (direct table access)
CREATE OR REPLACE VIEW public.provisioning_tokens AS
SELECT * FROM mdm.provisioning_tokens;

-- 7. Grant SELECT permissions to authenticated and anonymous users
GRANT SELECT ON public.device_summary TO authenticated, anon;
GRANT SELECT ON public.policy_summary TO authenticated, anon;
GRANT SELECT ON public.policies TO authenticated, anon;
GRANT SELECT ON public.commands TO authenticated, anon;
GRANT SELECT ON public.logs TO authenticated, anon;
GRANT SELECT ON public.provisioning_tokens TO authenticated, anon;

-- 8. ตรวจสอบว่า views ถูกสร้างแล้ว
SELECT 
    schemaname,
    viewname,
    viewowner
FROM pg_views
WHERE schemaname = 'public'
    AND viewname IN ('device_summary', 'policy_summary', 'policies', 'commands', 'logs', 'provisioning_tokens')
ORDER BY viewname;
