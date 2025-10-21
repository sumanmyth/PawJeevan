"""
Serializers for Admin Panel
"""
from rest_framework import serializers
from users.models import User
from store.models import Product, Order
from community.models import Post, Group
from .models import SystemSettings


class AdminUserSerializer(serializers.ModelSerializer):
    """Admin serializer for users with more details"""
    posts_count = serializers.SerializerMethodField()
    orders_count = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = '__all__'
    
    def get_posts_count(self, obj):
        return obj.posts.count()
    
    def get_orders_count(self, obj):
        return obj.orders.count()


class SystemSettingsSerializer(serializers.ModelSerializer):
    """Serializer for System Settings"""
    class Meta:
        model = SystemSettings
        fields = '__all__'