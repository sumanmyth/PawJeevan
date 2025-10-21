from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserRegistrationView, UserLoginView, UserViewSet,
    PetProfileViewSet, VaccinationRecordViewSet,
    MedicalRecordViewSet, NotificationViewSet
)

router = DefaultRouter()
router.register(r"profiles", UserViewSet, basename="user")
router.register(r"pets", PetProfileViewSet, basename="pet")
router.register(r"vaccinations", VaccinationRecordViewSet, basename="vaccination")
router.register(r"medical-records", MedicalRecordViewSet, basename="medical-record")
router.register(r"notifications", NotificationViewSet, basename="notification")

urlpatterns = [
    path("register/", UserRegistrationView.as_view(), name="register"),
    path("login/", UserLoginView.as_view(), name="login"),
    path("", include(router.urls)),
]