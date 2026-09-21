# Mustaqbali Educational Platform

Flutter-based educational platform with a student application, an administration
dashboard, Supabase backend services, and Firebase notifications/hosting.

The project is currently published from the `main` branch:

- Repository: <https://github.com/MohammedAlYounis/edu-platform>
- Web dashboard: <https://educational-platform-bd155.web.app>
- Current branding: **Mustaqbali** (`مستقبلي`)

## Features

### Student application

- Email/password authentication.
- Google OAuth.
- Subjects and lesson browsing.
- PDF lesson viewing and local PDF caching.
- Exam availability windows.
- PDF solution submission.
- Database-enforced active-submission rules.
- Submission status, grading, and resubmission requests.
- Notifications and notification read state.
- Profile, language, theme, cache, privacy, terms, and logout settings.

### Administration dashboard

- Dashboard statistics.
- Student search and activation controls.
- Subject management.
- Lesson and exam content management.
- PDF upload to Supabase Storage.
- Submission filtering and review.
- Grades and resubmission requests.
- Notification creation and targeted delivery.

## Technology

- Flutter and Dart.
- Riverpod for state management.
- `reactive_forms` for forms.
- GoRouter for navigation.
- Freezed and JSON serialization for models.
- Supabase Auth, Postgres, Storage, and Row Level Security.
- Firebase Cloud Messaging and Firebase Hosting.
- `SharedPreferences` for user settings.
- `pdfx` for PDF viewing.
- `file_picker` for PDF selection.
- Arabic and English localization.

## Architecture

Features follow a Clean Architecture layout:

```text
lib/
├── core/
│   ├── config/
│   ├── errors/
│   ├── localization/
│   ├── network/
│   └── storage/
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       ├── application/
│       └── presentation/
│           ├── screens/
│           └── widgets/
└── shared/
    ├── models/
    ├── services/
    ├── utils/
    └── widgets/
```

Rules:

- Supabase access belongs in repositories.
- Riverpod providers/notifiers connect repositories to presentation.
- RLS is the security boundary; UI checks are only for user experience.
- User-visible strings use `context.t('key')`.
- Every localization key must exist in both `assets/lang/ar.json` and
  `assets/lang/en.json`.
- Repository errors are converted to `Failure` objects with translation keys.
- Related records are soft-deleted with `is_active = false`.

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
  (`>=3.3.0 <4.0.0`).
- Dart SDK.
- Node.js and `npx` for Supabase CLI commands.
- A Supabase project.
- A Firebase project for Hosting and notifications.
- Android Studio or another Flutter-supported Android toolchain for Android builds.

Verify the local installation:

```powershell
flutter doctor
dart --version
node --version
npx supabase --version
```

## Local setup

### 1. Get the source

```powershell
git clone https://github.com/MohammedAlYounis/edu-platform.git
Set-Location edu-platform
```

### 2. Configure environment variables

