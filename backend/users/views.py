from rest_framework import viewsets, status, generics, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate

from .models import User, PetProfile, VaccinationRecord, MedicalRecord, Notification
from .serializers import (
    UserSerializer, UserRegistrationSerializer, PetProfileSerializer,
    VaccinationRecordSerializer, MedicalRecordSerializer, NotificationSerializer
)


class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = [AllowAny]
    serializer_class = UserRegistrationSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            "user": UserSerializer(user, context={"request": request}).data,
            "tokens": {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
            }
        }, status=status.HTTP_201_CREATED)


class UserLoginView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser]

    def post(self, request):
        email = request.data.get("email")
        password = request.data.get("password")
        user = authenticate(username=email, password=password)
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                "user": UserSerializer(user, context={"request": request}).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                }
            })
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    @action(detail=False, methods=["get", "patch"], url_path="me", parser_classes=[MultiPartParser, FormParser, JSONParser])
    def me(self, request):
        user = request.user
        if request.method.lower() == "get":
            ser = self.get_serializer(user)
            return Response(ser.data)

        # PATCH - supports multipart (avatar), as well as JSON for text fields
        ser = self.get_serializer(user, data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        ser.save()
        return Response(ser.data)

    @action(detail=True, methods=["post"])
    def follow(self, request, pk=None):
        to_follow = self.get_object()
        if to_follow == request.user:
            return Response({"error": "You cannot follow yourself"}, status=400)
        request.user.following.add(to_follow)
        return Response({"status": "following"})

    @action(detail=True, methods=["post"])
    def unfollow(self, request, pk=None):
        to_unfollow = self.get_object()
        request.user.following.remove(to_unfollow)
        return Response({"status": "unfollowed"})

    @action(detail=True, methods=["get"])
    def followers(self, request, pk=None):
        user = self.get_object()
        followers = user.followers.all()
        page = self.paginate_queryset(followers)
        if page is not None:
            serializer = UserSerializer(page, many=True, context={"request": request})
            return self.get_paginated_response(serializer.data)
        serializer = UserSerializer(followers, many=True, context={"request": request})
        return Response(serializer.data)

    @action(detail=True, methods=["get"])
    def following(self, request, pk=None):
        user = self.get_object()
        following = user.following.all()
        page = self.paginate_queryset(following)
        if page is not None:
            serializer = UserSerializer(page, many=True, context={"request": request})
            return self.get_paginated_response(serializer.data)
        serializer = UserSerializer(following, many=True, context={"request": request})
        return Response(serializer.data)


class PetProfileViewSet(viewsets.ModelViewSet):
    queryset = PetProfile.objects.all()
    serializer_class = PetProfileSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        if self.request.user.is_staff:
            return PetProfile.objects.all()
        return PetProfile.objects.filter(owner=self.request.user)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class VaccinationRecordViewSet(viewsets.ModelViewSet):
    queryset = VaccinationRecord.objects.all()
    serializer_class = VaccinationRecordSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return VaccinationRecord.objects.filter(pet__owner=self.request.user)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx


class MedicalRecordViewSet(viewsets.ModelViewSet):
    queryset = MedicalRecord.objects.all()
    serializer_class = MedicalRecordSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return MedicalRecord.objects.filter(pet__owner=self.request.user)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx


class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx