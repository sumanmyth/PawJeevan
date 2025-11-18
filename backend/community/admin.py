"""
Admin interface for Community app
"""
from django.contrib import admin
from .models import (
    Post, Comment, Group, GroupPost, GroupMessage, Event,
    AdoptionListing, LostFoundReport, Conversation, Message
)


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['author', 'content_preview', 'likes_count', 'comments_count', 'created_at']
    list_filter = ['is_public', 'created_at']
    search_fields = ['content', 'author__username']
    
    def content_preview(self, obj):
        return obj.content[:50]


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ['author', 'post', 'content_preview', 'created_at']
    list_filter = ['created_at']
    search_fields = ['content', 'author__username']
    
    def content_preview(self, obj):
        return obj.content[:50]


@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ['name', 'group_type', 'creator', 'members_count', 'is_private', 'created_at']
    list_filter = ['group_type', 'is_private', 'is_active']
    search_fields = ['name', 'description']
    prepopulated_fields = {'slug': ('name',)}


@admin.register(GroupMessage)
class GroupMessageAdmin(admin.ModelAdmin):
    list_display = ['sender', 'group', 'content_preview', 'created_at']
    list_filter = ['created_at', 'group']
    search_fields = ['content', 'sender__username', 'group__name']
    
    def content_preview(self, obj):
        return obj.content[:50]


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ['title', 'event_type', 'organizer', 'location', 'start_datetime', 'attendees_count']
    list_filter = ['event_type', 'start_datetime']
    search_fields = ['title', 'location']


@admin.register(AdoptionListing)
class AdoptionListingAdmin(admin.ModelAdmin):
    list_display = ['pet_name', 'pet_type', 'breed', 'poster', 'status', 'location', 'created_at']
    list_filter = ['pet_type', 'status', 'created_at']
    search_fields = ['pet_name', 'breed', 'location']


@admin.register(LostFoundReport)
class LostFoundReportAdmin(admin.ModelAdmin):
    list_display = ['pet_name', 'pet_type', 'report_type', 'status', 'location', 'date_lost_found']
    list_filter = ['report_type', 'status', 'pet_type']
    search_fields = ['pet_name', 'location']


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ['id', 'is_group', 'name', 'created_at']
    list_filter = ['is_group', 'created_at']


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['sender', 'conversation', 'content_preview', 'is_read', 'created_at']
    list_filter = ['is_read', 'created_at']
    search_fields = ['content', 'sender__username']
    
    def content_preview(self, obj):
        return obj.content[:50]