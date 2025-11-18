# Event Notifications Management Command

## Overview
The `send_event_notifications.py` command checks for upcoming and recently ended events, sending notifications to all attendees.

## Notification Types
1. **event_joined**: Sent immediately when a user joins an event (handled in views.py)
2. **event_starting**: Sent 1 hour before event starts
3. **event_ended**: Sent when event ends (within 1 hour after end time)

## Manual Execution
To manually run the command:

```bash
python manage.py send_event_notifications
```

## Scheduled Execution

### Option 1: Windows Task Scheduler
1. Open Task Scheduler
2. Create Basic Task
3. Name: "PawJeevan Event Notifications"
4. Trigger: Daily, repeat every 1 hour
5. Action: Start a program
   - Program: `python`
   - Arguments: `manage.py send_event_notifications`
   - Start in: `c:\Users\intel\OneDrive\Desktop\pawjeevan\backend`

### Option 2: Django-Crontab (Linux/Mac)
1. Install: `pip install django-crontab`
2. Add to `settings.py`:
```python
INSTALLED_APPS = [
    # ...
    'django_crontab',
]

CRONJOBS = [
    ('0 * * * *', 'django.core.management.call_command', ['send_event_notifications']),
]
```
3. Run: `python manage.py crontab add`

### Option 3: Celery Beat (Production)
1. Install: `pip install celery django-celery-beat`
2. Configure in `settings.py` and `celery.py`
3. Create periodic task to run every hour

## How It Works

### Event Starting Notifications
- Checks for events with `start_datetime` between now and 1 hour from now
- Creates notification with type `event_starting`
- Prevents duplicates by checking for existing notifications in last 2 hours

### Event Ended Notifications
- Checks for events with `end_datetime` between 1 hour ago and now
- Creates notification with type `event_ended`
- Prevents duplicates by checking for existing notifications in last 2 hours

## Testing
1. Create a test event with start time 1 hour from now
2. Join the event as a user
3. Run the command manually: `python manage.py send_event_notifications`
4. Check notifications in the app

## Notes
- Notifications are in-app only (not push notifications)
- Users must be attendees to receive start/end notifications
- Organizers also receive notifications if they're in the attendees list
- Duplicate prevention uses a 2-hour window to handle scheduler overlaps
