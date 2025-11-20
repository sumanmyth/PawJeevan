# Generated migration for adding is_profile_locked field

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0002_alter_notification_notification_type'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='is_profile_locked',
            field=models.BooleanField(default=False),
        ),
    ]
