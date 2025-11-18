# Generated migration

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('community', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='groupmessage',
            name='is_system_message',
            field=models.BooleanField(default=False),
        ),
    ]
