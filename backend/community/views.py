# backend/community/views.py
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Count, Q, F
from django.utils import timezone
from datetime import timedelta

from .models import (
    Post, Comment, Group, GroupPost, GroupMessage, Event,
    LostFoundReport
)
from .serializers import (
    PostSerializer, PostListSerializer, CommentSerializer,
    GroupSerializer, GroupPostSerializer, GroupMessageSerializer, EventSerializer,
    LostFoundReportSerializer
)
from users.models import User, Notification
from users.serializers import UserSerializer


class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all().order_by('-created_at')
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['content', 'author__username']
    ordering_fields = ['created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return PostListSerializer
        return PostSerializer

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def get_queryset(self):
        # Show all public posts by default
        qs = Post.objects.filter(is_public=True)
        
        # Optional filters
        author_id = self.request.query_params.get('author')
        if author_id:
            # Check if the author's profile is locked
            try:
                author = User.objects.get(id=author_id)
                # If profile is locked and requesting user is not the owner, return empty queryset
                if author.is_profile_locked and (not self.request.user.is_authenticated or author.id != self.request.user.id):
                    return Post.objects.none()
            except User.DoesNotExist:
                pass
            
            qs = qs.filter(author_id=author_id)
        
        if self.request.query_params.get('following') == 'true' and self.request.user.is_authenticated:
            following = self.request.user.following.all()
            qs = qs.filter(author__in=following)
        
        # Handle ordering
        ordering = self.request.query_params.get('ordering', '-created_at')
        
        if ordering == '-trending':
            # Calculate engagement score for all posts
            two_days_ago = timezone.now() - timedelta(days=2)
            
            qs = qs.annotate(
                likes_total=Count('likes', distinct=True),
                comments_total=Count('comments', distinct=True),
                engagement_score=F('likes_total') + F('comments_total'),
                is_recent=Q(created_at__gte=two_days_ago)
            ).order_by('-is_recent', '-engagement_score', '-created_at')
        else:
            qs = qs.order_by(ordering)
            
        return qs

    def perform_create(self, serializer):
        serializer.save(author=self.request.user, is_public=True)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def like(self, request, pk=None):
        post = self.get_object()
        if post.likes.filter(id=request.user.id).exists():
            post.likes.remove(request.user)
            return Response({'status': 'unliked', 'likes_count': post.likes.count()})
        post.likes.add(request.user)
        return Response({'status': 'liked', 'likes_count': post.likes.count()})

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def comment(self, request, pk=None):
        post = self.get_object()
        content = request.data.get('content', '').strip()
        parent_id = request.data.get('parent_id')
        if not content:
            return Response({'error': 'content is required'}, status=400)
        comment = Comment.objects.create(
            post=post, author=request.user, content=content, parent_id=parent_id or None
        )
        return Response(CommentSerializer(comment, context={'request': request}).data, status=201)


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    @action(detail=True, methods=['get'])
    def posts(self, request, pk=None):
        user = self.get_object()
        posts = Post.objects.filter(author=user, is_public=True)
        serializer = PostListSerializer(posts, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def follow(self, request, pk=None):
        user_to_follow = self.get_object()
        current_user = request.user

        if user_to_follow == current_user:
            return Response({'error': 'You cannot follow yourself'}, status=status.HTTP_400_BAD_REQUEST)

        if current_user in user_to_follow.followers.all():
            user_to_follow.followers.remove(current_user)
            return Response({'status': 'unfollowed'})
        else:
            user_to_follow.followers.add(current_user)
            return Response({'status': 'followed'})


class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['post']

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)


class GroupViewSet(viewsets.ModelViewSet):
    queryset = Group.objects.filter(is_active=True).order_by('-created_at')
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['group_type']
    search_fields = ['name', 'description']
    lookup_field = 'slug'

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def perform_create(self, serializer):
        group = serializer.save(creator=self.request.user, is_active=True)
        group.members.add(self.request.user)
        group.moderators.add(self.request.user)

    def perform_update(self, serializer):
        # Ensure the group stays active when updated
        serializer.save(is_active=True)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def join(self, request, slug=None):
        group = self.get_object()
        if group.is_private:
            # Check if join key is provided and correct
            join_key = request.data.get('join_key', '')
            if not join_key or join_key != group.join_key:
                return Response({'error': 'Invalid join key for private group'}, status=400)
        group.members.add(request.user)
        
        # Create a system message announcing the user joined
        GroupMessage.objects.create(
            group=group,
            sender=request.user,
            content=f"{request.user.username} joined the group",
            is_system_message=True
        )
        
        return Response({'status': 'joined', 'members_count': group.members.count()})

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def leave(self, request, slug=None):
        group = self.get_object()
        if group.creator == request.user:
            return Response({'error': 'Creator cannot leave the group'}, status=400)
        
        # Create a system message announcing the user left
        GroupMessage.objects.create(
            group=group,
            sender=request.user,
            content=f"{request.user.username} left the group",
            is_system_message=True
        )
        
        group.members.remove(request.user)
        return Response({'status': 'left', 'members_count': group.members.count()})

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my(self, request):
        """Return groups created by the current user."""
        groups = Group.objects.filter(creator=request.user, is_active=True).order_by('-created_at')
        serializer = self.get_serializer(groups, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def joined(self, request):
        """Return groups the current user has joined (is a member of but did not create)."""
        groups = Group.objects.filter(members=request.user, is_active=True).exclude(creator=request.user).order_by('-created_at')
        serializer = self.get_serializer(groups, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticatedOrReadOnly])
    def discover(self, request):
        """Return groups the user is not a member of (discoverable groups).

        If the user is anonymous, return all active groups.
        """
        if request.user.is_authenticated:
            qs = Group.objects.filter(is_active=True).exclude(members=request.user).order_by('-created_at')
        else:
            qs = Group.objects.filter(is_active=True).order_by('-created_at')
        serializer = self.get_serializer(qs, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['get', 'post'], permission_classes=[IsAuthenticated])
    def messages(self, request, slug=None):
        """Get or post messages for a group."""
        from .serializers import GroupMessageSerializer
        from .models import GroupMessage
        
        group = self.get_object()
        
        # Check if user is a member
        if not group.members.filter(id=request.user.id).exists():
            return Response({'error': 'You must be a member to access group messages'}, status=403)
        
        if request.method == 'GET':
            messages = GroupMessage.objects.filter(group=group).order_by('created_at')
            serializer = GroupMessageSerializer(messages, many=True, context={'request': request})
            return Response(serializer.data)
        
        elif request.method == 'POST':
            serializer = GroupMessageSerializer(data=request.data, context={'request': request})
            if serializer.is_valid():
                serializer.save(group=group, sender=request.user)
                return Response(serializer.data, status=201)
            return Response(serializer.errors, status=400)


class GroupPostViewSet(viewsets.ModelViewSet):
    queryset = GroupPost.objects.all().order_by('-created_at')
    serializer_class = GroupPostSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['group']

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)


