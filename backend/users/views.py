from rest_framework import viewsets, status, generics, permissions, filters
from rest_framework.decorators import action
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.db import transaction
from django.utils import timezone
from datetime import timedelta
import secrets
from django.core.mail import send_mail
from django.conf import settings
import textwrap

from .models import (
    User,
    PetProfile,
    VaccinationRecord,
    MedicalRecord,
    Notification,
    ScheduledNotification,
    UserOTP,
    PendingRegistration,
)
from .serializers import (
    UserSerializer, UserRegistrationSerializer, PetProfileSerializer,
    VaccinationRecordSerializer, MedicalRecordSerializer, NotificationSerializer,
    OTPRequestSerializer, OTPVerifySerializer
)
import logging

logger = logging.getLogger(__name__)


class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = [AllowAny]
    serializer_class = UserRegistrationSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        # If a real user already exists, refuse registration (serializer.validate should have caught this,
        # but double-check here to be safe)
        if User.objects.filter(username=data.get('username')).exists() or User.objects.filter(email=data.get('email')).exists():
            return Response({'error': 'Username or email already exists'}, status=status.HTTP_400_BAD_REQUEST)

        # If a pending registration exists for this email, and its OTP is still valid, return that state
        pending = None
        try:
            pending = PendingRegistration.objects.get(email=data.get('email'))
            if not pending.otp_is_expired() and not pending.used:
                return Response({
                    "requires_verification": True,
                    "pending_id": pending.id,
                }, status=status.HTTP_200_OK)
            else:
                # expired or used - remove it and continue to create a new pending
                pending.delete()
                pending = None
        except PendingRegistration.DoesNotExist:
            pending = None

        # Create a pending registration and send OTP (do not create the real User yet)
        from django.contrib.auth.hashers import make_password

        code = generate_otp(6)
        otp_expires = timezone.now() + timedelta(minutes=10)

        pending = PendingRegistration.objects.create(
            username=data.get('username'),
            email=data.get('email'),
            password=make_password(data.get('password')),
            first_name=data.get('first_name', ''),
            last_name=data.get('last_name', ''),
            phone=data.get('phone', None),
            otp_code=code,
            otp_expires_at=otp_expires,
        )

        try:
            send_otp_email(pending.email, code)
        except Exception:
            logger.exception("Failed to send OTP email to %s", pending.email)

        return Response({
            "requires_verification": True,
            "pending_id": pending.id,
        }, status=status.HTTP_201_CREATED)


def generate_otp(length=6):
    """Generate a numeric OTP of given length using a cryptographically secure generator."""
    digits = '0123456789'
    return ''.join(secrets.choice(digits) for _ in range(length))


def send_otp_email(email, code):
    subject = "Your PawJeevan verification code"
    # Build a clean plain-text message without accidental indentation/leading spaces
    message = textwrap.dedent(f"""
        Your verification code is: {code}

        This code will expire in 10 minutes.

        If you did not request this, please ignore this email.
    """).strip()

    # Also provide a small HTML version for email clients that support it
    html_message = (
        f"<p>Your verification code is: <strong>{code}</strong></p>"
        f"<p>This code will expire in 10 minutes.</p>"
        f"<p>If you did not request this, please ignore this email.</p>"
    )

    # Use a dedicated OTP sender (friendly display name) if configured, otherwise fall back
    # to the global DEFAULT_FROM_EMAIL.
    from_email = getattr(settings, 'OTP_FROM_EMAIL', getattr(settings, 'DEFAULT_FROM_EMAIL', 'no-reply@pawjeevan.local'))
    send_mail(subject, message, from_email, [email], fail_silently=False, html_message=html_message)


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


