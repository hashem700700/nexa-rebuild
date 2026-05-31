# 04_error_compensation_path.md

## 🎯 نقطة الربط التنفيذية (Binding Point)
تحويل الأخطاء الفوضوية للأنظمة أو قواعد البيانات إلى عقود أخطاء معيارية، وتفعيل مسارات الـ Rollback والتعويض (DLQ).

## 🛡️ الثابت الحاكم
- `INV-ERROR-CONTAINMENT`: عزل تام للتفاصيل الداخلية.
- `INV-NO-HANGING-TX`: ضمان إغلاق الـ Transactions المنقطعة.

## 📦 غلاف البيانات (Data Envelope)
- **المدخلات**: `Error` / `Exception` قادم من أي طبقة سفلى.
- **المخرجات**: `ClientErrorEnvelope` (يحتوي `status_code`, `contract_code`, `correlation_id`).

## 🔄 مسار الربط (Wiring Contract)
1. **Database / Driver Error**: أي خطأ (مثلاً: رصيد متضارب، خطأ في الحفظ) سيُرمى كـ Exception من الـ `tx`.
2. **UnitOfWork Catcher**: سيلتقط الـ UoW الاستثناء الأساسي، ويصدر أمر `ROLLBACK` قاعدة البيانات فوراً. سيعيد رمي الخطأ المُغلف `DomainError`.
3. **Gateway Error Handler**: 
   - الـ Middleware الأخير في إكسبرس (Express Error Handler) يمسك الـ `DomainError`.
   - يترجم الـ Error إلى استجابة موحدة `JSON`: `{"error": "...", "code": "INV-00X", "correlation_id": "uuid"}`.
   - لا يتم إرسال `stack trace` للعميل المحيطي أبداً.
4. **Compensation / DLQ Routing**: أخطاء المستهلكات (Consumers) في الـ Event Bus لا تؤثر على طبقة الكتابة، بل تُرحّل للـ `Dead Letter Queue` إن استنفدت استراتيجيات الـ Retry.

## ⚠️ الاستثناءات المقبولة
- أخطاء البنية التحتية المؤقتة (مثل Network Timeout اثناء القراءة) يمكن أن تمر باستراتيجية Retry قصيرة في الـ Client-side، لكن لا تُعالج في طبقة الـ Database.
