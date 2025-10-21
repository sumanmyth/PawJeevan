"""
URL routing for Admin Panel
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AdminUserViewSet, AdminAnalyticsViewSet, SystemSettingsViewSet

router = DefaultRouter()
router.register(r'users', AdminUserViewSet)
router.register(r'analytics', AdminAnalyticsViewSet, basename='analytics')
router.register(r'settings', SystemSettingsViewSet)

urlpatterns = [
    path('', include(router.urls)),
]