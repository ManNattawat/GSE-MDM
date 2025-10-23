-- =============================================
-- Script สำหรับตรวจสอบ Permissions ใน Supabase
-- =============================================

-- 1. ตรวจสอบว่ามี views ใน public schema หรือไม่
SELECT 
    schemaname,
    viewname,
    viewowner
FROM pg_views
WHERE schemaname IN ('public', 'mdm')
ORDER BY schemaname, viewname;

-- 2. ตรวจสอบ permissions ของ views
SELECT 
    schemaname,
    tablename,
    tableowner,
    hasinsert,
    hasselect,
    hasupdate,
    hasdelete
FROM pg_tables
WHERE schemaname IN ('public', 'mdm')
ORDER BY schemaname, tablename;

-- 3. ตรวจสอบ RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'mdm'
ORDER BY tablename, policyname;

-- 4. ตรวจสอบว่า authenticated users มีสิทธิ์อะไรบ้าง
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('authenticated', 'anon', 'service_role')
    AND table_schema IN ('public', 'mdm')
ORDER BY table_schema, table_name, grantee;

-- 5. นับจำนวนตารางและ views
SELECT 
    table_schema,
    table_type,
    COUNT(*) as count
FROM information_schema.tables
WHERE table_schema IN ('public', 'mdm')
GROUP BY table_schema, table_type
ORDER BY table_schema, table_type;
