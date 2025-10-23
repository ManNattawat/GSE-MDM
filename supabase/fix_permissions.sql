-- =============================================
-- Script สำหรับแก้ไข Permissions ใน Supabase
-- รันสคริปต์นี้ถ้า Dashboard ไม่สามารถเข้าถึงข้อมูลได้
-- =============================================

-- 1. Grant permissions สำหรับ mdm schema
GRANT USAGE ON SCHEMA mdm TO authenticated;
GRANT USAGE ON SCHEMA mdm TO anon;

-- 2. Grant SELECT permissions สำหรับทุกตารางใน mdm schema
GRANT SELECT ON ALL TABLES IN SCHEMA mdm TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA mdm TO anon;

-- 3. Grant SELECT permissions สำหรับ sequences
GRANT SELECT ON ALL SEQUENCES IN SCHEMA mdm TO authenticated;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA mdm TO anon;

-- 4. สร้าง/อัปเดต public views
CREATE OR REPLACE VIEW public.device_summary AS
SELECT * FROM mdm.device_summary;

CREATE OR REPLACE VIEW public.policy_summary AS
SELECT * FROM mdm.policy_summary;

-- 5. Grant permissions สำหรับ public views
GRANT SELECT ON public.device_summary TO authenticated;
GRANT SELECT ON public.device_summary TO anon;
GRANT SELECT ON public.policy_summary TO authenticated;
GRANT SELECT ON public.policy_summary TO anon;

-- 6. ตั้งค่า default privileges สำหรับตารางใหม่ในอนาคต
ALTER DEFAULT PRIVILEGES IN SCHEMA mdm
GRANT SELECT ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA mdm
GRANT SELECT ON TABLES TO anon;

-- 7. ตรวจสอบว่า RLS policies ถูกต้อง
-- ถ้ามี policy ที่บล็อก authenticated users ให้ลบออก
DO $$
BEGIN
    -- ตรวจสอบและสร้าง policy สำหรับ authenticated users
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'mdm' 
        AND tablename = 'devices' 
        AND policyname = 'Authenticated users can view all data'
    ) THEN
        CREATE POLICY "Authenticated users can view all data" ON mdm.devices
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- 8. แสดงผลลัพธ์
SELECT 
    'Permissions updated successfully' as status,
    NOW() as updated_at;

-- 9. แสดงรายการ permissions ที่ grant แล้ว
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('authenticated', 'anon')
    AND table_schema IN ('public', 'mdm')
ORDER BY table_schema, table_name, grantee;
