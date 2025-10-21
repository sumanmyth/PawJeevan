# backend/ai_module/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
import time

from .models import (
    BreedDetection, DiseaseDetection, DietRecommendation,
    ChatSession, ChatMessage, PhotoEnhancement
)
from .serializers import (
    BreedDetectionSerializer, DiseaseDetectionSerializer, DietRecommendationSerializer,
    ChatSessionSerializer, ChatMessageSerializer, PhotoEnhancementSerializer
)


class BreedDetectionViewSet(viewsets.ModelViewSet):
    queryset = BreedDetection.objects.all()
    serializer_class = BreedDetectionSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        return BreedDetection.objects.filter(user=self.request.user)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    def create(self, request, *args, **kwargs):
        start = time.time()
        if "image" not in request.FILES:
            return Response({"error": "No image provided"}, status=400)

        det = BreedDetection.objects.create(user=request.user, image=request.FILES["image"])

        # TODO: integrate real ML model
        mock = {
            "detected_breed": "Golden Retriever",
            "confidence": 0.89,
            "alternative_breeds": [
                {"breed": "Labrador Retriever", "confidence": 0.72},
                {"breed": "Yellow Labrador", "confidence": 0.65},
            ],
            "model_version": "v1.0-mock",
        }
        det.detected_breed = mock["detected_breed"]
        det.confidence = mock["confidence"]
        det.alternative_breeds = mock["alternative_breeds"]
        det.model_version = mock["model_version"]
        det.processing_time = time.time() - start
        det.save()

        ser = self.get_serializer(det)
        return Response(
            {
                **ser.data,
                "message": "TODO: Integrate actual breed detection ML model",
                "note": "Currently returning mock data for demonstration",
            },
            status=201,
        )


class DiseaseDetectionViewSet(viewsets.ModelViewSet):
    queryset = DiseaseDetection.objects.all()
    serializer_class = DiseaseDetectionSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        return DiseaseDetection.objects.filter(user=self.request.user)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    def create(self, request, *args, **kwargs):
        start = time.time()
        if "image" not in request.FILES:
            return Response({"error": "No image provided"}, status=400)

        disease_type = request.data.get("disease_type", "general")
        pet_id = request.data.get("pet_id")

        det = DiseaseDetection.objects.create(
            user=request.user,
            image=request.FILES["image"],
            disease_type=disease_type,
            pet_id=pet_id if pet_id else None
        )

        # TODO: integrate real ML
        mock_results = {
            "skin": {
                "detected_disease": "Mild Dermatitis",
                "confidence": 0.75,
                "severity": "low",
                "recommendations": "Keep area clean/dry. Apply ointment. Monitor 3-5 days.",
                "should_see_vet": False,
            },
            "eye": {
                "detected_disease": "Conjunctivitis",
                "confidence": 0.82,
                "severity": "medium",
                "recommendations": "Clean with warm water. Use eye drops. Avoid irritants.",
                "should_see_vet": True,
            },
            "ear": {
                "detected_disease": "Ear Mites",
                "confidence": 0.88,
                "severity": "medium",
                "recommendations": "Clean ears gently. Use drops. See vet if persists.",
                "should_see_vet": True,
            },
            "general": {
                "detected_disease": "Healthy - No Issues Detected",
                "confidence": 0.92,
                "severity": "low",
                "recommendations": "Pet appears healthy. Continue regular care.",
                "should_see_vet": False,
            },
        }
        result = mock_results.get(disease_type, mock_results["general"])

        det.detected_disease = result["detected_disease"]
        det.confidence = result["confidence"]
        det.severity = result["severity"]
        det.recommendations = result["recommendations"]
        det.should_see_vet = result["should_see_vet"]
        det.processing_time = time.time() - start
        det.save()

        ser = self.get_serializer(det)
        return Response(
            {
                **ser.data,
                "message": "TODO: Integrate actual disease detection ML model",
                "note": "Currently returning mock data for demonstration",
            },
            status=201,
        )


