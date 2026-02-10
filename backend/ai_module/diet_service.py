"""
Diet recommendation service.
Loads breed-specific diet data from dog_diets.json and combines it with
the user's pet profile (breed, age, weight) and breed-detection history
to generate personalised diet recommendations.
"""
import json
import os
from pathlib import Path

# ---------------------------------------------------------------------------
# Load the diet dataset once at module level
# ---------------------------------------------------------------------------
_DATA_DIR = Path(__file__).resolve().parent / "data"
_DIET_DATA: dict = {}


def _load_diet_data():
    global _DIET_DATA
    if _DIET_DATA:
        return
    diet_path = _DATA_DIR / "dog_diets.json"
    if diet_path.exists():
        with open(diet_path, "r", encoding="utf-8") as f:
            _DIET_DATA = json.load(f)
    else:
        _DIET_DATA = {}


_load_diet_data()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _normalise_breed(breed_name: str) -> str:
    """Convert a human-readable breed name to the key used in our dataset."""
    if not breed_name:
        return ""
    return breed_name.strip().replace(" ", "_")


def _get_size_category(breed_key: str) -> dict | None:
    """Return the size-category dict for a breed, or None."""
    cats = _DIET_DATA.get("size_categories", {})
    for cat_name, cat_data in cats.items():
        if breed_key in cat_data.get("breeds", []):
            return {"name": cat_name, **cat_data}
    return None


def _get_breed_diet(breed_key: str) -> dict | None:
    """Return breed-specific diet tips, or None."""
    return _DIET_DATA.get("breed_specific_diets", {}).get(breed_key)


def _get_age_stage(age_years: float) -> dict:
    """Return age-stage info from the dataset."""
    stages = _DIET_DATA.get("age_adjustments", {})
    if age_years < 1:
        return {"stage": "puppy", **stages.get("puppy", {})}
    elif age_years < 3:
        return {"stage": "young_adult", **stages.get("young_adult", {})}
    elif age_years < 7:
        return {"stage": "adult", **stages.get("adult", {})}
    elif age_years < 10:
        return {"stage": "senior", **stages.get("senior", {})}
    else:
        return {"stage": "geriatric", **stages.get("geriatric", {})}


