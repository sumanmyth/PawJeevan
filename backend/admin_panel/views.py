"""
Views for Admin Panel API endpoints
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from django.db.models import Count, Sum
from users.models import User
from store.models import Product, Order
from community.models import Post, Comment, Group
from .models import SystemSettings
from .serializers import AdminUserSerializer, SystemSettingsSerializer


class AdminUserViewSet(viewsets.ModelViewSet):
    """
    Admin endpoints for user management
    Only accessible by admin users
    """
    queryset = User.objects.all()
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminUser]
    
    @action(detail=True, methods=['post'])
    def ban(self, request, pk=None):
        """Ban a user"""
        user = self.get_object()
        user.is_active = False
        user.save()
        return Response({'status': 'user banned'})
    
    @action(detail=True, methods=['post'])
    def unban(self, request, pk=None):
        """Unban a user"""
        user = self.get_object()
        user.is_active = True
        user.save()
        return Response({'status': 'user unbanned'})


class AdminAnalyticsViewSet(viewsets.ViewSet):
    """
    Admin analytics endpoints
    GET /api/admin/analytics/dashboard/ - Dashboard stats
    GET /api/admin/analytics/users/ - User analytics
    GET /api/admin/analytics/sales/ - Sales analytics
    """
    permission_classes = [IsAdminUser]
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Get dashboard statistics"""
        stats = {
            'users': {
                'total': User.objects.count(),
                'active': User.objects.filter(is_active=True).count(),
                'new_this_month': User.objects.filter(
                    created_at__month=timezone.now().month
                ).count(),
            },
            'store': {
                'total_products': Product.objects.count(),
                'active_products': Product.objects.filter(is_active=True).count(),
                'total_orders': Order.objects.count(),
                'pending_orders': Order.objects.filter(status='pending').count(),
                'total_revenue': Order.objects.filter(
                    payment_status='paid'
                ).aggregate(Sum('total'))['total__sum'] or 0,
            },
            'community': {
                'total_posts': Post.objects.count(),
                'total_comments': Comment.objects.count(),
                'total_groups': Group.objects.count(),
            }
        }
        
        return Response(stats)


class SystemSettingsViewSet(viewsets.ModelViewSet):
    """
    System settings management
    """
    queryset = SystemSettings.objects.all()
    serializer_class = SystemSettingsSerializer
    permission_classes = [IsAdminUser]