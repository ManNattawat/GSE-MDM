-- =============================================
-- ลบนโยบายตัวอย่างที่สร้างจาก schema.sql
-- =============================================

-- ลบนโยบายตัวอย่างทั้ง 3 แบบ
DELETE FROM mdm.policies 
WHERE name IN ('Basic Policy', 'Default Policy', 'Strict Policy')
  AND created_by = 'system';

-- ตรวจสอบว่าลบสำเร็จ
SELECT 
    COUNT(*) as remaining_policies,
    STRING_AGG(name, ', ') as policy_names
FROM mdm.policies;

-- แสดงข้อความยืนยัน
SELECT 'นโยบายตัวอย่างถูกลบเรียบร้อยแล้ว' as status;
