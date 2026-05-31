# Event Catalog & Consumer Routing Matrix

## 🎯 الغرض التنفيذي
حصر الأحداث النظامية (Domain Events)، وتنظيم مسارات النشر والاستهلاك مع ضمان عدم تفويت أي حدث وتأمينه ضد الازدواجية (Idempotency).

## 🛡️ الثوابت الحاكمة المترجمة
- `EVENT MODEL RULE` (Side effects only, exactly-once delivery)
- `INV-PROJ-IDEMPOTENCY`
- `INV-CACHE-ORDERING`

## 🗂️ كتالوج الأحداث المعتمدة (Event Taxonomy)

| فئة الحدث (Aggregate) | اسم الحدث (Event Type) | النطاق المُصدّر (Producer) | النطاقات المستهلكة (Consumers) | أثر الاستهلاك (Consumer Impact) |
|-----------------------|------------------------|---------------------------|--------------------------------|---------------------------------|
| `InventoryStock` | `StockMovementCompleted` | Inventory | Projection Engine | تحديث أرصدة Read-Models. |
| `GeneralLedger` | `JournalEntryPosted` | Accounting | Projection Engine, Audit | تحديث ميزان المراجعة، ختم التدقيق. |
| `Authorization` | `PolicyInvalidated` | AuthZ Kernel | API Gateway, Domain APIs | إبطال الكاش الأمني محلياً بالترتيب الزمني. |
| `SagaOrchestrator` | `SagaStepFailed` | Orchestrator | DLQ Worker | تسجيل مسارات التعويض، وبدء الـ LIFO Reverse. |

## 🔄 قواعد التوجيه والاستهلاك (Routing Rules)
1. **Event Relayer / Outbox Worker**: مكون خلفي (Background Worker) وحيد لكل Tenant/Partition يقرأ من `outbox_events` بالترتيب ويكتب للـ `Message Broker` (Kafka/RabbitMQ).
2. **Idempotency Sink**: أي مستهلك (Consumer) يجب أن يقوم بإدراج `event_id` في جدول `projection_idempotency_log` كعقدة تحقق `UNIQUE` قبل تطبيق أي تحديث.
3. **No Direct Execution**: ممنوع تنفيذ `Business Logic` أو Business Rules داخل المستهلكات. المستهلك دورُه (Projection) أو (State Synchronization).
