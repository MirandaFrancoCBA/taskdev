from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Team, TeamMembership

User = get_user_model()


class TeamApiTests(APITestCase):
    def setUp(self):
        self.coordinator = User.objects.create_user(username="coord", password="strong-pass-123")
        self.member = User.objects.create_user(username="member", password="strong-pass-123")
        self.outsider = User.objects.create_user(username="outsider", password="strong-pass-123")

    def authenticate(self, user):
        self.client.force_authenticate(user=user)

    def test_creator_becomes_coordinator(self):
        self.authenticate(self.coordinator)
        response = self.client.post("/api/teams/", {"name": "Operations"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        team = Team.objects.get(pk=response.data["id"])
        self.assertTrue(team.memberships.filter(user=self.coordinator, role=TeamMembership.Role.COORDINATOR).exists())

    def test_member_cannot_rename_team(self):
        team = Team.objects.create(name="Operations", created_by=self.coordinator)
        TeamMembership.objects.create(team=team, user=self.member)
        self.authenticate(self.member)
        response = self.client.patch(f"/api/teams/{team.id}/", {"name": "Changed"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_outsider_cannot_read_team(self):
        team = Team.objects.create(name="Operations", created_by=self.coordinator)
        TeamMembership.objects.create(team=team, user=self.coordinator, role=TeamMembership.Role.COORDINATOR)
        self.authenticate(self.outsider)
        response = self.client.get(f"/api/teams/{team.id}/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_coordinator_can_add_member(self):
        team = Team.objects.create(name="Operations", created_by=self.coordinator)
        TeamMembership.objects.create(team=team, user=self.coordinator, role=TeamMembership.Role.COORDINATOR)
        self.authenticate(self.coordinator)
        response = self.client.post(f"/api/teams/{team.id}/members/", {"user": self.member.id, "role": "member"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(team.memberships.filter(user=self.member).exists())
