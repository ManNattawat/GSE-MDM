-- 6. สร้างตาราง device_apps สำหรับ App Management
-- ติดตามแอปที่ติดตั้งในอุปกรณ์

CREATE TABLE IF NOT EXISTS mdm.device_apps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id) ON DELETE CASCADE,
  package_name TEXT NOT NULL,
  app_name TEXT,
  version_name TEXT,
  version_code INTEGER,
  is_system_app BOOLEAN DEFAULT false,
  is_enabled BOOLEAN DEFAULT true,
  install_source TEXT, -- 'play_store', 'manual', 'mdm', 'unknown'
  installed_at TIMESTAMPTZ,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(device_id, package_name)
);

-- เพิ่ม indexes สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_device_apps_device_id 
ON mdm.device_apps(device_id);

CREATE INDEX IF NOT EXISTS idx_device_apps_package_name 
ON mdm.device_apps(package_name);

CREATE INDEX IF NOT EXISTS idx_device_apps_system 
ON mdm.device_apps(is_system_app);

CREATE INDEX IF NOT EXISTS idx_device_apps_enabled 
ON mdm.device_apps(is_enabled);

-- เพิ่ม index สำหรับหาแอปที่ไม่ได้รับอนุญาต
CREATE INDEX IF NOT EXISTS idx_device_apps_unauthorized 
ON mdm.device_apps(device_id, package_name) 
WHERE is_system_app = false;

-- เพิ่ม comment
COMMENT ON TABLE mdm.device_apps IS 'บันทึกแอปที่ติดตั้งในแต่ละอุปกรณ์';
COMMENT ON COLUMN mdm.device_apps.package_name IS 'Package name ของแอป (เช่น com.android.chrome)';
COMMENT ON COLUMN mdm.device_apps.app_name IS 'ชื่อแอปที่แสดง';
COMMENT ON COLUMN mdm.device_apps.is_system_app IS 'เป็นแอประบบหรือไม่';
COMMENT ON COLUMN mdm.device_apps.install_source IS 'แหล่งที่มาของการติดตั้ง';

-- Grant permissions
GRANT ALL ON mdm.device_apps TO authenticated, service_role;
GRANT SELECT ON mdm.device_apps TO anon;

-- สร้าง RLS policy
ALTER TABLE mdm.device_apps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view device apps"
ON mdm.device_apps FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to manage device apps"
ON mdm.device_apps FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);
