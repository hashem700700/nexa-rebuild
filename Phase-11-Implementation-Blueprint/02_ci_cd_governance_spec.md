# 02_ci_cd_governance_spec.md

## 🎯 الغرض التنفيذي
أتمتة الدستور المعماري من خلال خطوط الإنتاج (Pipelines) وتحويل ثوابت الحوكمة (Phases 0-10) إلى دوال وظائف (Fitness Functions) رياضية لضمان الامتثال الدائم.

## 🛡️ الثابت الحاكم المترجم
- `CONSTITUTION-AS-CODE`
- `INV-NO-DB-GEN`

---

### 1. Static Architecture Tests (Boundary Violation Guards)
تطبيق قواعد صارمة لتحليل الكود الثابت لمنع التجاوز المعماري:
- **تحليل الاستيرادات (Import Boundaries):**
  الـ `Inventory Engine` يُمنع برمجياً من استيراد أي ملف ينتمي لـ `Accounting Core`.
  - **القرار الأوتوماتيكي:** كسر البناء وإرجاع `Architectural Violation (Code A001)`.
- **تفحص التشفير (Crypto Scanning):**
  Linter يمنع وجود متغيرات مثل `plaintext_secret` أو تمرير مفاتيح KMS صريحة في الـ Domain Logic.

### 2. Formal Invariants Verification (Runtime Tests)
- **ZeroLeakageTest (Tenant Isolation):**
  اختبار وظيفي ينفذ استعلام `SELECT` من قاعدة البيانات في Test Environment بدون حقن `tenant_id` في مساحة عمل الجلسة.
  - **شرط النجاح:** إرجاع `0 rows` أو Access Error صريح.
  - **الفشل:** تسرب أي داتا يُسقط خط الإنتاج.

- **DenyOverrideTest (AuthZ Determinism):**
  توليد طلب يحتوي على دور مسموح به (Allow) دور آخر يحظره (Deny) بأولوية قصوى.
  - **شرط النجاح:** رفض قطعي وتسجيل القرار فـي `authz_decision_audit`.

- **ImbalanceBlockTest (Financial Integrity):**
  محاولة إرسال قيد يومية حيث مجموع الـ Debit والتصارع مع الـ Credit متباينان بمقدار 0.01.
  - **شرط النجاح:** `Transaction Rollback` في طبقة הـ Database Engine (عبر الـ Triggers الحاكمة).

### 3. Outbox Determinism Guard
- الفحص الاستاتيكي يُسقط أي كود يستخدم `UUIDv4` العشوائي لتوليد حقل `event_id`، بدلاً من `UUIDv7` הזمني.
