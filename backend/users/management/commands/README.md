# cleanup_pending_registrations management command

This file documents the `cleanup_pending_registrations` management command located at `backend/users/management/commands/cleanup_pending_registrations.py`.

Purpose
- Remove expired `PendingRegistration` records created during the email OTP registration flow.
- Remove very old `PendingRegistration` records as an additional safety/cleanup step.
- Remove stale `UserOTP` records (used or expired OTPs older than a configurable threshold).

Why this is useful
- Keeps the database tidy and prevents accumulation of stale pending registrations and OTPs.
- Helps avoid storage bloat and keeps admin views (Pending registrations) manageable.

Usage

Run from the `backend/` folder (PowerShell example):

```powershell
cd backend
# optional: activate your venv
.\.venv\Scripts\Activate.ps1
python manage.py cleanup_pending_registrations
```

Arguments
- `--pending-age <minutes>` (default: `60`): Age in minutes after which pending registrations are considered expired. The command deletes PendingRegistration rows whose `otp_expires_at` is less than `now`, and also deletes PendingRegistration rows older than `--pending-age` minutes as an extra safety cleanup.

- `--otp-age <minutes>` (default: `1440` = 24 hours): Age in minutes after which used or expired OTPs (`UserOTP`) are removed. The command keeps recent OTPs for a short period for audit but removes very old ones.

Examples

Dry-run style check (manual inspection needed): the command does not provide a dry-run option — instead, run it first on a staging copy or check counts in the Django shell:

```powershell
# show counts without deleting (using Django shell)
cd backend
.\.venv\Scripts\Activate.ps1
python manage.py shell
```

Then in the shell:

```python
from django.utils import timezone
from datetime import timedelta
from users.models import PendingRegistration, UserOTP
now = timezone.now()
print('expired_pending:', PendingRegistration.objects.filter(otp_expires_at__lt=now).count())
print('old_pending:', PendingRegistration.objects.filter(created_at__lt=now - timedelta(minutes=60)).count())
print('stale_otps:', UserOTP.objects.filter((Q(used=True) | Q(expires_at__lt=now)) & Q(created_at__lt=now - timedelta(minutes=1440))).count())
```

Scheduling

- Windows Task Scheduler (PowerShell): run daily or hourly depending on expected volume.

Example scheduled command (run daily at 03:00):

```text
Program/script: powershell.exe
Arguments: -NoProfile -WindowStyle Hidden -Command "cd 'C:\Users\intel\OneDrive\Desktop\pawjeevan\backend'; .\.venv\Scripts\Activate.ps1; python manage.py cleanup_pending_registrations"
```

- Linux cron example (run daily at 03:00):

```cron
0 3 * * * cd /path/to/pawjeevan/backend && /path/to/venv/bin/python manage.py cleanup_pending_registrations >> /var/log/pawjeevan/cleanup_pending_registrations.log 2>&1
```

Safety & precautions

- BACKUP: Always ensure you have recent database backups before running destructive cleanup tasks in production.
- Test in staging: Run the command in a staging environment to verify behavior.
- Logs: Configure logging or schedule redirection to a log file to keep an audit of when cleanup ran and how many rows were removed.
- Review model fields: The command uses `otp_expires_at` and `created_at` fields from `PendingRegistration`, and `used`, `expires_at`, and `created_at` from `UserOTP`. If your models differ, review the command.

Related maintenance

- There is a separate command `cleanup_expired_tokens` (token blacklist cleanup) in `admin_panel.management.commands` to clean expired `OutstandingToken` rows.

Contact

If you'd like me to add:
- a `--dry-run` mode to this command (I can add it),
- logging output to a file or structured JSON logs,
- a management command test,
I can implement that next.
