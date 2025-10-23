# 📊 MDM Schema Analysis

## ✅ ตารางที่มีอยู่แล้วใน MDM Schema

จากการตรวจสอบ Supabase พบว่ามีตารางเหล่านี้:

### 1. **mdm.devices** ✅
- อุปกรณ์ที่ลงทะเบียนในระบบ
- ควรมี: device_id, branch_code, model, os_version, status, etc.

### 2. **mdm.policies** ✅
- นโยบายการจัดการอุปกรณ์
- ควรมี: id, name, config (JSON), is_active

### 3. **mdm.device_policies** ✅
- เชื่อมโยงอุปกรณ์กับนโยบาย
- ควรมี: device_id, policy_id, applied_at, status

### 4. **mdm.provisioning_tokens** ✅
- Token สำหรับลงทะเบียนอุปกรณ์ใหม่
- ควรมี: token, branch_code, policy_id, expires_at, is_used

### 5. **mdm.commands** ✅
- คำสั่งที่ส่งไปยังอุปกรณ์
- ควรมี: device_id, command_type, payload, status, executed_at

### 6. **mdm.audit_logs** ✅
- บันทึกการเปลี่ยนแปลงและกิจกรรม
- ควรมี: action, user_id, device_id, details, timestamp

### 7. **mdm.logs** ✅
- Log ทั่วไปของระบบ
- ควรมี: level, message, metadata, timestamp

### 8. **mdm.device_status** ✅
- สถานะปัจจุบันของอุปกรณ์
- ควรมี: device_id, battery_level, storage_used, last_seen

### 9. **mdm.device_enrollments** ✅
- ประวัติการลงทะเบียนอุปกรณ์
- ควรมี: device_id, enrollment_method, enrolled_at, enrolled_by

### 10. **mdm.app_versions** ✅
- เวอร์ชันของแอป MDM Agent
- ควรมี: version, release_notes, min_os_version, download_url

---

## ❌ ตารางที่อาจจะขาดหรือควรเพิ่ม

### 1. **mdm.device_locations** 🆕
```sql
CREATE TABLE mdm.device_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  accuracy DECIMAL(10, 2),
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
**เหตุผล:** ติดตามตำแหน่งอุปกรณ์สำหรับ Find My Device

### 2. **mdm.device_apps** 🆕
```sql
CREATE TABLE mdm.device_apps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id),
  package_name TEXT NOT NULL,
  app_name TEXT,
  version_name TEXT,
  version_code INTEGER,
  is_system_app BOOLEAN DEFAULT false,
  installed_at TIMESTAMPTZ,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(device_id, package_name)
);
```
**เหตุผล:** ติดตามแอปที่ติดตั้งในอุปกรณ์

### 3. **mdm.compliance_checks** 🆕
```sql
CREATE TABLE mdm.compliance_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id),
  policy_id UUID REFERENCES mdm.policies(id),
  check_type TEXT NOT NULL, -- 'app_compliance', 'security_check', 'policy_violation'
  status TEXT NOT NULL CHECK (status IN ('compliant', 'non_compliant', 'warning')),
  details JSONB,
  checked_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);
```
**เหตุผล:** ตรวจสอบว่าอุปกรณ์ปฏิบัติตามนโยบายหรือไม่

### 4. **mdm.device_groups** 🆕
```sql
CREATE TABLE mdm.device_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mdm.device_group_members (
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id),
  group_id UUID NOT NULL REFERENCES mdm.device_groups(id),
  added_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (device_id, group_id)
);
```
**เหตุผล:** จัดกลุ่มอุปกรณ์เพื่อจัดการเป็นกลุ่ม

### 5. **mdm.notifications** 🆕
```sql
CREATE TABLE mdm.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT REFERENCES mdm.devices(device_id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info', -- 'info', 'warning', 'error', 'success'
  priority TEXT DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
  is_read BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ
);
```
**เหตุผล:** ส่งการแจ้งเตือนไปยังอุปกรณ์หรือผู้ดูแลระบบ

### 6. **mdm.geofences** 🆕
```sql
CREATE TABLE mdm.geofences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  center_latitude DECIMAL(10, 8) NOT NULL,
  center_longitude DECIMAL(11, 8) NOT NULL,
  radius_meters INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mdm.geofence_violations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id),
  geofence_id UUID NOT NULL REFERENCES mdm.geofences(id),
  violation_type TEXT NOT NULL, -- 'entered', 'exited'
  occurred_at TIMESTAMPTZ DEFAULT NOW()
);
```
**เหตุผล:** กำหนดพื้นที่ที่อนุญาตและติดตามการละเมิด

### 7. **mdm.remote_actions** 🆕
```sql
CREATE TABLE mdm.remote_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id),
  action_type TEXT NOT NULL, -- 'lock', 'wipe', 'locate', 'ring', 'message'
  initiated_by TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'executing', 'completed', 'failed'
  result JSONB,
  initiated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);
```
**เหตุผล:** บันทึกการดำเนินการระยะไกล (Remote Lock, Wipe, etc.)

### 8. **mdm.certificates** 🆕
```sql
CREATE TABLE mdm.certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT REFERENCES mdm.devices(device_id),
  certificate_type TEXT NOT NULL, -- 'device', 'vpn', 'wifi', 'email'
  subject TEXT,
  issuer TEXT,
  serial_number TEXT,
  valid_from TIMESTAMPTZ,
  valid_until TIMESTAMPTZ,
  is_revoked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
