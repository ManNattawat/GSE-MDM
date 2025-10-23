-- สร้างตาราง provisioning_tokens
CREATE TABLE IF NOT EXISTS provisioning_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  token TEXT UNIQUE NOT NULL,
  branch_code TEXT NOT NULL,
  policy_id UUID REFERENCES policies(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  is_used BOOLEAN DEFAULT false,
  used_at TIMESTAMPTZ,
  device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- สร้าง index สำหรับการค้นหา
CREATE INDEX IF NOT EXISTS idx_provisioning_tokens_token ON provisioning_tokens(token);
CREATE INDEX IF NOT EXISTS idx_provisioning_tokens_branch ON provisioning_tokens(branch_code);
CREATE INDEX IF NOT EXISTS idx_provisioning_tokens_expires ON provisioning_tokens(expires_at);

-- สร้าง trigger สำหรับ updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_provisioning_tokens_updated_at 
  BEFORE UPDATE ON provisioning_tokens 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security)
ALTER TABLE provisioning_tokens ENABLE ROW LEVEL SECURITY;

-- Policy สำหรับ authenticated users
CREATE POLICY "Allow authenticated users to manage provisioning tokens" 
ON provisioning_tokens FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);
