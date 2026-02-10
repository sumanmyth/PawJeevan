# backend/ai_module/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
import time
import os

from .models import (
    BreedDetection, DiseaseDetection, DietRecommendation,
    ChatSession, ChatMessage, PhotoEnhancement
)
from .serializers import (
    BreedDetectionSerializer, DiseaseDetectionSerializer, DietRecommendationSerializer,
    ChatSessionSerializer, ChatMessageSerializer, PhotoEnhancementSerializer
)

# Import the breed detector ML service
from .breed_detector import detect_breed_from_image, load_models, is_models_loaded


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

        # Save the uploaded image
        det = BreedDetection.objects.create(user=request.user, image=request.FILES["image"])

        # Get the absolute path to the saved image
        img_path = det.image.path

        # Run ML breed detection
        try:
            result = detect_breed_from_image(img_path)
            
            if result["success"]:
                det.detected_breed = result["detected_breed"]
                det.confidence = result["confidence"]
                det.alternative_breeds = result["alternative_breeds"]
                det.model_version = result.get("model_version", "ResNet50-v1.0")
            else:
                # Detection failed (no dog/human found)
                det.detected_breed = "Unknown"
                det.confidence = 0.0
                det.alternative_breeds = []
                det.model_version = "ResNet50-v1.0"
                
        except Exception as e:
            # Fallback if ML model fails
            det.detected_breed = "Error"
            det.confidence = 0.0
            det.alternative_breeds = []
            det.model_version = "error"
            result = {"success": False, "error": str(e)}

        det.processing_time = time.time() - start
        det.save()

        ser = self.get_serializer(det)
        response_data = {**ser.data}
        
        # Add extra info about detection
        if result.get("success"):
            response_data["is_dog"] = result.get("is_dog", False)
            response_data["is_human"] = result.get("is_human", False)
        else:
            response_data["error"] = result.get("error", "Detection failed")
            
        return Response(response_data, status=201)


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
        symptoms = request.data.get("symptoms", "")

        det = DiseaseDetection.objects.create(
            user=request.user,
            image=request.FILES["image"],
            disease_type=disease_type,
            pet_id=pet_id if pet_id else None
        )

        # Get image path
        img_path = det.image.path
        
        # Try to analyze with Ollama
        from .ollama_service import analyze_pet_image, analyze_pet_image_text_only, check_ollama_available, get_available_models
        
        # Get pet info if available
        pet_info = ""
        if det.pet:
            pet_info = f"{det.pet.breed}, {det.pet.age} years old, {det.pet.weight}kg"
        
        # Check if vision model is available
        available_models = get_available_models()
        has_vision = any("vision" in m.lower() for m in available_models)
        
        if has_vision:
            # Use vision model for image analysis
            result = analyze_pet_image(
                image_path=img_path,
                disease_type=disease_type,
                additional_context=f"Pet info: {pet_info}. Symptoms: {symptoms}" if (pet_info or symptoms) else "",
            )
        elif check_ollama_available():
            # Fall back to text-only analysis
            result = analyze_pet_image_text_only(
                disease_type=disease_type,
                symptoms=symptoms or "Visual inspection requested",
                pet_info=pet_info,
            )
        else:
            # Ollama not available - use mock data
            result = {"success": False, "error": "AI service not available"}
        
        if result.get("success"):
            det.detected_disease = result.get("detected_disease", "Analysis Complete")
            det.confidence = result.get("confidence", 0.7)
            det.severity = result.get("severity", "low")
            det.recommendations = result.get("recommendations", "Please consult a veterinarian for proper diagnosis.")
            det.should_see_vet = result.get("should_see_vet", True)
        else:
            # Fallback mock results if AI fails
            mock_results = {
                "skin": {
                    "detected_disease": "Possible Skin Condition",
                    "confidence": 0.6,
                    "severity": "medium",
                    "recommendations": "Keep area clean and dry. Monitor for changes. If symptoms persist or worsen, consult a veterinarian.",
                    "should_see_vet": True,
                },
                "eye": {
                    "detected_disease": "Eye Concern Detected",
                    "confidence": 0.6,
                    "severity": "medium",
                    "recommendations": "Avoid touching the eye area. Keep clean with sterile saline. Consult a vet if discharge or redness persists.",
                    "should_see_vet": True,
                },
                "ear": {
                    "detected_disease": "Ear Condition Possible",
                    "confidence": 0.6,
                    "severity": "medium",
                    "recommendations": "Do not insert anything into ear canal. Keep ears dry. Consult vet for proper examination.",
                    "should_see_vet": True,
                },
                "general": {
                    "detected_disease": "General Assessment",
                    "confidence": 0.7,
                    "severity": "low",
                    "recommendations": "Continue regular care and monitoring. Consult a vet for any specific concerns.",
                    "should_see_vet": False,
                },
            }
            fallback = mock_results.get(disease_type, mock_results["general"])
            det.detected_disease = fallback["detected_disease"]
            det.confidence = fallback["confidence"]
            det.severity = fallback["severity"]
            det.recommendations = fallback["recommendations"]
            det.should_see_vet = fallback["should_see_vet"]

        det.processing_time = time.time() - start
        det.save()

        ser = self.get_serializer(det)
        return Response(
            {
                **ser.data,
                "ai_powered": result.get("success", False),
                "ollama_available": check_ollama_available(),
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

        # Generate a breed-aware, age-aware, weight-aware recommendation
        from .diet_service import generate_diet_recommendation

        result = generate_diet_recommendation(
            pet,
            request.user,
            allergies=request.data.get("allergies", ""),
            health_conditions=request.data.get("health_conditions", ""),
            special_considerations=request.data.get("special_considerations", ""),
        )

        extra = result.pop("_extra", {})

        rec = DietRecommendation.objects.create(
            user=request.user,
            pet=pet,
            **result,
        )

        ser = self.get_serializer(rec)
        return Response(
            {
                **ser.data,
                **extra,
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

        # Get conversation history for context
        from .ollama_service import chat_with_ollama, check_ollama_available
        
        # Build message history (last 10 messages for context)
        history = list(session.messages.order_by("-created_at")[:10])
        history.reverse()
        
        messages = []
        for msg in history:
            if msg.role in ("user", "assistant"):
                messages.append({"role": msg.role, "content": msg.content})
        
        # Add current message
        messages.append({"role": "user", "content": message})
        
        # Call Ollama
        start = time.time()
        result = chat_with_ollama(messages)
        response_time = time.time() - start
        
        if result["success"]:
            reply = result["content"]
        else:
            # Fallback to simple response if Ollama fails
            reply = (
                f"I apologize, but I'm having trouble connecting to my AI brain right now. 🐾\n\n"
                f"Error: {result.get('error', 'Unknown error')}\n\n"
                f"In the meantime, for pet health questions, please consult your veterinarian. "
                f"I'll be back soon!"
            )

        ai_msg = ChatMessage.objects.create(
            session=session, 
            role="assistant", 
            content=reply,
            response_time=response_time,
        )
        ser_user = ChatMessageSerializer(user_msg, context={"request": request})
        ser_ai = ChatMessageSerializer(ai_msg, context={"request": request})
        session.save()  # updates updated_at

        return Response({
            "user_message": ser_user.data,
            "ai_message": ser_ai.data,
            "ollama_available": check_ollama_available(),
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