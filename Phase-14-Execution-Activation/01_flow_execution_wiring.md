# 01_flow_execution_wiring.md

## 🎯 نقطة الربط التنفيذية (Binding Point)
ربط مسار الطلب من البوابة (Gateway) وحتى تسجيل الحدث في الـ Outbox مروراً بنواة الأعمال، كمسار واحد متصل (Wired Sequence).

## 🛡️ الثابت الحاكم
- `INV-BOUNDARY-CALL-ORDER`: التسلسل الحتمي (AuthZ → UseCase → AtomicWrapper → Engine/Outbox).
- `INV-SLICE-ATOMICITY`: أي انقطاع في الربط يرمي استثناء يوقف المسار فوراً قبل الـ Commit.

## 📦 غلاف البيانات (Data Envelope)
- **المدخلات**: `ContextBundle` + `StockMovementDTO`.
- **المخرجات**: `ExecutionEnvelope` (يحتوي `movement_id`, `status: pending_sync`).

## 🔄 مسار الربط (Wiring Contract)
1. `Gateway Route` يستقبل HTTP Request ويعبر `authzPreFlight` middleware.
2. الـ Middleware يمرر `ContextBundle` إلى `PostStockMovementUseCase`.
3. الـ UseCase يستدعي `AtomicPostingWrapper.wrapMovementAndPost()`.
4. الـ Wrapper يطلب `UnitOfWork` لفتح Transaction.
5. داخل الـ callback، يستدعي الـ Wrapper كلا من `AccountingEngine.post()` و `OutboxPublisher.publish()`.
6. يُعاد الناتج عبر الطبقات إلى الـ Gateway لتنسيق `HTTP 202 Accepted` أو `201 Created`.

## ⚠️ الاستثناءات المقبولة
- لا يوجد استثناء. تخطي أي مكون في سلسلة الربط يُعتبر اختراقاً للـ `Boundary Isolation`.
