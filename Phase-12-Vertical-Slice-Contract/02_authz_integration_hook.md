# 02_authz_integration_hook.md

## 🎯 الغرض التنفيذي للمسار
تأمين البوابة التشغيلية للمسار. لا يتم الوصول لمنطق أعمال المخزون إلا بعد عبور محرك السياسات (Policy Engine) وفحص الفصل بين المهام (SoD).

## 🛡️ الثوابت الحاكمة المترجمة
- `INV-SOD-PRECHECK`: No logic executed without SoD validation.
- `INV-BOUNDARY-CALL-ORDER`: AuthZ always precedes Domain logic.

## 📊 نقطة الاعتراض (Interception Hook)
- **الموقع**: API Gateway or RPC Middleware.
- **التدفق**:
  1. التحقق من صحة JWT/Session Token.
  2. حقن هوية المستخدم `user_id` والمستأجر `tenant_id` في كائن الطلب.
  3. استدعاء `AuthZ_Kernel.Evaluate(Context, Action="CreateStockIssue")`.

## 🚧 حدود البيانات (Allowed/Forbidden Data Boundaries)
- **مسموح**: `AuthZ_Kernel` يطلب بيانات الـ Roles و SoD matrix فقط.
- **ممنوع**: `AuthZ_Kernel` يقوم بقراءة أي تفاصيل تشغيلية للطلب (مثل الكمية، السعر، أو المستودع) لأن هذه قواعد أعمال، وليست قواعد صلاحيات.

## 🔗 نقطة التكامل مع مستوى الحوكمة (Governance Layer)
- يسجل القرار النهائي في `policy_evaluation_logs` مع `input_context_hash` إثباتاً للقرار الجنائي.

## ⚠️ الاستثناءات المقبولة
- إذا تم تفعيل مسار PII (قراءة بيانات حساسة)، يجب ربطه بـ `INV-CRYPTO-KEY-SEPARATION`، لكن في حالة حركة المخزون لا توجد بيانات PII.
