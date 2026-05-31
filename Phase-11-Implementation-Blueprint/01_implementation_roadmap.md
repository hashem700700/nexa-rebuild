# 01_implementation_roadmap.md

## 🎯 الغرض التنفيذي
وضع خارطة طريق (Sprint-by-Sprint) لتسليم معمارية النظام (Phases 0-10) ككود تشغيلي خاضع للرقابة، وبناء الهيكل الفيزيائي للنطاقات والمكونات.

## 🛡️ الثابت الحاكم المترجم
- `EXECUTION REALITY LOCK`
- `INV-KERNEL-SINGLE-ENTRY`
- `DOMAIN ISOLATION RULE`

---

## 🗂️ هيكل مساحة العمل الفعلي (Repository Architecture)
بناءً على مصفوفة الحدود، سيتم اعتماد تصميم الـ Monorepo / Domain-Driven لفصل السياقات تماماً:

```text
/src
  /gateway              # API Gateway, Context Injector, AuthN Middleware
  /orchestrator         # Saga Engine, Timeout Managers, Reverse Compensation
  /domains
    /authz_kernel       # Policy Engine, SoD Validator, ABAC Evaluator
    /accounting         # General Ledger, Posting Engine, Fiscal Periods
    /inventory          # Stock Movement Commands
  /infrastructure
    /database           # PG Connection Pool, RLS Context Injector
    /messaging          # Kafka/Redis Publishers
  /workers
    /outbox_relayer     # Background worker reading outbox_events rigidly
    /projection_sync    # Consumers populating Read-Models
```

## 🏃 خريطة السبرنتات التنفيذية (Sprint Delivery Matrix)

### Sprint 1: Foundation & Identity 
- **التسليم:** إعداد `PostgreSQL`، تکامل نظام الجلسة، وتفعيل RLS.
- **عقد التنفيذ:** تطبيق `SET LOCAL app.current_tenant_id` تلقائياً لكل اتصال بالـ DB عبر الـ Infrastructure Middleware.

### Sprint 2: Zero-Trust Gateway & AuthZ Runtime
- **التسليم:** برمجة المدخل الموحد `API Gateway` وتطبيق نواة التفويض.
- **عقد التنفيذ:** استخراج الهوية، تكوين الـ `Context`، وتقييم `SoD Pre-Flight`. طلبات غير المصرحين تُرد بـ `403 HTTP` فوراً.

### Sprint 3: The Accounting Engine Skeleton
- **التسليم:** دالة ترحيل القيود (Posting Service) وتفعيل القيد المزدوج.
- **عقد التنفيذ:** التأكد في الـ Runtime من الـ (Balance) وأن الحدث المالي يتم إدراجه مع حدث الـ Outbox داخل `Transaction` ذري واحد.

### Sprint 4: Saga, Inventory, and Outbox Events
- **التسليم:** تنسيق حركة سير المخزون.
- **عقد التنفيذ:** محرك `Saga` يبدأ الحركة، يُقيم الصلاحيات، ويوجه التعويض (Compensation LIFO) عند أي فشل مالي من نظام المحاسبة.
