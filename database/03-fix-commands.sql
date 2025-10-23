-- 3. แก้ไข commands เพิ่ม columns สำหรับการจัดการ retry และ priority
-- เพิ่ม priority, retry_count, max_retries, expires_at

ALTER TABLE mdm.commands
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS max_retries INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- เพิ่ม index สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_commands_priority 
ON mdm.commands(priority);

CREATE INDEX IF NOT EXISTS idx_commands_status_priority 
ON mdm.commands(status, priority);

CREATE INDEX IF NOT EXISTS idx_commands_expires_at 
ON mdm.commands(expires_at) 
WHERE expires_at IS NOT NULL;

-- เพิ่ม index สำหรับหา commands ที่ต้อง retry
CREATE INDEX IF NOT EXISTS idx_commands_retry 
ON mdm.commands(status, retry_count, max_retries) 
WHERE status = 'failed' AND retry_count < max_retries;

-- เพิ่ม comment
COMMENT ON COLUMN mdm.commands.priority IS 'ลำดับความสำคัญของคำสั่ง (low, normal, high, urgent)';
COMMENT ON COLUMN mdm.commands.retry_count IS 'จำนวนครั้งที่พยายามส่งคำสั่งแล้ว';
COMMENT ON COLUMN mdm.commands.max_retries IS 'จำนวนครั้งสูงสุดที่จะพยายามส่งคำสั่ง';
COMMENT ON COLUMN mdm.commands.expires_at IS 'เวลาหมดอายุของคำสั่ง (ถ้าเลยเวลานี้จะไม่ส่งอีก)';
