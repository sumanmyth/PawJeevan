# backend/ai_module/serializers.py
from rest_framework import serializers
from users.serializers import AbsoluteURLImageField
from .models import (
    BreedDetection, DiseaseDetection, DietRecommendation,
    ChatSession, ChatMessage, PhotoEnhancement
)

class BreedDetectionSerializer(serializers.ModelSerializer):
    image = AbsoluteURLImageField()
    class Meta:
        model = BreedDetection
        fields = "__all__"
        read_only_fields = [
            "user", "detected_breed", "confidence",
            "alternative_breeds", "model_version",
            "processing_time", "created_at"
        ]


class DiseaseDetectionSerializer(serializers.ModelSerializer):
    image = AbsoluteURLImageField()
    class Meta:
        model = DiseaseDetection
        fields = "__all__"
        read_only_fields = [
            "user", "detected_disease", "confidence",
            "severity", "recommendations", "should_see_vet",
            "model_version", "processing_time", "created_at"
        ]


class DietRecommendationSerializer(serializers.ModelSerializer):
    # No image fields here; just serialize all fields
    class Meta:
        model = DietRecommendation
        fields = "__all__"
        read_only_fields = ["user", "created_at"]


class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = "__all__"
        read_only_fields = ["session", "created_at"]


class ChatSessionSerializer(serializers.ModelSerializer):
    messages = ChatMessageSerializer(many=True, read_only=True)
    messages_count = serializers.SerializerMethodField()

    class Meta:
        model = ChatSession
        fields = "__all__"
        read_only_fields = ["user", "created_at", "updated_at"]

    def get_messages_count(self, obj):
        return obj.messages.count()


class PhotoEnhancementSerializer(serializers.ModelSerializer):
    original_image = AbsoluteURLImageField()
    enhanced_image = AbsoluteURLImageField(required=False, allow_null=True)

    class Meta:
        model = PhotoEnhancement
        fields = "__all__"
        read_only_fields = ["user", "processing_time", "created_at"]