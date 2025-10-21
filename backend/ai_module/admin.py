"""
Admin interface for AI Module
"""
from django.contrib import admin
from .models import (
    BreedDetection, DiseaseDetection, DietRecommendation,
    ChatSession, ChatMessage, PhotoEnhancement
)


@admin.register(BreedDetection)
class BreedDetectionAdmin(admin.ModelAdmin):
    list_display = ['user', 'detected_breed', 'confidence', 'created_at']
    list_filter = ['detected_breed', 'created_at']
    search_fields = ['user__username', 'detected_breed']
    readonly_fields = ['created_at']


@admin.register(DiseaseDetection)
class DiseaseDetectionAdmin(admin.ModelAdmin):
    list_display = ['user', 'disease_type', 'detected_disease', 'severity', 'should_see_vet', 'created_at']
    list_filter = ['disease_type', 'severity', 'should_see_vet', 'created_at']
    search_fields = ['user__username', 'detected_disease']
    readonly_fields = ['created_at']


@admin.register(DietRecommendation)
class DietRecommendationAdmin(admin.ModelAdmin):
    list_display = ['pet', 'user', 'daily_calories', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'pet__name']
    readonly_fields = ['created_at']


class ChatMessageInline(admin.TabularInline):
    model = ChatMessage
    extra = 0
    readonly_fields = ['created_at']


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'created_at', 'updated_at']
    list_filter = ['created_at']
    search_fields = ['title', 'user__username']
    inlines = [ChatMessageInline]


@admin.register(PhotoEnhancement)
class PhotoEnhancementAdmin(admin.ModelAdmin):
    list_display = ['user', 'enhancement_type', 'processing_time', 'created_at']
    list_filter = ['enhancement_type', 'created_at']
    search_fields = ['user__username']