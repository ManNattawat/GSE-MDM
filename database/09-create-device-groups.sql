-- 9. สร้างตาราง device_groups และ device_group_members
-- จัดกลุ่มอุปกรณ์เพื่อจัดการเป็นกลุ่ม

-- ตารางหลัก: device_groups
CREATE TABLE IF NOT EXISTS mdm.device_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  group_type TEXT DEFAULT 'manual' CHECK (group_type IN ('manual', 'dynamic', 'branch', 'department')),
  dynamic_rules JSONB, -- กฎสำหรับ dynamic groups
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ตารางเชื่อมโยง: device_group_members
CREATE TABLE IF NOT EXISTS mdm.device_group_members (
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES mdm.device_groups(id) ON DELETE CASCADE,
  added_by TEXT,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (device_id, group_id)
);

-- เพิ่ม indexes สำหรับ device_groups
CREATE INDEX IF NOT EXISTS idx_device_groups_name 
ON mdm.device_groups(name);

CREATE INDEX IF NOT EXISTS idx_device_groups_type 
ON mdm.device_groups(group_type);

-- เพิ่ม indexes สำหรับ device_group_members
CREATE INDEX IF NOT EXISTS idx_device_group_members_device 
ON mdm.device_group_members(device_id);

CREATE INDEX IF NOT EXISTS idx_device_group_members_group 
ON mdm.device_group_members(group_id);

-- เพิ่ม comment
COMMENT ON TABLE mdm.device_groups IS 'กลุ่มอุปกรณ์สำหรับจัดการเป็นกลุ่ม';
COMMENT ON COLUMN mdm.device_groups.group_type IS 'ประเภทกลุ่ม (manual=เพิ่มเอง, dynamic=ตามกฎ, branch=ตามสาขา, department=ตามแผนก)';
COMMENT ON COLUMN mdm.device_groups.dynamic_rules IS 'กฎสำหรับ dynamic groups (เช่น branch_code=001)';

COMMENT ON TABLE mdm.device_group_members IS 'สมาชิกในแต่ละกลุ่มอุปกรณ์';

-- Grant permissions
GRANT ALL ON mdm.device_groups TO authenticated, service_role;
GRANT SELECT ON mdm.device_groups TO anon;

GRANT ALL ON mdm.device_group_members TO authenticated, service_role;
GRANT SELECT ON mdm.device_group_members TO anon;

-- สร้าง RLS policy สำหรับ device_groups
ALTER TABLE mdm.device_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view device groups"
ON mdm.device_groups FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to manage device groups"
ON mdm.device_groups FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- สร้าง RLS policy สำหรับ device_group_members
ALTER TABLE mdm.device_group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view group members"
ON mdm.device_group_members FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to manage group members"
ON mdm.device_group_members FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- สร้าง trigger สำหรับ updated_at
CREATE OR REPLACE FUNCTION mdm.update_device_groups_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_device_groups_updated_at
BEFORE UPDATE ON mdm.device_groups
FOR EACH ROW
EXECUTE FUNCTION mdm.update_device_groups_updated_at();
