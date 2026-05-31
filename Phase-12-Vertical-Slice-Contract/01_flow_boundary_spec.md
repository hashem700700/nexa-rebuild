# 01_flow_boundary_spec.md

## 🎯 الغرض التنفيذي للمسار
إثبات التشغيل الحتمي لمسار حركة المخزون (Inventory Stock Movement) كأول Vertical Slice. يضمن العقد أن الطلب يمر بجميع بوابات الحوكمة (AuthZ, Saga, Accounting, Outbox) كمعاملة ذرية واحدة قبل أن يعود برد للعميل.

## 🛡️ الثوابت الحاكمة المترجمة
- `INV-SLICE-ATOMICITY`: Transaction must completely succeed or completely fail.
- `INV-BOUNDARY-CALL-ORDER`: Strict sequence (AuthZ → Inventory → Accounting → Outbox).

## 📊 مسار التنفيذ الحتمي (Step-by-Step Contract)
1. **API Gateway Receiver**: استقبال الـ Request وتشكيل غلاف הـ `Context` (uuid, tenant_id, user_id).
2. **AuthZ Kernel Hook**: تمرير الـ `Context` لنواة التفويض. إذا الرد `DENY`، ينتهي المسار فوراً `403`.
3. **Inventory Command Handler**: 
   - بدء المعاملة الذرية (DB Transaction `BEGIN`).
   - تقييم قاعدة المخزون (INV-STOCK-NEVER-NEG).
4. **Accounting Posting Service (Atomic Call)**: 
   - إنشاء القيد المزدوج بناءً على تقييم المخزون المالي (INV-DB-ENTRY).
5. **Outbox Event Appender**: 
   - داخل نفس المعاملة، تسجيل حدث `StockMovementCompleted`.
6. **Transaction Commit**: `COMMIT` لإنهاء الـ Atomic Block المُدمج.

## 🚧 حدود البيانات (Allowed/Forbidden Data Boundaries)
- **مسموح**: تمرير `Context Envelope` كامل بين الطبقات.
- **ممنوع**: وصول `Inventory Command Handler` مباشرة لجداول `journal_entries`. الاتصال يتم حصراً عبر `Accounting Core Service`.

## 🔗 نقطة التكامل مع مستوى الحوكمة (Governance Layer)
- المعاملة بالكامل تخضع لاختبار `ImbalanceBlockTest` و `ZeroLeakageTest` في خط الإنتاج، ولـ RLS Session injection في طبقة الـ Database.

## ⚠️ الاستثناءات المقبولة
- لا توجد استثناءات. أي اختلال في الترتيب يُصنف Architectural Violation (A101).
