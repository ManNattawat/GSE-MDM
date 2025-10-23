-- 4. แก้ไข policies เพิ่ม columns สำหรับการจัดการขั้นสูง
-- เพิ่ม priority, applies_to, version

ALTER TABLE mdm.policies
ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS applies_to TEXT DEFAULT 'all' CHECK (applies_to IN ('all', 'branch', 'group', 'device')),
ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- เพิ่ม index สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_policies_priority 
ON mdm.policies(priority DESC);

CREATE INDEX IF NOT EXISTS idx_policies_applies_to 
ON mdm.policies(applies_to);

CREATE INDEX IF NOT EXISTS idx_policies_active_priority 
ON mdm.policies(is_active, priority DESC) 
WHERE is_active = true;

-- เพิ่ม comment
COMMENT ON COLUMN mdm.policies.priority IS 'ลำดับความสำคัญของนโยบาย (เลขมากกว่า = สำคัญกว่า)';
COMMENT ON COLUMN mdm.policies.applies_to IS 'ขอบเขตการใช้งาน (all=ทั้งหมด, branch=ตามสาขา, group=ตามกลุ่ม, device=ตามอุปกรณ์)';
COMMENT ON COLUMN mdm.policies.version IS 'เวอร์ชันของนโยบาย (เพิ่มทุกครั้งที่แก้ไข)';
