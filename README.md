# Educational Platform

## Phase 1 ✅ Project Setup
راجع الشرح في الرسالة الأولى — لم يتغيّر شيء هنا عدا الانتقال من `--dart-define` إلى ملف `.env`.

> ⚠️ **مهم:** أول استخدام فعلي لـ Freezed هو `UserProfile` في Phase 2، لذا شغّل بعد `flutter pub get`:
> ```bash
> dart run build_runner build --delete-conflicting-outputs
> ```
> بدونه لن يُوجد `user_profile.freezed.dart` وسيفشل الـ build.

## إعداد المفاتيح (.env)
1. افتح ملف `.env` في جذر المشروع.
2. عبّئ:
   ```
   SUPABASE_URL=https://xxxx.supabase.co
   SUPABASE_ANON_KEY=xxxx
   ```
3. `.env` مُستثنى من Git تلقائيًا (`.gitignore`) — لا تُشارك المفتاح العام حتى لو كان anon key منخفض الصلاحيات، لأنه سيُقيَّد لاحقًا بـ RLS فقط، والأفضل عدم رفعه لأي repo عام.

## التشغيل
```bash
flutter pub get
flutter run
```
لا حاجة لـ `--dart-define` بعد الآن؛ القيم تُقرأ من `.env` مباشرة عبر `flutter_dotenv`.

---

## Phase 2 ✅ Authentication

### 1) تطبيق الـ Migration على Supabase
انسخ محتوى `supabase/migrations/001_profiles.sql` وشغّله في SQL Editor بلوحة Supabase (أو عبر Supabase CLI: `supabase db push`).

يقوم بـ:
- إنشاء جدول `profiles` مع `student_number` فريد (UNIQUE).
- Trigger تلقائي (`handle_new_user`) ينشئ صف profile عند كل تسجيل جديد في `auth.users`.
- تفعيل RLS: كل مستخدم يرى/يعدّل صفّه فقط، الـ admin يرى الجميع.
- منع أي مستخدم عادي من تعديل `role` أو `is_active` أو `student_number` بنفسه (trigger حماية إضافي، وليس فقط RLS).

### 2) تفعيل Google OAuth
في لوحة Supabase → Authentication → Providers → Google:
1. فعّل Google واملأ Client ID / Client Secret من Google Cloud Console.
2. أضف Redirect URL الذي تعرضه Supabase إلى "Authorized redirect URIs" في Google Console.
3. لتفعيل الرجوع للتطبيق بعد OAuth على الموبايل، ستحتاج لاحقًا ضبط Deep Link (`io.supabase.eduplatform://login-callback`) — سنُفصّله عند تجهيز build فعلي على جهاز حقيقي، لأنه يحتاج تعديل AndroidManifest.xml / Info.plist.

### 3) ما تم بناؤه
- `AuthRepository`: كل عمليات Supabase Auth (signIn, signUp, signInWithGoogle, signOut, fetchCurrentProfile) — لا استدعاء مباشر لـ Supabase خارج هذا الملف.
- `AuthNotifier` (AsyncNotifier<UserProfile?>): يبث حالة (جلسة + profile كامل) معًا، ويُحدَّث تلقائيًا عند أي تغيّر في الجلسة عبر `onAuthStateChange`.
- `LoginScreen` / `RegisterScreen`: نماذج حقيقية بـ `reactive_forms` — validation فوري، رسائل عربية واضحة، Loading state أثناء الإرسال، تحقق تطابق كلمة المرور في التسجيل.
- `GoRouterRefreshStream`: يجعل GoRouter يعيد تقييم الـ redirect تلقائيًا فور تغيّر حالة المصادقة (لا حاجة لإعادة تشغيل الشاشة يدويًا).
- `HomeScreen` مؤقتة تعرض اسم الطالب ورقمه الجامعي + زر تسجيل خروج — للتحقق العملي من نجاح كامل تدفق: تسجيل → تحقق الجلسة → جلب profile → توجيه → خروج.

### اختبار المرحلة يدويًا
1. `flutter run` بعد تعبئة `.env` وتطبيق الـ migration.
2. سجّل حسابًا جديدًا برقم جامعي معيّن → يجب أن تنتقل تلقائيًا لـ Home وترى اسمك ورقمك.
3. جرّب التسجيل بنفس الرقم الجامعي مرة أخرى → يجب أن تظهر رسالة "هذا الرقم الجامعي مستخدم مسبقًا."
4. اضغط تسجيل خروج → يجب أن تعود لشاشة Login تلقائيًا.
5. سجّل دخول بنفس الحساب من جديد.

