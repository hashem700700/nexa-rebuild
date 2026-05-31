# 02_persistence_binding_contract.md

## 🎯 نقطة الربط التنفيذية (Binding Point)
ربط كائن `UnitOfWork` المُجرّد بمشغل قاعدة البيانات الفعلي (DB Driver/Connection Pool) مع ضمان حقن سياق العزل.

## 🛡️ الثابت الحاكم
- `INV-TENANT-ISOLATION`: لا يُبرم أي اتصال بـ DB دون `tenant_id`.
- `INV-RLS-ENFORCEMENT`: تطبيق الـ Session Variables على مستوى الاتصال (Connection).

## 📦 غلاف البيانات (Data Envelope)
- **المدخلات**: `ContextBundle` + `Callback(tx)`.
- **المخرجات**: `Transaction Result` أو `Rollback Exception`.

## 🔄 مسار الربط (Wiring Contract)
1. `UnitOfWork.execute()` يطلب اتصالاً (Connection) من الـ Pool.
2. **Hook الإلزامي**: فور استلام الاتصال، يتم تنفيذ `BEGIN`.
3. **Hook الإلزامي**: تنفيذ `SET LOCAL app.current_tenant_id = '...'` باستخدام البيانات من `ContextBundle`.
4. يتم تمرير كائن الاتصال `tx` إلى الـ callback الممرر من `AtomicPostingWrapper`.
5. في حال نجاح الـ callback، يتم إصدار `COMMIT`. في حال رمي أي `Error`، يتم إصدار `ROLLBACK`.
6. إعادة الاتصال إلى الـ Pool في كتلة `finally`.

## ⚠️ الاستثناءات المقبولة
- لا يوجد أي تجاوز للروتين. لا يُسمح بتشغيل استعلامات خارج كتلة الـ UoW.
