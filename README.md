# 🐾 PawJeevan

Welcome to PawJeevan! 🌟

PawJeevan is a full-stack platform for pet adoption, community engagement, and pet care services. It consists of a Django backend and a Flutter frontend.

## 🏗️ Project Structure
- 📦 `backend/`: Django REST API, user management, community, store, AI features
- 📱 `frontend/`: Flutter mobile app for Android, iOS, and web

Quick links
- Backend docs: `backend/README.md`
- Frontend docs: `frontend/README.md`

Quick start (development)

1. Backend (run from `backend/`):

```powershell
# from the repo root
cd backend
# create venv (optional) and install dependencies
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

2. Frontend (run from `frontend/`):

```powershell
cd frontend
flutter pub get
# run for web
flutter run -d chrome
# or run on a connected device
flutter run
```

Important notes
- Registration uses an email OTP flow: new registrations create a `PendingRegistration` record; the real `User` is created after OTP verification. See `backend/README.md` for endpoints and setup.
- The frontend fetches non-secret runtime config (for example Google client id) from the backend on startup. Ensure the backend is running while developing the frontend.

Repository layout (high level)

- `backend/` — Django project, apps, migrations, `db.sqlite3` (default)
- `frontend/` — Flutter app source in `lib/`, assets, and platform folders
- `media/` — uploaded files used by the backend

Contributing
- Read `backend/README.md` and `frontend/README.md` for environment and run instructions.
- Open issues and pull requests are welcome. Keep changes focused and include tests where applicable.

License

This project is released under the MIT License. See `LICENSE` (if present) or add one when ready.

Contact

For questions, open an issue or contact the repository owner.

---

Made with ❤️ by the PawJeevan Team
