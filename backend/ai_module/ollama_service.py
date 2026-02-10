"""
Ollama/Llama 3.2 integration service for AI chatbot and disease detection.
Communicates with the local Ollama API.
"""
import requests
import base64
import json
from pathlib import Path

# Ollama API endpoint (local)
OLLAMA_BASE_URL = "http://localhost:11434"
OLLAMA_MODEL = "llama3.2:latest"

# System prompts
PET_ASSISTANT_SYSTEM_PROMPT = """You are PawJeevan AI, a friendly and knowledgeable pet care assistant. You help pet owners with:
- Pet health questions and general wellness advice
- Nutrition and diet recommendations
- Training and behavior tips
- Grooming and care guidance
- Emergency first aid basics

Important guidelines:
1. Always be warm, friendly, and use occasional pet-related emojis 🐾🐕🐈
2. For serious health concerns, always recommend consulting a veterinarian
3. Never prescribe medications or make definitive medical diagnoses
4. Base your advice on established veterinary science
5. Keep responses concise but helpful (2-3 paragraphs max)
6. If unsure, acknowledge it and suggest professional consultation

You're chatting with a pet owner who loves their furry friend!"""

DISEASE_ANALYSIS_SYSTEM_PROMPT = """You are a veterinary AI assistant analyzing pet health images. Your role is to:
1. Describe what you observe in the image
2. Identify potential health concerns (skin issues, eye problems, ear conditions, etc.)
3. Assess the apparent severity (low, medium, high)
4. Provide care recommendations
5. Advise whether a vet visit is recommended

IMPORTANT DISCLAIMERS:
- You are NOT a substitute for professional veterinary care
- Your analysis is preliminary and educational only
- Always recommend vet consultation for concerning symptoms
- Be cautious and err on the side of recommending professional care

Format your response as JSON with these fields:
{
    "observation": "What you see in the image",
    "potential_condition": "Most likely condition or 'Appears Healthy'",
    "confidence": 0.0-1.0,
    "severity": "low|medium|high",
    "recommendations": "Care advice",
    "should_see_vet": true/false,
    "reasoning": "Brief explanation"
}"""


def check_ollama_available() -> bool:
    """Check if Ollama service is running."""
    try:
        response = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=2)
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False


def get_available_models() -> list:
    """Get list of available Ollama models."""
    try:
        response = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
        if response.status_code == 200:
            data = response.json()
            return [m["name"] for m in data.get("models", [])]
    except requests.exceptions.RequestException:
        pass
    return []


def chat_with_ollama(
    messages: list,
    system_prompt: str = PET_ASSISTANT_SYSTEM_PROMPT,
    model: str = OLLAMA_MODEL,
) -> dict:
    """
    Send a chat request to Ollama.
    
    Args:
        messages: List of {"role": "user"|"assistant", "content": "..."}
        system_prompt: System prompt for the model
        model: Model name to use
        
    Returns:
        dict with "success", "content", "error"
    """
    if not check_ollama_available():
        return {
            "success": False,
            "content": "",
            "error": "Ollama service is not running. Please start Ollama."
        }
    
    # Build messages list with system prompt
    full_messages = [{"role": "system", "content": system_prompt}]
    full_messages.extend(messages)
    
    try:
        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/chat",
            json={
                "model": model,
                "messages": full_messages,
                "stream": False,
                "options": {
                    "temperature": 0.7,
                    "top_p": 0.9,
                }
            },
            timeout=120  # 2 minute timeout for slower responses
        )
        
        if response.status_code == 200:
            data = response.json()
            content = data.get("message", {}).get("content", "")
            return {
                "success": True,
                "content": content,
                "error": None,
                "total_duration": data.get("total_duration"),
                "eval_count": data.get("eval_count"),
            }
        else:
            return {
                "success": False,
                "content": "",
                "error": f"Ollama returned status {response.status_code}"
            }
            
    except requests.exceptions.Timeout:
        return {
            "success": False,
            "content": "",
            "error": "Request timed out. The model may be loading."
        }
    except requests.exceptions.RequestException as e:
        return {
            "success": False,
            "content": "",
            "error": f"Connection error: {str(e)}"
        }