class DietRecommendationViewSet(viewsets.ModelViewSet):
    queryset = DietRecommendation.objects.all()
    serializer_class = DietRecommendationSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def get_queryset(self):
        return DietRecommendation.objects.filter(user=self.request.user)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    def create(self, request, *args, **kwargs):
        pet_id = request.data.get("pet_id")
        if not pet_id:
            return Response({"error": "pet_id is required"}, status=400)

        from users.models import PetProfile
        try:
            pet = PetProfile.objects.get(id=pet_id, owner=request.user)
        except PetProfile.DoesNotExist:
            return Response({"error": "Pet not found"}, status=404)

        # Simple mock recommendation
        age = pet.age or 1
        weight = float(pet.weight) if pet.weight else 1.0
        daily_calories = int(weight * 30 + 70)
        if age < 1:
            daily_calories = int(daily_calories * 1.5)
        elif age > 7:
            daily_calories = int(daily_calories * 0.9)

        rec = DietRecommendation.objects.create(
            user=request.user,
            pet=pet,
            recommended_diet=(
                f"Based on {pet.name} ({pet.breed}, {age}y, {weight}kg): "
                f"Daily calories ~{daily_calories} kcal. Balanced meals, fresh water."
            ),
            daily_calories=daily_calories,
            feeding_frequency="3-4 times daily" if age < 1 else "2 times daily",
            food_types=["Premium dry food", "Wet food", "Natural treats"],
            special_considerations=request.data.get("special_considerations", ""),
            allergies=request.data.get("allergies", ""),
            health_conditions=request.data.get("health_conditions", ""),
            recommended_products=[]
        )

        ser = self.get_serializer(rec)
        return Response(
            {
                **ser.data,
                "message": "TODO: Integrate AI model for personalized diets",
                "note": "Current result uses a simple formula"
            },
            status=201
        )


class ChatSessionViewSet(viewsets.ModelViewSet):
    queryset = ChatSession.objects.all()
    serializer_class = ChatSessionSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def get_queryset(self):
        return ChatSession.objects.filter(user=self.request.user).order_by("-updated_at")

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    def create(self, request, *args, **kwargs):
        title = request.data.get("title", "New Pet Care Chat")
        session = ChatSession.objects.create(user=request.user, title=title)
        ChatMessage.objects.create(
            session=session,
            role="assistant",
            content=(
                "Hello! I'm your AI Pet Care Assistant 🐾\n"
                "I can help with health, nutrition, training, and more. How can I help?"
            ),
        )
        ser = self.get_serializer(session)
        return Response(ser.data, status=201)

    @action(detail=True, methods=["post"])
    def send_message(self, request, pk=None):
        session = self.get_object()
        message = (request.data.get("message") or "").strip()
        if not message:
            return Response({"error": "message is required"}, status=400)

        user_msg = ChatMessage.objects.create(session=session, role="user", content=message)

        # TODO: integrate OpenAI/LLM. For now, keyword-based reply:
        lower = message.lower()
        if any(k in lower for k in ["food", "diet", "eat"]):
            reply = ("For a balanced diet, use high-quality food matching age and breed. "
                     "Control portions and provide fresh water. Avoid chocolate/onions/grapes.")
        elif any(k in lower for k in ["train", "behavior"]):
            reply = ("Use positive reinforcement, be consistent, keep sessions short, "
                     "and start with sit/stay/come. Avoid punishment.")
        elif any(k in lower for k in ["health", "sick", "vet"]):
            reply = ("I can give general advice, but for specific symptoms please consult a vet. "
                     "Watch for appetite loss, lethargy, vomiting, breathing issues.")
        else:
            reply = ("I can help with pet care, nutrition, training, grooming, and more! "
                     "What would you like to know?")

        ai_msg = ChatMessage.objects.create(session=session, role="assistant", content=reply)
        ser_user = ChatMessageSerializer(user_msg, context={"request": request})
        ser_ai = ChatMessageSerializer(ai_msg, context={"request": request})
        session.save()  # updates updated_at

        return Response({
            "user_message": ser_user.data,
            "ai_message": ser_ai.data,
            "message": "TODO: Integrate with an LLM provider",
            "note": "Mock keyword-based response"
        })


class PhotoEnhancementViewSet(viewsets.ModelViewSet):
    queryset = PhotoEnhancement.objects.all()
    serializer_class = PhotoEnhancementSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        return PhotoEnhancement.objects.filter(user=self.request.user).order_by("-created_at")

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    def create(self, request, *args, **kwargs):
        if "image" not in request.FILES:
            return Response({"error": "No image provided"}, status=400)

        enh = PhotoEnhancement.objects.create(
            user=request.user,
            original_image=request.FILES["image"],
            enhancement_type=request.data.get("enhancement_type", "enhance")
        )

        # TODO: plug actual image processing
        enh.enhanced_image = enh.original_image
        enh.processing_time = 0.2
        enh.parameters = request.data.get("parameters", {})
        enh.save()

        ser = self.get_serializer(enh)
        return Response(
            {
                **ser.data,
                "message": "TODO: Integrate image enhancement model",
                "note": "Returning original as enhanced"
            },
            status=201
        )