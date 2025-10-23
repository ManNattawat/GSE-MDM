-- แก้ไข RPC function create_provisioning_token ให้ทำงานได้
-- วันที่: 2025-01-27

-- 1. ลบ function เดิมก่อน (ทุก signature ที่เป็นไปได้)
DROP FUNCTION IF EXISTS create_provisioning_token(text,uuid,integer);
DROP FUNCTION IF EXISTS create_provisioning_token(text,text,integer);
DROP FUNCTION IF EXISTS create_provisioning_token(text,jsonb,integer);
DROP FUNCTION IF EXISTS public.create_provisioning_token(text,uuid,integer);
DROP FUNCTION IF EXISTS public.create_provisioning_token(text,text,integer);
DROP FUNCTION IF EXISTS public.create_provisioning_token(text,jsonb,integer);

-- 2. ตรวจสอบและสร้างตาราง provisioning_tokens ถ้ายังไม่มี
CREATE TABLE IF NOT EXISTS provisioning_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token TEXT UNIQUE NOT NULL,
    branch_code TEXT NOT NULL,
    policy_id UUID,  -- ให้เป็น nullable เพื่อรองรับทั้งแบบเก่าและใหม่
    config JSONB,    -- เก็บ config แบบใหม่
    expires_at TIMESTAMPTZ NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMPTZ,
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. สร้าง index ถ้ายังไม่มี
CREATE INDEX IF NOT EXISTS idx_provisioning_tokens_token ON provisioning_tokens(token);
CREATE INDEX IF NOT EXISTS idx_provisioning_tokens_branch_code ON provisioning_tokens(branch_code);
CREATE INDEX IF NOT EXISTS idx_provisioning_tokens_expires_at ON provisioning_tokens(expires_at);

-- 4. สร้าง RPC function ใหม่ที่รองรับทั้งแบบเก่าและใหม่
CREATE OR REPLACE FUNCTION create_provisioning_token(
    p_branch_code TEXT,
    p_policy_id UUID DEFAULT NULL,
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
        used,
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

-- 5. Grant permission ให้ authenticated users
GRANT EXECUTE ON FUNCTION create_provisioning_token TO authenticated;
GRANT EXECUTE ON FUNCTION create_provisioning_token TO anon;
GRANT EXECUTE ON FUNCTION create_provisioning_token TO service_role;

-- 6. เพิ่ม comment
COMMENT ON FUNCTION create_provisioning_token IS 'สร้าง provisioning token สำหรับการลงทะเบียนอุปกรณ์ใหม่';

-- 7. ตรวจสอบว่า function ถูกสร้างแล้ว
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'create_provisioning_token' 
AND routine_schema = 'public';
