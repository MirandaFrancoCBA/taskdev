from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError

from teams.models import TeamMembership


@database_sync_to_async
def authenticate_token(raw_token):
    auth = JWTAuthentication()
    try:
        validated = auth.get_validated_token(raw_token)
        return auth.get_user(validated)
    except (InvalidToken, TokenError):
        return None


@database_sync_to_async
def belongs_to_team(user, team_id):
    return TeamMembership.objects.filter(user=user, team_id=team_id).exists()


def websocket_token(scope):
    # Prefer the WebSocket subprotocol so credentials are not placed in URLs,
    # reverse-proxy logs, browser history, or referrer-like diagnostics.
    subprotocols = scope.get("subprotocols") or []
    if len(subprotocols) >= 2 and subprotocols[0] == "taskdev.jwt":
        return subprotocols[1], "taskdev.jwt"

    # Temporary compatibility path for older clients during the v1.1 rollout.
    query = parse_qs(scope.get("query_string", b"").decode())
    tokens = query.get("token")
    return (tokens[0], None) if tokens else (None, None)


class TeamTaskConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        self.team_id = self.scope["url_route"]["kwargs"]["team_id"]
        token, accepted_subprotocol = websocket_token(self.scope)
        user = await authenticate_token(token) if token else None
        if not user or not await belongs_to_team(user, self.team_id):
            await self.close(code=4403)
            return
        self.scope["user"] = user
        self.group_name = f"team_{self.team_id}"
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept(subprotocol=accepted_subprotocol)

    async def disconnect(self, close_code):
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def task_event(self, event):
        await self.send_json({
            "type": event["event"],
            "task_id": event["task_id"],
            "team_id": event["team_id"],
            "status": event["status"],
            "assignee_id": event["assignee_id"],
        })
