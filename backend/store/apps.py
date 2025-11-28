from django.apps import AppConfig


class StoreConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'store'

    def ready(self):
        # Create default product categories after migrations if they don't exist.
        from django.db.models.signals import post_migrate
        from django.dispatch import receiver

        @receiver(post_migrate)
        def create_default_categories(sender, **kwargs):
            # Avoid running when other apps migrate
            if sender.name != self.name:
                return
            try:
                from .models import Category

                defaults = [
                    ("Food & Treats", "food-and-treats"),
                    ("Toys", "toys"),
                    ("Health & Wellness", "health-and-wellness"),
                    ("Grooming Supplies", "grooming-supplies"),
                    ("Bedding & Furniture", "bedding-and-furniture"),
                    ("Travel & Carriers", "travel-and-carriers"),
                    ("Collars, Leashes & Harnesses", "collars-leashes-harnesses"),
                ]

                for name, slug in defaults:
                    obj, created = Category.objects.get_or_create(slug=slug, defaults={"name": name})
                    if not created and obj.name != name:
                        obj.name = name
                        obj.save()
            except Exception:
                # Safe guard: if models aren't ready or DB not available, skip.
                pass
