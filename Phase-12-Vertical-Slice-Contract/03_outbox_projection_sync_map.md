# 03_outbox_projection_sync_map.md

## 🎯 الغرض التنفيذي للمسار
ضمان التزامن غير المتزامن (Asynchronous Sync) بين طبقة الكتابة (Write-Path) وطبقة القراءة (Read-Models) دون التأثير على زمن استجابة المستخدم (Latency) ودون خسارة البيانات.

## 🛡️ الثوابت الحاكمة المترجمة
- `INV-PROJECTION-SYNC-LAG`: Eventual consistency bounds well managed.
- `INV-PROJ-IDEMPOTENCY`: Exactly-once delivery semantics for views.

## 📊 مسار الاستهلاك (Consumer Routing Map)
1. **Outbox Relayer Worker**: 
   - يقرأ `StockMovementCompleted` من جدول `outbox_events` بترتيب `event_id` (UUIDv7).
   - ينشر الحدث إلى `Event Bus`.
2. **Inventory Projection Consumer**:
   - يستلم الحدث.
   - يفحص جدول `projection_idempotency_log` بواسطة `event_id`.
   - إذا الحدث معالج مسبقاً → يتجاهل (Skip).
   - إذا جديد → يحدث أرصدة جدول `projection_inventory_stock` (Read Model).
   - يسجل `event_id` كمكتمل.

## 🚧 حدود البيانات (Allowed/Forbidden Data Boundaries)
- **مسموح**: المستهلك يقوم بعمليات `INSERT/UPDATE` حصرية على جداول `projection_*`.
- **ممنوع**: المستهلك يمنع منعاً باتاً من تنفيذ Business Logic معقد. يكتفي بتطبيق (Apply) الحدث لتحديث الحالة المنعكسة.

## 🔗 نقطة التكامل مع مستوى الحوكمة (Governance Layer)
- مراقبة الـ `Sync Lag` (الفارق الزمني بين النشر والاستهلاك) تخضع لـ `INV-OBSERVABILITY-GOVERNANCE`. إذا تجاوز الفارق SLO معتمد (e.g., 5 seconds)، يطلق تنبيه Escalation.

## ⚠️ الاستثناءات المقبولة
- يمكن قبول التأخر المؤقت في طبقات الاسقاط، طالما أن العمليات المالية (Write-Path) تعتمد على جداول المصدر وليس الـ View.
