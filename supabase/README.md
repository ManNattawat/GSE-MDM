# GSE-MDM Supabase Schema Setup

## การติดตั้ง Schema

### 1. รัน Schema หลัก
```bash
# ใช้ psql
psql -h <your-supabase-host> -U postgres -d postgres -f schema.sql

# หรือใช้ Supabase Dashboard
# 1. เปิด Supabase Dashboard
# 2. ไปที่ SQL Editor
# 3. Copy เนื้อหาจาก schema.sql แล้ว Paste
# 4. กด Run
```

### 2. ตรวจสอบ Permissions
```bash
# รันสคริปต์ตรวจสอบ
psql -h <your-supabase-host> -U postgres -d postgres -f check_permissions.sql
```

**สิ่งที่ต้องตรวจสอบ:**
- ✅ มี views `public.device_summary` และ `public.policy_summary`
- ✅ `authenticated` role มีสิทธิ์ SELECT บน `mdm.*` tables
- ✅ `authenticated` role มีสิทธิ์ SELECT บน `public.device_summary` และ `public.policy_summary`

### 3. แก้ไข Permissions (ถ้าจำเป็น)
```bash
# รันสคริปต์แก้ไข
psql -h <your-supabase-host> -U postgres -d postgres -f fix_permissions.sql
```

## โครงสร้าง Schema

### Schema: `mdm`
ตารางหลักทั้งหมด:
- `devices` - ข้อมูลเครื่อง Tablet
- `policies` - นโยบายการควบคุม
- `commands` - คำสั่งระยะไกล
- `logs` - บันทึกการทำงาน
- `device_status` - สถานะเครื่อง
- `device_policies` - ผูกเครื่องกับนโยบาย
- `provisioning_tokens` - QR tokens
- `device_enrollments` - การลงทะเบียน
- `audit_logs` - บันทึกตรวจสอบ
- `app_versions` - เวอร์ชันแอป

Views:
- `device_summary` - รวมข้อมูล devices + status
- `policy_summary` - รวมข้อมูล policies + สถิติ

### Schema: `public`
Views สำหรับ Dashboard:
- `device_summary` → ชี้ไปที่ `mdm.device_summary`
- `policy_summary` → ชี้ไปที่ `mdm.policy_summary`

## การใช้งานใน Dashboard

### อ่านข้อมูล (Recommended)
```typescript
// ใช้ public views
const { data } = await supabase.from('device_summary').select('*')
const { data } = await supabase.from('policy_summary').select('*')
```

### เขียนข้อมูล
```typescript
// ใช้ตาราง mdm โดยตรง
const { error } = await supabase.from('mdm.policies').insert(...)
const { error } = await supabase.from('mdm.commands').insert(...)
```

## Troubleshooting

### ปัญหา: Dashboard ไม่สามารถอ่านข้อมูลได้

**สาเหตุที่เป็นไปได้:**
1. ไม่มี permissions สำหรับ `authenticated` role
2. RLS policies บล็อกการเข้าถึง
3. Views ใน `public` schema ยังไม่ถูกสร้าง

**วิธีแก้:**
```sql
-- 1. ตรวจสอบ permissions
SELECT * FROM information_schema.role_table_grants
WHERE grantee = 'authenticated' AND table_schema = 'mdm';

-- 2. Grant permissions
GRANT SELECT ON ALL TABLES IN SCHEMA mdm TO authenticated;

-- 3. ตรวจสอบ views
SELECT * FROM pg_views WHERE schemaname = 'public';

-- 4. สร้าง views ใหม่
CREATE OR REPLACE VIEW public.device_summary AS
SELECT * FROM mdm.device_summary;
```

### ปัญหา: ไม่สามารถ INSERT/UPDATE/DELETE ได้

**สาเหตุ:**
- ใช้ views แทนตาราง (views เป็น read-only)

**วิธีแก้:**
```typescript
// ❌ ผิด
await supabase.from('device_summary').insert(...)

// ✅ ถูก
await supabase.from('mdm.devices').insert(...)
```

### ปัญหา: Error "permission denied for schema mdm"

**วิธีแก้:**
```sql
GRANT USAGE ON SCHEMA mdm TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA mdm TO authenticated;
```

## Environment Variables

ตั้งค่าใน `.env`:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

## Security Notes

1. **RLS (Row Level Security)** เปิดใช้งานทุกตาราง
2. **Service Role** มีสิทธิ์เต็ม (ใช้สำหรับ Agent App)
3. **Authenticated Users** อ่านได้อย่างเดียว (ใช้สำหรับ Dashboard)
4. **Anonymous Users** อ่านได้เฉพาะ public views

## Sample Data

Schema มี sample data พร้อมใช้งาน:
- 3 policies (Default, Strict, Basic)
- 1 app version (GSE-MDM-Agent v1.0.0)

## การอัปเดต Schema

เมื่อมีการเปลี่ยนแปลง schema:

1. แก้ไขไฟล์ `schema.sql`
2. สร้าง migration script แยก
3. รันใน Supabase Dashboard
4. อัปเดต TypeScript types ใน `dashboard/src/lib/supabase.ts`

## ติดต่อ

หากมีปัญหาหรือคำถาม:
- ตรวจสอบ logs ใน Supabase Dashboard
- รันสคริปต์ `check_permissions.sql`
- ดู error messages ใน browser console
