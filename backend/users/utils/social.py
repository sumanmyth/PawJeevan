from django.conf import settings
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests


def verify_google_id_token(token: str):
    """Verify a Google ID token and return the payload on success.

    Returns payload dict containing at least 'email', 'sub', 'name', 'picture'
    Raises ValueError on invalid token.
    """
    if not token:
        raise ValueError("No token provided")

    # Prepare allowed audiences: prefer explicit allowed list from settings
    audiences = []
    if hasattr(settings, 'GOOGLE_ALLOWED_CLIENT_IDS') and settings.GOOGLE_ALLOWED_CLIENT_IDS:
        audiences = list(settings.GOOGLE_ALLOWED_CLIENT_IDS)
    else:
        raw_aud = settings.GOOGLE_CLIENT_ID or ""
        audiences = [a.strip() for a in raw_aud.split(",") if a.strip()]

    request = google_requests.Request()
    try:
        # If we have multiple audiences, pass the list; otherwise pass the single value
        aud_param = audiences if len(audiences) > 1 else (audiences[0] if audiences else None)
        payload = id_token.verify_oauth2_token(token, request, aud_param)
        return payload
    except ValueError as err:
        # Try to decode without audience to expose token audience for better diagnostics
        try:
            payload = id_token.verify_oauth2_token(token, request, None)
            token_aud = payload.get("aud")
            raise ValueError(f"Invalid Google token details: Token has wrong audience: {token_aud!r}, expected one of {audiences!r}")
        except Exception:
            # Re-raise the original error if we couldn't decode
            raise ValueError(f"Invalid Google token: {err}")
