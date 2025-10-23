-- ตรวจสอบตารางทั้งหมดใน MDM Schema
SELECT 
    table_name,
    (
        SELECT COUNT(*) 
        FROM information_schema.columns 
        WHERE table_schema = 'mdm' 
        AND columns.table_name = tables.table_name
    ) as column_count
FROM information_schema.tables
WHERE table_schema = 'mdm'
ORDER BY table_name;

-- ดูรายละเอียด columns ของแต่ละตาราง
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'mdm'
ORDER BY table_name, ordinal_position;
