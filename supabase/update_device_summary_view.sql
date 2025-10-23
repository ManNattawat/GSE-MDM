-- =============================================
-- Script สำหรับอัปเดต device_summary view
-- เพิ่มคอลัมน์ที่ขาดหายไปจาก device_status
-- =============================================

-- 1. Drop และสร้าง view ใหม่ใน mdm schema
DROP VIEW IF EXISTS mdm.device_summary CASCADE;

CREATE VIEW mdm.device_summary AS
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

-- 2. สร้าง view ใน public schema
DROP VIEW IF EXISTS public.device_summary;

CREATE VIEW public.device_summary AS
SELECT * FROM mdm.device_summary;

-- 3. Grant permissions
GRANT SELECT ON public.device_summary TO authenticated;
GRANT SELECT ON public.device_summary TO anon;

-- 4. ตรวจสอบว่า view ถูกสร้างแล้ว
SELECT 
    schemaname,
    viewname,
    viewowner
FROM pg_views
WHERE viewname = 'device_summary'
ORDER BY schemaname;

-- 5. ตรวจสอบคอลัมน์ใน view
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'device_summary'
ORDER BY ordinal_position;
