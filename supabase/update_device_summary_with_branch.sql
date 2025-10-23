-- =============================================
-- อัปเดต device_summary view ให้รวมข้อมูลสาขา
-- =============================================

-- Drop view ก่อนเพื่อให้สามารถเปลี่ยนลำดับคอลัมน์ได้
DROP VIEW IF EXISTS public.device_summary CASCADE;

CREATE VIEW public.device_summary AS
SELECT 
    d.id,
    d.device_id,
    d.serial_number,
    d.branch_code,
    b.name as branch_name,           -- เพิ่มชื่อสาขา
    b.province as branch_province,   -- เพิ่มจังหวัด
    b.region as branch_region,       -- เพิ่มภูมิภาค
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
LEFT JOIN mdm.device_status ds ON d.id = ds.device_id
LEFT JOIN company.branches b ON b.code = d.branch_code;

-- Grant permissions
GRANT SELECT ON public.device_summary TO authenticated, anon;

-- ตรวจสอบคอลัมน์ใหม่
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'device_summary'
    AND column_name IN ('branch_name', 'branch_province', 'branch_region')
ORDER BY ordinal_position;
