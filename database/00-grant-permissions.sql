-- 0. Grant permissions สำหรับ MDM Schema
-- รันไฟล์นี้ก่อนรันไฟล์อื่น ๆ

-- Grant usage บน schema
GRANT USAGE ON SCHEMA mdm TO authenticated, anon, service_role;

-- Grant permissions บนตารางที่มีอยู่แล้ว
GRANT ALL ON ALL TABLES IN SCHEMA mdm TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA mdm TO anon;

-- Grant permissions บน sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA mdm TO authenticated, service_role;

-- Grant permissions สำหรับตารางใหม่ในอนาคต
ALTER DEFAULT PRIVILEGES IN SCHEMA mdm 
GRANT ALL ON TABLES TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA mdm 
GRANT SELECT ON TABLES TO anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA mdm 
GRANT ALL ON SEQUENCES TO authenticated, service_role;

-- Grant execute บน functions (ถ้ามี)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA mdm TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA mdm 
GRANT EXECUTE ON FUNCTIONS TO authenticated, service_role;

-- สำหรับ RLS policies
-- ต้องรันหลังจากสร้างตารางแล้ว
