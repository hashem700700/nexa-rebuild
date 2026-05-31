# Deployment Topology & Security Perimeter Contract

## 🎯 الغرض التنفيذي
تحديد طوبولوجيا النشر الفعلي، وحدود الشبكة، وأنواع العُقد (Nodes) لمنع الوصول المباشر وتقليص مساحات الهجوم.

## 🛡️ الثوابت الحاكمة المترجمة
- `MULTI-TENANCY HARD ISOLATION`
- `INV-CRYPTO-KEY-SEPARATION`
- `DOMAIN ISOLATION RULE`

## 🏗️ مكونات النشر (Scaling Units & Node Roles)

1. **Edge Gateway (API / WAF)**
   - **Role**: نقطة الدخول الوحيدة للتطبيقات. 
   - **Isolation**: لا تملك أي اتصال بقواعد البيانات. اتصالها فقط بـ `Domain APIs` عبر شبكة داخلية (VPC).
   - **Responsibility**: SSL Termination, Rate Limiting, WAF, JWT Parsing.

2. **Domain API Nodes (Stateless Web Workers)**
   - **Role**: خدمات الأعمال الجوهرية (Accounting API, Inventory API).
   - **Isolation**: اتصال بـ PostgreSQL عبر `Connection Pooler` (مثل PgBouncer). 
   - **Responsibility**: حقن الـ `tenant_id` في `SET LOCAL app.current_tenant`، استدعاء الـ DB، تسليم الرد.

3. **Outbox Relayer & Event Consumers (Background Workers)**
   - **Role**: عمال غير متزامنين لنقل الأحداث وتحديث الـ Read-Models.
   - **Isolation**: ممنوع استقبال HTTP Requests. تقرأ من قاعدة البيانات أو Event Bus.

4. **KMS & Secrets Manager (External Vault)**
   - **Role**: إدارة مفاتيح التشفير.
   - **Limit**: الـ Domain API يستعير مفتاح JWT أو مفتاح تشفير البيانات مؤقتاً لفك التشفير بالذاكرة `In-Memory` ثم يسقطه.

## 🧱 حد العزل الأمني (Security Boundaries)
- خوادم قاعدة البيانات `PostgreSQL` وتطبيقات `Frontend` لا يمكن أن يتحدثا مباشرة أبدًا.
- تطبيق مبدأ الـ `Row-Level Security (RLS)` يُفرض على اتصال הـ DB Role الخاص بالـ Application، مع منع `Bypass RLS`.
