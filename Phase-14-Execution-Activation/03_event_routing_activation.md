# 03_event_routing_activation.md

## 🎯 نقطة الربط التنفيذية (Binding Point)
ربط `OutboxPublisher` الهيكلي بعملية إدراج فعلية في قاعدة البيانات، وربط الـ Consumer بآلية سحب تعتمد على الـ Cursor.

## 🛡️ الثابت الحاكم
- `INV-OUTBOX-IDEMPOTENCY`: مفتاح الحدث يجب أن يُشتق حتمياً.
- `INV-PROJECTION-NO-FEEDBACK`: المستهلك لا يُرجع ردًا مباشراً لطبقة الكتابة.

## 📦 غلاف البيانات (Data Envelope)
- **المدخلات (Publisher)**: `tx` (من الـ UoW) + `EventPayload` + `ContextBundle`.
- **المخرجات (Consumer)**: `Ack` بتحديث الـ Cursor + إدراج في `Idempotency Store`.

## 🔄 مسار الربط (Wiring Contract)
1. **Publisher Activation**: 
   - داخل `OutboxPublisher.publish`، يتم دمج `tenant_id`، `correlation_id`، ونوع الحدث لبناء حقل `idempotency_key`.
   - يتم إلحاق (INSERT) سجل في جدول `outbox_events` باستخدام نفس الـ `tx` لضمان الذرية.
2. **Relayer/Consumer Activation**: 
   - يعمل كترس خلفي (Background Worker). يسحب الأحداث حيث `event_id > cursor`.
   - يمرر الحدث إلى `StockMovedProjectionHandler`.
   - الـ Handler يتأكد من متجر التكرار (`IdempotencyStore`)، ويحدث `projection_inventory_stock` إذا كان جديداً.

## ⚠️ الاستثناءات المقبولة
- يمكن قبول `At-Least-Once Delivery` من الـ Relayer، لأن `IdempotencyStore` سيتولى صد النسخ المكررة `Duplicates`.
