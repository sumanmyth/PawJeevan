# Generated manually to migrate AdoptionListing data from community to store

from django.db import migrations


def migrate_adoption_listings(apps, schema_editor):
    """Copy AdoptionListing data from community to store"""
    # Get the old and new models
    CommunityAdoption = apps.get_model('community', 'AdoptionListing')
    StoreAdoption = apps.get_model('store', 'AdoptionListing')
    
    # Copy all records
    for old_listing in CommunityAdoption.objects.all():
        StoreAdoption.objects.create(
            id=old_listing.id,
            title=old_listing.title,
            pet_name=old_listing.pet_name,
            pet_type=old_listing.pet_type,
            breed=old_listing.breed,
            age=old_listing.age,
            gender=old_listing.gender,
            description=old_listing.description,
            health_status=old_listing.health_status,
            vaccination_status=old_listing.vaccination_status,
            is_neutered=old_listing.is_neutered,
            photo=old_listing.photo,
            poster_id=old_listing.poster_id,
            contact_phone=old_listing.contact_phone,
            contact_email=old_listing.contact_email,
            location=old_listing.location,
            status=old_listing.status,
            created_at=old_listing.created_at,
            updated_at=old_listing.updated_at,
        )


def reverse_migrate(apps, schema_editor):
    """Delete all store AdoptionListing records"""
    StoreAdoption = apps.get_model('store', 'AdoptionListing')
    StoreAdoption.objects.all().delete()


class Migration(migrations.Migration):

    dependencies = [
        ('store', '0002_adoptionlisting'),
        ('community', '0005_remove_conversation_message'),
    ]

    operations = [
        migrations.RunPython(migrate_adoption_listings, reverse_migrate),
    ]
