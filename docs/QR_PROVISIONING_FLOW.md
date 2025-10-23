# QR Provisioning Flow - GSE-MDM

## ภาพรวม
QR Provisioning Flow เป็นกระบวนการลงทะเบียนเครื่องใหม่โดยใช้ QR Code เพื่อให้เครื่องสามารถเชื่อมต่อกับระบบ MDM ได้อย่างปลอดภัย

## ขั้นตอนการทำงาน

### 1. Admin สร้าง QR Token
```sql
-- Admin เรียกใช้ฟังก์ชันสร้าง token
SELECT * FROM mdm.create_provisioning_token(
    'BKK01',           -- รหัสสาขา
    'policy-uuid-123', -- Policy ID
    168                -- หมดอายุใน 7 วัน
);
```

**ผลลัพธ์:**
- `token`: "abc123def456..." (64 ตัวอักษร)
- `expires_at`: "2024-01-15 10:30:00"

### 2. Dashboard สร้าง QR Code
Dashboard ใช้ token ที่ได้จากขั้นตอนที่ 1 สร้าง QR Code ที่มีข้อมูล:
```json
{
  "token": "abc123def456...",
  "server_url": "https://your-project.supabase.co",
  "api_key": "your-service-role-key"
}
```

### 3. Agent สแกน QR Code
```java
// QRScannerActivity.java
private void processQRData(String qrData) {
    // Parse QR data
    JSONObject qrInfo = new JSONObject(qrData);
    String token = qrInfo.getString("token");
    
    // Validate token with Supabase
    JSONObject result = supabaseService.validateProvisioningToken(
        token, deviceId, serialNumber
    );
    
    if (result.getBoolean("valid")) {
        // Token ถูกต้อง, ดำเนินการต่อ
        activateEnrollment(result.getString("enrollment_id"));
    }
}
```

### 4. Supabase ตรวจสอบ Token
```sql
-- ฟังก์ชัน validate_provisioning_token
SELECT * FROM mdm.validate_provisioning_token(
    'abc123def456...',  -- token
    'device-uuid-001',  -- device_id
    'SN123456789'       -- serial_number
);
```

**ผลลัพธ์:**
- `valid`: true
- `branch_code`: "BKK01"
- `policy_id`: "policy-uuid-123"
- `enrollment_id`: "enrollment-uuid-456"

### 5. Agent ลงทะเบียนเครื่อง
```java
// QRScannerActivity.java
private void activateEnrollment(String enrollmentId) {
    JSONObject device = supabaseService.activateDeviceEnrollment(
        enrollmentId,
        deviceName,
        model,
        osVersion,
        knoxVersion,
        userId
    );
    
    if (device != null) {
        // ลงทะเบียนสำเร็จ
        PreferenceUtils.setDeviceRegistered(this, true);
        PreferenceUtils.setDeviceUuid(this, device.getString("device_uuid"));
    }
}
```

### 6. Supabase สร้าง Device Record
```sql
-- ฟังก์ชัน activate_device_enrollment
-- 1. อัปเดต enrollment status เป็น 'active'
UPDATE mdm.device_enrollments 
SET status = 'active', last_seen_at = NOW() 
WHERE id = enrollment_id;

-- 2. สร้าง device record
INSERT INTO mdm.devices (
    device_uuid, serial_number, branch_code, 
    policy_id, status, enrollment_id
) VALUES (
    'device-uuid-001', 'SN123456789', 'BKK01',
    'policy-uuid-123', 'active', 'enrollment-uuid-456'
);

-- 3. Apply initial policy
INSERT INTO mdm.device_policies (device_id, policy_id, status)
VALUES (device_id, policy_id, 'applied');
```

## ไฟล์ที่เกี่ยวข้อง

### Android Agent App
- `QRScannerActivity.java` - หน้าจอสแกน QR
- `activity_qr_scanner.xml` - Layout สำหรับ QR Scanner
- `SupabaseService.java` - API client สำหรับ Supabase

### Supabase Database
- `provisioning_tokens` - ตารางเก็บ QR tokens
- `device_enrollments` - ตารางเก็บการลงทะเบียน
- `devices` - ตารางเก็บเครื่องที่ active
- `create_provisioning_token()` - ฟังก์ชันสร้าง token
- `validate_provisioning_token()` - ฟังก์ชันตรวจสอบ token
- `activate_device_enrollment()` - ฟังก์ชัน activate เครื่อง

## Security Features

### 1. Token Security
- Token มีความยาว 64 ตัวอักษร (32 bytes hex)
- มีวันหมดอายุ (default 7 วัน)
- ใช้ได้ครั้งเดียว (one-time use)
- สร้างด้วย `gen_random_bytes()`

### 2. Device Validation
- ตรวจสอบ Device Owner status
- ตรวจสอบ Serial Number
- ตรวจสอบ Knox support

### 3. Policy Enforcement
- Apply policy ทันทีหลังลงทะเบียน
- ใช้ DevicePolicyManager API
- รองรับ Knox SDK features

## Error Handling

### 1. Invalid Token
```java
if (!result.getBoolean("valid")) {
    tvStatus.setText("QR Code ไม่ถูกต้องหรือหมดอายุ");
    Toast.makeText(this, "QR Code ไม่ถูกต้อง", Toast.LENGTH_LONG).show();
}
```

### 2. Network Error
```java
try {
    JSONObject result = supabaseService.validateProvisioningToken(...);
} catch (Exception e) {
    LogUtils.logError(this, TAG, "processQRData", e);
    tvStatus.setText("เกิดข้อผิดพลาด: " + e.getMessage());
}
```

### 3. Device Owner Required
```java
if (!DeviceUtils.isDeviceOwner(context)) {
    // แสดงข้อความให้ตั้ง Device Owner ก่อน
    showDeviceOwnerRequiredDialog();
}
```

## Testing

### 1. Unit Tests
- Test token generation
- Test token validation
- Test device activation

### 2. Integration Tests
- Test QR scan flow
- Test Supabase communication
- Test policy application

### 3. End-to-End Tests
- Test complete provisioning flow
- Test error scenarios
- Test security features

## Monitoring & Logging

### 1. Device Registration Logs
```sql
SELECT * FROM mdm.logs 
WHERE category = 'enrollment' 
ORDER BY created_at DESC;
```

### 2. Token Usage Stats
```sql
SELECT 
    COUNT(*) as total_tokens,
    COUNT(CASE WHEN used = true THEN 1 END) as used_tokens,
    COUNT(CASE WHEN expires_at < NOW() THEN 1 END) as expired_tokens
FROM mdm.provisioning_tokens;
```

### 3. Device Status
```sql
SELECT 
    status,
    COUNT(*) as device_count
FROM mdm.devices 
GROUP BY status;
```

## Best Practices

### 1. Token Management
- สร้าง token ใหม่สำหรับแต่ละเครื่อง
- ตั้งวันหมดอายุที่เหมาะสม (7-30 วัน)
- ลบ token ที่หมดอายุแล้ว

### 2. Error Handling
- แสดงข้อความ error ที่เข้าใจง่าย
- Log error details สำหรับ debugging
- Retry mechanism สำหรับ network errors

### 3. Security
- ใช้ HTTPS สำหรับ API calls
- ตรวจสอบ Device Owner status
- Validate input data

### 4. User Experience
- แสดง progress indicator
- ให้ feedback ที่ชัดเจน
- รองรับ manual entry (fallback)
