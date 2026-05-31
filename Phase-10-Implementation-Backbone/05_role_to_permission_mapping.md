# RBAC to ABAC & SoD Mapping Matrix

## 🎯 الغرض التنفيذي
نقل تعريفات الأدوار الوهمية إلى هيكل وظيفي فعلي يخضع لفحوصات قصر الدارة (Short-circuit) للـ SoD وعمليات الـ JIT Escalation.

## 🛡️ الثوابت الحاكمة المترجمة
- `INV-PRIVILEGE-BOUND`
- `INV-SOD-PRECHECK`
- `INV-JIT-WORKFLOW`

## 🧩 مصفوفة الوظائف التشغيلية والمالية (Functional Matrix)

| الدور (Role) | التصنيف المعماري | الوصف التنفيذي | تفعيل SoD | مسار التجاوز الاستثنائي (JIT) |
|--------------|-------------------|----------------|-----------|------------------------------|
| `Inventory_Manager` | `OPERATIONAL` | اعتماد استلام وإصدار المخزون. | يتعارض مع `Financial_Controller`. | JIT يتطلب Risk Tier: Medium، وعتماد مدير عام. |
| `Financial_Controller` | `FINANCIAL` | ترحيل القيود اليومية (Posting). | يتعارض مع `Inventory_Manager`. | JIT يتطلب Risk Tier: High، وعتماد لجنة التدقيق. |
| `System_Auditor` | `SYSTEM` | قراءة السجلات، تتبع المهلة (DLQ). | يتعارض مع أي دور كتابي (Write Role). | لا يقبل التجاوز لإنشاء قيود مالية نهائياً. |
| `Tenant_Admin` | `SYSTEM_ADMIN` | إعداد قواعد الـ Policy Engine. | -- | كل الأنشطة المحاسبية المباشرة معطلة، الإدراج مقفل عبر DB. |

## ⚙️ نقاط التكامل التشغيلي (Enforcement Hooks)
- نظام `AuthZ Kernel` سيقوم بتمرير مُعرّف المستخدم وأدواره إلى جدول `sod_conflict_matrix`.
- إذا اكتشف أي `HardBlock`، يعود برد `403` مع `{"code": "SOD_CONFLICT", "roles": [...]}`.
- تطبيق الواجهة الأمامية (`Frontend`) مُلزم بتقديم تجربة (JIT Workflow) لطلب صلاحية مؤقتة وإرفاق `justification` عند استلام هذا الرمز، ولا يسمح باتخاذ قرار صلاحية محلياً.
