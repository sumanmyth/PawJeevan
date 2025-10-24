# backend/community/views.py
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from django_filters.rest_framework import DjangoFilterBackend

from .models import (
    Post, Comment, Group, GroupPost, Event,
    AdoptionListing, LostFoundReport, Conversation, Message
)
from .serializers import (
    PostSerializer, PostListSerializer, CommentSerializer,
    GroupSerializer, GroupPostSerializer, EventSerializer,
    AdoptionListingSerializer, LostFoundReportSerializer,
    ConversationSerializer, MessageSerializer
)
from users.models import User
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
        qs = Post.objects.filter(is_public=True).order_by('-created_at')
        
        # Optional filters
        author_id = self.request.query_params.get('author')
        if author_id:
            qs = qs.filter(author_id=author_id)
        
        if self.request.query_params.get('following') == 'true' and self.request.user.is_authenticated:
            following = self.request.user.following.all()
            qs = qs.filter(author__in=following)
            
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
        group = serializer.save(creator=self.request.user)
        group.members.add(self.request.user)
        group.moderators.add(self.request.user)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def join(self, request, slug=None):
        group = self.get_object()
        if group.is_private:
            return Response({'error': 'This is a private group'}, status=400)
        group.members.add(request.user)
        return Response({'status': 'joined', 'members_count': group.members.count()})

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def leave(self, request, slug=None):
        group = self.get_object()
        if group.creator == request.user:
            return Response({'error': 'Creator cannot leave the group'}, status=400)
        group.members.remove(request.user)
        return Response({'status': 'left', 'members_count': group.members.count()})

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my(self, request):
        """Return groups the current user is a member of."""
        groups = Group.objects.filter(members=request.user, is_active=True).order_by('-created_at')
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
        event.attendees.add(request.user)
        return Response({'status': 'attending', 'attendees_count': event.attendees.count()})

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def unattend(self, request, pk=None):
        event = self.get_object()
        event.attendees.remove(request.user)
        return Response({'status': 'not attending', 'attendees_count': event.attendees.count()})


class AdoptionListingViewSet(viewsets.ModelViewSet):
    queryset = AdoptionListing.objects.all().order_by('-created_at')
    serializer_class = AdoptionListingSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['pet_type', 'status', 'location']
    search_fields = ['title', 'pet_name', 'breed', 'description']

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def get_queryset(self):
        qs = super().get_queryset()
        if not self.request.query_params.get('status'):
            qs = qs.filter(status='available')
        return qs

    def perform_create(self, serializer):
        serializer.save(poster=self.request.user)


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
        if not self.request.query_params.get('status'):
            qs = qs.filter(status='active')
        return qs

    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user)


class ConversationViewSet(viewsets.ModelViewSet):
    queryset = Conversation.objects.all().order_by('-updated_at')
    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Conversation.objects.filter(participants=self.request.user).order_by('-updated_at')

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def create(self, request, *args, **kwargs):
        participant_ids = request.data.get('participant_ids', [])
        if not participant_ids:
            return Response({'error': 'participant_ids required'}, status=400)

        convo = Conversation.objects.create()
        convo.participants.add(request.user)
        convo.participants.add(*participant_ids)
        ser = self.get_serializer(convo)
        return Response(ser.data, status=201)

    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        convo = self.get_object()
        content = request.data.get('content', '').strip()
        if not content:
            return Response({'error': 'content required'}, status=400)

        msg = Message.objects.create(
            conversation=convo, sender=request.user, content=content
        )
        convo.save()  # updates updated_at
        return Response(MessageSerializer(msg, context={'request': request}).data, status=201)

    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        convo = self.get_object()
        msgs = convo.messages.all()
        msgs.exclude(sender=request.user).update(is_read=True)
        return Response(MessageSerializer(msgs, many=True, context={'request': request}).data)
