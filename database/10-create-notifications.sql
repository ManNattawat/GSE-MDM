-- 10. สร้างตาราง notifications สำหรับระบบแจ้งเตือน
-- ส่งการแจ้งเตือนไปยังอุปกรณ์หรือผู้ดูแลระบบ

CREATE TABLE IF NOT EXISTS mdm.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT REFERENCES mdm.devices(device_id) ON DELETE CASCADE,
  user_id TEXT, -- ผู้รับการแจ้งเตือน (ถ้าเป็น admin notification)
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success', 'alert')),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  category TEXT, -- 'compliance', 'security', 'update', 'system'
  action_url TEXT, -- URL สำหรับ action button
  action_label TEXT, -- Label ของ action button
  metadata JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  is_sent BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- เพิ่ม indexes สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_notifications_device_id 
ON mdm.notifications(device_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id 
ON mdm.notifications(user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_type 
ON mdm.notifications(type);

CREATE INDEX IF NOT EXISTS idx_notifications_priority 
ON mdm.notifications(priority);

CREATE INDEX IF NOT EXISTS idx_notifications_is_read 
ON mdm.notifications(is_read);

CREATE INDEX IF NOT EXISTS idx_notifications_category 
ON mdm.notifications(category);

-- Index สำหรับหา notifications ที่ยังไม่ได้อ่าน
CREATE INDEX IF NOT EXISTS idx_notifications_unread 
ON mdm.notifications(device_id, created_at DESC) 
WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_notifications_unread_user 
ON mdm.notifications(user_id, created_at DESC) 
WHERE is_read = false;

-- Index สำหรับหา notifications ที่ยังไม่ได้ส่ง
CREATE INDEX IF NOT EXISTS idx_notifications_unsent 
ON mdm.notifications(created_at) 
WHERE is_sent = false;

-- เพิ่ม comment
COMMENT ON TABLE mdm.notifications IS 'การแจ้งเตือนสำหรับอุปกรณ์และผู้ดูแลระบบ';
COMMENT ON COLUMN mdm.notifications.device_id IS 'อุปกรณ์ที่จะรับการแจ้งเตือน (null = แจ้งเตือนผู้ดูแล)';
COMMENT ON COLUMN mdm.notifications.user_id IS 'ผู้ใช้ที่จะรับการแจ้งเตือน (สำหรับ admin notifications)';
COMMENT ON COLUMN mdm.notifications.type IS 'ประเภทการแจ้งเตือน (info, warning, error, success, alert)';
COMMENT ON COLUMN mdm.notifications.priority IS 'ลำดับความสำคัญ (low, normal, high, urgent)';
COMMENT ON COLUMN mdm.notifications.category IS 'หมวดหมู่ (compliance, security, update, system)';
COMMENT ON COLUMN mdm.notifications.action_url IS 'URL สำหรับปุ่ม action';
COMMENT ON COLUMN mdm.notifications.expires_at IS 'เวลาหมดอายุของการแจ้งเตือน';

-- Grant permissions
GRANT ALL ON mdm.notifications TO authenticated, service_role;
GRANT SELECT ON mdm.notifications TO anon;

-- สร้าง RLS policy
ALTER TABLE mdm.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view notifications"
ON mdm.notifications FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to create notifications"
ON mdm.notifications FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update notifications"
ON mdm.notifications FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- สร้าง function สำหรับ mark as read
CREATE OR REPLACE FUNCTION mdm.mark_notification_as_read(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE mdm.notifications
  SET is_read = true, read_at = NOW()
  WHERE id = notification_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION mdm.mark_notification_as_read TO authenticated, service_role;
