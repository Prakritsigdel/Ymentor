# Ymentor — Zero-Budget Micro-Mentorship Marketplace

Full, runnable rebuild: Node/Express/MongoDB backend + Flutter frontend +
Android build config fixed for your environment (Windows 11, JDK 17 Temurin,
API 36 device).

## What's in this zip

```
ymentor/
  server.js            Express API (unchanged from your original)
  models/               <-- was MISSING before; server.js requires these to boot
    User.js
    Booking.js
    Workspace.js
    Note.js
  package.json          Backend-only deps (express, mongoose, multer, jwt, bcrypt)
  uploads/               Static PDF storage folder
  pubspec.yaml           Flutter deps (added file_picker, intl, cupertino_icons)
  lib/                    <-- the actual Flutter app, previously missing entirely
    main.dart
    config/               theme.dart, api_config.dart
    models/                user_model.dart, booking_model.dart, workspace_model.dart
    services/               api_service.dart (wraps every backend endpoint)
    providers/               auth_provider.dart (persisted login + pending-booking guard)
    screens/
      discovery_screen.dart          guest browsing + skill filters + leaderboard
      mentor_profile_screen.dart      duration picker + slot grid + auth-guarded booking
      checkout_screen.dart            escrow itemization + mock payment + receipt
      root_shell.dart                 bottom nav shell
      auth/                            login_screen.dart, register_screen.dart
      bookings/                        active_call_screen.dart (join/complete/escrow release)
      workspace/                       workspace_screen.dart (PDF notes + comment threads)
      dashboard/                       mentor_dashboard_screen.dart (wallet, upload, pricing)
    widgets/
      mentor_card.dart
  android/                Rebuilt Gradle config (see below)
```

## Why your build was failing

1. **`server.js` required `./models/User`, `./models/Booking`, etc., but those
   files didn't exist in your project.** Node crashes on `require()` of a
   missing file *before* it even checks Mongo — so the backend couldn't start
   at all, independent of any Android issue. Added all four models.
2. **There was no `lib/` folder / Dart source anywhere in your project** — only
   `pubspec.yaml`. Nothing for `flutter run` to actually build. Wrote the full
   app from your original spec.
3. **Android Gradle Plugin 9.0 (released Jan 2026) changed its default DSL**,
   and your Flutter install is new enough to pull it in. AGP 9 only reads the
   new declarative DSL by default, so a `build.gradle` written in the old
   Groovy style (`sourceCompatibility JavaVersion...`) fails with:
   `Starting AGP 9+, only the new DSL interface will be read.`
   Rather than migrate to the new DSL (still actively changing), this project
   **pins AGP to `8.13.2`** (last pre-AGP-9 line, still fully supported) and
   explicitly sets `android.newDsl=false` / `android.builtInKotlin=false` in
   `gradle.properties` as a safety net, so a future Flutter auto-migrator run
   can't silently flip you onto AGP 9 defaults again.
4. **Gradle wrapper pinned to 8.14** (`gradle-wrapper.properties`), which
   satisfies both AGP 8.13.2's minimum (Gradle ≥ 8.13) and your Flutter
   install's own minimum (8.14) — the two error messages you hit were each
   asking for a different floor; 8.14 clears both.
5. **No hardcoded `org.gradle.java.home`** anywhere — Gradle uses your system
   `JAVA_HOME` (Temurin 17), so this works regardless of the exact install
   path on your machine.

## Setup

### 1. Backend
```powershell
cd ymentor
npm install
node server.js
```
Runs on `http://localhost:3000`. If MongoDB isn't running locally, it
auto-falls back to an in-memory store with seeded demo mentors — no DB setup
required to try it out.

### 2. Connect your Android device
```powershell
adb reverse tcp:3000 tcp:3000
```

### 3. Flutter app
```powershell
flutter clean
flutter pub get
flutter run
```
`flutter pub get` auto-writes `android/local.properties` for you — don't
create it by hand.

### Demo login
```
Mentee: jordan.cole@gmail.com / password123
Mentor: alex.rivera@ymentor.demo / password123
```

## If Android Studio still shows a JVM prompt when opening the project
That's the IDE's own "Gradle JVM" setting, separate from `JAVA_HOME` used by
`flutter run`. Settings → Build Tools → Gradle → Gradle JVM → pick your
Temurin 17 install (or "Add JDK..." and browse to it). This doesn't affect
command-line `flutter run`.

## Known simplifications
- The mock payment form in Checkout is a visual sandbox only (pre-filled,
  disabled fields) — no real card processing, matching the spec's "zero
  budget" demo intent.
- Launcher icons are simple placeholder shapes in the app's mint/forest-green
  palette — swap `android/app/src/main/res/mipmap-*/ic_launcher.png` for real
  branding whenever you like.
- `applicationId` is `com.ymentor.app`. If you need a different one, update
  `android/app/build.gradle` (`namespace` + `applicationId`) and move
  `MainActivity.kt` to match the new package path.
