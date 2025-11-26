from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    UserRegistrationView, UserLoginView, UserViewSet,
    PetProfileViewSet, VaccinationRecordViewSet,
    MedicalRecordViewSet, NotificationViewSet, SocialLoginView
)
from .views import SendOTPView, VerifyOTPView

router = DefaultRouter()
router.register(r"profiles", UserViewSet, basename="user")
router.register(r"pets", PetProfileViewSet, basename="pet")
router.register(r"vaccinations", VaccinationRecordViewSet, basename="vaccination")
router.register(r"medical-records", MedicalRecordViewSet, basename="medical-record")
router.register(r"notifications", NotificationViewSet, basename="notification")

urlpatterns = [
    path("register/", UserRegistrationView.as_view(), name="register"),
    path("login/", UserLoginView.as_view(), name="login"),
    path("social-login/", SocialLoginView.as_view(), name="social_login"),
    path("send-otp/", SendOTPView.as_view(), name="send_otp"),
    path("verify-otp/", VerifyOTPView.as_view(), name="verify_otp"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("", include(router.urls)),
]