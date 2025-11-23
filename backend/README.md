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
   # PawJeevan — Backend

   This folder contains the Django REST backend for PawJeevan. It provides authentication (email+OTP flow), community features, pet adoption endpoints, store APIs, and media handling.

   Supported (development) default: SQLite (`db.sqlite3`). For production use PostgreSQL or another robust DB.

   Prerequisites

   - Python 3.8+ (3.10/3.11 recommended)
   - `pip` and optional virtual environment tooling

   Quick start (Windows PowerShell)

   ```powershell
   cd backend
   # Optional: use the included setup script on Windows
   .\setup.bat

   # Or create a virtual environment manually
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt

   # Apply migrations and create admin
   python manage.py makemigrations
   python manage.py migrate
   python manage.py createsuperuser

   # Start development server
   python manage.py runserver
   ```

   Configuration and environment variables

   - The project reads sensitive settings from environment variables or a local `.env` (do not commit `.env`). Common values:
     - `DJANGO_SECRET_KEY` (keep secret in production)
     - `DEBUG` (True/False)
     - `ALLOWED_HOSTS` (comma-separated)
     - SMTP/email settings (see below)
     - `DATABASE_URL` (if switching from SQLite)

   Email and OTP registration

   - The backend implements a `PendingRegistration` model used for email OTP verification. Registration endpoints may return `requires_verification` and a `pending_id` — the frontend should prompt the user to enter the OTP sent by email.
   - Important endpoints (examples):
     - `POST /api/users/register/` — register and possibly return `{ "requires_verification": true, "pending_id": <id> }`
     - `POST /api/users/send-otp/` — resend OTP
     - `POST /api/users/verify-otp/` — verify OTP and create the real user; returns auth tokens on success

   SMTP (example)

   Use environment variables for SMTP. Example (do not commit to repo):

   ```env
   EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_HOST_USER=you@example.com
   EMAIL_HOST_PASSWORD=your-app-password
   EMAIL_USE_TLS=True
   DEFAULT_FROM_EMAIL=No Reply <no-reply@pawjeevan.local>
   ```

   Development notes

   - Media uploads: the `media/` folder stores uploaded files. Ensure it exists and is writable.
   - CORS: in development the project may allow all origins. For production, set `CORS_ALLOWED_ORIGINS` and `CSRF_TRUSTED_ORIGINS` appropriately in `pawjeevan_backend/settings.py`.

   Tests

   ```powershell
   cd backend
   .\.venv\Scripts\Activate.ps1  # if using venv
   python manage.py test
   ```

   Production

   - Use a proper WSGI server (Gunicorn, uWSGI) behind a reverse proxy (NGINX).
   - Move from SQLite to PostgreSQL or another production-ready DB.
   - Set `DEBUG=False`, configure `ALLOWED_HOSTS`, secrets, and secure email settings.

  Maintenance: cleanup expired OutstandingToken rows

  If you're using `djangorestframework-simplejwt` with the `token_blacklist` app, outstanding refresh tokens are recorded in the `OutstandingToken` model. Over time expired rows can accumulate.

  A management command is provided to remove expired `OutstandingToken` rows:

  ```powershell
  cd backend
  .\.venv\Scripts\Activate.ps1
  python manage.py cleanup_expired_tokens --dry-run
  python manage.py cleanup_expired_tokens
  ```

  Schedule this command in your production environment (cron, systemd timer, or a scheduled task) to keep the table small.

   API

   - API endpoints are generally available under `/api/`.
   - Media files are served under `/media/` in development.

   If you need any help running the backend locally, open an issue with the error message and I can help debug.

   ---

   Made with ❤️ by the PawJeevan Team
