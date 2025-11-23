# 🐾 PawJeevan Frontend

Flutter mobile application for PawJeevan - Pet Store & AI Care Platform 📱

## 🚀 Getting Started

### Prerequisites
- 🐦 Flutter SDK (3.0.0 or higher)
- 🎯 Dart SDK
- 🌐 Chrome/Edge browser for web development

### Installation
1. 📦 Install dependencies:
   ```bash
   flutter pub get
   ```
2. ▶️ Run the app:
   ```bash
   flutter run
   ```
   - For web: `flutter run -d chrome`
   - For Android: `flutter run -d android`
   - For iOS: `flutter run -d ios`

## 🗂️ Project Structure
- `lib/`: Main source code
  - `models/`: Data models
  - `providers/`: State management
  - `screens/`: UI screens
  - `services/`: API and business logic
  - `utils/`: Utility functions
  - `widgets/`: Reusable UI components
- `assets/`: Images and icons
- `test/`: Widget and unit tests

## ✨ Features
- 👤 User authentication and profile management (registration now requires email OTP verification)
- 🐶 Pet adoption and lost & found
- 📝 Community posts, events, and groups
- 🛒 Store for pet products
- 🤖 AI-powered pet care features

## �️ Development
# PawJeevan — Frontend (Flutter)

This directory contains the Flutter application used by PawJeevan (mobile and web).

Prerequisites

- Flutter SDK (stable channel) installed and available on PATH
- A compatible Dart SDK (bundled with Flutter)
- For mobile builds: Android SDK / Xcode (as required by Flutter)

Quick start (Windows PowerShell)

```powershell
cd frontend
flutter doctor
flutter pub get

# Run on web (Chrome)
flutter run -d chrome

# Or run on connected device/emulator
flutter run

# Build release outputs
flutter build web
flutter build apk
```

Configuration

- API base URL / runtime config: the app loads non-secret runtime configuration from the backend at startup. Ensure the backend is running locally while developing.
- For local development, update the API settings in `lib/config.dart` if needed, or make sure your backend's `api` host is reachable.

Project layout (important folders)

- `lib/` — application source
   - `models/`, `providers/`, `screens/`, `services/`, `utils/`, `widgets/`
- `assets/` — images and icons referenced from `pubspec.yaml`
- `test/` — widget & unit tests

OTP registration flow (frontend notes)

- The app's registration flow supports an email OTP verification step. When the backend returns `requires_verification` with a `pending_id`, the app shows a screen to collect the 6-digit OTP and complete verification.
- Relevant frontend pieces: `AuthService.register()` and `AuthService.verifyOtp()` (verify how `pending_id` is handled in your app code).

Testing

```powershell
cd frontend
flutter test
```

Deployment

- Use `flutter build` variants for your target platform (`web`, `apk`, `ios`).
- For web deployment, serve the contents of `build/web` via any static host or CDN.

Notes

- Keep secrets out of the repo. Do not commit API keys or `.env` files. Use runtime config and environment variables.
- If you change native platform files, run `flutter pub get` and rebuild.

---

Made with ❤️ by the PawJeevan Team
