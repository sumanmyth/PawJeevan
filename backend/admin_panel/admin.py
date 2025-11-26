"""
Admin interface for Admin Panel app
"""
from django.contrib import admin
from .models import SystemSettings
from django.contrib import messages

# SimpleJWT token blacklist models
try:
    from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
except Exception:
    OutstandingToken = None
    BlacklistedToken = None


@admin.register(SystemSettings)
class SystemSettingsAdmin(admin.ModelAdmin):
    list_display = ['key', 'value', 'updated_at']
    search_fields = ['key', 'description']


def blacklist_outstanding_tokens(modeladmin, request, queryset):
    """Admin action: blacklist selected OutstandingToken entries."""
    if OutstandingToken is None or BlacklistedToken is None:
        messages.error(request, "SimpleJWT token blacklist models are not available. Ensure 'rest_framework_simplejwt.token_blacklist' is installed and in INSTALLED_APPS.")
        return

    count = 0
    for token in queryset:
        # Create a BlacklistedToken referencing the OutstandingToken
        bt, created = BlacklistedToken.objects.get_or_create(token=token)
        if created:
            count += 1

    messages.success(request, f"Blacklisted {count} token(s).")


if OutstandingToken is not None:
    class OutstandingTokenAdmin(admin.ModelAdmin):
        list_display = ['jti', 'user', 'created_at']
        search_fields = ['jti', 'user__email', 'user__username']
        readonly_fields = ('jti', 'user', 'created_at')
        actions = [blacklist_outstanding_tokens]

    # Register only if not already registered by the package
    if OutstandingToken not in admin.site._registry:
        admin.site.register(OutstandingToken, OutstandingTokenAdmin)