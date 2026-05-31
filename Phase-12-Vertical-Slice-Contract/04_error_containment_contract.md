# 04_error_containment_contract.md

## 🎯 الغرض التنفيذي للمسار
ضبط سلوك النظام عند الفشل لمنع التسرب المعلوماتي، تجنب الحركات المعلقة، وتحفيز آليات التعويض الصارمة (Saga Compensation & DLQ).

## 🛡️ الثوابت الحاكمة المترجمة
- `INV-ERROR-CONTAINMENT`: Strict failure bounding, standardized error responses.
- `INV-NO-HANGING-TX`: Timeout or failure translates to rollbacks/DLQ immediately.

## 📊 مسار إدارة الفشل (Failure Flow Matrix)

| نقطة الفشل | العلة (Trigger) | الفعل الهندسي (System Action) | رد العميل (Client Response) |
|------------|-----------------|-------------------------------|-----------------------------|
| `API/AuthZ` | Token Invalid / SoD Violation | `Stop Execution`, تسطير محاولة الفشل. | `401 Unauthorized` / `403 Forbidden` + `ErrorCode` مجرد. |
| `Inventory`| Stock becomes negative | المعاملة (Transaction Block Blocked) → `ROLLBACK`. | `422 Unprocessable Entity` + "Insufficient Stock". |
| `Accounting`| Journal Imbalance | Database Trigger יﺮﻓﺾ الـ Commit → `ROLLBACK`. | `500/400 Error` + Log Alert. |
| `Sync Consumer` | Database Unreachable | Event يترك في `Bus` أو يُنقل إلى `DLQ`. | Client Unknown. مسار مستقل لا يعطل تجربة المستخدم. |

## 🚧 حدود البيانات (Allowed/Forbidden Data Boundaries)
- **مسموح**: عرض أكواد أخطاء وظيفية مجردة (e.g., `ERR_INVENTORY_001`).
- **ممنوع**: إرجاع التفاصيل التقنية الدقيقة (Database Exception Traces, Stack Traces) إلى الـ Client قطعيًا لمنع Reverse Engineering للمخطط الحساس.

## 🔗 نقطة التكامل مع مستوى الحوكمة (Governance Layer)
- الحركات المعلقة تنقل لـ `dead_letter_queue` وفق سياسة `INV-NO-HANGING-TX`. كل حركة في DLQ تتطلب معالجة بشرية أو إعادة توجيه تسجل كـ Audit.

## ⚠️ الاستثناءات المقبولة
- أخطاء الشبكة المؤقتة (Transient Network Errors) في الاتصال بقاعدة البيانات تُعاد تلقائياً (Retries) 3 مرات داخل הـ Gateway قبل اتخاذ قرار الفشل النهائي.