> Google OAuth لن يعمل فعليًا حتى تُفعَّل الخطوات أعلاه في لوحة Supabase وتُضبط الـ Redirect بشكل صحيح على جهاز حقيقي — الزر موجود وجاهز في الكود.

---

## الخطوة التالية: Phase 3 — Database (باقي الجداول)
- `subjects`, `contents`, `submissions`, `notifications`, `user_devices`.
- RLS الكاملة لكل جدول (حسب المستند المعتمد).
- Storage buckets + policies (لا public على submissions).
- Partial unique index لقاعدة "submission واحد فعّال".

---

## Phase 3 ✅ Database (باقي الجداول + Storage)

### تطبيق الـ migrations بالترتيب
شغّل الملفات التالية بالترتيب في SQL Editor (أو `supabase db push` إذا تستخدم CLI):

1. `002_subjects_contents.sql` — المواد والمحتوى (دروس/اختبارات)
2. `003_submissions.sql` — الحلول + قاعدة "submission واحد فعّال"
3. `004_notifications_devices.sql` — الإشعارات + FCM tokens
4. `005_storage.sql` — الـ buckets الخمسة + كل الـ policies

> يجب أن يكون `001_profiles.sql` مُطبَّقًا مسبقًا (Phase 2) لأن باقي الجداول تعتمد على `public.is_admin()` و `profiles`.

### أهم القرارات التصميمية المطبَّقة

**قاعدة "Submission واحد فعّال" (بند 13/54.2):**
- عمود `is_superseded` على `submissions` بدل الحذف أو التعديل — أي حل قديم يبقى كسجل تاريخي.
- `unique index` جزئي (`where is_superseded = false`) يمنع فعليًا وجود أكثر من حل فعّال واحد لكل (طالب + اختبار)، حتى تحت تزامن عالٍ.
- `trigger` قبل كل INSERT يتحقق من: نوع المحتوى exam فعلًا، الاختبار متاح ضمن `available_from/until`، ثم إما يسمح بالإدراج (ويُعلِّم القديم superseded إذا `can_resubmit = true`) أو يرفضه برسالة عربية واضحة.
- **الطالب لا يملك أي صلاحية UPDATE على submissions إطلاقًا** — لا grade، لا status، لا can_resubmit — القرار الأكثر أمانًا بدل محاولة تقييد أعمدة معينة بصلاحية معقّدة.

**Content (دروس/اختبارات):**
- `constraint chk_exam_dates` على مستوى الجدول: الدرس يجب أن يكون تاريخاه NULL، الاختبار يجب أن يملك تاريخين صحيحين (`until > from`) — هذا يمنع بيانات متناقضة من الجذر، وليس فقط validation في Flutter.

**Notifications:**
- أضفت جدول `notification_reads` منفصل بدل عمود read/unread على notifications نفسها، لأن نفس الإشعار (مثلاً "اختبار جديد") يستهدف عدة طلاب دفعة واحدة — عمود واحد لا يكفي لتتبع من قرأ ومن لم يقرأ.

**Storage:**
- `submissions` bucket **غير عام** (`public: false`) + RLS على `storage.objects` تتحقق أن أول جزء من المسار (`foldername`) يطابق `auth.uid()` — حماية مزدوجة حتى لو تسرّب مسار الملف، لأن الوصول الفعلي من التطبيق سيكون عبر Signed URL قصير الأجل وليس رابطًا دائمًا.
- `lessons`/`exams` قراءة لأي `authenticated` (لا حاجة Signed URL — ليست بيانات شخصية).
- مسار الرفع المتوقع من التطبيق: `submissions/{student_id}/{content_id}/{timestamp}_{filename}.pdf`.

### اختبار المرحلة
بعد تطبيق كل الملفات، تحقق يدويًا من SQL Editor:
```sql
select public.is_admin(); -- يجب أن ترجع false إن لم تكن مسجّلًا كـ admin بعد
select * from storage.buckets; -- يجب أن ترى الخمسة buckets، submissions/lessons/exams public=false
```
لجعل حسابك admin مؤقتًا للاختبار (يدويًا فقط، ليس عبر التطبيق):
```sql
update public.profiles set role = 'admin' where email = 'your-email@example.com';
```

---

## الخطوة التالية: Phase 4 — Student App
- بناء `SubjectsRepository`, `ContentRepository`, `SubmissionsRepository` + Freezed models (`Subject`, `Content`, `Submission`).
- شاشات: Home (بأقسامها الحقيقية)، Subjects، Subject Details، Lesson، Exam.
- رفع ملف PDF فعليًا إلى `submissions` bucket + إنشاء الـ submission، مع Confirmation Dialog قبل الإرسال.
- PDF Viewer (Syncfusion) لعرض ملفات الدروس والاختبارات.

