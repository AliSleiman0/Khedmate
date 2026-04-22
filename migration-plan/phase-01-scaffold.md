# Phase 01 — Scaffold Unified App

## Goal
Create an empty `mobile/` Flutter app with the union of both apps' dependencies, assets, and platform config, and confirm it builds on Android + iOS before any real code lands.

## Why this phase
A working baseline is the foundation. If Phase 2+ runs into build errors, we must be able to know they came from our new code, not from a broken scaffold.

## Pre-requisites
- Phase 00 complete (branch + decisions)
- Flutter SDK installed and on PATH
- Android Studio (emulator) or physical Android device
- Xcode (iOS simulator) on macOS, or iOS device

## Scope

### 1. Create the Flutter project
From repo root:
```bash
cd "C:/Khedmate - ANJU_Context"
flutter create mobile --org com.khudmati --project-name mobile --platforms=android,ios
```

This produces `C:/Khedmate - ANJU_Context/mobile/` with standard structure.

### 2. Merge pubspec.yaml
Replace `mobile/pubspec.yaml` dependencies section with the union of both apps. Use these exact pins (take the newer where they diverge):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  go_router: ^13.2.0
  dio: ^5.4.0
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  signalr_netcore: ^1.3.5
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  pinput: ^6.0.2
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  image_picker: ^1.1.2
  lottie: ^3.1.0
  flutter_stripe: ^10.1.1
  url_launcher: ^6.2.4
  firebase_core: ^2.27.0
  firebase_messaging: ^14.9.0
  flutter_local_notifications: ^17.0.0
  fl_chart: ^0.68.0
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.10
```

Also declare fonts and assets (Cairo + Inter, logo):
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
  fonts:
    - family: Cairo
      fonts:
        - asset: assets/fonts/Cairo-Regular.ttf
        - asset: assets/fonts/Cairo-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

Run `flutter pub get`.

### 3. Copy assets
Copy font files and logo from the customer app (its assets are complete; provider's fonts folder is empty):
```bash
cp -r "C:/Khedmate - ANJU_Context/mobile-customer/assets/fonts" "C:/Khedmate - ANJU_Context/mobile/assets/fonts"
cp -r "C:/Khedmate - ANJU_Context/mobile-customer/assets/images" "C:/Khedmate - ANJU_Context/mobile/assets/images"
```

### 4. Configure Android
Edit `mobile/android/app/build.gradle`:
- `applicationId "com.khudmati.app"` (or whatever Phase 0 Decision A specified)
- `minSdkVersion 21`
- `targetSdkVersion flutter.targetSdkVersion`

Edit `mobile/android/app/src/main/AndroidManifest.xml`:
- `android:label="Khudmati"` on `<application>` (update after Phase 9 for per-locale labels)

### 5. Configure iOS
Open `mobile/ios/Runner.xcodeproj` in Xcode:
- Bundle identifier: `com.khudmati.app`
- Display name: `Khudmati`
- Deployment target: iOS 13.0

### 6. Baseline build verification
```bash
cd "C:/Khedmate - ANJU_Context/mobile"
flutter pub get
flutter analyze                    # expect 0 errors, warnings OK
flutter run                        # on Android emulator
flutter run -d ios                 # on iOS simulator (macOS only)
```

The default Flutter counter app should appear. No further changes.

## Files to create / modify
- `C:/Khedmate - ANJU_Context/mobile/` — new directory (entire Flutter scaffold)
- `C:/Khedmate - ANJU_Context/mobile/pubspec.yaml` — merged dependencies
- `C:/Khedmate - ANJU_Context/mobile/android/app/build.gradle` — package id
- `C:/Khedmate - ANJU_Context/mobile/ios/Runner.xcodeproj` — bundle id (via Xcode)
- `C:/Khedmate - ANJU_Context/mobile/assets/` — copied from customer app

## Files to reference (do not modify)
- `C:/Khedmate - ANJU_Context/mobile-customer/pubspec.yaml` — source of asset declarations
- `C:/Khedmate - ANJU_Context/mobile-provider/pubspec.yaml` — source of provider-only deps

## Verification
- `flutter run` on Android shows the default counter app
- `flutter run -d ios` on iOS simulator shows the default counter app
- `flutter analyze` returns 0 errors
- App package id visible via `adb shell pm list packages | grep khudmati` matches the Phase 0 decision

## Exit criteria
- [ ] `mobile/` directory exists with valid Flutter structure
- [ ] Merged pubspec.yaml compiles (`flutter pub get` succeeds)
- [ ] Fonts + logo copied under `assets/`
- [ ] Android build runs on emulator
- [ ] iOS build runs on simulator (if macOS available)
- [ ] `flutter analyze` clean
- [ ] Branch `feat/unified-app` has one commit named something like `feat(mobile): scaffold unified app`

## Rollback
- `rm -rf mobile/` and reset branch. No external systems affected.
