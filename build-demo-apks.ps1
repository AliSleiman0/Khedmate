# =============================================================================
# build-demo-apks.ps1 — Install Flutter (if needed) + build demo APKs
#
# Prerequisites: Chocolatey, JDK 17, Android SDK (or Android Studio)
# Run from the workspace root: c:\Khedmate - ANJU_Context\
#
# Usage:
#   Set-ExecutionPolicy Bypass -Scope Process -Force
#   .\build-demo-apks.ps1
# =============================================================================

$ROOT = "c:\Khedmate - ANJU_Context"
Set-Location $ROOT

# ── Step 1: Install Flutter via Chocolatey (if not present) ─────────────────
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "==> Installing Flutter SDK via Chocolatey..." -ForegroundColor Cyan
    choco install flutter --confirm
    # Refresh PATH in current session
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH","User")
}

# ── Step 2: Verify flutter is available ─────────────────────────────────────
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Flutter not found after install. Restart PowerShell and re-run." -ForegroundColor Red
    exit 1
}

flutter --version

# ── Step 3: Accept Android SDK licenses ─────────────────────────────────────
Write-Host "==> Accepting Android SDK licenses..." -ForegroundColor Cyan
& flutter doctor --android-licenses 2>&1 | ForEach-Object { if ($_ -match "y/N") { "y" } else { $_ } }

# ── Step 4: Build customer APK ───────────────────────────────────────────────
Write-Host ""
Write-Host "==> [Customer App] Setting up Android platform..." -ForegroundColor Cyan
Set-Location "$ROOT\mobile-customer"
flutter create --platforms=android . --org com.khudmati
flutter pub get

Write-Host "==> [Customer App] Building debug APK..." -ForegroundColor Cyan
flutter build apk --debug

$customerApk = "$ROOT\mobile-customer\build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $customerApk) {
    Copy-Item $customerApk "$ROOT\khudmati-customer-demo.apk"
    Write-Host "  DONE: khudmati-customer-demo.apk" -ForegroundColor Green
} else {
    Write-Host "  WARNING: APK not found at expected path. Check build output above." -ForegroundColor Yellow
}

# ── Step 5: Build provider APK ───────────────────────────────────────────────
Write-Host ""
Write-Host "==> [Provider App] Setting up Android platform..." -ForegroundColor Cyan
Set-Location "$ROOT\mobile-provider"
flutter create --platforms=android . --org com.khudmati
flutter pub get

Write-Host "==> [Provider App] Building debug APK..." -ForegroundColor Cyan
flutter build apk --debug

$providerApk = "$ROOT\mobile-provider\build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $providerApk) {
    Copy-Item $providerApk "$ROOT\khudmati-provider-demo.apk"
    Write-Host "  DONE: khudmati-provider-demo.apk" -ForegroundColor Green
} else {
    Write-Host "  WARNING: APK not found at expected path. Check build output above." -ForegroundColor Yellow
}

# ── Done ─────────────────────────────────────────────────────────────────────
Set-Location $ROOT
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  APKs ready in workspace root:" -ForegroundColor Green
Write-Host "    khudmati-customer-demo.apk" -ForegroundColor Green
Write-Host "    khudmati-provider-demo.apk" -ForegroundColor Green
Write-Host ""
Write-Host "  Once droplet is live, update AppConfig.backendHost in:" -ForegroundColor Yellow
Write-Host "    mobile-customer\lib\core\constants\app_config.dart" -ForegroundColor Yellow
Write-Host "    mobile-provider\lib\core\constants\app_config.dart" -ForegroundColor Yellow
Write-Host "  Then rebuild with: flutter build apk --debug" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
