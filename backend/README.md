# PawJeevan Backend

This is the backend for the PawJeevan project, built with Django.

## Features
- User authentication and management
- Community posts, events, and groups
- Pet adoption and lost & found
- Store for products and brands
- AI module for advanced features
- RESTful API endpoints
- Media file handling (avatars, pet photos, certificates, etc.)

## Structure
- `admin_panel/`, `ai_module/`, `community/`, `store/`, `users/`: Django apps for different functionalities
- `pawjeevan_backend/`: Main Django project settings and URLs
- `media/`: Stores uploaded files and images
- `db.sqlite3`: Default database (can be changed to PostgreSQL, MySQL, etc.)
- `requirements.txt`: Python dependencies
- `manage.py`: Django management script

## Setup
1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. Run migrations:
   ```bash
   python manage.py migrate
   ```
3. Create superuser:
   ```bash
   python manage.py createsuperuser
   ```
4. Start the server:
   ```bash
   python manage.py runserver
   ```

## API Usage
- Endpoints are available under `/api/`
- Media files are served from `/media/`

## Notes
- Ensure the `media` folder exists for file uploads
- For production, configure environment variables and use a robust database
