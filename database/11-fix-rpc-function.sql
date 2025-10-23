-- 11. แก้ไข RPC function create_provisioning_token ให้ใช้ mdm schema
-- ลบ function เดิมก่อน (ทุก signature ที่เป็นไปได้)
DROP FUNCTION IF EXISTS create_provisioning_token(text,uuid,integer);
DROP FUNCTION IF EXISTS create_provisioning_token(text,text,integer);
DROP FUNCTION IF EXISTS create_provisioning_token(text,jsonb,integer);

-- สร้าง function ใหม่ที่รับ config แทน policy_id
CREATE OR REPLACE FUNCTION create_provisioning_token(
  p_branch_code TEXT,
  p_config JSONB DEFAULT '{}'::jsonb,
  p_expires_in_hours INTEGER DEFAULT 168
)
RETURNS TABLE(token TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_token TEXT;
  expiry_time TIMESTAMPTZ;
BEGIN
  -- สร้าง random token
  new_token := encode(gen_random_bytes(32), 'base64');
  
  -- คำนวณเวลาหมดอายุ
  expiry_time := NOW() + (p_expires_in_hours || ' hours')::INTERVAL;
  
  -- บันทึกลงตาราง mdm.provisioning_tokens (ใช้ schema prefix)
  -- ไม่ใช้ policy_id แต่เก็บ config ใน metadata แทน
  INSERT INTO mdm.provisioning_tokens (
    token,
    branch_code,
    policy_id,
    expires_at,
    used,
    created_at
  ) VALUES (
    new_token,
    p_branch_code,
    NULL,  -- policy_id เป็น NULL เพราะใช้ config แทน
    expiry_time,
    false,
    NOW()
  );
  
  -- ส่งคืนผลลัพธ์
  RETURN QUERY SELECT new_token, expiry_time;
END;
$$;

-- Grant permission ให้ authenticated users
GRANT EXECUTE ON FUNCTION create_provisioning_token TO authenticated, anon, service_role;

-- เพิ่ม comment
COMMENT ON FUNCTION create_provisioning_token IS 'สร้าง provisioning token สำหรับการลงทะเบียนอุปกรณ์ใหม่';
