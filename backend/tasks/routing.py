from django.urls import path

from .consumers import TeamTaskConsumer

websocket_urlpatterns = [
    path("ws/teams/<int:team_id>/tasks/", TeamTaskConsumer.as_asgi()),
]
