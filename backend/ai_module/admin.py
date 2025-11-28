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
    list_display = [f.name for f in BreedDetection._meta.fields]
    list_filter = ['detected_breed', 'created_at']
    search_fields = ['user__username', 'detected_breed']
    readonly_fields = ['created_at']


@admin.register(DiseaseDetection)
class DiseaseDetectionAdmin(admin.ModelAdmin):
    list_display = [f.name for f in DiseaseDetection._meta.fields]
    list_filter = ['disease_type', 'severity', 'should_see_vet', 'created_at']
    search_fields = ['user__username', 'detected_disease']
    readonly_fields = ['created_at']


@admin.register(DietRecommendation)
class DietRecommendationAdmin(admin.ModelAdmin):
    list_display = [f.name for f in DietRecommendation._meta.fields]
    list_filter = ['created_at']
    search_fields = ['user__username', 'pet__name']
    readonly_fields = ['created_at']


class ChatMessageInline(admin.TabularInline):
    model = ChatMessage
    extra = 0
    readonly_fields = ['created_at']


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    list_display = [f.name for f in ChatSession._meta.fields] + ['created_at', 'updated_at']
    list_filter = ['created_at']
    search_fields = ['title', 'user__username']
    inlines = [ChatMessageInline]


@admin.register(PhotoEnhancement)
class PhotoEnhancementAdmin(admin.ModelAdmin):
    list_display = [f.name for f in PhotoEnhancement._meta.fields]
    list_filter = ['enhancement_type', 'created_at']
    search_fields = ['user__username']