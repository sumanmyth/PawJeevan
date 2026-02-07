"""
Dog Breed Detection ML Service
Uses ResNet50 for breed classification
"""
import os
import json
import numpy as np
import cv2
import tensorflow as tf
from tensorflow.keras.applications.resnet50 import ResNet50, preprocess_input
from tensorflow.keras.preprocessing import image
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense
from django.conf import settings

# Get the directory where this file is located
AI_MODULE_DIR = os.path.dirname(os.path.abspath(__file__))

# Global model variables (loaded once at startup)
_ResNet50_model = None
_ResNet50_feature_extractor = None
_breed_classifier = None
_dog_names = None
_models_loaded = False


def _get_model_paths():
    """Get paths to model files"""
    return {
        'weights': os.path.join(AI_MODULE_DIR, 'ml_models', 'weights.best.Resnet.hdf5'),
        'dog_names': os.path.join(AI_MODULE_DIR, 'data', 'dog_names.json'),
        'haarcascade': os.path.join(AI_MODULE_DIR, 'haarcascades', 'haarcascade_frontalface_alt.xml'),
    }


def load_models():
    """
    Load all ML models into memory.
    This should be called once at Django startup.
    """
    global _ResNet50_model, _ResNet50_feature_extractor, _breed_classifier, _dog_names, _models_loaded
    
    if _models_loaded:
        return True
    
    paths = _get_model_paths()
    
    # Check if weights file exists
    if not os.path.exists(paths['weights']):
        print(f"[BreedDetector] Warning: Model weights not found at {paths['weights']}")
        print("[BreedDetector] Please copy weights.best.Resnet.hdf5 to ai_module/ml_models/")
        return False
    
    try:
        print("[BreedDetector] Loading dog breed names...")
        with open(paths['dog_names'], 'r') as f:
            _dog_names = json.load(f)
        
        print("[BreedDetector] Loading ResNet50 model for dog detection...")
        _ResNet50_model = ResNet50(weights='imagenet')
        
        print("[BreedDetector] Loading ResNet50 model for feature extraction...")
        _ResNet50_feature_extractor = ResNet50(weights='imagenet', include_top=False)
        
        print("[BreedDetector] Building custom dog breed classifier...")
        _breed_classifier = Sequential([
            GlobalAveragePooling2D(input_shape=(1, 1, 2048)),
            Dense(133, activation='softmax')
        ])
        _breed_classifier.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])
        
        print("[BreedDetector] Loading pre-trained weights...")
        _breed_classifier.load_weights(paths['weights'])
        
        _models_loaded = True
        print("[BreedDetector] All models loaded successfully!")
        return True
        
    except Exception as e:
        print(f"[BreedDetector] Error loading models: {e}")
        return False


def is_models_loaded():
    """Check if models are loaded"""
    return _models_loaded


def _path_to_tensor(img_path):
    """Convert image path to 4D tensor for CNN input"""
    img = image.load_img(img_path, target_size=(224, 224))
    x = image.img_to_array(img)
    return np.expand_dims(x, axis=0)


def _ResNet50_predict_labels(img_path):
    """Predict ImageNet labels using ResNet50"""
    img = preprocess_input(_path_to_tensor(img_path))
    return np.argmax(_ResNet50_model.predict(img, verbose=0))


def detect_dog(img_path):
    """
    Returns True if a dog is detected in the image.
    Uses ImageNet labels 151-268 which correspond to dog breeds.
    """
    if not _models_loaded:
        load_models()
    
    prediction = _ResNet50_predict_labels(img_path)
    return (prediction <= 268) and (prediction >= 151)


def detect_face(img_path):
    """
    Returns True if a human face is detected in the image.
    Uses OpenCV Haar Cascade classifier.
    """
    paths = _get_model_paths()
    
    if not os.path.exists(paths['haarcascade']):
        print(f"[BreedDetector] Warning: Haarcascade not found at {paths['haarcascade']}")
        return False
    
    try:
        img = cv2.imread(img_path)
        if img is None:
            return False
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        face_cascade = cv2.CascadeClassifier(paths['haarcascade'])
        faces = face_cascade.detectMultiScale(gray)
        return len(faces) > 0
    except Exception as e:
        print(f"[BreedDetector] Face detection error: {e}")
        return False


def predict_breed(img_path):
    """
    Predict dog breed from image.
    Returns tuple: (breed_name, confidence, all_predictions)
    """
    if not _models_loaded:
        if not load_models():
            return None, 0.0, []
    
    try:
        # Prepare image tensor
        tensor = _path_to_tensor(img_path)
        tensor = preprocess_input(tensor)
        
        # Extract features using ResNet50
        bottleneck_feature = _ResNet50_feature_extractor.predict(tensor, verbose=0)
        
        # Predict breed probabilities
        predictions = _breed_classifier.predict(bottleneck_feature, verbose=0)[0]
        
        # Get top prediction
        top_idx = np.argmax(predictions)
        breed_name = _dog_names[top_idx].replace("_", " ")
        confidence = float(predictions[top_idx])
        
        # Get top 5 predictions for alternatives
        top_indices = np.argsort(predictions)[-5:][::-1]
        all_predictions = [
            {
                "breed": _dog_names[idx].replace("_", " "),
                "confidence": float(predictions[idx])
            }
            for idx in top_indices
        ]
        
        return breed_name, confidence, all_predictions
        
    except Exception as e:
        print(f"[BreedDetector] Prediction error: {e}")
        return None, 0.0, []


def detect_breed_from_image(img_path):
    """
    Main function to detect dog breed from image.
    Returns a dictionary with detection results.
    """
    if not _models_loaded:
        if not load_models():
            return {
                "success": False,
                "error": "ML models not loaded. Please ensure model weights are installed.",
                "detected_breed": None,
                "confidence": 0.0,
                "alternative_breeds": [],
                "is_dog": False,
                "is_human": False,
            }
    
    is_dog = detect_dog(img_path)
    is_human = detect_face(img_path) if not is_dog else False
    
    if is_dog or is_human:
        breed_name, confidence, alternatives = predict_breed(img_path)
        
        if breed_name:
            return {
                "success": True,
                "detected_breed": breed_name,
                "confidence": confidence,
                "alternative_breeds": alternatives[1:],  # Exclude top prediction
                "is_dog": is_dog,
                "is_human": is_human,
                "model_version": "ResNet50-v1.0",
            }
    
    return {
        "success": False,
        "error": "No dog or human face detected in the image.",
        "detected_breed": None,
        "confidence": 0.0,
        "alternative_breeds": [],
        "is_dog": False,
        "is_human": False,
    }
