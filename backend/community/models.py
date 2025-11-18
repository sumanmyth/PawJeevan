"""
Community models: Post, Comment, Group, Event, Message, LostFound
"""
from django.db import models
from users.models import User


class Post(models.Model):
    """
    User posts in the community
    Users can share photos, videos, stories about their pets
    """
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    content = models.TextField()
    image = models.ImageField(upload_to='posts/images/', blank=True, null=True)
    video = models.FileField(upload_to='posts/videos/', blank=True, null=True)
    
    # Engagement
    likes = models.ManyToManyField(User, related_name='liked_posts', blank=True)
    
    # Visibility
    is_public = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Post by {self.author.username} - {self.content[:50]}"
    
    @property
    def likes_count(self):
        return self.likes.count()
    
    @property
    def comments_count(self):
        return self.comments.count()


class Comment(models.Model):
    """
    Comments on posts
    """
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    
    # Nested comments (replies)
    parent = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='replies')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Comment by {self.author.username} on {self.post.id}"


class Group(models.Model):
    """
    Community groups
    Users can create and join groups based on interests
    """
    GROUP_TYPES = [
        ('breed', 'Breed-Specific'),
        ('location', 'Location-Based'),
        ('interest', 'Interest-Based'),
        ('support', 'Support Group'),
    ]
    
    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    description = models.TextField()
    group_type = models.CharField(max_length=20, choices=GROUP_TYPES)
    cover_image = models.ImageField(upload_to='groups/', blank=True, null=True)
    
    # Members
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_groups')
    members = models.ManyToManyField(User, related_name='joined_groups', blank=True)
    moderators = models.ManyToManyField(User, related_name='moderated_groups', blank=True)
    
    # Settings
    is_private = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    join_key = models.CharField(max_length=100, blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.name
    
    def clean(self):
        from django.core.exceptions import ValidationError
        if self.is_private and not self.join_key:
            raise ValidationError('Join key is required for private groups.')
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)
    
    @property
    def members_count(self):
        return self.members.count()


class GroupMessage(models.Model):
    """
    Messages in groups
    """
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name='group_messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='group_messages')
    content = models.TextField()
    is_system_message = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message from {self.sender.username} in {self.group.name}"


class GroupPost(models.Model):
    """
    Posts within a group
    """
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name='posts')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='group_posts')
    content = models.TextField()
    image = models.ImageField(upload_to='group_posts/images/', blank=True, null=True)
    
    is_pinned = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-is_pinned', '-created_at']
    
    def __str__(self):
        return f"Post in {self.group.name} by {self.author.username}"


class Event(models.Model):
    """
    Pet-friendly events and meetups
    """
    EVENT_TYPES = [
        ('meetup', 'Pet Meetup'),
        ('training', 'Training Session'),
        ('adoption', 'Adoption Drive'),
        ('fundraiser', 'Fundraiser'),
        ('competition', 'Competition'),
        ('other', 'Other'),
    ]
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    event_type = models.CharField(max_length=20, choices=EVENT_TYPES)
    
    # Location
    location = models.CharField(max_length=200)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    
    # Time
    start_datetime = models.DateTimeField()
    end_datetime = models.DateTimeField()
    
    # Organization
    organizer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='organized_events')
    group = models.ForeignKey(Group, on_delete=models.SET_NULL, null=True, blank=True, related_name='events')
    
    # Participants
    attendees = models.ManyToManyField(User, related_name='attending_events', blank=True)
    max_attendees = models.IntegerField(null=True, blank=True)
    
    # Media
    cover_image = models.ImageField(upload_to='events/', blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['start_datetime']
    
    def __str__(self):
        return self.title
    
    @property
    def attendees_count(self):
        return self.attendees.count()


class LostFoundReport(models.Model):
    """
    Lost and found pet reports
    """
    REPORT_TYPES = [
        ('lost', 'Lost Pet'),
        ('found', 'Found Pet'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]
    
    # Report type
    report_type = models.CharField(max_length=10, choices=REPORT_TYPES)
    
    # Pet details
    pet_name = models.CharField(max_length=100, blank=True)
    pet_type = models.CharField(max_length=20)
    breed = models.CharField(max_length=100, blank=True)
    color = models.CharField(max_length=50)
    description = models.TextField()
    
    # Location and time
    location = models.CharField(max_length=200)
    address = models.TextField()
    date_lost_found = models.DateField()
    
    # Contact
    reporter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='lost_found_reports')
    contact_phone = models.CharField(max_length=15)
    
    # Media
    photo = models.ImageField(upload_to='lost_found/', blank=True, null=True)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.get_report_type_display()} - {self.pet_type}"