---

## Phase 4 ✅ Student App

### ما تم بناؤه
- **Models**: `Subject`, `Content` (بمنطق `availability` المحسوب من الوقت الحالي، بند 51)، `Submission`.
- **Repositories**: `SubjectsRepository` (يجلب عدد الدروس/الاختبارات بـ query واحد بدل N+1)، `ContentRepository`، `SubmissionsRepository` (رفع الملف + إنشاء السجل، مع rollback تلقائي للملف إذا فشل إنشاء السجل بعد الرفع — بند 50).
- **`PdfCacheService`**: يحمّل ملف PDF مرة واحدة عبر الجلسة المصادَق عليها ويخزّنه محليًا (hash-based)، فلا يُعاد التنزيل عند كل فتح.
- **`PdfViewerWidget`**: Loading/Error/Retry + Syncfusion PDF viewer (Zoom/Scroll مدمجان).
- **`SubmissionUploadNotifier`**: يمنع الضغط المتكرر أثناء الرفع، ويحوّل رسالة "حل مُرسَل مسبقًا" القادمة من الـ DB trigger إلى نص عربي واضح.
- **الشاشات**: `SubjectsScreen` (Cards + عدد الدروس/الاختبارات)، `SubjectDetailsScreen` (محتوى مرتّب برقم تسلسلي)، `LessonScreen` (PDF فقط، بند 10)، `ExamScreen` (فتح الأسئلة + رفع الحل + Confirmation Dialog + عرض الحالة/العلامة/الملاحظات + دعم "رفع حل جديد" عند `needs_resubmission`)، `HomeScreen` (كل الأقسام الحقيقية: آخر الدروس، اختبارات حالية، اختبارات قريبة الانتهاء، آخر الحلول، Quick Actions).
- إضافة `.env` — لا تنسَ `flutter pub get` ثم `build_runner build` بعد كل تعديل على الـ Freezed models الجديدة (Subject, Content, Submission).

### ملاحظة الترخيص (محدَّثة)
تم استبدال `syncfusion_flutter_pdfviewer` بـ **`pdfx`** — رخصة MIT مفتوحة المصدر بالكامل، بدون أي قيود تجارية أو حاجة لتفعيل Community License. `PdfViewerWidget` الآن يدعم pinch-to-zoom + عداد صفحات + نفس تدفق Loading/Error/Retry.

### اختبار المرحلة يدويًا
1. أضف مادة + درس + اختبار يدويًا من SQL Editor (لوحة الإدارة لسّا ما بُنيت — Phase 5):
   ```sql
   insert into subjects (title, order_index) values ('رياضيات', 1) returning id;
   -- استخدم الـ id الناتج بالأسفل، وارفع ملف PDF تجريبي إلى bucket lessons/exams يدويًا من لوحة Storage
   insert into contents (subject_id, title, type, file_path, file_name, order_index)
   values ('<subject_id>', 'مقدمة', 'lesson', '<path_in_lessons_bucket>.pdf', 'intro.pdf', 1);
   insert into contents (subject_id, title, type, file_path, file_name, order_index, available_from, available_until)
   values ('<subject_id>', 'اختبار الوحدة 1', 'exam', '<path_in_exams_bucket>.pdf', 'exam1.pdf', 2, now(), now() + interval '7 days');
   ```
2. `flutter run` → المواد يجب أن تظهر في Home والـ Subjects.
3. افتح الدرس → PDF يفتح ويُخزَّن محليًا (جرّب وضع الطيران بعد أول فتح، يجب أن يفتح من الـ cache).
4. افتح الاختبار → ارفع ملف PDF → يجب أن تظهر رسالة التأكيد ثم "تم الإرسال" ثم يختفي زر الرفع.
5. حاول الدخول للاختبار مرة أخرى → يجب ألا يظهر زر رفع جديد (لا submission ثانٍ ممكن).

---

## الخطوة التالية: Phase 5 — Admin Web Panel
- Flutter Web منفصل منطقيًا: Dashboard, Students (بحث جزئي بالاسم/الرقم), Content Management, Submission Management (Review + Grade + Notes + Request Resubmission).

---

## Phase 5 ✅ Admin Web Panel

### تحديث مهم: تم التخلص من الترخيص التجاري
استبدلت `syncfusion_flutter_pdfviewer` بـ **`pdfx`** (رخصة MIT، مفتوح المصدر بالكامل). `PdfViewerWidget` أُعيد بناؤه بالكامل عليها — يدعم pinch-to-zoom وعداد صفحات، بدون أي قيود تجارية أو Community License مطلوبة.

