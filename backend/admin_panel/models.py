"""
Admin panel specific models (if any additional needed)
"""
from django.db import models

# Most admin functionality will use existing models
# This file can be empty or contain admin-specific models if needed

class SystemSettings(models.Model):
    """System-wide settings"""
    key = models.CharField(max_length=100, unique=True)
    value = models.TextField()
    description = models.TextField(blank=True)
    
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.key