**เหตุผล:** จัดการ certificates สำหรับความปลอดภัย

### 9. **mdm.network_configs** 🆕
```sql
CREATE TABLE mdm.network_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  config_type TEXT NOT NULL, -- 'wifi', 'vpn', 'proxy'
  config_data JSONB NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mdm.device_network_configs (
  device_id TEXT NOT NULL REFERENCES mdm.devices(device_id),
  config_id UUID NOT NULL REFERENCES mdm.network_configs(id),
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (device_id, config_id)
);
```
**เหตุผล:** จัดการการตั้งค่า WiFi, VPN, Proxy

### 10. **mdm.scheduled_tasks** 🆕
```sql
CREATE TABLE mdm.scheduled_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_type TEXT NOT NULL, -- 'compliance_check', 'update_check', 'backup'
  target_type TEXT NOT NULL, -- 'device', 'group', 'all'
  target_id TEXT,
  schedule_cron TEXT NOT NULL, -- Cron expression
  is_active BOOLEAN DEFAULT true,
  last_run_at TIMESTAMPTZ,
  next_run_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
**เหตุผล:** กำหนดเวลาการทำงานอัตโนมัติ

---

## 🔧 Columns ที่อาจจะขาดในตารางที่มีอยู่

### **mdm.devices**
ควรมี columns เหล่านี้:
- ✅ `device_id` (Primary Key)
- ✅ `branch_code`
- ✅ `device_name`
- ✅ `model`
- ✅ `manufacturer`
- ✅ `os_version`
- ✅ `status` (active, inactive, lost, wiped)
- ✅ `enrolled_at`
- ✅ `last_seen`
- 🆕 `imei` - IMEI number
- 🆕 `serial_number` - Serial number
- 🆕 `phone_number` - เบอร์โทรศัพท์
- 🆕 `is_rooted` - ตรวจสอบว่า root/jailbreak หรือไม่
- 🆕 `security_patch_level` - ระดับ security patch
- 🆕 `assigned_to` - ผู้ใช้งานปัจจุบัน

### **mdm.policies**
ควรมี columns เหล่านี้:
- ✅ `id` (Primary Key)
- ✅ `name`
- ✅ `description`
- ✅ `config` (JSONB)
- ✅ `is_active`
- 🆕 `priority` - ลำดับความสำคัญ
- 🆕 `applies_to` - ใช้กับกลุ่มไหน (all, branch, group)
- 🆕 `version` - เวอร์ชันของนโยบาย

### **mdm.commands**
ควรมี columns เหล่านี้:
- ✅ `id` (Primary Key)
- ✅ `device_id`
- ✅ `command_type`
- ✅ `payload` (JSONB)
- ✅ `status`
- ✅ `created_at`
- 🆕 `priority` - ลำดับความสำคัญ
- 🆕 `retry_count` - จำนวนครั้งที่ลองใหม่
- 🆕 `max_retries` - จำนวนครั้งสูงสุด
- 🆕 `expires_at` - เวลาหมดอายุ

---

## 📝 สรุปและคำแนะนำ

### ✅ **ที่มีอยู่แล้ว (10 ตาราง)**
ระบบมีตารางพื้นฐานครบแล้ว เพียงพอสำหรับ MDM ระดับ Basic

### 🆕 **ที่ควรเพิ่ม (10 ตาราง)**
1. `device_locations` - สำคัญมาก (Find My Device)
2. `device_apps` - สำคัญมาก (App Management)
3. `compliance_checks` - สำคัญ (Policy Enforcement)
4. `device_groups` - มีประโยชน์ (Group Management)
5. `notifications` - มีประโยชน์ (Alert System)
6. `geofences` - ขึ้นกับความต้องการ
7. `remote_actions` - สำคัญ (Remote Management)
8. `certificates` - ขึ้นกับความต้องการ
9. `network_configs` - มีประโยชน์ (Network Management)
10. `scheduled_tasks` - มีประโยชน์ (Automation)

### 🎯 **ลำดับความสำคัญในการเพิ่ม**

**Phase 1 (สำคัญที่สุด):**
1. `device_locations`
2. `device_apps`
3. `remote_actions`
4. `compliance_checks`

**Phase 2 (มีประโยชน์):**
5. `device_groups`
6. `notifications`
7. `network_configs`

**Phase 3 (ขึ้นกับความต้องการ):**
8. `geofences`
9. `certificates`
10. `scheduled_tasks`

---

## 🚀 ขั้นตอนต่อไป

1. **ตรวจสอบ structure** ของตารางที่มีอยู่ว่าครบหรือไม่
2. **เพิ่ม columns** ที่ขาดในตารางเดิม
3. **สร้างตารางใหม่** ตาม Phase 1-3
4. **สร้าง RLS policies** สำหรับความปลอดภัย
5. **สร้าง indexes** สำหรับ performance
6. **สร้าง functions** สำหรับ business logic

**คุณต้องการให้ผมสร้าง SQL scripts สำหรับตารางไหนก่อนครับ?**
