# Splash screen assets

Drop `logo.png` here (usually ~512x512 transparent PNG of the Khudmati wordmark on brand-blue background).

After adding the file run:

```bash
dart run flutter_native_splash:create
```

Splash background is brand blue (`#1B4F72`) on all platforms (including Android 12+). Configured in `mobile/pubspec.yaml` under `flutter_native_splash`.
