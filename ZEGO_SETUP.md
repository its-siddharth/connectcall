# ZegoCloud Setup Guide — ConnectCall

This guide walks you through getting **real audio/video calls** working end-to-end on two devices.

---

## Prerequisites

| Tool | Required version | Download |
|---|---|---|
| Flutter SDK | 3.10 or later | https://docs.flutter.dev/get-started/install/windows |
| Android Studio | Latest | https://developer.android.com/studio |
| JDK | 17+ | Bundled with Android Studio |
| Android device or emulator | API 21+ | — |

---

## Part 1 — Install Flutter (if not installed)

1. Download the Flutter SDK zip from https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter` (avoid paths with spaces)
3. Add `C:\flutter\bin` to your **System PATH**
4. Open a new terminal and verify:
   ```powershell
   flutter --version
   flutter doctor
   ```
5. Fix any issues `flutter doctor` reports (especially Android toolchain)

---

## Part 2 — Create a ZegoCloud Account & Project

1. Go to **https://console.zegocloud.com** and sign up (free)
2. Click **"Start for free"** → Choose **"In-app Chat"** or **"Voice & Video Calls"**
3. On the dashboard, click **"Create Project"**
   - Project name: `ConnectCall` (or anything)
   - Use case: **Voice & Video Calls**
4. After creation, you'll see your project card. Click it to open.
5. On the **Project Info** page, note down:
   - **AppID** (a number like `1234567890`)
   - **AppSign** (a 64-character hex string like `abcdef123...`)

> ✅ Free tier: **10,000 minutes/month** — enough for extensive testing.

---

## Part 3 — Add Credentials to the App

### Option A: Via setup script (recommended)

Open PowerShell in the project root and run:

```powershell
.\setup.ps1 -ZegoAppId YOUR_APP_ID -ZegoAppSign YOUR_APP_SIGN
```

Example:
```powershell
.\setup.ps1 -ZegoAppId 1234567890 -ZegoAppSign abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
```

### Option B: Manual edit

Open [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart) and replace:

```dart
static const int zegoAppId = 0;           // ← replace 0 with your App ID
static const String zegoAppSign = '';     // ← replace '' with your App Sign
```

With your real values:

```dart
static const int zegoAppId = 1234567890;
static const String zegoAppSign = 'abcdef1234567890...';
```

---

## Part 4 — Android Configuration

The Android project already has all required settings. Verify:

### `android/app/build.gradle`
- `minSdkVersion 21` ✅ (ZegoCloud requires minimum API 21)
- `compileSdkVersion 34` ✅
- `multiDexEnabled true` ✅

### `android/app/src/main/AndroidManifest.xml`
Already includes all required permissions:
```xml
INTERNET, RECORD_AUDIO, CAMERA, MODIFY_AUDIO_SETTINGS,
BLUETOOTH, BLUETOOTH_CONNECT, ACCESS_NETWORK_STATE, FOREGROUND_SERVICE
```

### `android/build.gradle`
Already includes ZegoCloud Maven repo:
```groovy
maven { url 'https://storage.zego.im/maven' }
```

---

## Part 5 — Run the App

```powershell
# Install dependencies
flutter pub get

# Check connected devices
flutter devices

# Run on a connected Android device
flutter run

# Or run on a specific device
flutter run -d DEVICE_ID
```

---

## Part 6 — Test Real Calls Between Two Devices

1. **Install the app on two Android devices** (or one device + one emulator)
2. **Device A**: Log in as `alice@example.com` / `password123`
3. **Device B**: Log in as `bob@example.com` / `password123`
4. On Device A: tap the 📞 button next to Bob
5. Device B will show the incoming call screen
6. Accept → both devices connect via ZegoCloud WebRTC

> **Important**: Both devices need to be on internet (not just local network) for ZegoCloud signalling to work. The Zego servers relay the connection.

---

## Part 7 — Build APK

```powershell
# Debug APK (for testing)
flutter build apk --debug

# Release APK (optimised)
flutter build apk --release

# Output location:
# build\app\outputs\flutter-apk\app-release.apk
```

---

## How the ZegoCloud Integration Works

```
Device A (Caller)                        Device B (Callee)
─────────────────                        ────────────────────
User taps call button
      │
ZegoSendCallInvitationButton
   sends invitation via
   ZegoUIKitSignalingPlugin
      │
      ├──── Zego Signalling Server ────→  ZegoUIKitPrebuiltCallInvitationService
      │                                           │
      │                                  Shows incoming call overlay
      │                                           │
      │                                  User taps Accept
      │                                           │
      └──── Both join same callID ───────────────→┘
                  │
       ZegoUIKitPrebuiltCall
       (WebRTC audio/video)
       handles the rest
```

### Key files:

| File | Role |
|---|---|
| [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart) | `zegoAppId` + `zegoAppSign` |
| [`lib/services/zego_service.dart`](lib/services/zego_service.dart) | SDK init/uninit, call widget builders |
| [`lib/providers/auth_provider.dart`](lib/providers/auth_provider.dart) | Calls `ZegoService.init` after login |
| [`lib/main.dart`](lib/main.dart) | Passes `AuthProvider.navigatorKey` to `MaterialApp` |
| [`lib/screens/call/audio_call_screen.dart`](lib/screens/call/audio_call_screen.dart) | Uses `ZegoService.buildAudioCall` or mock UI |
| [`lib/screens/call/video_call_screen.dart`](lib/screens/call/video_call_screen.dart) | Uses `ZegoService.buildVideoCall` or mock UI |

---

## Troubleshooting

### `flutter pub get` fails with ZegoCloud package not found
- Check internet connection
- Run `flutter pub cache repair`
- Ensure `android/build.gradle` has `maven { url 'https://storage.zego.im/maven' }`

### App runs but calls stay in mock mode
- Verify `zegoAppId != 0` and `zegoAppSign != ''` in `app_constants.dart`
- Check that `ZegoService.isConfigured` returns `true`

### Incoming call not shown on callee device
- Make sure `ZegoUIKitPrebuiltCallInvitationService().init()` was called (happens automatically after login)
- Both users must be logged in to the app
- Check that `AuthProvider.navigatorKey` is passed to `MaterialApp.navigatorKey`

### Build error: `minSdkVersion` too low
- Ensure `minSdkVersion 21` in `android/app/build.gradle`

### Camera/Microphone permission denied on device
- Go to Android Settings → Apps → ConnectCall → Permissions
- Enable Camera and Microphone
- The app also shows a dialog and "Open Settings" button when permanently denied

### `Duplicate class` errors during build
- Add to `android/app/build.gradle` dependencies:
  ```groovy
  configurations.all {
      resolutionStrategy {
          force 'com.google.firebase:firebase-messaging:23.1.2'
      }
  }
  ```

---

## ZegoCloud Free Tier Limits

| Resource | Free limit |
|---|---|
| Minutes/month | 10,000 |
| Concurrent users | 50 |
| Projects | 2 |
| Support | Community |

For the internship assignment this is more than sufficient.
