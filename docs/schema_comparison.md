# 📊 เปรียบเทียบ Schema v1 vs v2

## 🔄 การเปลี่ยนแปลงหลัก

### ❌ ลบออก
- `mdm.policies` - ไม่ใช้แล้ว
- `mdm.device_policies` - ไม่ใช้แล้ว (ความสัมพันธ์ระหว่าง device กับ policy)

### ✅ เพิ่มเข้ามา
- `mdm.config_templates` - Template preset สำหรับโหลดค่ามาตรฐาน

### 🔧 แก้ไข
- `mdm.devices` - เพิ่ม column `config` (JSONB)
- `mdm.provisioning_tokens` - เปลี่ยนจาก `policy_id` เป็น `config` (JSONB)
- `mdm.device_enrollments` - เปลี่ยนจาก `policy_id` เป็น `config` (JSONB)
- `mdm.commands` - เพิ่ม command type `update_config`

---

## 📋 โครงสร้างตาราง

### 1. mdm.devices

#### v1 (เดิม)
```sql
CREATE TABLE mdm.devices (
    id UUID PRIMARY KEY,
    device_id TEXT UNIQUE NOT NULL,
    branch_code TEXT NOT NULL,
    -- ไม่มี config
    status TEXT,
    ...
);
```

#### v2 (ใหม่)
```sql
CREATE TABLE mdm.devices (
    id UUID PRIMARY KEY,
    device_id TEXT UNIQUE NOT NULL,
    branch_code TEXT NOT NULL,
    
    -- 🆕 เพิ่ม config
    config JSONB NOT NULL DEFAULT '{
        "allowlist": ["com.gse.mdm"],
        "disable_screenshot": false,
        "disable_usb": false,
        "disable_install": false,
        "disable_camera": false,
        "disable_bluetooth": false,
        "kiosk_mode": false
    }'::jsonb,
    
    status TEXT,
    ...
);
```

**ประโยชน์:**
- ✅ เก็บ config ไว้ที่อุปกรณ์โดยตรง
- ✅ ไม่ต้อง JOIN กับตาราง policies
- ✅ แต่ละอุปกรณ์มี config เป็นของตัวเอง
- ✅ แก้ไข config ได้ทันที ไม่กระทบอุปกรณ์อื่น

---

### 2. mdm.provisioning_tokens

#### v1 (เดิม)
```sql
CREATE TABLE mdm.provisioning_tokens (
    id UUID PRIMARY KEY,
    token TEXT UNIQUE NOT NULL,
    branch_code TEXT NOT NULL,
    policy_id UUID REFERENCES mdm.policies(id),  -- ❌ อ้างอิง policy
    expires_at TIMESTAMPTZ NOT NULL,
    ...
);
```

#### v2 (ใหม่)
```sql
CREATE TABLE mdm.provisioning_tokens (
    id UUID PRIMARY KEY,
    token TEXT UNIQUE NOT NULL,
    branch_code TEXT NOT NULL,
    
    -- 🆕 เก็บ config โดยตรง
    config JSONB NOT NULL DEFAULT '{
        "allowlist": ["com.gse.mdm"],
        "disable_screenshot": false,
        ...
    }'::jsonb,
    
    expires_at TIMESTAMPTZ NOT NULL,
    ...
);
```

**ประโยชน์:**
- ✅ QR Code มี config ติดมาเลย
- ✅ ไม่ต้องไป fetch policy จาก database
- ✅ QR Code เป็น self-contained
- ✅ ลด network request

---

### 3. mdm.config_templates (ใหม่)

