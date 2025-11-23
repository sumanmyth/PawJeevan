# 🐾 PawJeevan Backend

Welcome to the backend of PawJeevan! 🚀

## ✨ Features
- 👤 User authentication & management
- 📝 Community posts, events, and groups
- 🐶 Pet adoption & lost & found
- 🛒 Store for products & brands
- 🤖 AI module for advanced features
- 🔗 RESTful API endpoints
- 🖼️ Media file handling (avatars, pet photos, certificates, etc.)

## 🗂️ Structure
- `admin_panel/`, `ai_module/`, `community/`, `store/`, `users/`: Django apps for different functionalities
- `pawjeevan_backend/`: Main Django project settings and URLs
- `media/`: Stores uploaded files and images
- `db.sqlite3`: Default database (can be changed to PostgreSQL, MySQL, etc.)
- `requirements.txt`: Python dependencies
- `manage.py`: Django management script

## ⚡ Quickstart
1. 📦 Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. 🛠️ Run migrations:
   ```bash
   python manage.py migrate
   ```
3. 👑 Create superuser:
   ```bash
   python manage.py createsuperuser
   ```
4. ▶️ Start the server:
   ```bash
   python manage.py runserver
   ```

## Runtime configuration for frontend

- The frontend expects a non-secret runtime configuration endpoint on the backend that returns the Google OAuth client id used for Google Sign-In.
- Local development: put your Google OAuth client id in the backend `.env` as `GOOGLE_CLIENT_ID` (this file should not be committed).
- Endpoint: `GET /api/config/google/` — returns JSON `{"google_client_id": "<value>"}`.
- This keeps the client id out of frontend source control; the frontend fetches it at startup or before sign-in.

## CORS and production notes

- In development `CORS_ALLOW_ALL_ORIGINS = True` is set for convenience. For production set `CORS_ALLOW_ALL_ORIGINS = False` and add your frontend origin(s) to `CORS_ALLOWED_ORIGINS` and `CSRF_TRUSTED_ORIGINS` in `pawjeevan_backend/settings.py`.

## 🔌 API Usage
- Endpoints are available under `/api/`
- Media files are served from `/media/`

## 📝 Notes
- 📁 Ensure the `media` folder exists for file uploads
- 🏭 For production, configure environment variables and use a robust database

---

Made with ❤️ by the PawJeevan Team
