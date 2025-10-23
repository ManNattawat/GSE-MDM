-- 5. สร้างตาราง device_locations สำหรับ Find My Device
-- ติดตามตำแหน่งอุปกรณ์

CREATE TABLE IF NOT EXISTS mdm.device_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id) ON DELETE CASCADE,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy DECIMAL(10, 2),
  altitude DECIMAL(10, 2),
  speed DECIMAL(10, 2),
  bearing DECIMAL(10, 2),
  provider TEXT, -- 'gps', 'network', 'fused'
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- เพิ่ม indexes สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_device_locations_device_id 
ON mdm.device_locations(device_id);

CREATE INDEX IF NOT EXISTS idx_device_locations_recorded_at 
ON mdm.device_locations(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_device_locations_device_time 
ON mdm.device_locations(device_id, recorded_at DESC);

-- เพิ่ม index สำหรับ geospatial queries (ถ้าต้องการในอนาคต)
CREATE INDEX IF NOT EXISTS idx_device_locations_coords 
ON mdm.device_locations(latitude, longitude);

-- เพิ่ม comment
COMMENT ON TABLE mdm.device_locations IS 'บันทึกตำแหน่งของอุปกรณ์สำหรับ Find My Device';
COMMENT ON COLUMN mdm.device_locations.latitude IS 'ละติจูด (Latitude)';
COMMENT ON COLUMN mdm.device_locations.longitude IS 'ลองจิจูด (Longitude)';
COMMENT ON COLUMN mdm.device_locations.accuracy IS 'ความแม่นยำของตำแหน่ง (เมตร)';
COMMENT ON COLUMN mdm.device_locations.provider IS 'แหล่งที่มาของตำแหน่ง (gps, network, fused)';
COMMENT ON COLUMN mdm.device_locations.recorded_at IS 'เวลาที่บันทึกตำแหน่ง';

-- สร้าง RLS policy
ALTER TABLE mdm.device_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view device locations"
ON mdm.device_locations FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to insert device locations"
ON mdm.device_locations FOR INSERT
TO authenticated
WITH CHECK (true);
