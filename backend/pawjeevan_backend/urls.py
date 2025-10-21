from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/users/", include("users.urls")),
    path("api/store/", include("store.urls")),
    path("api/community/", include("community.urls")),
    path("api/ai/", include("ai_module.urls")),
    path("api/admin/", include("admin_panel.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)