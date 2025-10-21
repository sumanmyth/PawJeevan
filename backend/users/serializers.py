from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, PetProfile, VaccinationRecord, MedicalRecord, Notification


class AbsoluteURLImageField(serializers.ImageField):
    """
    ImageField that returns an absolute URL using request.build_absolute_uri.
    Also supports write for multipart PATCH.
    """
    def to_representation(self, value):
        if not value:
            return None
        url = super().to_representation(value)
        request = self.context.get("request")
        if request is None:
            return url
        return request.build_absolute_uri(url)


class UserSerializer(serializers.ModelSerializer):
    avatar = AbsoluteURLImageField(required=False, allow_null=True)

    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()
    is_following = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id", "username", "email", "first_name", "last_name",
            "phone", "avatar", "bio", "location", "is_verified",
            "followers_count", "following_count", "is_following", "created_at",
        ]
        read_only_fields = ["id", "is_verified", "created_at"]

    def get_followers_count(self, obj):
        return obj.followers.count()

    def get_following_count(self, obj):
        return obj.following.count()

    def get_is_following(self, obj):
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return request.user.following.filter(id=obj.id).exists()
        return False


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ["username", "email", "password", "password2", "first_name", "last_name", "phone"]

    def validate(self, attrs):
        if attrs["password"] != attrs["password2"]:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop("password2")
        user = User.objects.create_user(**validated_data)
        return user


class PetProfileSerializer(serializers.ModelSerializer):
    owner_username = serializers.CharField(source="owner.username", read_only=True)
    age = serializers.SerializerMethodField()
    photo = AbsoluteURLImageField(required=False, allow_null=True)

    class Meta:
        model = PetProfile
        fields = "__all__"
        read_only_fields = ["id", "owner", "created_at", "updated_at"]

    def get_age(self, obj):
        if obj.date_of_birth:
            from datetime import date
            today = date.today()
            years = today.year - obj.date_of_birth.year
            if (today.month, today.day) < (obj.date_of_birth.month, obj.date_of_birth.day):
                years -= 1
            return years
        return None


class VaccinationRecordSerializer(serializers.ModelSerializer):
    pet_name = serializers.CharField(source="pet.name", read_only=True)

    class Meta:
        model = VaccinationRecord
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at"]


class MedicalRecordSerializer(serializers.ModelSerializer):
    pet_name = serializers.CharField(source="pet.name", read_only=True)

    class Meta:
        model = MedicalRecord
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at"]


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = "__all__"
        read_only_fields = ["id", "user", "created_at"]