Copy `.env.example` to `.env` and set the values:

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-publishable-key
FIREBASE_WEB_VAPID_KEY=your-firebase-web-push-certificate-key
```

`.env` is ignored by Git. Never commit service-role keys, private Firebase
credentials, or OAuth client secrets.

### 3. Install dependencies and generate code

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 4. Apply Supabase migrations

Link the local project once:

```powershell
npx supabase link --project-ref eneqsskqrdlvpnjersrq
```

Apply all migrations:

```powershell
npx supabase db push --linked
```

Verify the local and remote migration histories:

```powershell
npx supabase migration list --linked
```

The current repository includes migrations `001` through `008`. The latest
migrations include targeted notification RLS and repaired lesson/exam Storage
buckets and policies.

The account used for administration must have:

```text
profiles.role = admin
profiles.is_active = true
```

## Run the application

Run the student application on a connected device or emulator:

```powershell
flutter run
```

Run the web dashboard locally:

```powershell
flutter run -d chrome
```

The application loads `.env` through `flutter_dotenv`. Do not use
`--dart-define` unless the configuration implementation is changed accordingly.

## Upload behavior

Lesson, exam, and student-solution uploads use binary uploads on Supabase
Storage. Storage object names are generated as ASCII-only names, for example:

```text
upload_1758451234567_123456789.pdf
```

The original filename, including Arabic characters, remains in the database
`file_name` column and is shown to users. This avoids Supabase Storage
`InvalidKey` errors for Arabic filenames.

The relevant helper is:

```text
lib/shared/utils/storage_file_name.dart
```

## Testing and validation

Run the complete test suite:

```powershell
flutter test
```

Run static analysis:

```powershell
flutter analyze
```

Build the production web bundle:

```powershell
flutter build web --release
```

The current test suite covers content availability, failure mapping, last-opened
content persistence, and ASCII-safe Storage filenames. Full end-to-end tests
against Auth, RLS, Storage, FCM, and real PDF uploads still require a configured
Supabase/Firebase environment.

## Firebase Hosting deployment

Firebase Hosting serves the generated `build/web` directory. The repository
contains a predeploy script that copies the built environment asset to the
location expected by the web application:

```powershell
flutter build web --release
firebase deploy --only hosting
```

`firebase.json` configures:

- `build/web` as the public directory.
- SPA rewrites to `index.html`.
- No-cache headers for the main Flutter web files.
- The web environment preparation script.

The Firebase CLI must already be authenticated and linked to the correct
project:

```powershell
firebase login
firebase use educational-platform-bd155
```

## Authentication and redirects

Supabase Auth uses:

```text
Supabase callback:
https://eneqsskqrdlvpnjersrq.supabase.co/auth/v1/callback

Production web redirect:
https://educational-platform-bd155.web.app

Android deep link:
com.example.edu_platform://login-callback
```

The Android package name and deep-link scheme should not be changed without
updating Supabase, Google Cloud, and Android manifest configuration together.

## Storage buckets

The current private/public behavior is defined by the SQL migrations, not by
the Flutter UI:

- `lessons`: lesson PDF files.
- `exams`: exam PDF files.
- `submissions`: student solution files with restricted access.

When an upload fails, first confirm the authenticated profile is an active
admin, then inspect the translated Failure diagnostic in the debug console and
the Supabase Storage logs.

## Localization

Translation files:

```text
assets/lang/ar.json
assets/lang/en.json
```

Use the localization extension:

```dart
Text(context.t('translation_key'))
```

The default locale is English. The selected locale is persisted with
`SharedPreferences`.

## Branding and icons

The application name is **Mustaqbali**. The source icon is:

```text
assets/images/app-icon-edu.jpeg
```

Android launcher icons, web icons, favicon, manifest metadata, login branding,
and splash branding are generated or configured from this asset.

## Repository hygiene

Ignored local/generated directories include:

```text
.dart_tool/
build/
.firebase/
node_modules/
```

Do not commit:

- `.env`.
- Firebase service-account JSON files.
- Supabase service-role keys.
- Generated build output.
- Local IDE state.

Before removing tracked files such as legacy archives or deployment
configuration, verify that no release or external automation still depends on
them.

## Current known follow-up work

The core application and deployment path are operational, but the following
items should be addressed in a future maintenance pass:

1. Add missing Arabic localization entries for the existing
   `edit_subject` and `edit_content` keys.
2. Replace remaining hard-coded user-facing strings in the PDF viewer and
   repository auth failure path with translated Failure keys.
3. Resolve the remaining Flutter analyzer informational warnings in the admin
   notification screen.
4. Add integration tests for Auth, RLS roles, Storage policies, one-submission
   enforcement, and the admin upload workflow.
5. Review web compatibility of student PDF submission paths that currently use
   `dart:io`.
6. Decide whether the tracked `lib.zip` archive and legacy `vercel.json` are
   still required; remove them only after confirming no external process uses
   them.
7. Add production monitoring and a documented backup/restore procedure for
   Supabase data and Storage.

## License

No public license has been declared yet. Add a license before distributing the
project outside its current repository or organization.
