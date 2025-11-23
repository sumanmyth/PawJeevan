"""
User models: User, PetProfile, VaccinationRecord, MedicalRecord, Notification
"""
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.utils import timezone


class User(AbstractUser):
    """
    Custom User Model extending Django's AbstractUser
    Adds social features and profile information
    """
    email = models.EmailField(_('email address'), unique=True)
    phone = models.CharField(max_length=15, blank=True, null=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    bio = models.TextField(blank=True)
    location = models.CharField(max_length=100, blank=True)
    is_verified = models.BooleanField(default=False)
    
    # Privacy settings
    is_profile_locked = models.BooleanField(default=False)
    
    # Social features - users can follow each other
    followers = models.ManyToManyField(
        'self', 
        symmetrical=False, 
        related_name='following', 
        blank=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Use email for login instead of username
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.email


class PetProfile(models.Model):
    """
    Pet Profile Model
    Users can create profiles for their pets with medical history
    """
    PET_TYPE_CHOICES = [
        ('dog', 'Dog'),
        ('cat', 'Cat'),
        ('bird', 'Bird'),
        ('fish', 'Fish'),
        ('rabbit', 'Rabbit'),
        ('hamster', 'Hamster'),
        ('other', 'Other'),
    ]
    
    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
    ]
    
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='pets')
    name = models.CharField(max_length=100)
    pet_type = models.CharField(max_length=20, choices=PET_TYPE_CHOICES)
    breed = models.CharField(max_length=100, blank=True)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES)
    date_of_birth = models.DateField(null=True, blank=True)
    weight = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        help_text="Weight in kg"
    )
    color = models.CharField(max_length=50, blank=True)
    microchip_id = models.CharField(
        max_length=50, 
        blank=True, 
        unique=True, 
        null=True
    )
    photo = models.ImageField(upload_to='pets/', blank=True, null=True)
    medical_notes = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} ({self.owner.username})"
    
    @property
    def age(self):
        """Calculate pet's age in years"""
        if self.date_of_birth:
            from datetime import date
            today = date.today()
            age = today.year - self.date_of_birth.year
            if today.month < self.date_of_birth.month or \
               (today.month == self.date_of_birth.month and today.day < self.date_of_birth.day):
                age -= 1
            return age
        return None


class VaccinationRecord(models.Model):
    """
    Vaccination records for pets
    Tracks vaccination history and upcoming vaccinations
    """
    pet = models.ForeignKey(
        PetProfile, 
        on_delete=models.CASCADE, 
        related_name='vaccinations'
    )
    vaccine_name = models.CharField(max_length=100)
    vaccination_date = models.DateField()
    next_due_date = models.DateField(null=True, blank=True)
    veterinarian = models.CharField(max_length=100, blank=True)
    clinic_name = models.CharField(max_length=200, blank=True)
    notes = models.TextField(blank=True)
    certificate = models.FileField(
        upload_to='vaccination_certificates/', 
        blank=True, 
        null=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-vaccination_date']
    
    def __str__(self):
        return f"{self.vaccine_name} - {self.pet.name}"


class MedicalRecord(models.Model):
    """
    Medical records for pets
    Tracks vet visits, treatments, surgeries, etc.
    """
    RECORD_TYPE_CHOICES = [
        ('checkup', 'Checkup'),
        ('treatment', 'Treatment'),
        ('surgery', 'Surgery'),
        ('emergency', 'Emergency'),
        ('dental', 'Dental'),
        ('other', 'Other'),
    ]
    
    pet = models.ForeignKey(
        PetProfile, 
        on_delete=models.CASCADE, 
        related_name='medical_records'
    )
    record_type = models.CharField(max_length=50, choices=RECORD_TYPE_CHOICES)
    title = models.CharField(max_length=200)
    description = models.TextField()
    date = models.DateField()
    veterinarian = models.CharField(max_length=100, blank=True)
    clinic_name = models.CharField(max_length=200, blank=True)
    cost = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        null=True, 
        blank=True
    )
    prescription = models.TextField(blank=True)
    attachments = models.FileField(
        upload_to='medical_records/', 
        blank=True, 
        null=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.title} - {self.pet.name}"


class Notification(models.Model):
    """
    User notifications
    For reminders, updates, community activity, etc.
    """
    NOTIFICATION_TYPES = (
        ('vaccination', 'Vaccination Reminder'),
        ('food_restock', 'Food Restock'),
        ('vet_checkup', 'Vet Checkup'),
        ('order', 'Order Update'),
        ('community', 'Community Activity'),
        ('message', 'New Message'),
        ('follow', 'New Follower'),
        ('event_joined', 'Event Joined'),
        ('event_starting', 'Event Starting Soon'),
        ('event_ended', 'Event Ended'),
        ('system', 'System'),
    )

    user = models.ForeignKey('User', on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    action_url = models.CharField(max_length=500, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.notification_type} - {self.title} ({self.user.username})"


class ScheduledNotification(models.Model):
    """
    Scheduled in-app notifications to be sent at a specific time.
    This allows reliable scheduling (created when user joins an event)
    and processed by a periodic worker/management command.
    """
    user = models.ForeignKey('User', on_delete=models.CASCADE, related_name='scheduled_notifications')
    notification_type = models.CharField(max_length=50)
    title = models.CharField(max_length=200)
    message = models.TextField()
    action_url = models.CharField(max_length=500, blank=True)
    send_at = models.DateTimeField()
    processed = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['send_at']

    def __str__(self):
        return f"Scheduled {self.notification_type} for {self.user.username} at {self.send_at}"


class UserOTP(models.Model):
    """
    Stores one-time-passwords for actions like email verification.
    """
    PURPOSE_CHOICES = (
        ('email_verification', 'Email Verification'),
    )

    user = models.ForeignKey('User', on_delete=models.CASCADE, related_name='otps')
    code = models.CharField(max_length=10)
    purpose = models.CharField(max_length=30, choices=PURPOSE_CHOICES, default='email_verification')
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    attempts = models.IntegerField(default=0)
    used = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"OTP for {self.user.email} ({self.purpose})"

    def is_expired(self):
        return timezone.now() > self.expires_at


class PendingRegistration(models.Model):
    """
    Temporary store for user registration data until email OTP is verified.
    The password stored here is the hashed password using Django's password hasher.
    """
    username = models.CharField(max_length=150)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=128)
    first_name = models.CharField(max_length=30, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    phone = models.CharField(max_length=15, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    # OTP fields for this pending registration
    otp_code = models.CharField(max_length=10)
    otp_expires_at = models.DateTimeField()
    attempts = models.IntegerField(default=0)
    used = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Pending registration for {self.email}"

    def otp_is_expired(self):
        return timezone.now() > self.otp_expires_at