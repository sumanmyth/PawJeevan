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
- 👤 User authentication and profile management
- 🐶 Pet adoption and lost & found
- 📝 Community posts, events, and groups
- 🛒 Store for pet products
- 🤖 AI-powered pet care features

## 🛠️ Development
- ⚡ Hot reload supported for rapid development
- 📱 Responsive design for mobile and web
- 🔗 Integration with backend REST API

### Runtime configuration (Google client id)

- The frontend no longer hard-codes the Google OAuth client id. Instead the app fetches a non-secret runtime configuration from the backend endpoint:

   - `GET http://<api-host>/api/config/google/`
   - Response: `{"google_client_id": "<value>"}`

- Local development: ensure the backend is running and that `backend/.env` contains `GOOGLE_CLIENT_ID` (this file is not committed). The frontend calls `ConfigService.init()` at startup to load the value.

- Web: `web/index.html` contains a small script that fetches the backend value and sets the `meta[name="google-signin-client_id"]` tag before the Google sign-in script initializes. For production you may prefer CI-time injection instead of runtime fetch.

### Notes
- If the frontend cannot reach the backend at startup it will still run, but Google Sign-In will fail until the client id is available. During local development run both backend and frontend.

## 📦 Deployment
- 📱 Android, 🍏 iOS, and 🌐 Web supported
- See official Flutter docs for build and release instructions

## 📝 Notes
- 📄 Update `pubspec.yaml` for new dependencies
- 🔧 Configure API endpoints in `lib/services/`

## 📄 License
MIT

---

Made with ❤️ by the PawJeevan Team