```sql
CREATE TABLE mdm.config_templates (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,                    -- "Kiosk Mode สำหรับสาขา"
    description TEXT,                      -- คำอธิบาย
    config JSONB NOT NULL,                 -- Config ที่จะใช้
    is_default BOOLEAN DEFAULT FALSE,      -- เป็น template เริ่มต้นหรือไม่
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**ประโยชน์:**
- ✅ เก็บ template preset ไว้
- ✅ Admin กดโหลดค่ามาตรฐานได้เลย
- ✅ ไม่ต้อง toggle ทีละอันทุกครั้ง
- ✅ มี template สำหรับแต่ละสถานการณ์

**ตัวอย่าง Templates:**
1. **ค่าเริ่มต้น** - การตั้งค่าพื้นฐาน
2. **Kiosk Mode สำหรับสาขา** - ล็อคอุปกรณ์
3. **ความปลอดภัยสูง** - สำหรับข้อมูลสำคัญ

---

### 4. mdm.commands

#### v1 (เดิม)
```sql
CREATE TABLE mdm.commands (
    id UUID PRIMARY KEY,
    device_id UUID REFERENCES mdm.devices(id),
    command_type TEXT CHECK (command_type IN ('lock', 'unlock', 'reboot', 'wipe', 'update_policy', 'status_check')),
    payload JSONB,
    ...
);
```

#### v2 (ใหม่)
```sql
CREATE TABLE mdm.commands (
    id UUID PRIMARY KEY,
    device_id UUID REFERENCES mdm.devices(id),
    
    -- 🆕 เปลี่ยน update_policy เป็น update_config
    command_type TEXT CHECK (command_type IN ('lock', 'unlock', 'reboot', 'wipe', 'update_config', 'status_check')),
    
    payload JSONB,  -- สำหรับ update_config จะมี config ใหม่
    ...
);
```

**ประโยชน์:**
- ✅ ส่งคำสั่ง update_config ได้
- ✅ payload มี config ใหม่ทั้งหมด
- ✅ อุปกรณ์รับ config แล้ว apply ทันที

---

## 🔄 Flow การทำงาน

### v1 (เดิม) - ใช้ Policies

```
1. Admin สร้าง Policy
   ↓
2. Admin สร้าง QR Code (เลือก Policy)
   ↓
3. สาขาสแกน QR
   ↓
4. Agent ได้ token → fetch policy_id
   ↓
5. Agent ดึง policy config จาก API
   ↓
6. Agent apply config
```

**ปัญหา:**
- ❌ ต้องสร้าง policy ก่อน (ขั้นตอนเพิ่ม)
- ❌ ต้อง fetch policy จาก API (network request เพิ่ม)
- ❌ ถ้าแก้ policy กระทบทุกอุปกรณ์ที่ใช้ policy นั้น

---

### v2 (ใหม่) - ไม่ใช้ Policies

```
1. Admin สร้าง QR Code (ตั้งค่าเลย)
   ↓
2. สาขาสแกน QR
   ↓
3. Agent ได้ token + config (ครบในตัว)
   ↓
4. Agent apply config ทันที
```

**ข้อดี:**
- ✅ ลดขั้นตอน (จาก 6 เหลือ 4)
- ✅ ไม่ต้อง fetch policy (ลด network request)
- ✅ QR Code เป็น self-contained
- ✅ แก้ config อุปกรณ์หนึ่งไม่กระทบอุปกรณ์อื่น

---

## 📱 ตัวอย่าง Config JSON

```json
{
  "allowlist": [
    "com.gse.mdm",
    "jp.naver.line.android",
    "com.android.chrome"
  ],
  "disable_screenshot": true,
  "disable_usb": true,
  "disable_install": true,
  "disable_camera": false,
  "disable_bluetooth": false,
  "kiosk_mode": true
}
```

**การใช้งาน:**
- เก็บใน `devices.config`
- เก็บใน `provisioning_tokens.config`
- เก็บใน `device_enrollments.config` (เพื่อ audit)
- เก็บใน `config_templates.config` (เป็น template)

---

## 🔧 Functions ใหม่

### 1. create_provisioning_token

#### v1 (เดิม)
```sql
mdm.create_provisioning_token(
    p_branch_code TEXT,
    p_policy_id UUID,  -- ❌ ต้องส่ง policy_id
    p_expires_in_hours INTEGER
)
```

#### v2 (ใหม่)
```sql
mdm.create_provisioning_token(
    p_branch_code TEXT,
    p_config JSONB,  -- 🆕 ส่ง config โดยตรง
    p_expires_in_hours INTEGER
)
```

---

### 2. update_device_config (ใหม่)

```sql
mdm.update_device_config(
    p_device_id UUID,
    p_config JSONB
)
```

**ใช้สำหรับ:**
- อัปเดต config ของอุปกรณ์จากระยะไกล
- ส่งคำสั่ง `update_config` ไปยังอุปกรณ์
- Log การเปลี่ยนแปลงใน audit_logs

---

## 📊 Views ที่เปลี่ยนแปลง

### public.device_summary

#### v1 (เดิม)
```sql
SELECT 
    d.id,
    d.device_id,
    d.branch_code,
    p.name as policy_name,  -- ❌ JOIN กับ policies
    ...
