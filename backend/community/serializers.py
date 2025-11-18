# backend/community/serializers.py
from rest_framework import serializers
from django.utils import timezone
from users.serializers import AbsoluteURLImageField
from users.models import User
from .models import (
    Post, Comment, Group, GroupPost, GroupMessage, Event,
    LostFoundReport
)

def build_abs_url(request, path):
    if not path:
        return None
    if request and not (str(path).startswith("http://") or str(path).startswith("https://")):
        return request.build_absolute_uri(path)
    return path

class CommentSerializer(serializers.ModelSerializer):
    author_username = serializers.CharField(source='author.username', read_only=True)
    author_avatar = serializers.SerializerMethodField()
    replies = serializers.SerializerMethodField()
    is_current_user_author = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = [
            'id', 'author', 'author_username', 'author_avatar',
            'content', 'created_at', 'replies', 'is_current_user_author'
        ]
        read_only_fields = ['author', 'created_at', 'updated_at']

    def get_author_avatar(self, obj):
        req = self.context.get('request')
        if obj.author and obj.author.avatar:
            return build_abs_url(req, obj.author.avatar.url)
        return None

    def get_replies(self, obj):
        qs = obj.replies.all()
        return CommentSerializer(qs, many=True, context=self.context).data

    def get_is_current_user_author(self, obj):
        req = self.context.get('request')
        user = getattr(req, 'user', None)
        return user and user.is_authenticated and obj.author_id == user.id


class PostListSerializer(serializers.ModelSerializer):
    author_username = serializers.CharField(source='author.username', read_only=True)
    author_avatar = serializers.SerializerMethodField()
    image = AbsoluteURLImageField(required=False, allow_null=True)
    video = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    is_current_user_author = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'author', 'author_username', 'author_avatar',
            'content', 'image', 'video',
            'likes_count', 'comments_count', 'is_liked',
            'created_at', 'is_public', 'is_current_user_author'
        ]

    def get_author_avatar(self, obj):
        req = self.context.get('request')
        if obj.author and obj.author.avatar:
            return build_abs_url(req, obj.author.avatar.url)
        return None

    def get_video(self, obj):
        req = self.context.get('request')
        if obj.video:
            return build_abs_url(req, obj.video.url)
        return None

    def get_likes_count(self, obj):
        return obj.likes.count()

    def get_comments_count(self, obj):
        return obj.comments.count()

    def get_is_liked(self, obj):
        req = self.context.get('request')
        user = getattr(req, 'user', None)
        if user and user.is_authenticated:
            return obj.likes.filter(id=user.id).exists()
        return False

    def get_is_current_user_author(self, obj):
        req = self.context.get('request')
        user = getattr(req, 'user', None)
        return user and user.is_authenticated and obj.author_id == user.id


class PostSerializer(serializers.ModelSerializer):
    author_username = serializers.CharField(source='author.username', read_only=True)
    author_avatar = serializers.SerializerMethodField()
    image = AbsoluteURLImageField(required=False, allow_null=True)
    video = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    is_current_user_author = serializers.SerializerMethodField()
    comments = CommentSerializer(many=True, read_only=True, source='comments.all')

    class Meta:
        model = Post
        fields = '__all__'
        read_only_fields = ['author', 'likes', 'created_at', 'updated_at']

    def get_author_avatar(self, obj):
        req = self.context.get('request')
        if obj.author and obj.author.avatar:
            return build_abs_url(req, obj.author.avatar.url)
        return None

    def get_video(self, obj):
        req = self.context.get('request')
        if obj.video:
            return build_abs_url(req, obj.video.url)
        return None

    def get_likes_count(self, obj):
        return obj.likes.count()

    def get_comments_count(self, obj):
        return obj.comments.count()

    def get_is_liked(self, obj):
        req = self.context.get('request')
        user = getattr(req, 'user', None)
        if user and user.is_authenticated:
            return obj.likes.filter(id=user.id).exists()
        return False
        
    def get_is_current_user_author(self, obj):
        req = self.context.get('request')
        user = getattr(req, 'user', None)
        return user and user.is_authenticated and obj.author_id == user.id


class GroupSerializer(serializers.ModelSerializer):
    creator_username = serializers.CharField(source='creator.username', read_only=True)
    members_count = serializers.SerializerMethodField()
    is_member = serializers.SerializerMethodField()

    class Meta:
        model = Group
        fields = '__all__'
        read_only_fields = ['creator', 'members', 'moderators', 'created_at', 'updated_at']
    
    def get_fields(self):
        fields = super().get_fields()
        # Make slug read-only on update, but writable on create
        if self.instance is not None:
            fields['slug'].read_only = True
        return fields

    def validate(self, data):
        """Validate that join_key is provided for private groups."""
        is_private = data.get('is_private', False)
        join_key = data.get('join_key', '')
        
        # If updating, check the instance values
        if self.instance:
            is_private = data.get('is_private', self.instance.is_private)
            join_key = data.get('join_key', self.instance.join_key)
        
        if is_private and not join_key:
            raise serializers.ValidationError({
                'join_key': 'Join key is required for private groups.'
            })
        
        return data

    def get_members_count(self, obj):
        return obj.members.count()

    def get_is_member(self, obj):
        req = self.context.get('request')
        user = getattr(req, 'user', None)
        if user and user.is_authenticated:
            return obj.members.filter(id=user.id).exists()
        return False


class GroupMessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.username', read_only=True)
    sender_id = serializers.IntegerField(source='sender.id', read_only=True)
    sender_avatar = serializers.SerializerMethodField()

    class Meta:
        model = GroupMessage
        fields = ['id', 'sender_id', 'sender_name', 'sender_avatar', 'content', 'is_system_message', 'created_at']
        read_only_fields = ['sender', 'created_at']
    
    def get_sender_avatar(self, obj):
        req = self.context.get('request')
        if obj.sender and obj.sender.avatar:
            return build_abs_url(req, obj.sender.avatar.url)
        return None


class GroupPostSerializer(serializers.ModelSerializer):
    author_username = serializers.CharField(source='author.username', read_only=True)
    author_avatar = serializers.SerializerMethodField()

    class Meta:
        model = GroupPost
        fields = '__all__'
        read_only_fields = ['author', 'created_at', 'updated_at']

    def get_author_avatar(self, obj):
        req = self.context.get('request')
        if obj.author and obj.author.avatar:
            return build_abs_url(req, obj.author.avatar.url)
        return None


class EventSerializer(serializers.ModelSerializer):
    organizer_username = serializers.CharField(source='organizer.username', read_only=True)
    organizer_avatar = serializers.SerializerMethodField()
    group_name = serializers.CharField(source='group.name', read_only=True)
    attendees_count = serializers.SerializerMethodField()
    is_attending = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = '__all__'
        read_only_fields = ['organizer', 'attendees', 'created_at', 'updated_at']

    def get_organizer_avatar(self, obj):
        req = self.context.get('request')
        if obj.organizer and obj.organizer.avatar:
            return build_abs_url(req, obj.organizer.avatar.url)
        return None

    def get_attendees_count(self, obj):
        return obj.attendees.count()

    def get_is_attending(self, obj):
        req = self.context.get('request')
        user = getattr(req, 'user', None)
        if user and user.is_authenticated:
            return obj.attendees.filter(id=user.id).exists()
        return False


class LostFoundReportSerializer(serializers.ModelSerializer):
    reporter_username = serializers.CharField(source='reporter.username', read_only=True)
    photo = AbsoluteURLImageField(required=False, allow_null=True)

    class Meta:
        model = LostFoundReport
        fields = '__all__'
        read_only_fields = ['reporter', 'created_at', 'updated_at']