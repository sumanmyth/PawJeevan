# Event Notifications Management Command

## Overview
`send_event_notifications.py` is a periodic management command that:

- Sends notifications for events that are about to start (`event_starting`).
- Sends notifications for events that have just ended (`event_ended`).
- Processes explicit scheduled reminders stored in `ScheduledNotification` (used for per-user reminders such as vaccination due reminders and scheduled event reminders created when a user joins an event).

The command converts any due `ScheduledNotification` rows into real `Notification` records and marks them processed.

## Notification Types
1. **event_joined**: Sent immediately when a user joins an event (created in the event join view).
2. **event_starting**: Sent ~1 hour before an event starts (the command looks for events starting within the next hour).
3. **event_ended**: Sent for events that ended recently (the command looks for events that ended within the last hour).
4. **vaccination** (scheduled): Created as a `ScheduledNotification` when a vaccination record with `next_due_date` is created/updated; processed by this command at the scheduled time.

## Manual Execution
To run the command manually:

```bash
python manage.py send_event_notifications
```

## Scheduled Execution (recommended)

Run the command periodically. For reliable reminders, run it every 1–5 minutes in production. Common deployment options:

### Option 1: Windows Task Scheduler
Create a scheduled task that runs `python manage.py send_event_notifications` in the backend directory and repeats at your desired cadence.

### Option 2: System cron / django-crontab (Linux)
Use `cron` or `django-crontab` to schedule the command. Example `django-crontab` entry for hourly runs:

```python
CRONJOBS = [
    ('0 * * * *', 'django.core.management.call_command', ['send_event_notifications']),
]
```

### Option 3: Celery Beat (production-grade)
Use Celery Beat to schedule `send_event_notifications` frequently (recommended when you need sub-hour accuracy and reliability).

## How It Works

### Event Starting Notifications
- Finds events with `start_datetime` between now and now + 1 hour.
- Creates `event_starting` notifications for attendees, avoiding duplicates by checking recent notifications.

### Event Ended Notifications
- Finds events with `end_datetime` between now - 1 hour and now.
- Creates `event_ended` notifications for attendees, avoiding duplicates by checking recent notifications.
- Note: the current implementation deletes events after sending the end notification. If you want to preserve event records (recommended), consider removing the delete step or marking events inactive instead.

### ScheduledNotification Processing
- The command also processes `ScheduledNotification.objects.filter(processed=False, send_at__lte=now)`.
- For each due scheduled item it creates a corresponding `Notification` and marks the `ScheduledNotification` as `processed=True`.
- `ScheduledNotification` rows are created in a few places (examples):
  - When a user joins an event (views.create scheduled reminder for that user/event).
  - When a `VaccinationRecord` with a `next_due_date` is created or updated (the `VaccinationRecordViewSet` schedules a vaccination reminder for the pet owner at `next_due_date - 1 day` at 09:00 local time).

## Testing
1. Create a test event or vaccination record that should trigger a scheduled notification.
2. For scheduled reminders, ensure the `ScheduledNotification` row exists with the desired `send_at` (inspect the DB table `users_schedulednotification`).
3. Run the command manually: `python manage.py send_event_notifications`.
4. Inspect `users_notification` (or check the app UI) to confirm notifications were created.

## Notes
- Notifications are in-app only (no external push by default).
- Duplicate prevention uses a recent time window to avoid sending duplicates when the scheduler runs multiple times.
- For production reliability, run the command often (e.g., every 1–5 minutes) or migrate scheduled sending to a task queue (Celery) for precise timing.
- See `backend/users/views.py` and `backend/users/models.py` for where `ScheduledNotification` entries are created and defined.
