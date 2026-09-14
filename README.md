# ConnectCall — Flutter Calling App

**Connect with anyone, anywhere.**

A functional 1-to-1 audio and video calling application built with Flutter for the Flutter Development Intern Assignment.

---

## Features

### Core
- ✅ Splash screen with animated logo
- ✅ Login / Registration (mock auth with 8 demo users)
- ✅ Home screen with recent contacts & bottom navigation
- ✅ Contacts screen — profile, online/offline status, audio/video call buttons
- ✅ User Profile screen — view profile, initiate call
- ✅ **Audio Calling** — mute/unmute, speaker toggle, call timer, end call
- ✅ **Video Calling** — mute/unmute, camera on/off, front/rear switch, end call
- ✅ **Incoming Call screen** — accept/decline with animation
- ✅ Call History — caller, type, time, duration, missed indicator, call-back
- ✅ Search — real-time contact search
- ✅ Edit Profile — update display name
- ✅ Dark mode support
- ✅ Permission handling — microphone & camera

### Calling Technology
**ZegoCloud** (UIKit Prebuilt) is used for real-time audio/video calling.

When Zego credentials (`zegoAppId` / `zegoAppSign`) are configured, the app uses the real Zego SDK for live calls. Without credentials, a mock call UI is shown for demonstration purposes.

**Why Zego?**
- Easiest Flutter integration via `zego_uikit_prebuilt_call`
- Pre-built call UI handles WebRTC, signalling, and permissions internally
- Supports 1-to-1 audio & video out of the box

### Backend
- Mock in-memory + SharedPreferences persistence
- Simulates login, registration, user list, call history
- Easily swappable with Firebase / Supabase

---

## Architecture

```
lib/
├── core/
│   ├── constants/       app_constants.dart, route_constants.dart
│   ├── theme/           app_colors.dart, app_theme.dart
│   └── utils/           app_utils.dart, storage_service.dart
├── models/
│   ├── user_model.dart
│   └── call_model.dart
├── services/
│   ├── auth_service.dart
│   ├── user_service.dart
│   └── calling_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── users_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── splash/          splash_screen.dart
│   ├── auth/            login_screen.dart, register_screen.dart
│   ├── home/            home_screen.dart  (all 4 tabs)
│   ├── profile/         user_profile_screen.dart, edit_profile_screen.dart
│   ├── call/            audio_call_screen.dart, video_call_screen.dart, incoming_call_screen.dart
│   └── search/          search_screen.dart
├── widgets/
│   ├── user_avatar.dart
│   ├── user_tile.dart
│   ├── app_text_field.dart
│   └── common_button.dart
└── main.dart
```

---

## State Management
**Provider** — chosen for its simplicity, testability, and official Flutter support.
- `AuthProvider` — authentication state
- `UsersProvider` — contacts and search
- `ThemeProvider` — light/dark mode
- `CallingService` (ChangeNotifier) — call lifecycle & history

---

## Flutter Version
Tested with Flutter 3.x (Dart 3.x)

---

## Packages Used

| Package | Purpose |
|---|---|
| `provider` | State management |
| `shared_preferences` | Local persistence |
| `permission_handler` | Microphone / Camera permissions |
| `zego_uikit_prebuilt_call` | Real-time audio/video calling |
| `uuid` | Unique call/user IDs |
| `intl` | Date/time formatting |
| `timeago` | Relative timestamps |
| `connectivity_plus` | Network status |
| `cached_network_image` | Avatar images |
| `logger` | Debug logging |

---

## Setup Instructions

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Configure ZegoCloud (for real calls)
1. Create an account at [ZegoCloud console](https://console.zegocloud.com/)
2. Create a new project → get **App ID** and **App Sign**
3. Open `lib/core/constants/app_constants.dart`
4. Replace:
   ```dart
   static const int zegoAppId = 0;         // ← your App ID
   static const String zegoAppSign = '';   // ← your App Sign
   ```

> Without Zego credentials, the app runs in **mock mode** — all UI is functional but calls are simulated.

### 3. Run the app
```bash
flutter run
```

### 4. Demo Accounts
| Email | Password |
|---|---|
| alice@example.com | password123 |
| bob@example.com | password123 |
| carol@example.com | password123 |
| (5 more...) | password123 |

---

## Environment Variables / Configuration

| Key | File | Description |
|---|---|---|
| `zegoAppId` | `app_constants.dart` | ZegoCloud App ID |
| `zegoAppSign` | `app_constants.dart` | ZegoCloud App Sign |

---

## Known Limitations

- Real-time incoming call notifications (push) require a backend + FCM; currently simulated in-app
- Call signalling between two physical devices requires ZegoCloud credentials
- Avatar image upload is UI-only (no file storage backend)
- No actual WebRTC without Zego credentials

---

## AI Tools Used
- IBM Bob (primary development assistant)
- Architecture and code patterns were reviewed and understood throughout

---

## Call States Handled

```
Calling → Ringing → Connected → In Call → Ended
                             ↓
                  Rejected | Missed | Failed | Disconnected
```
