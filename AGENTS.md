# تعليمات المشروع — منصة تعليمية (Flutter + Supabase)

## 1) نظرة عامة على المشروع

منصة تعليمية للطلاب: تطبيق Flutter (طالب) + لوحة إدارة Flutter Web + Supabase
(Postgres + Auth + Storage + Edge Functions) + Firebase Cloud Messaging للإشعارات.

**الـ Stack:**

- State management: **Riverpod** فقط (لا `setState` لإدارة منطق العمل، لا Provider/Bloc/GetX)
- Forms: **reactive_forms** فقط
- Routing: **go_router**
- Models: **Freezed**
- Backend: **Supabase** (RLS مفعّلة على كل جدول — الأمان من الخادم دائمًا، ليس من الواجهة)
- Local storage: **SharedPreferences** (إعدادات المستخدم فقط — لغة، ثيم، تفضيلات إشعارات؛ لا Hive)
- PDF: **pdfx** (ليس Syncfusion — مفتوح المصدر بالكامل)
- Localization: `assets/lang/ar.json` + `assets/lang/en.json`، الوصول عبر `context.t('key')`

---

## 2) القواعد المعمارية الملزمة — لا تُخالفها

### أ) Clean Architecture على كل Feature

كل شيء داخل `lib/features/<feature>/`:

```
data/
  models/           ← Freezed models
  repositories/     ← كل تفاعل مع Supabase من هنا فقط
application/        ← Riverpod providers/notifiers
presentation/
  screens/
  widgets/
```

**ممنوع** استدعاء `Supabase.instance.client` مباشرة داخل أي Widget. كل استعلام يمر عبر
Repository، والـ Repository يُستدعى فقط من provider/notifier في `application/`.

### ب) معالجة الأخطاء — نمط `Failure` بمفتاح ترجمة

```dart
// lib/core/errors/failure.dart
sealed class Failure {
  final String messageKey; // مفتاح من assets/lang/*.json — ليس نصًا جاهزًا!
  const Failure(this.messageKey, {this.debugDetails});
}
```

كل Repository يلف استدعاءات Supabase بـ `try/catch` ويحوّل الخطأ عبر
`mapExceptionToFailure()` (في `core/network/supabase_client_provider.dart`).

**لا تكتب** `throw Failure('نص عربي جاهز')`. الترجمة في الشاشة:

```dart
} on Failure catch (e) {
  _showError(context.t(e.messageKey));
}
```

### ج) الترجمة — إلزامية على كل نص

- **ممنوع** نص عربي/إنجليزي مباشر في `Text('...')`. استخدم `context.t('key')`
  (`core/localization/localization_extension.dart`).
- كل مفتاح جديد **يُضاف فورًا** في `assets/lang/ar.json` و `assets/lang/en.json` معًا.
- **اللغة الافتراضية إنجليزي** (`LocaleController` في `core/localization/locale_controller.dart`).
  التبديل يُحفظ في **SharedPreferences** (`SettingsKeys.locale`) ويبقى بعد إعادة فتح التطبيق.
- placeholders: `context.t('key').replaceFirst('{field}', value)`.
- قبل اعتبار شاشة جاهزة: تأكد أن كل `context.t('...')` موجود في كلا ملفي JSON.

### د) الأمان — RLS أولًا

لا تعتمد على إخفاء زر أو `if` في الواجهة. الصلاحيات في سياسات RLS
(`supabase/migrations/*.sql`). الواجهة تعكس الصلاحية لتجربة أفضل فقط.

### هـ) Soft Delete

لا تحذف صفوفًا مرتبطة — استخدم `is_active = false` (`subjects`, `contents`).

---

## 3) حالة المشروع الحالية (منجز)

- Auth: Email/Password + Google OAuth + RLS + trigger لـ profile
- Student App: Home، Subjects، Lesson (PDF + cache)، Exam (حل واحد — DB trigger + unique index)
- Admin Web: Dashboard، Students، Subjects/Content، Submissions، Review Submission
- Notifications: FCM (HTTP v1) + Deep Linking + إشعارات تلقائية
- Settings: Profile، إشعارات (FcmService)، ثيم Light/Dark/System (**SharedPreferences**)،
  لغة (**SharedPreferences**، افتراضي en)، مسح cache، About/Privacy/Terms، Logout
- الترجمة: ~154 مفتاحًا، `context.t()` في الشاشات
- Failure: رسائل خطأ بمفتاح ترجمة في طبقة data

---

## 4) الثغرات المعروفة (بالأولوية)

1. **Forgot Password** — `sendPasswordResetEmail` في `AuthRepository`؛ الزر يعرض `forgot_password_soon` فقط.
2. **Edit + Reorder في لوحة الإدارة** — Add + تفعيل/تعطيل فقط؛ `updateSubject()` في `AdminRepository` غير مستخدمة في UI.
3. **استهداف الإشعارات بمادة** — حاليًا «الكل» أو «طالب» فقط (`notification_target_note`).
4. **Testing (Phase 8)** — لا ملفات اختبار بعد (Auth، RLS، One-Submission، Exam dates، admin vs student).
5. **ملفات native / secrets** — قد تكون خارج الـ repo: `android/app/google-services.json`،
   OAuth deep link في `AndroidManifest.xml`، `ios/Info.plist`. في `pubspec.yaml` تأكد من:
   `shared_preferences`, `path_provider`, `package_info_plus`, `pdfx`, `firebase_core`,
   `firebase_messaging`, `flutter_local_notifications`.
6. **Local Cache (Phase 7 جزئي)** — SharedPreferences للإعدادات؛ PDF عبر `PdfCacheService`؛
   «آخر محتوى تم فتحه» غير مخزَّن محليًا بعد.

---

## 5) قبل اعتبار أي مهمة منتهية

- [ ] `flutter analyze` بدون تحذيرات جديدة
- [ ] كل نص جديد له مفتاح في `ar.json` و `en.json`
- [ ] أخطاء جديدة كـ `Failure` بمفتاح، لا نص جاهز
- [ ] استعلام Supabase جديد عبر Repository فقط
- [ ] صلاحيات جديدة في RLS migration
- [ ] تجربة AR/EN على الشاشة المعدّلة

---

## 6) البنية التحتية

- Supabase + Firebase مربوطان (`FIREBASE_SERVICE_ACCOUNT` secret على Supabase).
- Google Sign-In عبر Google Cloud + Supabase Auth Provider.
- `.env`: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (لا يُرفع علنًا).
