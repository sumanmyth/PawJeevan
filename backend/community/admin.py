"""
Admin interface for Community app
"""
from django.contrib import admin
from django.utils.html import format_html
from .models import (
    Post, Comment, Group, GroupPost, GroupMessage, Event,
    LostFoundReport
)


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['id', 'author', 'content_preview', 'has_media', 'likes_count', 'comments_count', 'is_public', 'created_at']
    list_filter = ['is_public', 'created_at']
    search_fields = ['content', 'author__username', 'author__email']
    readonly_fields = ['created_at', 'updated_at', 'likes_count', 'comments_count']
    filter_horizontal = ['likes']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Post Information', {
            'fields': ('author', 'content', 'is_public')
        }),
        ('Media', {
            'fields': ('image', 'video')
        }),
        ('Engagement', {
            'fields': ('likes', 'likes_count', 'comments_count'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'
    
    def has_media(self, obj):
        if obj.image:
            return format_html('<span style="color: green;">📷 Image</span>')
        elif obj.video:
            return format_html('<span style="color: blue;">🎥 Video</span>')
        return format_html('<span style="color: gray;">-</span>')
    has_media.short_description = 'Media'


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ['id', 'author', 'post_link', 'content_preview', 'likes_count', 'has_parent', 'created_at']
    list_filter = ['created_at']
    search_fields = ['content', 'author__username', 'author__email', 'post__content']
    readonly_fields = ['created_at', 'updated_at', 'likes_count']
    filter_horizontal = ['likes']
    date_hierarchy = 'created_at'
    raw_id_fields = ['post', 'author', 'parent']
    
    fieldsets = (
        ('Comment Information', {
            'fields': ('author', 'post', 'content', 'parent')
        }),
        ('Engagement', {
            'fields': ('likes', 'likes_count'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'
    
    def post_link(self, obj):
        return format_html('<a href="/admin/community/post/{}/change/">Post #{}</a>', obj.post.id, obj.post.id)
    post_link.short_description = 'Post'
    
    def has_parent(self, obj):
        return format_html('<span style="color: green;">✓</span>') if obj.parent else format_html('<span style="color: gray;">-</span>')
    has_parent.short_description = 'Reply'


@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'group_type', 'creator', 'members_count', 'is_private', 'is_active', 'created_at']
    list_filter = ['group_type', 'is_private', 'is_active', 'created_at']
    search_fields = ['name', 'description', 'creator__username']
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = ['created_at', 'updated_at', 'members_count']
    filter_horizontal = ['members', 'moderators']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Group Information', {
            'fields': ('name', 'slug', 'description', 'group_type', 'cover_image')
        }),
        ('Management', {
            'fields': ('creator', 'members', 'moderators')
        }),
        ('Settings', {
            'fields': ('is_private', 'is_active', 'join_key')
        }),
        ('Statistics', {
            'fields': ('members_count',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(GroupPost)
class GroupPostAdmin(admin.ModelAdmin):
    list_display = ['id', 'author', 'group', 'content_preview', 'is_pinned', 'has_image', 'created_at']
    list_filter = ['is_pinned', 'created_at', 'group']
    search_fields = ['content', 'author__username', 'group__name']
    readonly_fields = ['created_at', 'updated_at']
    raw_id_fields = ['group', 'author']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Post Information', {
            'fields': ('author', 'group', 'content', 'image', 'is_pinned')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'
    
    def has_image(self, obj):
        return format_html('<span style="color: green;">✓</span>') if obj.image else format_html('<span style="color: gray;">-</span>')
    has_image.short_description = 'Image'


@admin.register(GroupMessage)
class GroupMessageAdmin(admin.ModelAdmin):
    list_display = ['id', 'sender', 'group', 'content_preview', 'is_system_message', 'created_at']
    list_filter = ['is_system_message', 'created_at', 'group']
    search_fields = ['content', 'sender__username', 'group__name']
    readonly_fields = ['created_at', 'updated_at']
    raw_id_fields = ['group', 'sender']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Message Information', {
            'fields': ('sender', 'group', 'content', 'is_system_message')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'event_type', 'organizer', 'location', 'start_datetime', 'end_datetime', 'attendees_count', 'is_full']
    list_filter = ['event_type', 'start_datetime', 'created_at']
    search_fields = ['title', 'location', 'organizer__username', 'description']
    readonly_fields = ['created_at', 'updated_at', 'attendees_count']
    filter_horizontal = ['attendees']
    date_hierarchy = 'start_datetime'
    raw_id_fields = ['organizer', 'group']
    
    fieldsets = (
        ('Event Information', {
            'fields': ('title', 'description', 'event_type', 'cover_image')
        }),
        ('Location', {
            'fields': ('location', 'address', 'latitude', 'longitude')
        }),
        ('Schedule', {
            'fields': ('start_datetime', 'end_datetime')
        }),
        ('Organization', {
            'fields': ('organizer', 'group')
        }),
        ('Attendees', {
            'fields': ('attendees', 'max_attendees', 'attendees_count'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def is_full(self, obj):
        if obj.max_attendees and obj.attendees_count >= obj.max_attendees:
            return format_html('<span style="color: red;">✓ Full</span>')
        return format_html('<span style="color: green;">Open</span>')
    is_full.short_description = 'Status'


@admin.register(LostFoundReport)
class LostFoundReportAdmin(admin.ModelAdmin):
    list_display = ['id', 'pet_name_display', 'pet_type', 'breed', 'report_type', 'status', 'location', 'date_lost_found', 'reporter', 'created_at']
    list_filter = ['report_type', 'status', 'pet_type', 'date_lost_found', 'created_at']
    search_fields = ['pet_name', 'pet_type', 'breed', 'location', 'reporter__username', 'description']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'date_lost_found'
    raw_id_fields = ['reporter']
    
    fieldsets = (
        ('Report Information', {
            'fields': ('report_type', 'status', 'reporter', 'contact_phone')
        }),
        ('Pet Details', {
            'fields': ('pet_name', 'pet_type', 'breed', 'color', 'description', 'photo')
        }),
        ('Location & Time', {
            'fields': ('location', 'address', 'date_lost_found')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def pet_name_display(self, obj):
        return obj.pet_name if obj.pet_name else format_html('<span style="color: gray;">Unknown</span>')
    pet_name_display.short_description = 'Pet Name'