class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all().order_by('start_datetime')
    serializer_class = EventSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['event_type', 'organizer', 'group']
    search_fields = ['title', 'description', 'location']
    ordering_fields = ['start_datetime', 'created_at']

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def perform_create(self, serializer):
        serializer.save(organizer=self.request.user)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def attend(self, request, pk=None):
        event = self.get_object()
        if event.max_attendees and event.attendees.count() >= event.max_attendees:
            return Response({'error': 'Event is full'}, status=400)
        
        # Add user to attendees
        event.attendees.add(request.user)
        
        # Create notification for joining the event
        Notification.objects.create(
            user=request.user,
            notification_type='event_joined',
            title=f'You joined "{event.title}"',
            message=f'You are now attending {event.title} on {event.start_datetime.strftime("%B %d, %Y at %I:%M %p")}. We will remind you before the event starts.',
            action_url=f'/events/{event.id}/'
        )
        
        return Response({'status': 'attending', 'attendees_count': event.attendees.count()})

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def unattend(self, request, pk=None):
        event = self.get_object()
        event.attendees.remove(request.user)
        return Response({'status': 'not attending', 'attendees_count': event.attendees.count()})


class LostFoundReportViewSet(viewsets.ModelViewSet):
    queryset = LostFoundReport.objects.all().order_by('-created_at')
    serializer_class = LostFoundReportSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['report_type', 'status', 'pet_type']
    search_fields = ['pet_name', 'breed', 'location', 'description']

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def get_queryset(self):
        qs = super().get_queryset()
        
        # Don't filter during update/delete operations
        if self.action in ['update', 'partial_update', 'destroy']:
            return qs
        
        status_param = self.request.query_params.get('status')
        
        # If status is explicitly set to empty string, return all statuses
        # If status is not provided at all, default to showing only active reports
        # If status is provided with a value, filterset_fields will handle it
        if status_param is None:
            qs = qs.filter(status='active')
        elif status_param == '':
            # Return all statuses (no filter)
            pass
            
        return qs

    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user)
