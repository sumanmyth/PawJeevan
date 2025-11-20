"""
Management command to send event notifications
This should be run periodically (e.g., every hour) via cron or task scheduler
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from community.models import Event
from users.models import Notification


class Command(BaseCommand):
    help = 'Send event start and end notifications to attendees'

    def handle(self, *args, **options):
        now = timezone.now()
        
        # Send notifications for events starting in 1 hour
        upcoming_events = Event.objects.filter(
            start_datetime__gte=now,
            start_datetime__lte=now + timedelta(hours=1)
        )
        
        for event in upcoming_events:
            for attendee in event.attendees.all():
                # Check if notification already sent
                existing = Notification.objects.filter(
                    user=attendee,
                    notification_type='event_starting',
                    action_url=f'/events/{event.id}/',
                    created_at__gte=now - timedelta(hours=2)
                ).exists()
                
                if not existing:
                    Notification.objects.create(
                        user=attendee,
                        notification_type='event_starting',
                        title=f'Event "{event.title}" is starting soon!',
                        message=f'{event.title} will start in about an hour at {event.location}. Get ready!',
                        action_url=f'/events/{event.id}/'
                    )
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'Sent start notification for "{event.title}" to {attendee.username}'
                        )
                    )
        
        # Send notifications for events that just ended (within last hour)
        ended_events = Event.objects.filter(
            end_datetime__gte=now - timedelta(hours=1),
            end_datetime__lte=now
        )
        
        events_to_delete = []
        for event in ended_events:
            # Send notifications to all attendees
            for attendee in event.attendees.all():
                # Check if notification already sent
                existing = Notification.objects.filter(
                    user=attendee,
                    notification_type='event_ended',
                    action_url=f'/events/{event.id}/',
                    created_at__gte=now - timedelta(hours=2)
                ).exists()
                
                if not existing:
                    Notification.objects.create(
                        user=attendee,
                        notification_type='event_ended',
                        title=f'Thanks for attending "{event.title}"!',
                        message=f'We hope you enjoyed {event.title}. Share your experience with the community!',
                        action_url=f'/events/{event.id}/'
                    )
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'Sent end notification for "{event.title}" to {attendee.username}'
                        )
                    )
            
            # Mark event for deletion after notifications are sent
            events_to_delete.append(event)
        
        # Delete ended events from database
        for event in events_to_delete:
            event_title = event.title
            event.delete()
            self.stdout.write(
                self.style.WARNING(
                    f'Deleted ended event: "{event_title}"'
                )
            )
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Event notifications processed at {now}'
            )
        )
