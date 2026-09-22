from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from teams.models import Team, TeamMembership
from .models import Task

User = get_user_model()


class TaskApiTests(APITestCase):
    def setUp(self):
        self.coordinator = User.objects.create_user(username="coord", password="pass-12345")
        self.member = User.objects.create_user(username="member", password="pass-12345")
        self.outsider = User.objects.create_user(username="outsider", password="pass-12345")
        self.team = Team.objects.create(name="Operations", created_by=self.coordinator)
        TeamMembership.objects.create(team=self.team, user=self.coordinator, role=TeamMembership.Role.COORDINATOR)
        TeamMembership.objects.create(team=self.team, user=self.member)

    def test_member_can_create_unassigned_task(self):
        self.client.force_authenticate(self.member)
        response = self.client.post("/api/tasks/", {"title": "Prepare shipment", "team": self.team.id, "priority": "high"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNone(response.data["assignee"])

    def test_outsider_cannot_create_task_for_team(self):
        self.client.force_authenticate(self.outsider)
        response = self.client.post("/api/tasks/", {"title": "No access", "team": self.team.id}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_assignee_must_belong_to_team(self):
        self.client.force_authenticate(self.coordinator)
        response = self.client.post("/api/tasks/", {"title": "Invalid assignment", "team": self.team.id, "assignee": self.outsider.id}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_pool_returns_only_pending_unassigned_tasks(self):
        Task.objects.create(title="Available", team=self.team, creator=self.coordinator)
        Task.objects.create(title="Assigned", team=self.team, creator=self.coordinator, assignee=self.member)
        self.client.force_authenticate(self.member)
        response = self.client.get(f"/api/tasks/?team={self.team.id}&pool=true")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["title"], "Available")

    def test_outsider_cannot_read_task(self):
        task = Task.objects.create(title="Private", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.outsider)
        response = self.client.get(f"/api/tasks/{task.id}/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
