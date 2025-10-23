-- 2. แก้ไข devices เพิ่ม columns สำหรับข้อมูลอุปกรณ์เพิ่มเติม
-- เพิ่ม IMEI, Phone Number, Root Status, Security Patch Level

ALTER TABLE mdm.devices
ADD COLUMN IF NOT EXISTS imei TEXT,
ADD COLUMN IF NOT EXISTS phone_number TEXT,
ADD COLUMN IF NOT EXISTS is_rooted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS security_patch_level TEXT;

-- เพิ่ม unique constraint สำหรับ IMEI (ถ้ามี)
CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_imei 
ON mdm.devices(imei) 
WHERE imei IS NOT NULL;

-- เพิ่ม index สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_devices_phone_number 
ON mdm.devices(phone_number) 
WHERE phone_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_devices_is_rooted 
ON mdm.devices(is_rooted);

-- เพิ่ม comment
COMMENT ON COLUMN mdm.devices.imei IS 'IMEI number ของอุปกรณ์';
COMMENT ON COLUMN mdm.devices.phone_number IS 'เบอร์โทรศัพท์ของอุปกรณ์';
COMMENT ON COLUMN mdm.devices.is_rooted IS 'ตรวจสอบว่าอุปกรณ์ถูก root/jailbreak หรือไม่';
COMMENT ON COLUMN mdm.devices.security_patch_level IS 'ระดับ Android Security Patch (เช่น 2024-10-01)';
