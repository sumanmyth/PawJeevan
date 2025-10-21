@echo off
echo === PawJeevan Backend Setup ===

echo Step 1: Cleaning old files...
if exist db.sqlite3 del db.sqlite3
if exist users\migrations\0*.py del users\migrations\0*.py
if exist store\migrations\0*.py del store\migrations\0*.py
if exist ai_module\migrations\0*.py del ai_module\migrations\0*.py
if exist community\migrations\0*.py del community\migrations\0*.py
if exist admin_panel\migrations\0*.py del admin_panel\migrations\0*.py

echo Step 2: Creating migrations...
python manage.py makemigrations users
python manage.py makemigrations store
python manage.py makemigrations ai_module
python manage.py makemigrations community
python manage.py makemigrations admin_panel

echo Step 3: Applying migrations...
python manage.py migrate

echo Step 4: Setup complete!
echo Now create a superuser:
python manage.py createsuperuser

echo Done! Run: python manage.py runserver