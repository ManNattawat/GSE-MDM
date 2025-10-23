# GSE-MDM System Flow

## 🎯 Overview

เอกสารนี้อธิบายการทำงานของระบบ GSE-MDM ตั้งแต่การ Provision เครื่องใหม่จนถึงการ Monitor และควบคุมเครื่องระยะไกล

---

## 📱 1. Provisioning Flow (การเตรียมเครื่องใหม่)

### 1.1 QR Code Generation
```
Admin Dashboard → Generate QR Code
├── Supabase URL
├── Service Role Key (encrypted)
├── Branch Code
├── Initial Policy ID
└── Expiration Time
```

### 1.2 Device Setup Process
```
1. Reset Samsung Tablet (Factory Reset)
2. Scan QR Code with Agent App
3. Agent App becomes Device Owner
4. Register device with Supabase
5. Download and apply initial policy
6. Device ready for use
```

### 1.3 QR Code Structure
```json
{
  "supabase_url": "https://xxx.supabase.co",
  "service_key": "encrypted_key",
  "branch_code": "BKK001",
  "policy_id": "uuid",
  "expires_at": "2025-12-31T23:59:59Z"
}
```

---

## 🔐 2. Policy Enforcement Flow (การบังคับใช้นโยบาย)

### 2.1 Policy Distribution
```
Supabase → Agent App (Every 30 seconds)
├── Check for new policies
├── Download policy config
├── Apply policy locally
└── Send result back to Supabase
```

### 2.2 Policy Types
```json
{
  "allowlist": [
    "com.gse.pwa",
    "jp.naver.line.android"
  ],
  "kiosk_mode": true,
  "disable_screenshot": true,
  "disable_usb": true,
  "disable_install": true,
  "restrict_settings": true
}
```

### 2.3 Policy Application Process
```
1. Agent receives policy from Supabase
2. Validate policy configuration
3. Apply using DevicePolicyManager
4. Apply Knox-specific settings
5. Send success/failure status
6. Log policy application
```

---

## 🎮 3. Remote Command Flow (การสั่งงานระยะไกล)

### 3.1 Command Issuance
```
Admin Dashboard → Supabase → Agent App
├── Admin clicks command button
├── Command queued in database
├── Agent polls for commands
├── Execute command locally
└── Send result back
```

### 3.2 Command Types
- **LOCK** - ล็อคหน้าจอ
- **WIPE** - ลบข้อมูลทั้งหมด
- **REBOOT** - รีสตาร์ทเครื่อง
- **UPDATE** - อัปเดต Agent App
- **POLICY_UPDATE** - อัปเดต Policy

### 3.3 Command Execution Process
```
1. Agent polls Supabase every 30 seconds
2. Check for pending commands
3. Execute command using appropriate API
4. Update command status in database
5. Send execution result
6. Log command execution
```

---

## 📊 4. Monitoring Flow (การติดตามสถานะ)

### 4.1 Device Status Reporting
```
Agent App → Supabase (Every 30 seconds)
├── Device status (online/offline)
├── Battery level
├── Policy compliance status
├── Error logs
└── Performance metrics
```

### 4.2 Real-time Dashboard Updates
```
Supabase → Dashboard (Real-time subscription)
├── Device list updates
├── Status changes
├── Command results
├── Policy changes
└── Alert notifications
```

### 4.3 Alert System
```
Conditions:
├── Device offline > 1 hour
├── Policy violation detected
├── Command execution failed
├── Battery level < 20%
└── Agent version outdated
```

---

## 🔄 5. Update Flow (การอัปเดตระบบ)

### 5.1 Agent App Update
```
1. Admin uploads new APK to Supabase
2. Agent checks for updates every hour
3. Download new APK if available
4. Install silently (Device Owner privilege)
5. Restart with new version
6. Report update status
```

### 5.2 Policy Update
```
1. Admin modifies policy in Dashboard
2. Policy marked as "pending" for devices
3. Agent downloads new policy
4. Apply policy changes
5. Report application status
6. Policy marked as "applied"
```

---

## 🛡️ 6. Security Flow (การรักษาความปลอดภัย)

### 6.1 Authentication
```
Agent App:
├── Service Role Key (encrypted in QR)
├── Device ID (unique per device)
└── Branch Code (for grouping)

Dashboard:
├── Supabase Auth
├── Role-based access (admin/operator)
└── Session management
```

### 6.2 Data Encryption
```
Sensitive Data:
├── Service keys (AES-256)
├── Command payloads (encrypted)
├── Log data (encrypted at rest)
└── Communication (HTTPS/TLS)
```

---

## 📈 7. Performance Flow (การจัดการประสิทธิภาพ)

### 7.1 Sync Optimization
```
Polling Intervals:
├── Commands: 30 seconds
├── Policies: 5 minutes
├── Status: 30 seconds
├── Logs: 1 minute
└── Updates: 1 hour
```

### 7.2 Error Handling
```
Error Types:
├── Network errors (retry with backoff)
├── API errors (log and continue)
├── Policy errors (revert to safe state)
├── Command errors (report failure)
└── System errors (restart service)
```

---

## 🔧 8. Troubleshooting Flow (การแก้ไขปัญหา)

### 8.1 Common Issues
```
Device Issues:
├── Cannot become Device Owner
├── Policy not applying
├── Commands not executing
├── Sync failures
└── App crashes
```

### 8.2 Recovery Procedures
```
Recovery Steps:
├── Check device connectivity
├── Verify Supabase connection
├── Restart Agent service
├── Re-apply policies
├── Factory reset (last resort)
└── Re-provision device
```

---

## 📋 9. Audit Flow (การตรวจสอบ)

### 9.1 Activity Logging
```
Logged Events:
├── Device registration
├── Policy applications
├── Command executions
├── Status changes
├── Error occurrences
└── Admin actions
```

### 9.2 Compliance Reporting
```
Reports:
├── Device compliance status
├── Policy violation summary
├── Command execution history
├── System health metrics
└── Security audit trail
```

---

## 🎯 10. Success Criteria

### 10.1 Functional Requirements
- ✅ 100% Device Owner control
- ✅ Real-time policy enforcement
- ✅ Remote command execution
- ✅ Comprehensive monitoring
- ✅ Secure communication

### 10.2 Performance Requirements
- ✅ < 30 seconds command execution
- ✅ < 5 minutes policy distribution
- ✅ 99% uptime for critical functions
- ✅ < 1MB data usage per day
- ✅ < 5% battery impact

### 10.3 Security Requirements
- ✅ Encrypted communication
- ✅ Role-based access control
- ✅ Audit trail for all actions
- ✅ Secure key management
- ✅ Data privacy compliance

---

**Last Updated:** 2025-01-07  
**Version:** 1.0.0  
**Status:** Development Phase