### ما تم بناؤه
- **`AdminRepository`**: كل عمليات الإدارة (Dashboard stats، بحث الطلاب، إدارة المواد/المحتوى مع رفع PDF، إدارة الحلول والتصحيح، الإشعارات). كل استعلام محمي بـ RLS من الخادم (`is_admin()`) — حتى لو انكسرت الواجهة، الحماية الحقيقية بالـ backend (بند 42).
- **`AdminShell`**: Sidebar ثابت على الكمبيوتر (عرض ≥ 900)، Drawer قابل للسحب على الموبايل/تابلت — بند 49.
- **Dashboard**: 6 بطاقات إحصائيات (طلاب، مواد، دروس، اختبارات، حلول قيد المراجعة، حلول تمت مراجعتها) + أحدث الطلاب + أحدث الحلول.
- **Students**: بحث جزئي server-side واحد يغطي `full_name` و `student_number` معًا (بند 24) + تفعيل/تعطيل الحساب.
- **Student Details**: بيانات الطالب + سجل كل حلوله بحالتها، مع فتح مباشر لأي حل للمراجعة.
- **Subjects/Content Management**: إضافة مادة، تفعيل/تعطيل (Soft Delete — بند 26)، إضافة درس أو اختبار مع رفع PDF فعلي + تواريخ البداية/النهاية للاختبار (مع تحقق `until > from` في الواجهة، والقاعدة الصارمة موجودة أصلًا في DB constraint من Phase 3).
- **Submissions Management**: قائمة + فلترة بالحالة (Chips) + بحث موحّد (اسم/رقم/عنوان اختبار).
- **Review Submission**: يبدأ `reviewing` تلقائيًا عند الفتح إن كانت `pending` (بند 31)، عرض ملف الحل عبر نفس `PdfViewerWidget`، حفظ العلامة والملاحظات، أو طلب إعادة إرسال بسبب مكتوب (`can_resubmit=true` تلقائيًا).
- **Admin Notifications**: إنشاء إشعار عام لكل الطلاب (تخزين في DB فقط الآن — إرسال FCM push الفعلي في Phase 6).
- **التوجيه حسب الدور**: بعد تسجيل الدخول، admin يُوجَّه تلقائيًا لـ `/admin`، والطالب لـ `/home`. محاولة طالب الوصول لـ `/admin/*` تُعاد لـ `/home` (تجربة استخدام فقط؛ الحماية الحقيقية RLS).

### اختبار المرحلة
1. حوّل حسابك لـ admin (نفس أمر Phase 3):
   ```sql
   update public.profiles set role = 'admin' where email = 'بريدك';
   ```
2. `flutter run -d chrome` (أو أي متصفح) لتجربة الـ Responsive Layout فعليًا على الويب.
3. سجّل دخول → يجب أن تُنقل مباشرة لـ `/admin` وترى الـ Sidebar.
4. أضف مادة → أضف درسًا واختبارًا بملف PDF حقيقي وتواريخ صحيحة.
5. من حساب طالب آخر: افتح الاختبار، ارفع حلًا.
6. ارجع لحساب admin → Submissions → افتح الحل → لاحظ تغيّر الحالة لـ "قيد التصحيح" تلقائيًا → أدخل علامة واحفظ → تحقق أن حساب الطالب يرى العلامة فورًا.
7. جرّب "طلب إعادة إرسال" → تحقق أن الطالب يرى رسالة السبب وزر "رفع حل جديد" يظهر له.

---

## الخطوة التالية: Phase 6 — Notifications (FCM)
- تفعيل Firebase Cloud Messaging فعليًا (`firebase_core` و`firebase_messaging` موجودتان بالـ pubspec منذ Phase 1).
- جدول `user_devices` لتخزين tokens (جاهز من Phase 3).
- Edge Function أو DB trigger يُرسل push حقيقي عند إدراج صف في `notifications`.
- Deep Linking: الضغط على إشعار اختبار يفتح شاشة الاختبار مباشرة عبر GoRouter.

---

## Phase 6 ✅ Notifications (FCM حقيقي + Deep Linking)

