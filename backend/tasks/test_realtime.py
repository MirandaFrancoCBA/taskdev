from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase

from teams.models import Team, TeamMembership
from .consumers import belongs_to_team
from .models import Task


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
