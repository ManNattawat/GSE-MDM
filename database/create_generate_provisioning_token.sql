-- สร้าง RPC function generate_provisioning_token สำหรับ GSE-MDM
-- ฟังก์ชันนี้จะสร้าง provisioning token สำหรับการลงทะเบียนอุปกรณ์

CREATE OR REPLACE FUNCTION generate_provisioning_token(
    p_branch_code TEXT,
    p_expires_hours INTEGER DEFAULT 168,
    p_created_by TEXT DEFAULT 'system'
)
RETURNS TABLE (
    token TEXT,
    expires_at TIMESTAMPTZ,
    branch_code TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_token TEXT;
    v_expires_at TIMESTAMPTZ;
    v_branch_exists BOOLEAN;
BEGIN
    -- ตรวจสอบว่าสาขามีอยู่จริง
    SELECT EXISTS(
        SELECT 1 FROM branches 
        WHERE code = p_branch_code AND is_active = true
    ) INTO v_branch_exists;
    
    IF NOT v_branch_exists THEN
        RAISE EXCEPTION 'Branch code % not found or inactive', p_branch_code;
    END IF;
    
    -- สร้าง token แบบ random
    v_token := encode(gen_random_bytes(32), 'base64');
    
    -- คำนวณเวลาหมดอายุ
    v_expires_at := NOW() + (p_expires_hours || ' hours')::INTERVAL;
    
    -- บันทึก token ลงในตาราง mdm.provisioning_tokens
    INSERT INTO mdm.provisioning_tokens (
        token,
        branch_code,
        policy_id,
        expires_at,
        used,
        created_by,
        created_at
    ) VALUES (
        v_token,
        p_branch_code,
        NULL, -- policy_id เป็น NULL เพราะใช้ config แทน
        v_expires_at,
        false,
        p_created_by,
        NOW()
    );
    
    -- ส่งคืนผลลัพธ์
    RETURN QUERY SELECT v_token, v_expires_at, p_branch_code, NOW();
END;
$$;

-- Grant permission ให้ authenticated users
GRANT EXECUTE ON FUNCTION generate_provisioning_token TO authenticated, anon, service_role;

-- เพิ่ม comment
COMMENT ON FUNCTION generate_provisioning_token IS 'สร้าง provisioning token สำหรับการลงทะเบียนอุปกรณ์ใหม่';
