"""
Admin interface for Users app
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    User,
    PetProfile,
    VaccinationRecord,
    MedicalRecord,
    Notification,
    PendingRegistration,
    UserOTP,
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['email', 'username', 'first_name', 'last_name', 'is_verified', 'is_active', 'is_profile_locked', 'created_at']
    list_filter = ['is_verified', 'is_staff', 'is_active', 'is_profile_locked']
    list_editable = ['is_verified', 'is_active']
    search_fields = ['email', 'username', 'first_name', 'last_name']
    ordering = ['-created_at']
    
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Additional Info', {'fields': ('phone', 'avatar', 'bio', 'location', 'is_verified', 'is_profile_locked')}),
    )
    readonly_fields = ('created_at',)


@admin.register(PetProfile)
class PetProfileAdmin(admin.ModelAdmin):
    list_display = ['name', 'pet_type', 'breed', 'owner', 'created_at']
    list_filter = ['pet_type', 'gender']
    search_fields = ['name', 'breed', 'owner__username']
    ordering = ['-created_at']


@admin.register(VaccinationRecord)
class VaccinationRecordAdmin(admin.ModelAdmin):
    list_display = ['vaccine_name', 'pet', 'vaccination_date', 'next_due_date']
    list_filter = ['vaccination_date']
    search_fields = ['vaccine_name', 'pet__name']
    ordering = ['-vaccination_date']


@admin.register(MedicalRecord)
class MedicalRecordAdmin(admin.ModelAdmin):
    list_display = ['title', 'pet', 'record_type', 'date', 'veterinarian']
    list_filter = ['record_type', 'date']
    search_fields = ['title', 'pet__name', 'veterinarian']
    ordering = ['-date']


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'notification_type', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read']
    search_fields = ['title', 'user__username']
    ordering = ['-created_at']


# Register PendingRegistration so admins can inspect pending signups and OTPs
@admin.register(PendingRegistration)
class PendingRegistrationAdmin(admin.ModelAdmin):
    list_display = ['email', 'username', 'phone', 'created_at', 'otp_code', 'otp_expires_at', 'used', 'attempts']
    list_filter = ['used']
    search_fields = ['email', 'username', 'phone']
    ordering = ['-created_at']
    readonly_fields = ('otp_code', 'otp_expires_at', 'created_at')


@admin.register(UserOTP)
class UserOTPAdmin(admin.ModelAdmin):
    list_display = ['user', 'code', 'created_at', 'expires_at', 'used', 'attempts']
    list_filter = ['used']
    search_fields = ['user__email', 'code']
    ordering = ['-created_at']