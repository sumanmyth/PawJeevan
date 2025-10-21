"""
URL routing for AI Module
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    BreedDetectionViewSet, DiseaseDetectionViewSet,
    DietRecommendationViewSet, ChatSessionViewSet,
    PhotoEnhancementViewSet
)

router = DefaultRouter()
router.register(r'breed-detection', BreedDetectionViewSet, basename='breed-detection')
router.register(r'disease-detection', DiseaseDetectionViewSet, basename='disease-detection')
router.register(r'diet-recommendations', DietRecommendationViewSet, basename='diet-recommendation')
router.register(r'chat-sessions', ChatSessionViewSet, basename='chat-session')
router.register(r'photo-enhancement', PhotoEnhancementViewSet, basename='photo-enhancement')

urlpatterns = [
    path('', include(router.urls)),
]