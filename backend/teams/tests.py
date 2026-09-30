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


    def test_coordinator_can_change_member_role(self):
        team = Team.objects.create(name="Operations", created_by=self.coordinator)
        TeamMembership.objects.create(team=team, user=self.coordinator, role=TeamMembership.Role.COORDINATOR)
        membership = TeamMembership.objects.create(team=team, user=self.member)
        self.authenticate(self.coordinator)
        response = self.client.patch(
            f"/api/teams/{team.id}/members/{membership.id}/",
            {"role": TeamMembership.Role.COORDINATOR},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        membership.refresh_from_db()
        self.assertEqual(membership.role, TeamMembership.Role.COORDINATOR)

    def test_member_cannot_manage_membership(self):
        team = Team.objects.create(name="Operations", created_by=self.coordinator)
        TeamMembership.objects.create(team=team, user=self.coordinator, role=TeamMembership.Role.COORDINATOR)
        actor = TeamMembership.objects.create(team=team, user=self.member)
        target = TeamMembership.objects.create(team=team, user=self.outsider)
        self.authenticate(self.member)
        response = self.client.patch(
            f"/api/teams/{team.id}/members/{target.id}/",
            {"role": TeamMembership.Role.COORDINATOR},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        actor.refresh_from_db()

    def test_coordinator_can_remove_member_but_not_self(self):
        team = Team.objects.create(name="Operations", created_by=self.coordinator)
        coordinator_membership = TeamMembership.objects.create(team=team, user=self.coordinator, role=TeamMembership.Role.COORDINATOR)
        member_membership = TeamMembership.objects.create(team=team, user=self.member)
        self.authenticate(self.coordinator)

        response = self.client.delete(f"/api/teams/{team.id}/members/{member_membership.id}/")
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(TeamMembership.objects.filter(pk=member_membership.id).exists())

        response = self.client.delete(f"/api/teams/{team.id}/members/{coordinator_membership.id}/")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(TeamMembership.objects.filter(pk=coordinator_membership.id).exists())
