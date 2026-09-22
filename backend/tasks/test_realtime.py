from unittest.mock import patch

from asgiref.sync import async_to_sync
from channels.testing import WebsocketCommunicator
from django.contrib.auth import get_user_model
from django.test import TestCase, TransactionTestCase
from rest_framework_simplejwt.tokens import AccessToken

from config.asgi import application
from teams.models import Team, TeamMembership
from .consumers import belongs_to_team
from .models import Task
from .realtime import publish_task_event


User = get_user_model()


class RealtimeTaskTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="member", password="pass-12345")
        self.outsider = User.objects.create_user(username="outsider", password="pass-12345")
        self.team = Team.objects.create(name="Ops", created_by=self.user)
        TeamMembership.objects.create(team=self.team, user=self.user, role=TeamMembership.Role.COORDINATOR)

    @patch("tasks.views.publish_task_event")
    def test_creation_publishes_after_commit(self, publish):
        from rest_framework.test import APIClient
        client = APIClient()
        client.force_authenticate(self.user)
        with self.captureOnCommitCallbacks(execute=True):
            response = client.post("/api/tasks/", {"title": "Realtime", "team": self.team.id}, format="json")
        self.assertEqual(response.status_code, 201)
        publish.assert_called_once()
        self.assertEqual(publish.call_args.args[1], "task.created")

    @patch("tasks.views.publish_task_event")
    def test_claim_publishes_after_commit(self, publish):
        from rest_framework.test import APIClient
        task = Task.objects.create(title="Claim me", team=self.team, creator=self.user)
        client = APIClient()
        client.force_authenticate(self.user)
        with self.captureOnCommitCallbacks(execute=True):
            response = client.post(f"/api/tasks/{task.id}/claim/")
        self.assertEqual(response.status_code, 200)
        publish.assert_called_once()
        self.assertEqual(publish.call_args.args[1], "task.claimed")


class WebSocketRuntimeTests(TransactionTestCase):
    reset_sequences = True

    def setUp(self):
        self.user = User.objects.create_user(username="ws-member", password="pass-12345")
        self.outsider = User.objects.create_user(username="ws-outsider", password="pass-12345")
        self.team = Team.objects.create(name="Realtime Ops", created_by=self.user)
        TeamMembership.objects.create(team=self.team, user=self.user, role=TeamMembership.Role.COORDINATOR)
        self.task = Task.objects.create(title="Observe me", team=self.team, creator=self.user)

    def test_member_receives_task_event_over_websocket(self):
        async_to_sync(self._member_receives_event)()

    async def _member_receives_event(self):
        token = str(AccessToken.for_user(self.user))
        communicator = WebsocketCommunicator(application, f"/ws/teams/{self.team.id}/tasks/?token={token}")
        connected, _ = await communicator.connect()
        self.assertTrue(connected)
        await publish_task_event(self.task, "task.updated")
        event = await communicator.receive_json_from(timeout=2)
        self.assertEqual(event["type"], "task.updated")
        self.assertEqual(event["task_id"], self.task.id)
        self.assertEqual(event["team_id"], self.team.id)
        await communicator.disconnect()

    def test_outsider_is_rejected(self):
        async_to_sync(self._outsider_is_rejected)()

    async def _outsider_is_rejected(self):
        token = str(AccessToken.for_user(self.outsider))
        communicator = WebsocketCommunicator(application, f"/ws/teams/{self.team.id}/tasks/?token={token}")
        connected, code = await communicator.connect()
        self.assertFalse(connected)
        self.assertEqual(code, 4403)
