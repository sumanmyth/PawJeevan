"""
AI Module models: BreedDetection, DiseaseDetection, DietRecommendation, ChatSession
"""
from django.db import models
from users.models import User, PetProfile


class BreedDetection(models.Model):
    """
    Store breed detection results
    User uploads pet image, AI detects breed
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='breed_detections')
    image = models.ImageField(upload_to='breed_detection/')
    detected_breed = models.CharField(max_length=100, blank=True)
    confidence = models.FloatField(null=True, blank=True, help_text="Confidence percentage")
    alternative_breeds = models.JSONField(default=list, blank=True, help_text="List of alternative breeds with confidence")
    
    # Detection type flags
    is_dog = models.BooleanField(default=True, help_text="Whether a dog was detected")
    is_human = models.BooleanField(default=False, help_text="Whether a human face was detected")
    
    # Model information
    model_version = models.CharField(max_length=50, default='v1.0')
    processing_time = models.FloatField(null=True, blank=True, help_text="Time taken in seconds")
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Breed Detection - {self.detected_breed or 'Processing'} ({self.user.username})"


class DiseaseDetection(models.Model):
    """
    Store disease detection results
    Detect skin, eye, ear diseases from pet images
    """
    DISEASE_TYPES = [
        ('skin', 'Skin Disease'),
        ('eye', 'Eye Disease'),
        ('ear', 'Ear Disease'),
        ('dental', 'Dental Issue'),
        ('general', 'General Health'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='disease_detections')
    pet = models.ForeignKey(PetProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name='disease_detections')
    image = models.ImageField(upload_to='disease_detection/')
    disease_type = models.CharField(max_length=20, choices=DISEASE_TYPES)
    
    detected_disease = models.CharField(max_length=200, blank=True)
    confidence = models.FloatField(null=True, blank=True)
    severity = models.CharField(max_length=20, choices=[
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ], blank=True)
    
    recommendations = models.TextField(blank=True)
    should_see_vet = models.BooleanField(default=False)
    
    # Model information
    model_version = models.CharField(max_length=50, default='v1.0')
    processing_time = models.FloatField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Disease Detection - {self.disease_type} ({self.user.username})"


class DietRecommendation(models.Model):
    """
    AI-based diet recommendations for pets
    Based on breed, age, weight, health conditions
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='diet_recommendations')
    pet = models.ForeignKey(PetProfile, on_delete=models.CASCADE, related_name='diet_recommendations')
    
    # Recommendation details
    recommended_diet = models.TextField()
    daily_calories = models.IntegerField(help_text="Recommended daily calories")
    feeding_frequency = models.CharField(max_length=100)
    food_types = models.JSONField(default=list, help_text="List of recommended food types")
    
    # Considerations
    special_considerations = models.TextField(blank=True)
    allergies = models.TextField(blank=True)
    health_conditions = models.TextField(blank=True)
    
    # Products recommendations
    recommended_products = models.JSONField(default=list, blank=True, help_text="List of product IDs")
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Diet Recommendation for {self.pet.name}"


class ChatSession(models.Model):
    """
    AI Pet Care Assistant Chat Sessions
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='chat_sessions')
    title = models.CharField(max_length=200, default='New Chat')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-updated_at']
    
    def __str__(self):
        return f"Chat Session - {self.title} ({self.user.username})"


class ChatMessage(models.Model):
    """
    Individual messages in chat sessions
    """
    ROLE_CHOICES = [
        ('user', 'User'),
        ('assistant', 'AI Assistant'),
        ('system', 'System'),
    ]
    
    session = models.ForeignKey(ChatSession, on_delete=models.CASCADE, related_name='messages')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    content = models.TextField()
    
    # Metadata
    tokens_used = models.IntegerField(null=True, blank=True)
    response_time = models.FloatField(null=True, blank=True, help_text="Response time in seconds")
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"{self.role}: {self.content[:50]}"


class PhotoEnhancement(models.Model):
    """
    Pet photo enhancement/filter results
    """
    ENHANCEMENT_TYPES = [
        ('enhance', 'Quality Enhancement'),
        ('filter', 'Filter Applied'),
        ('background', 'Background Removal'),
        ('colorize', 'Colorization'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='photo_enhancements')
    original_image = models.ImageField(upload_to='photo_enhancement/original/')
    enhanced_image = models.ImageField(upload_to='photo_enhancement/enhanced/', blank=True, null=True)
    enhancement_type = models.CharField(max_length=20, choices=ENHANCEMENT_TYPES)
    
    parameters = models.JSONField(default=dict, blank=True, help_text="Enhancement parameters")
    processing_time = models.FloatField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Photo Enhancement - {self.enhancement_type} ({self.user.username})"