def _get_weight_status(weight_kg: float, size_cat_name: str | None) -> dict:
    """
    Rough heuristic for weight status based on size category.
    Returns the matching weight-guideline entry.
    """
    ideal_ranges = {
        "toy": (1, 5),
        "small": (5, 10),
        "medium": (10, 25),
        "large": (25, 45),
        "giant": (45, 90),
    }
    guidelines = _DIET_DATA.get("weight_guidelines", {})
    if size_cat_name and size_cat_name in ideal_ranges:
        lo, hi = ideal_ranges[size_cat_name]
        if weight_kg < lo * 0.9:
            return {"status": "underweight", **guidelines.get("underweight", {})}
        elif weight_kg > hi * 1.2:
            return {"status": "obese", **guidelines.get("obese", {})}
        elif weight_kg > hi:
            return {"status": "overweight", **guidelines.get("overweight", {})}
    return {"status": "ideal", **guidelines.get("ideal", {})}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def generate_diet_recommendation(
    pet,
    user,
    *,
    allergies: str = "",
    health_conditions: str = "",
    special_considerations: str = "",
):
    """
    Generate a comprehensive diet recommendation for a pet.

    ``pet`` – a PetProfile model instance (has .breed, .age, .weight, etc.)
    ``user`` – the request user

    Returns a dict ready to be unpacked into DietRecommendation.objects.create().
    """
    _load_diet_data()  # ensure data is available

    breed_raw = pet.breed or ""
    breed_key = _normalise_breed(breed_raw)
    age = pet.age or 1  # years
    weight = float(pet.weight) if pet.weight else 5.0

    # ----- look up breed-detection history for this user ----
    from .models import BreedDetection
    recent_detections = list(
        BreedDetection.objects.filter(user=user)
        .exclude(detected_breed="")
        .order_by("-created_at")[:5]
        .values_list("detected_breed", flat=True)
    )
    # If the pet's breed is empty but we have detection history, use the latest
    if not breed_key and recent_detections:
        breed_key = _normalise_breed(recent_detections[0])
        breed_raw = recent_detections[0]

    # ----- gather data from JSON dataset -----
    size_cat = _get_size_category(breed_key)
    breed_diet = _get_breed_diet(breed_key)
    age_stage = _get_age_stage(age)
    weight_info = _get_weight_status(weight, size_cat["name"] if size_cat else None)

    # ----- calculate daily calories -----
    base_cal_per_kg = (size_cat or {}).get("base_calories_per_kg", 30)
    cal_multiplier = age_stage.get("calorie_multiplier", 1.0)
    weight_adj = weight_info.get("calorie_adjustment", 1.0)
    daily_calories = int(weight * base_cal_per_kg * cal_multiplier * weight_adj)
    # Ensure a sensible minimum
    daily_calories = max(daily_calories, 100)

    # ----- feeding frequency -----
    feeding_freq = age_stage.get(
        "feeding_frequency",
        (size_cat or {}).get("feeding_frequency", "2 times daily"),
    )

    # ----- build food-types list -----
    food_types = []
    if breed_diet:
        food_types = breed_diet.get("recommended_foods", [])
    elif size_cat:
        food_types = ["Premium dry food suited for " + (size_cat.get("name", "") + " breeds"),
                      "Lean protein", "Vegetables", "Fresh water"]
    else:
        food_types = ["High-quality dry kibble", "Lean protein", "Vegetables"]

    # ----- build the recommendation text -----
    lines = []
    lines.append(f"🐾 Diet plan for {pet.name} ({breed_raw or 'Unknown breed'}, "
                 f"{age}y, {weight}kg)")
    lines.append("")

    if size_cat:
        lines.append(f"📏 Size category: {size_cat['name'].title()} "
                     f"({size_cat.get('weight_range', '')})")
    lines.append(f"🎂 Life stage: {age_stage.get('stage', 'adult').replace('_', ' ').title()}")
    lines.append(f"⚖️ Weight status: {weight_info.get('status', 'ideal').title()}")
    lines.append("")

    lines.append(f"🔥 Recommended daily calories: ~{daily_calories} kcal")
    lines.append(f"🍽️ Feeding frequency: {feeding_freq}")
    lines.append("")

    if breed_diet:
        lines.append("📋 Breed-specific tips:")
        lines.append(f"   {breed_diet.get('diet_tips', '')}")
        lines.append("")
        if breed_diet.get("health_notes"):
            lines.append(f"🏥 Health notes: {breed_diet['health_notes']}")
        foods_to_avoid = breed_diet.get("foods_to_avoid", [])
        if foods_to_avoid:
            lines.append(f"🚫 Foods to avoid: {', '.join(foods_to_avoid)}")
        supps = breed_diet.get("supplements", [])
        if supps:
            lines.append(f"💊 Recommended supplements: {', '.join(supps)}")
    else:
        lines.append("ℹ️ No breed-specific data found – using general guidelines.")

    if age_stage.get("notes"):
        lines.append("")
        lines.append(f"📝 Age-stage notes: {age_stage['notes']}")

    if weight_info.get("notes"):
        lines.append(f"📝 Weight notes: {weight_info['notes']}")

    if recent_detections:
        lines.append("")
        lines.append("🔍 Recent breed detections: " + ", ".join(recent_detections[:3]))

    # ----- special considerations passed by user -----
    sc_parts = []
    if special_considerations:
        sc_parts.append(special_considerations)
    if size_cat and size_cat.get("portion_note"):
        sc_parts.append(size_cat["portion_note"])
    special_text = ". ".join(sc_parts)

    # ----- general danger foods -----
    danger_foods = _DIET_DATA.get("general_foods_to_never_feed", [])

    recommended_text = "\n".join(lines)

    return {
        "recommended_diet": recommended_text,
        "daily_calories": daily_calories,
        "feeding_frequency": feeding_freq,
        "food_types": food_types,
        "special_considerations": special_text,
        "allergies": allergies,
        "health_conditions": health_conditions,
        "recommended_products": [],
        # Extra keys returned for the API response (not saved in model)
        "_extra": {
            "size_category": size_cat["name"] if size_cat else None,
            "life_stage": age_stage.get("stage"),
            "weight_status": weight_info.get("status"),
            "breed_specific_available": breed_diet is not None,
            "foods_to_avoid": (breed_diet or {}).get("foods_to_avoid", []) + danger_foods,
            "supplements": (breed_diet or {}).get("supplements", []),
            "recent_detections": recent_detections,
            "age_stage_notes": age_stage.get("notes", ""),
            "weight_notes": weight_info.get("notes", ""),
        },
    }
