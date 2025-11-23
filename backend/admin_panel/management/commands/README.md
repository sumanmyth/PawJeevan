# cleanup_expired_tokens management command

This file documents the `cleanup_expired_tokens` management command located at `backend/admin_panel/management/commands/cleanup_expired_tokens.py`.

Purpose
- Remove expired `OutstandingToken` rows created by `djangorestframework-simplejwt`'s `token_blacklist` app.
- Keeps the `OutstandingToken` table tidy and reduces storage/administrative clutter.

Prerequisites
- `djangorestframework-simplejwt` must be installed (it's listed in `backend/requirements.txt`).
- Ensure `rest_framework_simplejwt.token_blacklist` is present in `INSTALLED_APPS` in `pawjeevan_backend/settings.py` so the `OutstandingToken` model and its migrations are available.
- Run migrations to create the token_blacklist tables:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1  # if using venv
python manage.py migrate
```

Why use this command
- `OutstandingToken` stores issued refresh tokens (jti and expiry). Although expired tokens cannot be used, the rows remain and may accumulate over time.
- Deleting expired rows is safe and helps keep admin lists and DB tables small.

Usage

Run from the `backend/` folder (PowerShell example):

```powershell
cd backend
# Optional: activate virtualenv
.\.venv\Scripts\Activate.ps1

# Show how many expired rows would be removed and perform deletion
python manage.py cleanup_expired_tokens --dry-run
python manage.py cleanup_expired_tokens
```

Options
- `--dry-run`: Displays how many expired `OutstandingToken` rows would be deleted without performing deletion.

Behavior
- The command finds `OutstandingToken` rows whose `expires_at` is less than the current time and deletes them.
- If the `token_blacklist` app is not installed or import fails, the command raises a clear error message.

Scheduling the command
- Add a scheduled job to run this command periodically (daily or weekly depending on traffic).

Windows Task Scheduler (PowerShell) example — daily at 03:00:

```
Program/script: powershell.exe
Arguments: -NoProfile -WindowStyle Hidden -Command "cd 'C:\Users\intel\OneDrive\Desktop\pawjeevan\backend'; .\.venv\Scripts\Activate.ps1; python manage.py cleanup_expired_tokens --dry-run; python manage.py cleanup_expired_tokens"
```

Windows `schtasks` example (create task to run daily at 03:00):

```powershell
schtasks /Create /SC DAILY /TN "PawJeevan_CleanupExpiredTokens" /TR "powershell -NoProfile -WindowStyle Hidden -Command \"cd 'C:\\Users\\intel\\OneDrive\\Desktop\\pawjeevan\\backend'; .\\.venv\\Scripts\\Activate.ps1; python manage.py cleanup_expired_tokens\"" /ST 03:00 /F
```

Linux cron example (run daily at 03:00):

```cron
0 3 * * * cd /path/to/pawjeevan/backend && /path/to/venv/bin/python manage.py cleanup_expired_tokens >> /var/log/pawjeevan/cleanup_expired_tokens.log 2>&1
```

Safety & best practices
- BACKUP: Ensure recent database backups exist before scheduling deletion jobs in production.
- Dry-run: Run `--dry-run` first to verify how many rows will be removed.
- Test in staging: Verify behavior in a staging environment before enabling in production.
- Logging: Redirect stdout/stderr to a log file when scheduling so you have an audit trail.
- Monitoring: Monitor DB size and the number of outstanding tokens to detect unexpected growth.

Related maintenance
- `backend/users/management/commands/cleanup_pending_registrations.py` — cleans expired `PendingRegistration` and stale `UserOTP` rows (used for OTP registration flow).
- Admin actions: There is an admin action to blacklist selected `OutstandingToken` entries (see `backend/admin_panel/admin.py`). Blacklisting is used to actively revoke tokens before expiry.

Contact / next steps
- I can add an admin action to delete expired tokens from the admin UI too.
- I can add a `--confirm` flag that requires explicit confirmation when run interactively, or add structured JSON logging for monitoring.
- I can also provide a ready-to-run `schtasks` script tailored to your environment.

If you want any of the above, tell me which and I'll implement it.