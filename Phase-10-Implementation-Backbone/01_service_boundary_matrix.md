# Service Boundary Matrix & Domain Ownership Contract

## 🎯 الغرض التنفيذي
تحويل قاعدة الفصل المنطقي إلى حواجز فيزيائية (Module Boundaries) تمنع التداخل أو تجاوز الصلاحيات بين النطاقات.

## 🛡️ الثوابت الحاكمة المترجمة
- `DOMAIN ISOLATION RULE`
- `INV-NO-DIRECT-LEDGER`
- `INV-KERNEL-SINGLE-ENTRY`

## 📦 مصفوفة حدود النطاقات (Domain Boundaries)

| النطاق (Domain) | المسؤولية الحصرية (Ownership) | الاتصالات المسموحة (Allowed Outbound) | الممنوعات المطلقة (Forbidden) |
|-----------------|-------------------------------|---------------------------------------|--------------------------------|
| **Identity Kernel** | التوليد الحصري لـ UUID v7 و v4 وإدارة تسلسل الهوية | None. (يُستدعى ولا يَستدعي) | حفظ حالة (Stateless only)، استدعاء أي نطاق آخر. |
| **AuthZ Kernel** | تقييم الصلاحيات، SoD، وفحص الـ JIT | إصدار أحداث `AuthZ_Invalidation` في Outbox | أي تجاوز لمنطق `Deny-Overrides`، قراءة بيانات الأعمال. |
| **Accounting Core** | دفتر الأستاذ (GL)، القيود المزدوجة، فترات الإغلاق | حفظ القيود، إصدار حدث `JournalPosted` | قبول بيانات غير متوازنة، أي تعديل مباشر بعد الترحيل. |
| **Inventory MVP** | حركات المخزون، تقييم الأرصدة التشغيلية | بدء `Saga Execution`، إصدار `StockMoved` | التعديل المباشر أو القراءة المباشرة لجداول `Accounting`. |
| **Saga Orchestrator** | مسارات العمليات العابرة وتطبيق التعويض العكسي | استدعاء `AuthZ Kernel`، تعديل حالة الـ Steps | اتخاذ قرارات الأعمال (Business Logic)، يجب أن يكون مجرد منسق. |

## 🚫 قيود الاستيراد (Import/Dependency Rules)
1. ممنوع مطلقاً (Circular Dependency) بين أي نطاقين.
2. نطاقات الأعمال (`Accounting`, `Inventory`) تتواصل فيما بينها **فقط** عبر الـ `Event Bus` أو منسق `Saga Orchestrator`.
3. واجهات القراءة (Projections) لا تستدعي أبداً أوامر الكتابة (Commands).
