# Phase 09 — Platform Config, Firebase, Icons, Splash

## Goal
Finalize Android + iOS platform configuration (permissions, Firebase, icons, splash, app names) so release builds can be signed and installed on real devices with no runtime permission errors.

## Why this phase
Permissions and Firebase config are the things most likely to ship broken to stores if left until the last minute. Handle them before the release-build verification in Phase 11.

## Pre-requisites
- Phase 08 complete
- Phase 0 Decision B locked in (Firebase strategy)
- Access to Firebase console for whichever project was decided
- Icon source file (SVG or 1024×1024 PNG) from designer

## Scope

### 1. Android permissions
Edit `mobile/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<queries>
  <intent>
    <action android:name="android.intent.action.DIAL" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```

`ACCESS_BACKGROUND_LOCATION` is required for provider navigation GPS broadcasting during EnRoute — Google Play reviews this carefully, document the use case in listing.

### 2. iOS permissions (Info.plist)
Add to `mobile/ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Khudmati uses your location to find nearby service providers and to share your address when you book a job.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Providers share their live location with customers while en route to a job.</string>
<key>NSCameraUsageDescription</key>
<string>Take photos of the job for accurate service, identity verification, and before/after records.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Attach existing photos to help describe the job or upload verification documents.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Send voice messages in chat with your provider or customer.</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>khudmati</string>
    </array>
  </dict>
</array>
```

All copy bilingual-friendly (short enough to translate into AR if localized strings file is used).

### 3. Firebase setup (per Phase 0 Decision B)

**If new project `khudmati-app`:**
1. Create project in Firebase console
2. Add Android app with package `com.khudmati.app` → download `google-services.json` → place at `mobile/android/app/google-services.json`
3. Add iOS app with bundle `com.khudmati.app` → download `GoogleService-Info.plist` → place at `mobile/ios/Runner/GoogleService-Info.plist`
4. Enable Cloud Messaging
5. Upload APNs key from Apple Developer portal
6. Update backend's FCM server key env var to the new sender id

**If reusing existing project:**
- Register new Android + iOS app within that project; repeat steps 2–3 + backend env var only if sender id differs.

### 4. App icons
Use `flutter_launcher_icons`:

`pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#1B4F72"
  adaptive_icon_foreground: "assets/icon/icon-foreground.png"
  min_sdk_android: 21
  remove_alpha_ios: true
```

Run: `dart run flutter_launcher_icons`

### 5. Splash screen
Use `flutter_native_splash`:

`pubspec.yaml`:
```yaml
flutter_native_splash:
  color: "#1B4F72"
  image: "assets/splash/logo.png"
  android_12:
    image: "assets/splash/logo.png"
    color: "#1B4F72"
```

Run: `dart run flutter_native_splash:create`

### 6. App display name (localized)
Android — `android/app/src/main/res/values/strings.xml`:
```xml
<resources>
  <string name="app_name">Khudmati</string>
</resources>
```
Android — `android/app/src/main/res/values-ar/strings.xml`:
```xml
<resources>
  <string name="app_name">خدمتي</string>
</resources>
```

AndroidManifest: `android:label="@string/app_name"`.

iOS — `ios/Runner/InfoPlist.strings` (create if absent) + `ar.lproj/InfoPlist.strings`:
```
"CFBundleDisplayName" = "خدمتي";
```

### 7. Stripe publishable key — environment gating
Move from hardcoded to `--dart-define`:
- `mobile/lib/main.dart`: `Stripe.publishableKey = const String.fromEnvironment('STRIPE_PK', defaultValue: 'pk_test_...')`
- Document build commands: `flutter build apk --release --dart-define=STRIPE_PK=pk_live_xxx`

### 8. ProGuard / R8 (Android release)
Edit `mobile/android/app/build.gradle`:
```groovy
buildTypes {
  release {
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
  }
}
```

Create `mobile/android/app/proguard-rules.pro` with rules for Stripe + SignalR + Firebase (copy from provider app if it has one).

### 9. iOS capabilities (Xcode)
In Xcode project:
- Background Modes: Location updates, Remote notifications
- Push Notifications capability
- Associated Domains (for universal links if using them later — optional)

## Files to create
- `mobile/assets/icon/icon.png`
- `mobile/assets/icon/icon-foreground.png`
- `mobile/assets/splash/logo.png`
- `mobile/android/app/google-services.json` (downloaded from Firebase)
- `mobile/ios/Runner/GoogleService-Info.plist` (downloaded from Firebase)
- `mobile/android/app/src/main/res/values-ar/strings.xml`
- `mobile/ios/Runner/ar.lproj/InfoPlist.strings`
- `mobile/android/app/proguard-rules.pro`

## Files to modify
- `mobile/pubspec.yaml` — add `flutter_launcher_icons` + `flutter_native_splash` config
- `mobile/android/app/src/main/AndroidManifest.xml` — permissions
- `mobile/ios/Runner/Info.plist` — permissions + URL scheme
- `mobile/android/app/build.gradle` — ProGuard + applicationId
- `mobile/lib/main.dart` — Stripe key via `--dart-define`

## Verification
1. `flutter build apk --release` succeeds
2. `flutter build ios --release --no-codesign` succeeds (on macOS)
3. Install release APK — app icon correct, splash shows, app launches
4. Permission prompts appear correctly on first launch (location, camera, notifications)
5. FCM test message sent from Firebase console arrives as a system notification, tap routes correctly
6. Background location permission dialog appears when provider enters navigation screen
7. Stripe test payment completes end-to-end with `--dart-define STRIPE_PK=pk_test_xxx` on release build
8. Deep link: `adb shell am start -W -a android.intent.action.VIEW -d "khudmati://job/abc123"` opens correct screen based on role

## Exit criteria
- [ ] Release builds succeed for both platforms
- [ ] All permission rationales bilingual-ready
- [ ] Firebase Cloud Messaging verified end-to-end
- [ ] App icon + splash render correctly on Android 12+, Android 11-, iOS
- [ ] ProGuard rules don't break Stripe, SignalR, or Firebase on release
- [ ] Commit: `feat(mobile): platform config + Firebase + icons + splash`

## Rollback
- Revert commit. Debug builds still work; no store submission yet.