class SocialLoginView(generics.GenericAPIView):
    """Accepts a Google ID token from the client, verifies it with Google,
    creates or fetches a local user, and returns the app JWT tokens.
    Expected POST body: { "provider": "google", "id_token": "..." }
    """
    permission_classes = [AllowAny]
    parser_classes = [JSONParser]

    @transaction.atomic
    def post(self, request):
        provider = request.data.get("provider")
        if provider != "google":
            return Response({"error": "Unsupported provider"}, status=status.HTTP_400_BAD_REQUEST)

        id_token_str = request.data.get("id_token")
        if not id_token_str:
            return Response({"error": "Missing id_token"}, status=status.HTTP_400_BAD_REQUEST)

        # Verify token
        try:
            from .utils.social import verify_google_id_token
            payload = verify_google_id_token(id_token_str)
        except Exception as e:
            return Response({"error": "Invalid Google token", "details": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        # Extract user info
        email = payload.get("email")
        google_sub = payload.get("sub")
        full_name = payload.get("name") or ""
        picture = payload.get("picture")

        if not email:
            return Response({"error": "Google token did not contain email"}, status=status.HTTP_400_BAD_REQUEST)

        # Find or create user
        user, created = User.objects.get_or_create(email=email, defaults={
            "username": email.split("@")[0],
            "first_name": full_name.split(" ")[0] if full_name else "",
            "last_name": " ".join(full_name.split(" ")[1:]) if full_name and len(full_name.split(" ")) > 1 else "",
        })

        # Optionally update profile picture or other fields. Download and save
        # the Google profile image when:
        #  - the user was just created, or
        #  - the user exists but has no avatar yet.
        if picture and hasattr(user, "avatar") and (created or not bool(user.avatar)):
            try:
                import requests
                from django.core.files.base import ContentFile

                resp = requests.get(picture, timeout=5)
                if resp.status_code == 200 and resp.content:
                    # Determine a safe extension (fallback to jpg)
                    ext = picture.split('?')[0].split('.')[-1].lower()
                    if len(ext) > 4 or '/' in ext or ext == '':
                        ext = 'jpg'
                    filename = f'google_{google_sub}.{ext}'
                    try:
                        user.avatar.save(filename, ContentFile(resp.content), save=True)
                        logger.info("Saved Google avatar for user %s", user.email)
                    except Exception as e:
                        logger.warning("Failed to save avatar for user %s: %s", user.email, e)
            except Exception as e:
                logger.warning("Failed to download Google avatar for %s: %s", user.email, e)

        # Issue tokens using SimpleJWT
        refresh = RefreshToken.for_user(user)
        return Response({
            "user": UserSerializer(user, context={"request": request}).data,
            "tokens": {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
            }
        })


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    filter_backends = [filters.SearchFilter]
    search_fields = ['username', 'first_name', 'last_name']

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    @action(detail=False, methods=["post"], url_path="change-password")
    def change_password(self, request):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')

        if not user.check_password(old_password):
            return Response({"error": "Current password is incorrect"}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()
        return Response({"message": "Password changed successfully"})

    @action(detail=False, methods=["post"], url_path="reset-password")
    def reset_password(self, request):
        """Set a new password for the authenticated user.

        This endpoint is intended to be used after OTP verification which
        issues an authentication token. The client should call verify-otp,
        receive tokens, include the access token in Authorization header,
        then call this endpoint with the new password.
        """
        user = request.user
        new_password = request.data.get('new_password')
        if not new_password or len(new_password) < 6:
            return Response({"error": "Password must be at least 6 characters"}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()
        return Response({"message": "Password reset successfully"})

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
        
        # Check if profile is locked and requesting user is not the owner
        if user.is_profile_locked and user != request.user:
            return Response(
                {"error": "This user's profile is locked. Followers list is private."},
                status=status.HTTP_403_FORBIDDEN
            )
        
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
        
        # Check if profile is locked and requesting user is not the owner
        if user.is_profile_locked and user != request.user:
            return Response(
                {"error": "This user's profile is locked. Following list is private."},
                status=status.HTTP_403_FORBIDDEN
            )
        
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
        # Always filter by owner, even for staff users in the API
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
        queryset = VaccinationRecord.objects.filter(pet__owner=self.request.user)
        pet_id = self.request.query_params.get('pet', None)
        if pet_id is not None:
            queryset = queryset.filter(pet_id=pet_id)
        return queryset

    def perform_create(self, serializer):
        # Verify the pet belongs to the current user
        pet_id = self.request.data.get('pet')
        try:
            pet = PetProfile.objects.get(id=pet_id, owner=self.request.user)
            serializer.save(pet=pet)
            # Schedule vaccination reminder if next_due_date provided
            record = serializer.instance
            if record.next_due_date:
                try:
                    from datetime import datetime, time, timedelta
                    from django.utils import timezone as dj_timezone
                    tz = dj_timezone.get_current_timezone()
                    send_date = record.next_due_date - timedelta(days=1)
                    send_dt = datetime.combine(send_date, time(hour=9, minute=0))
                    send_at = dj_timezone.make_aware(send_dt, tz)
                    now = dj_timezone.now()
                    if send_at > now:
                        exists = ScheduledNotification.objects.filter(
                            user=record.pet.owner,
                            notification_type='vaccination',
                            action_url=f'/pets/{record.pet.id}/vaccinations/{record.id}/',
                            send_at=send_at,
                            processed=False
                        ).exists()
                        if not exists:
                            ScheduledNotification.objects.create(
                                user=record.pet.owner,
                                notification_type='vaccination',
                                title=f'Vaccination due: {record.vaccine_name}',
                                message=f'{record.pet.name} has a vaccination due on {record.next_due_date}.',
                                action_url=f'/pets/{record.pet.id}/',
                                send_at=send_at
                            )
                except Exception:
                    # scheduling failure should not block the API
                    pass
        except PetProfile.DoesNotExist:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You can only add vaccinations to your own pets.")

    def perform_update(self, serializer):
        # Ensure the vaccination record belongs to a pet owned by the current user
        if not serializer.instance.pet.owner == self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You can only update vaccinations of your own pets.")
        serializer.save()
        # After update, (re)schedule vaccination reminder if next_due_date present
        try:
            record = serializer.instance
            if record.next_due_date:
                from datetime import datetime, time, timedelta
                from django.utils import timezone as dj_timezone
                tz = dj_timezone.get_current_timezone()
                send_date = record.next_due_date - timedelta(days=1)
                send_dt = datetime.combine(send_date, time(hour=9, minute=0))
                send_at = dj_timezone.make_aware(send_dt, tz)
                now = dj_timezone.now()
                if send_at > now:
                    exists = ScheduledNotification.objects.filter(
                        user=record.pet.owner,
                        notification_type='vaccination',
                        action_url=f'/pets/{record.pet.id}/vaccinations/{record.id}/',
                        send_at=send_at,
                        processed=False
                    ).exists()
                    if not exists:
                        ScheduledNotification.objects.create(
                            user=record.pet.owner,
                            notification_type='vaccination',
                            title=f'Vaccination due: {record.vaccine_name}',
                            message=f'{record.pet.name} has a vaccination due on {record.next_due_date}.',
                            action_url=f'/pets/{record.pet.id}/',
                            send_at=send_at
                        )
        except Exception:
            pass

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx


class MedicalRecordViewSet(viewsets.ModelViewSet):
    queryset = MedicalRecord.objects.all()
    serializer_class = MedicalRecordSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = MedicalRecord.objects.filter(pet__owner=self.request.user)
        pet_id = self.request.query_params.get('pet', None)
        if pet_id is not None:
            queryset = queryset.filter(pet_id=pet_id)
        return queryset

    def perform_create(self, serializer):
        pet_id = self.request.data.get('pet')
        try:
            pet = PetProfile.objects.get(id=pet_id, owner=self.request.user)
            serializer.save(pet=pet)
        except PetProfile.DoesNotExist:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You can only add medical records to your own pets.")

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
        
    @action(detail=True, methods=['post', 'patch'])
    def mark_read(self, request, pk=None):
        """Mark a notification as read"""
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({'status': 'notification marked as read'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read"""
        self.get_queryset().update(is_read=True)
        return Response({'status': 'all notifications marked as read'})


class SendOTPView(generics.GenericAPIView):
    """Request or resend an OTP to a user's email."""
    permission_classes = [AllowAny]
    serializer_class = OTPRequestSerializer

    def post(self, request):
        ser = self.get_serializer(data=request.data)
        ser.is_valid(raise_exception=True)
        email = ser.validated_data.get('email')
        user_id = ser.validated_data.get('user_id')
        # Prefer pending registration for resend. If not found, fall back to existing user.
        pending = None
        try:
            if email:
                pending = PendingRegistration.objects.get(email=email)
            else:
                pending = PendingRegistration.objects.get(id=user_id)
        except PendingRegistration.DoesNotExist:
            pending = None

        if pending:
            code = generate_otp(6)
            expires_at = timezone.now() + timedelta(minutes=10)
            pending.otp_code = code
            pending.otp_expires_at = expires_at
            pending.attempts = 0
            pending.used = False
            pending.save()
            try:
                send_otp_email(pending.email, code)
            except Exception:
                logger.exception('Failed to send OTP email')
                return Response({'error': 'Failed to send OTP'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            return Response({'status': 'otp_sent', 'pending_id': pending.id})

        # Fallback to existing user OTP (legacy flow)
        try:
            if email:
                user = User.objects.get(email=email)
            else:
                user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        code = generate_otp(6)
        expires_at = timezone.now() + timedelta(minutes=10)
        UserOTP.objects.create(user=user, code=code, expires_at=expires_at)
        try:
            send_otp_email(user.email, code)
        except Exception:
            logger.exception('Failed to send OTP email')
            return Response({'error': 'Failed to send OTP'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({'status': 'otp_sent', 'user_id': user.id})


class VerifyOTPView(generics.GenericAPIView):
    """Verify an OTP and activate the user's account."""
    permission_classes = [AllowAny]
    serializer_class = OTPVerifySerializer

    def post(self, request):
        ser = self.get_serializer(data=request.data)
        ser.is_valid(raise_exception=True)
        email = ser.validated_data.get('email')
        user_id = ser.validated_data.get('user_id')
        code = ser.validated_data.get('code')

        # First try pending registration
        pending = None
        try:
            if email:
                pending = PendingRegistration.objects.get(email=email)
            else:
                pending = PendingRegistration.objects.get(id=user_id)
        except PendingRegistration.DoesNotExist:
            pending = None

        if pending:
            if pending.otp_is_expired():
                return Response({'error': 'OTP expired'}, status=status.HTTP_400_BAD_REQUEST)
            if pending.otp_code != code:
                pending.attempts += 1
                pending.save()
                return Response({'error': 'Invalid code'}, status=status.HTTP_400_BAD_REQUEST)

            # Create the real user now using the hashed password stored
            with transaction.atomic():
                user = User(
                    username=pending.username,
                    email=pending.email,
                    first_name=pending.first_name or '',
                    last_name=pending.last_name or '',
                )
                # password is already hashed with make_password
                user.password = pending.password
                user.is_active = True
                user.is_verified = True
                user.save()

                # mark pending registration used and remove it
                pending.used = True
                pending.save()
                try:
                    pending.delete()
                except Exception:
                    pass

                refresh = RefreshToken.for_user(user)
                return Response({
                    'user': UserSerializer(user, context={'request': request}).data,
                    'tokens': {
                        'refresh': str(refresh),
                        'access': str(refresh.access_token),
                    }
                })

        # Fallback: existing user + UserOTP flow
        try:
            if email:
                user = User.objects.get(email=email)
            else:
                user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        # Find latest unused OTP for purpose
        otp_qs = UserOTP.objects.filter(user=user, used=False, purpose='email_verification').order_by('-created_at')
        if not otp_qs.exists():
            return Response({'error': 'No OTP found'}, status=status.HTTP_400_BAD_REQUEST)
        otp = otp_qs.first()

        if otp.is_expired():
            return Response({'error': 'OTP expired'}, status=status.HTTP_400_BAD_REQUEST)

        if otp.code != code:
            otp.attempts += 1
            otp.save()
            return Response({'error': 'Invalid code'}, status=status.HTTP_400_BAD_REQUEST)

        # Successful verification
        otp.used = True
        otp.save()
        user.is_active = True
        user.is_verified = True
        user.save()

        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user, context={'request': request}).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        })