### إعداد Firebase (خطوات لمرة واحدة)
1. أنشئ مشروع Firebase (أو استخدم موجودًا) من [console.firebase.google.com](https://console.firebase.google.com).
2. ثبّت FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. من جذر المشروع: `flutterfire configure` — يختار مشروع Firebase ويُنشئ `firebase_options.dart` تلقائيًا، ويُعدّل `main.dart` ليمرر `DefaultFirebaseOptions.currentPlatform` (خصوصًا ضروري على الويب).
4. لتفعيل الإشعارات الفعلية، فعّل **"Cloud Messaging API (Legacy)"** من Google Cloud Console لنفس مشروع Firebase (Settings → Cloud Messaging → Server key القديم — كافٍ لـ MVP، راجع الملاحظة أدناه للترقية لاحقًا).

### نشر الـ Edge Function
```bash
supabase functions deploy send-notification
supabase secrets set FCM_SERVER_KEY=your_legacy_server_key
```

### ما تم بناؤه
- **`FcmService`**: طلب الإذن، حفظ/تحديث `fcm_token` في `user_devices` (بند 40)، عرض إشعار فعلي عبر `flutter_local_notifications` عندما يكون التطبيق مفتوحًا (foreground)، والتعامل مع 3 حالات ضغط: foreground (local notification tap)، background (`onMessageOpenedApp`)، وتطبيق مغلق تمامًا (`getInitialMessage`).
- **`AppRouterHolder`**: مرجع ثابت لآخر `GoRouter` مُنشأ، يسمح لـ `FcmService` بالتنقّل مباشرة (Deep Linking) دون الحاجة لـ `BuildContext`.
- **إشعارات تلقائية حقيقية** (بند 19)، تُطلق من `AdminRepository` نفسها بدون أي تدخّل يدوي من الأدمن:
  - إضافة درس/اختبار جديد → إشعار "درس جديد" / "اختبار جديد" لكل الطلاب.
  - حفظ تصحيح (`saveReview`) → إشعار "تم تصحيح حلّك" للطالب صاحب الحل تحديدًا.
  - طلب إعادة إرسال (`requestResubmission`) → إشعار بالسبب للطالب تحديدًا.
- **`NotificationsScreen`** حقيقية: قائمة من `notifications` مدمجة مع `notification_reads`، غامق/عادي حسب حالة القراءة، نقطة زرقاء للإشعار غير المقروء، تحديد كمقروء + فتح الوجهة عند الضغط.
- **تسجيل الجهاز تلقائيًا** بعد أي نجاح لتسجيل الدخول (password أو Google) من `AuthNotifier._refresh()` — مكان واحد يغطي كل المسارات.

### قرار تصميمي مهم صححته أثناء البناء
اكتشفت تعارضًا في استخدام `target_id`: تصميم الجدول الأصلي يستخدمه لتحديد **وجهة الفتح** (subject/content/submission)، لكن بند 33 يحتاج أيضًا حقل **استهداف الجمهور** (كل الطلاب / طالب معيّن). بدل إضافة عمود جديد الآن (تعقيد غير ضروري لهذه المرحلة)، استخدمت `target_id` للاستهداف فقط، وقصرت الـ Deep Linking الفعلي على الحالتين الآمنتين فعليًا: **درس جديد** و**اختبار جديد** (حيث `target_id` = معرّف المحتوى نفسه). إشعارات "تم التصحيح" و"إعادة الإرسال" تُعلم الطالب لكن تفتح فقط قائمة الإشعارات وليس الاختبار مباشرة — توسيع هذا لاحقًا يحتاج عمود `content_id` منفصل عن `target_id`، وهو تحسين مرشّح لمرحلة لاحقة إن احتجته.

### ملاحظة للترقية لاحقًا
FCM Legacy API يعمل الآن لكن Google توصي بـ HTTP v1 (OAuth2 + Service Account) للمشاريع الجديدة. الترقية تتطلب تعديل `supabase/functions/send-notification/index.ts` فقط — لا شيء في Flutter يتغيّر.

### اختبار المرحلة
1. `flutterfire configure` + نشر الـ Edge Function + ضبط `FCM_SERVER_KEY`.
2. `flutter run` على جهاز حقيقي (الإشعارات لا تعمل جيدًا على المحاكي أحيانًا) → اقبل إذن الإشعارات.
3. تحقق من SQL: `select * from user_devices;` — يجب أن يظهر جهازك بعد تسجيل الدخول.
4. من حساب admin: أضف درسًا جديدًا → يجب أن يصل إشعار فوري لجهاز الطالب (حتى لو التطبيق بالخلفية).
5. اضغط الإشعار → يجب أن يفتح شاشة الدرس مباشرة (Deep Link).
6. صحّح حل طالب → يجب أن يصله إشعار "تم تصحيح حلّك" فورًا.

---

## الخطوة التالية: Phase 7 — Local Cache
- `Hive` لتخزين إعدادات المستخدم (لغة، ثيم) وآخر محتوى تم فتحه.
- التأكد أن التطبيق يعمل بشكل طبيعي حتى بدون اتصال، معتمدًا على الـ PDF cache الموجود أصلًا من Phase 4.
