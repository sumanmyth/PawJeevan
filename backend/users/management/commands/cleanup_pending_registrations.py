from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from django.db import models

from users.models import PendingRegistration, UserOTP


class Command(BaseCommand):
    help = 'Cleanup expired PendingRegistration records and stale UserOTP entries'

    def add_arguments(self, parser):
        parser.add_argument(
            '--pending-age',
            type=int,
            default=60,  # minutes
            help='Age in minutes after which pending registrations are considered expired (default: 60)'
        )
        parser.add_argument(
            '--otp-age',
            type=int,
            default=24 * 60,  # minutes (24 hours)
            help='Age in minutes after which used or expired OTPs are removed (default: 1440)'
        )

    def handle(self, *args, **options):
        now = timezone.now()
        pending_age_mins = options.get('pending_age')
        otp_age_mins = options.get('otp_age')

        pending_cutoff = now - timedelta(minutes=pending_age_mins)
        otp_cutoff = now - timedelta(minutes=otp_age_mins)

        # Remove expired pending registrations
        expired_pending = PendingRegistration.objects.filter(otp_expires_at__lt=now)
        expired_count = expired_pending.count()
        expired_pending.delete()

        # Additionally, remove pending registrations older than pending_cutoff (safety)
        old_pending = PendingRegistration.objects.filter(created_at__lt=pending_cutoff)
        old_count = old_pending.count()
        old_pending.delete()

        # Cleanup UserOTP: remove used or expired OTPs older than otp_cutoff
        # Keep recent OTPs (even if used) for a short window for audit; remove very old ones
        stale_otps = UserOTP.objects.filter(
            (models.Q(used=True) | models.Q(expires_at__lt=now)) & models.Q(created_at__lt=otp_cutoff)
        )
        stale_count = stale_otps.count()
        stale_otps.delete()

        self.stdout.write(self.style.SUCCESS(
            f'Cleaned {expired_count} expired pending registrations, {old_count} old pending registrations, and {stale_count} stale OTPs.'
        ))