FROM mdm.devices d
LEFT JOIN mdm.device_policies dp ON d.id = dp.device_id
LEFT JOIN mdm.policies p ON dp.policy_id = p.id;
```

#### v2 (ใหม่)
```sql
SELECT 
    d.id,
    d.device_id,
    d.branch_code,
    d.config,  -- 🆕 แสดง config โดยตรง
    ...
FROM mdm.devices d
LEFT JOIN mdm.device_status ds ON d.id = ds.device_id
LEFT JOIN company.branches b ON b.code = d.branch_code;
```

**ข้อดี:**
- ✅ ไม่ต้อง JOIN กับ policies
- ✅ Query เร็วขึ้น
- ✅ แสดง config ทั้งหมดของอุปกรณ์

---

## 🎯 สรุปข้อดี v2

### 1. ความเรียบง่าย
- ❌ ไม่มีตาราง policies
- ❌ ไม่มีตาราง device_policies
- ✅ เก็บ config ไว้ที่อุปกรณ์โดยตรง

### 2. Performance
- ✅ ลด JOIN ตาราง
- ✅ ลด network request (ไม่ต้อง fetch policy)
- ✅ Query เร็วขึ้น

### 3. Flexibility
- ✅ แต่ละอุปกรณ์มี config เป็นของตัวเอง
- ✅ แก้ไข config ได้ทันที
- ✅ ไม่กระทบอุปกรณ์อื่น

### 4. User Experience
- ✅ ลดขั้นตอนการใช้งาน
- ✅ ไม่ต้องเข้าใจคำว่า "นโยบาย"
- ✅ Toggle switch ชัดเจน

### 5. Template Preset
- ✅ มี config_templates สำหรับโหลดค่ามาตรฐาน
- ✅ ไม่ต้อง toggle ทีละอันทุกครั้ง
- ✅ มี template สำหรับแต่ละสถานการณ์

---

## 🔄 Migration Path

### ถ้าต้องการ migrate จาก v1 → v2

```sql
-- 1. เพิ่ม column config ใน devices
ALTER TABLE mdm.devices 
ADD COLUMN config JSONB NOT NULL DEFAULT '{
    "allowlist": ["com.gse.mdm"],
    "disable_screenshot": false,
    "disable_usb": false,
    "disable_install": false,
    "disable_camera": false,
    "disable_bluetooth": false,
    "kiosk_mode": false
}'::jsonb;

-- 2. Copy config จาก policies ไปยัง devices
UPDATE mdm.devices d
SET config = p.config
FROM mdm.device_policies dp
JOIN mdm.policies p ON dp.policy_id = p.id
WHERE d.id = dp.device_id;

-- 3. เพิ่ม column config ใน provisioning_tokens
ALTER TABLE mdm.provisioning_tokens
ADD COLUMN config JSONB NOT NULL DEFAULT '{
    "allowlist": ["com.gse.mdm"],
    "disable_screenshot": false,
    "disable_usb": false,
    "disable_install": false,
    "disable_camera": false,
    "disable_bluetooth": false,
    "kiosk_mode": false
}'::jsonb;

-- 4. Copy config จาก policies ไปยัง provisioning_tokens
UPDATE mdm.provisioning_tokens pt
SET config = p.config
FROM mdm.policies p
WHERE pt.policy_id = p.id;

-- 5. สร้างตาราง config_templates
CREATE TABLE mdm.config_templates (...);

-- 6. ลบตาราง policies และ device_policies (ระวัง!)
-- DROP TABLE mdm.device_policies;
-- DROP TABLE mdm.policies;
```

**หมายเหตุ:** ควร backup ข้อมูลก่อน migrate!
