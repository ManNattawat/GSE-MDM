-- 8. สร้างตาราง compliance_checks สำหรับตรวจสอบการปฏิบัติตามนโยบาย
-- ติดตามว่าอุปกรณ์ปฏิบัติตามนโยบายหรือไม่

CREATE TABLE IF NOT EXISTS mdm.compliance_checks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id) ON DELETE CASCADE,
  policy_id UUID REFERENCES mdm.policies(id) ON DELETE SET NULL,
  check_type TEXT NOT NULL CHECK (check_type IN ('app_compliance', 'security_check', 'policy_violation', 'configuration_check')),
  status TEXT NOT NULL CHECK (status IN ('compliant', 'non_compliant', 'warning', 'unknown')),
  severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  details JSONB DEFAULT '{}'::jsonb,
  violation_details TEXT,
  checked_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolved_by TEXT,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- เพิ่ม indexes สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_compliance_checks_device_id 
ON mdm.compliance_checks(device_id);

CREATE INDEX IF NOT EXISTS idx_compliance_checks_policy_id 
ON mdm.compliance_checks(policy_id);

CREATE INDEX IF NOT EXISTS idx_compliance_checks_status 
ON mdm.compliance_checks(status);

CREATE INDEX IF NOT EXISTS idx_compliance_checks_severity 
ON mdm.compliance_checks(severity);

CREATE INDEX IF NOT EXISTS idx_compliance_checks_device_status 
ON mdm.compliance_checks(device_id, status);

-- Index สำหรับหา violations ที่ยังไม่ได้แก้ไข
CREATE INDEX IF NOT EXISTS idx_compliance_checks_unresolved 
ON mdm.compliance_checks(device_id, checked_at DESC) 
WHERE status IN ('non_compliant', 'warning') AND resolved_at IS NULL;

-- เพิ่ม comment
COMMENT ON TABLE mdm.compliance_checks IS 'บันทึกการตรวจสอบการปฏิบัติตามนโยบาย';
COMMENT ON COLUMN mdm.compliance_checks.check_type IS 'ประเภทการตรวจสอบ';
COMMENT ON COLUMN mdm.compliance_checks.status IS 'สถานะการปฏิบัติตาม (compliant, non_compliant, warning, unknown)';
COMMENT ON COLUMN mdm.compliance_checks.severity IS 'ระดับความรุนแรง (low, medium, high, critical)';
COMMENT ON COLUMN mdm.compliance_checks.details IS 'รายละเอียดการตรวจสอบ';
COMMENT ON COLUMN mdm.compliance_checks.violation_details IS 'รายละเอียดการละเมิด';

-- Grant permissions
GRANT ALL ON mdm.compliance_checks TO authenticated, service_role;
GRANT SELECT ON mdm.compliance_checks TO anon;

-- สร้าง RLS policy
ALTER TABLE mdm.compliance_checks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view compliance checks"
ON mdm.compliance_checks FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to manage compliance checks"
ON mdm.compliance_checks FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);
