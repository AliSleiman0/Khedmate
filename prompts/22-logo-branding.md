# 22 — Logo & Branding: House Icon Across All Platforms

## Context
Set `logo.png` (dark-brown house icon on cream background, located at project root) as the brand logo across all platforms:
- **Websites**: favicon + header/sidebar logo image (replacing current text-only branding)
- **Flutter apps**: launcher icon + native Android splash + assets (welcome screens already reference `assets/images/logo.png` which is currently missing)

---

## Source Asset
`logo.png` (project root) — single source of truth for all platforms.

---

## Part 1: Web Projects

All three web projects currently have no image assets and no favicon. Logos are text-only.

### web-landing

**Files to modify:**
- `web-landing/public/logo.png` ← copy from root `logo.png`
- `web-landing/index.html` — add `<link rel="icon" type="image/png" href="/logo.png" />`
- `web-landing/src/components/layout/Header.tsx` — replace `<span>خدمتي</span>` with `<img src="/logo.png" alt="خدمتي" style={{ height: 40 }} />`
- `web-landing/src/components/layout/Footer.tsx` — replace `<p>خدمتي</p>` with `<img src="/logo.png" alt="خدمتي" style={{ height: 36 }} />`

### web-admin

**Files to modify:**
- `web-admin/public/logo.png` ← copy from root `logo.png`
- `web-admin/index.html` — add favicon `<link>` tag
- `web-admin/src/layouts/AdminLayout.tsx` — replace `<p className="text-xl font-bold">Khudmati</p>` with `<img src="/logo.png" alt="Khudmati" className="h-10 w-auto" />` (keep "Admin Portal" subtitle)

### web-superadmin

**Files to modify:**
- `web-superadmin/public/logo.png` ← copy from root `logo.png`
- `web-superadmin/index.html` — add favicon `<link>` tag
- `web-superadmin/src/layouts/SuperAdminLayout.tsx` — replace `<p className="text-xl font-bold text-white">Khudmati</p>` with `<img src="/logo.png" alt="Khudmati" className="h-10 w-auto" />` (keep SUPER ADMIN badge)

---

## Part 2: Flutter Mobile Apps

### 2a. Logo Asset (fixes broken welcome screen)

Both welcome screens already call `Image.asset('assets/images/logo.png', height: 130)` but the file is missing — causing a runtime error.

- Copy root `logo.png` → `mobile-customer/assets/images/logo.png`
- Copy root `logo.png` → `mobile-provider/assets/images/logo.png`

No `pubspec.yaml` changes needed — `assets/images/` is already declared in both.

### 2b. Launcher Icons (app icon)

Add `flutter_launcher_icons` dev dependency to both apps.

**`pubspec.yaml` additions (both apps):**
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#FAF0E6"   # matches logo's cream background
  adaptive_icon_foreground: "assets/images/logo.png"
  min_sdk_android: 21
```

**After code changes, run in each app directory:**
```bash
flutter pub get && dart run flutter_launcher_icons
```

### 2c. Native Android Splash Screen

Update `launch_background.xml` in both apps to show the logo centered on brand-blue (`#1B4F72`) background.

**`android/app/src/main/res/drawable/launch_background.xml`** (and `drawable-v21/launch_background.xml`):
```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_bg" />
    <item>
        <bitmap android:gravity="center" android:src="@drawable/splash_logo" />
    </item>
</layer-list>
```

**`android/app/src/main/res/values/colors.xml`** (new file, both apps):
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_bg">#1B4F72</color>
</resources>
```

Also copy root `logo.png` → `android/app/src/main/res/drawable/splash_logo.png` in both apps.

---

## All Files Changed

| File | Action |
|---|---|
| `web-landing/public/logo.png` | New (copy) |
| `web-landing/index.html` | Add favicon link |
| `web-landing/src/components/layout/Header.tsx` | Text → `<img>` |
| `web-landing/src/components/layout/Footer.tsx` | Text → `<img>` |
| `web-admin/public/logo.png` | New (copy) |
| `web-admin/index.html` | Add favicon link |
| `web-admin/src/layouts/AdminLayout.tsx` | Text → `<img>` |
| `web-superadmin/public/logo.png` | New (copy) |
| `web-superadmin/index.html` | Add favicon link |
| `web-superadmin/src/layouts/SuperAdminLayout.tsx` | Text → `<img>` |
| `mobile-customer/assets/images/logo.png` | New (copy) |
| `mobile-provider/assets/images/logo.png` | New (copy) |
| `mobile-customer/pubspec.yaml` | Add flutter_launcher_icons dev dep + config |
| `mobile-provider/pubspec.yaml` | Add flutter_launcher_icons dev dep + config |
| `mobile-customer/android/app/src/main/res/drawable/launch_background.xml` | Add logo + brand-blue bg |
| `mobile-customer/android/app/src/main/res/drawable-v21/launch_background.xml` | Same |
| `mobile-customer/android/app/src/main/res/drawable/splash_logo.png` | New (copy) |
| `mobile-customer/android/app/src/main/res/values/colors.xml` | New |
| `mobile-provider/android/app/src/main/res/drawable/launch_background.xml` | Add logo + brand-blue bg |
| `mobile-provider/android/app/src/main/res/drawable-v21/launch_background.xml` | Same |
| `mobile-provider/android/app/src/main/res/drawable/splash_logo.png` | New (copy) |
| `mobile-provider/android/app/src/main/res/values/colors.xml` | New |

---

## Verification

1. **Websites**: `npm run dev` in each web project → favicon in browser tab, logo in header/sidebar
2. **Flutter welcome screen**: `flutter run` → WelcomeScreen shows logo (no missing asset error)
3. **Flutter launcher icon**: After running `dart run flutter_launcher_icons` + reinstall APK → home screen shows new icon
4. **Flutter native splash**: Cold start shows brand-blue screen with centered logo before Flutter engine loads
