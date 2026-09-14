# ConnectCall — Complete ZegoCloud Setup Script
# Run this in your project root AFTER installing Flutter SDK

param(
    [string]$ZegoAppId = "",
    [string]$ZegoAppSign = ""
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ConnectCall — ZegoCloud Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Check Flutter ─────────────────────────────────────────────────────
Write-Host "[1/5] Checking Flutter installation..." -ForegroundColor Yellow
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "  ERROR: Flutter not found in PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Install Flutter from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor White
    Write-Host "  Then add Flutter\bin to your PATH and re-run this script." -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host "  Flutter found: $($flutterCmd.Source)" -ForegroundColor Green

# ── Step 2: Inject Zego credentials ──────────────────────────────────────────
if ($ZegoAppId -ne "" -and $ZegoAppSign -ne "") {
    Write-Host ""
    Write-Host "[2/5] Injecting ZegoCloud credentials..." -ForegroundColor Yellow

    $constantsFile = "lib\core\constants\app_constants.dart"
    $content = Get-Content $constantsFile -Raw
    $content = $content -replace 'static const int zegoAppId = \d+;', "static const int zegoAppId = $ZegoAppId;"
    $content = $content -replace "static const String zegoAppSign = '[^']*';", "static const String zegoAppSign = '$ZegoAppSign';"
    Set-Content $constantsFile $content
    Write-Host "  Credentials written to app_constants.dart" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[2/5] Skipping credential injection (no -ZegoAppId / -ZegoAppSign provided)." -ForegroundColor DarkYellow
    Write-Host "  You can set them manually in lib\core\constants\app_constants.dart" -ForegroundColor White
    Write-Host "  or re-run: .\setup.ps1 -ZegoAppId YOUR_ID -ZegoAppSign YOUR_SIGN" -ForegroundColor White
}

# ── Step 3: flutter pub get ───────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/5] Running flutter pub get..." -ForegroundColor Yellow
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: flutter pub get failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Dependencies resolved." -ForegroundColor Green

# ── Step 4: Verify Android setup ──────────────────────────────────────────────
Write-Host ""
Write-Host "[4/5] Checking Android SDK..." -ForegroundColor Yellow
$androidHome = $env:ANDROID_HOME
if (-not $androidHome) { $androidHome = $env:ANDROID_SDK_ROOT }
if ($androidHome) {
    Write-Host "  Android SDK found: $androidHome" -ForegroundColor Green
} else {
    Write-Host "  WARNING: ANDROID_HOME not set." -ForegroundColor DarkYellow
    Write-Host "  Install Android Studio from https://developer.android.com/studio" -ForegroundColor White
}
& flutter doctor --android-licenses 2>$null

# ── Step 5: Summary ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/5] Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Connect an Android device or start an emulator" -ForegroundColor White
Write-Host "  2. Run:  flutter run" -ForegroundColor White
Write-Host "  3. Login: alice@example.com / password123" -ForegroundColor White
Write-Host ""
if ($ZegoAppId -ne "") {
    Write-Host "  Real ZegoCloud calls: ENABLED" -ForegroundColor Green
    Write-Host "  To test between two devices, install the app on both," -ForegroundColor White
    Write-Host "  log in with different accounts, and tap the call button." -ForegroundColor White
} else {
    Write-Host "  ZegoCloud calls: MOCK MODE (no real WebRTC)" -ForegroundColor DarkYellow
    Write-Host "  To enable real calls, get credentials at:" -ForegroundColor White
    Write-Host "  https://console.zegocloud.com" -ForegroundColor Cyan
    Write-Host "  Then re-run: .\setup.ps1 -ZegoAppId YOUR_ID -ZegoAppSign YOUR_SIGN" -ForegroundColor White
}
Write-Host ""
