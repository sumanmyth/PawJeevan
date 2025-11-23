from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response


@api_view(['GET'])
@permission_classes([AllowAny])
def google_config_view(request):
    """Return non-secret frontend configuration values.

    Example response: {"google_client_id": "..."}
    """
    return Response({
        'google_client_id': settings.GOOGLE_CLIENT_ID or ''
    })
