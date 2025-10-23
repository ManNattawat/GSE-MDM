-- 7. สร้างตาราง remote_actions สำหรับ Remote Management
-- บันทึกการดำเนินการระยะไกล (Lock, Wipe, Locate, etc.)

CREATE TABLE IF NOT EXISTS mdm.remote_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id) ON DELETE CASCADE,
  action_type TEXT NOT NULL CHECK (action_type IN ('lock', 'wipe', 'locate', 'ring', 'message', 'reboot', 'screenshot')),
  initiated_by TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'executing', 'completed', 'failed', 'cancelled')),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  parameters JSONB DEFAULT '{}'::jsonb,
  result JSONB,
  error_message TEXT,
  initiated_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- เพิ่ม indexes สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_remote_actions_device_id 
ON mdm.remote_actions(device_id);

CREATE INDEX IF NOT EXISTS idx_remote_actions_status 
ON mdm.remote_actions(status);

CREATE INDEX IF NOT EXISTS idx_remote_actions_action_type 
ON mdm.remote_actions(action_type);

CREATE INDEX IF NOT EXISTS idx_remote_actions_device_status 
ON mdm.remote_actions(device_id, status);

CREATE INDEX IF NOT EXISTS idx_remote_actions_pending 
ON mdm.remote_actions(device_id, initiated_at DESC) 
WHERE status IN ('pending', 'executing');

-- เพิ่ม comment
COMMENT ON TABLE mdm.remote_actions IS 'บันทึกการดำเนินการระยะไกลกับอุปกรณ์';
COMMENT ON COLUMN mdm.remote_actions.action_type IS 'ประเภทการดำเนินการ (lock, wipe, locate, ring, message, reboot, screenshot)';
COMMENT ON COLUMN mdm.remote_actions.initiated_by IS 'ผู้ที่สั่งการ (user_id หรือ email)';
COMMENT ON COLUMN mdm.remote_actions.parameters IS 'พารามิเตอร์เพิ่มเติม (เช่น ข้อความสำหรับ message action)';
COMMENT ON COLUMN mdm.remote_actions.result IS 'ผลลัพธ์ของการดำเนินการ';

-- Grant permissions
GRANT ALL ON mdm.remote_actions TO authenticated, service_role;
GRANT SELECT ON mdm.remote_actions TO anon;

-- สร้าง RLS policy
ALTER TABLE mdm.remote_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view remote actions"
ON mdm.remote_actions FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to create remote actions"
ON mdm.remote_actions FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update remote actions"
ON mdm.remote_actions FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);
