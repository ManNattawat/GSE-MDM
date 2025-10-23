-- 1. แก้ไข provisioning_tokens เพิ่ม columns สำหรับติดตาม usage
-- เพิ่ม used_at และ device_id

ALTER TABLE mdm.provisioning_tokens 
ADD COLUMN IF NOT EXISTS used_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS device_id TEXT;

-- เพิ่ม foreign key constraint (ถ้ายังไม่มี)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_provisioning_tokens_device'
  ) THEN
    ALTER TABLE mdm.provisioning_tokens
    ADD CONSTRAINT fk_provisioning_tokens_device 
    FOREIGN KEY (device_id) REFERENCES mdm.devices(device_id) 
    ON DELETE SET NULL;
  END IF;
END $$;

-- เพิ่ม index สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_provisioning_tokens_device_id 
ON mdm.provisioning_tokens(device_id);

CREATE INDEX IF NOT EXISTS idx_provisioning_tokens_used 
ON mdm.provisioning_tokens(used);

-- เพิ่ม comment
COMMENT ON COLUMN mdm.provisioning_tokens.used_at IS 'เวลาที่ token ถูกใช้งาน';
COMMENT ON COLUMN mdm.provisioning_tokens.device_id IS 'อุปกรณ์ที่ใช้ token นี้ลงทะเบียน';