def analyze_pet_image(
    image_path: str,
    disease_type: str = "general",
    additional_context: str = "",
) -> dict:
    """
    Analyze a pet image for potential health issues using Llama 3.2 vision.
    
    Args:
        image_path: Path to the image file
        disease_type: Type of analysis (skin, eye, ear, dental, general)
        additional_context: Any additional context from the user
        
    Returns:
        dict with analysis results
    """
    if not check_ollama_available():
        return {
            "success": False,
            "error": "Ollama service is not running. Please start Ollama."
        }
    
    # Read and encode the image
    try:
        image_path = Path(image_path)
        if not image_path.exists():
            return {"success": False, "error": "Image file not found"}
            
        with open(image_path, "rb") as f:
            image_data = base64.b64encode(f.read()).decode("utf-8")
    except Exception as e:
        return {"success": False, "error": f"Failed to read image: {str(e)}"}
    
    # Build the analysis prompt
    type_prompts = {
        "skin": "Focus on analyzing the skin/coat for issues like rashes, hot spots, hair loss, bumps, or irritation.",
        "eye": "Focus on analyzing the eyes for issues like redness, discharge, cloudiness, swelling, or infection signs.",
        "ear": "Focus on analyzing the ears for issues like redness, discharge, odor indicators, swelling, or mites.",
        "dental": "Focus on analyzing the mouth/teeth for issues like tartar, gum disease, broken teeth, or bad breath signs.",
        "general": "Perform a general health assessment based on what's visible in the image.",
    }
    
    focus_prompt = type_prompts.get(disease_type, type_prompts["general"])
    
    user_prompt = f"""Please analyze this pet image for health concerns.

Analysis focus: {disease_type.upper()}
{focus_prompt}

{f"Additional context from owner: {additional_context}" if additional_context else ""}

Provide your analysis in the JSON format specified."""

    try:
        # Use llama3.2-vision if available, otherwise fall back to base model
        # Note: For vision, we need a vision-capable model
        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/chat",
            json={
                "model": model if (model := "llama3.2-vision:latest") in get_available_models() else OLLAMA_MODEL,
                "messages": [
                    {"role": "system", "content": DISEASE_ANALYSIS_SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": user_prompt,
                        "images": [image_data]  # Base64 encoded image
                    }
                ],
                "stream": False,
                "options": {
                    "temperature": 0.3,  # Lower temp for more consistent analysis
                }
            },
            timeout=180  # 3 minute timeout for image analysis
        )
        
        if response.status_code == 200:
            data = response.json()
            content = data.get("message", {}).get("content", "")
            
            # Try to parse as JSON
            try:
                # Find JSON in the response
                json_start = content.find("{")
                json_end = content.rfind("}") + 1
                if json_start >= 0 and json_end > json_start:
                    analysis = json.loads(content[json_start:json_end])
                    return {
                        "success": True,
                        "detected_disease": analysis.get("potential_condition", "Unknown"),
                        "confidence": float(analysis.get("confidence", 0.5)),
                        "severity": analysis.get("severity", "low"),
                        "recommendations": analysis.get("recommendations", ""),
                        "should_see_vet": analysis.get("should_see_vet", True),
                        "observation": analysis.get("observation", ""),
                        "reasoning": analysis.get("reasoning", ""),
                        "raw_response": content,
                    }
            except json.JSONDecodeError:
                pass
            
            # If JSON parsing fails, return raw response with defaults
            return {
                "success": True,
                "detected_disease": "Analysis Complete",
                "confidence": 0.7,
                "severity": "low",
                "recommendations": content,
                "should_see_vet": True,
                "observation": content,
                "raw_response": content,
            }
        else:
            return {
                "success": False,
                "error": f"Ollama returned status {response.status_code}"
            }
            
    except requests.exceptions.Timeout:
        return {
            "success": False,
            "error": "Analysis timed out. Please try again."
        }
    except requests.exceptions.RequestException as e:
        return {
            "success": False,
            "error": f"Connection error: {str(e)}"
        }


def analyze_pet_image_text_only(
    disease_type: str = "general",
    symptoms: str = "",
    pet_info: str = "",
) -> dict:
    """
    Analyze pet health based on text description (when vision model not available).
    
    Args:
        disease_type: Type of issue
        symptoms: Description of symptoms
        pet_info: Pet breed, age, etc.
        
    Returns:
        dict with analysis results
    """
    prompt = f"""A pet owner is concerned about their pet's health and is asking for guidance.

Pet Information: {pet_info if pet_info else "Not specified"}
Area of Concern: {disease_type}
Symptoms/Description: {symptoms if symptoms else "Not specified"}

Based on this information, provide:
1. Possible conditions that might cause these symptoms
2. Severity assessment
3. Home care recommendations
4. Whether they should see a vet

Respond in JSON format:
{{
    "potential_condition": "Most likely condition",
    "confidence": 0.0-1.0,
    "severity": "low|medium|high",
    "recommendations": "Care advice",
    "should_see_vet": true/false,
    "reasoning": "Brief explanation"
}}"""

    result = chat_with_ollama(
        messages=[{"role": "user", "content": prompt}],
        system_prompt=DISEASE_ANALYSIS_SYSTEM_PROMPT,
    )
    
    if result["success"]:
        content = result["content"]
        try:
            json_start = content.find("{")
            json_end = content.rfind("}") + 1
            if json_start >= 0 and json_end > json_start:
                analysis = json.loads(content[json_start:json_end])
                return {
                    "success": True,
                    "detected_disease": analysis.get("potential_condition", "Unknown"),
                    "confidence": float(analysis.get("confidence", 0.5)),
                    "severity": analysis.get("severity", "low"),
                    "recommendations": analysis.get("recommendations", ""),
                    "should_see_vet": analysis.get("should_see_vet", True),
                    "reasoning": analysis.get("reasoning", ""),
                }
        except json.JSONDecodeError:
            pass
        
        return {
            "success": True,
            "detected_disease": "Analysis Complete",
            "confidence": 0.6,
            "severity": "medium",
            "recommendations": content,
            "should_see_vet": True,
        }
    
    return result
