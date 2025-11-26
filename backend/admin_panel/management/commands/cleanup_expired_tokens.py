from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone


class Command(BaseCommand):
    help = "Clean up expired OutstandingToken rows created by djangorestframework-simplejwt's token_blacklist app."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            dest="dry_run",
            help="Show how many rows would be deleted without deleting them.",
        )

    def handle(self, *args, **options):
        dry_run = options.get("dry_run", False)

        try:
            from rest_framework_simplejwt.token_blacklist.models import OutstandingToken
        except Exception as exc:  # pragma: no cover - environment dependent
            raise CommandError(
                "Could not import OutstandingToken. Is 'rest_framework_simplejwt.token_blacklist' installed and in INSTALLED_APPS?"
            ) from exc

        now = timezone.now()
        expired_qs = OutstandingToken.objects.filter(expires_at__lt=now)
        count = expired_qs.count()

        if dry_run:
            self.stdout.write(self.style.NOTICE(f"Found {count} expired OutstandingToken row(s). (dry-run)"))
            return

        if count == 0:
            self.stdout.write(self.style.SUCCESS("No expired OutstandingToken rows found."))
            return

        # Delete expired rows
        deleted_info = expired_qs.delete()
        # deleted_info is a tuple (num_deleted, {<model>: num, ...})
        self.stdout.write(self.style.SUCCESS(f"Deleted {deleted_info[0]} expired OutstandingToken row(s)."))
