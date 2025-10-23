-- ลบ function เดิมก่อน
DROP FUNCTION IF EXISTS create_provisioning_token(text,uuid,integer);
DROP FUNCTION IF EXISTS create_provisioning_token(text,text,integer);

-- สร้าง function ใหม่
CREATE OR REPLACE FUNCTION create_provisioning_token(
  p_branch_code TEXT,
  p_policy_id UUID,
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
  
  -- บันทึกลงตาราง provisioning_tokens
  INSERT INTO provisioning_tokens (
    token,
    branch_code,
    policy_id,
    expires_at,
    is_used,
    created_at
  ) VALUES (
    new_token,
    p_branch_code,
    p_policy_id,
    expiry_time,
    false,
    NOW()
  );
  
  -- ส่งคืนผลลัพธ์
  RETURN QUERY SELECT new_token, expiry_time;
END;
$$;

-- Grant permission ให้ authenticated users
GRANT EXECUTE ON FUNCTION create_provisioning_token TO authenticated;
