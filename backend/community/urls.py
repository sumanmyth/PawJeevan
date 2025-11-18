"""
URL routing for Community app
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PostViewSet, CommentViewSet, GroupViewSet, GroupPostViewSet,
    EventViewSet, LostFoundReportViewSet,
    UserViewSet
)

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')
router.register(r'posts', PostViewSet, basename='post')
router.register(r'comments', CommentViewSet, basename='comment')
router.register(r'groups', GroupViewSet)
router.register(r'group-posts', GroupPostViewSet)
router.register(r'events', EventViewSet)
router.register(r'lost-found', LostFoundReportViewSet, basename='lost-found')

urlpatterns = [
    path('', include(router.urls)),
]
