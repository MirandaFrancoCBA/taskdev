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
        self.member2 = User.objects.create_user(username="member2", password="pass-12345")
        self.outsider = User.objects.create_user(username="outsider", password="pass-12345")
        self.team = Team.objects.create(name="Operations", created_by=self.coordinator)
        TeamMembership.objects.create(team=self.team, user=self.coordinator, role=TeamMembership.Role.COORDINATOR)
        TeamMembership.objects.create(team=self.team, user=self.member)
        TeamMembership.objects.create(team=self.team, user=self.member2)

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

    def test_member_can_claim_available_task(self):
        task = Task.objects.create(title="Available", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.member)
        response = self.client.post(f"/api/tasks/{task.id}/claim/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        task.refresh_from_db()
        self.assertEqual(task.assignee, self.member)
        self.assertEqual(task.status, Task.Status.IN_PROGRESS)

    def test_second_claim_returns_conflict(self):
        task = Task.objects.create(title="Available", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.member)
        self.assertEqual(self.client.post(f"/api/tasks/{task.id}/claim/").status_code, status.HTTP_200_OK)
        self.client.force_authenticate(self.member2)
        response = self.client.post(f"/api/tasks/{task.id}/claim/")
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        task.refresh_from_db()
        self.assertEqual(task.assignee, self.member)

    def test_outsider_cannot_claim_task(self):
        task = Task.objects.create(title="Available", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.outsider)
        response = self.client.post(f"/api/tasks/{task.id}/claim/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        task.refresh_from_db()
        self.assertIsNone(task.assignee)

    def test_non_pending_task_cannot_be_claimed(self):
        task = Task.objects.create(title="Blocked", team=self.team, creator=self.coordinator, status=Task.Status.BLOCKED)
        self.client.force_authenticate(self.member)
        response = self.client.post(f"/api/tasks/{task.id}/claim/")
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)


    def test_creation_records_activity(self):
        self.client.force_authenticate(self.member)
        response = self.client.post("/api/tasks/", {"title": "Tracked", "team": self.team.id}, format="json")
        task = Task.objects.get(pk=response.data["id"])
        activity = task.activities.get()
        self.assertEqual(activity.event, "created")
        self.assertEqual(activity.actor, self.member)

    def test_claim_records_activity(self):
        task = Task.objects.create(title="Available", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.member)
        self.client.post(f"/api/tasks/{task.id}/claim/")
        activity = task.activities.get()
        self.assertEqual(activity.event, "claimed")
        self.assertEqual(activity.actor, self.member)
        self.assertEqual(activity.new_value["assignee_id"], self.member.id)

    def test_status_change_records_activity(self):
        task = Task.objects.create(title="Working", team=self.team, creator=self.coordinator, assignee=self.member, status=Task.Status.IN_PROGRESS)
        self.client.force_authenticate(self.member)
        response = self.client.patch(f"/api/tasks/{task.id}/", {"status": "completed"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        activity = task.activities.get()
        self.assertEqual(activity.event, "completed")
        self.assertEqual(activity.previous_value["status"], "in_progress")
        self.assertEqual(activity.new_value["status"], "completed")

    def test_member_can_read_activity_but_outsider_cannot(self):
        task = Task.objects.create(title="Tracked", team=self.team, creator=self.coordinator)
        from .models import TaskActivity
        TaskActivity.objects.create(task=task, actor=self.coordinator, event=TaskActivity.Event.CREATED)
        self.client.force_authenticate(self.member)
        self.assertEqual(self.client.get(f"/api/tasks/{task.id}/activity/").status_code, status.HTTP_200_OK)
        self.client.force_authenticate(self.outsider)
        response = self.client.get(f"/api/tasks/{task.id}/activity/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)


    def test_member_cannot_assign_task_through_patch(self):
        task = Task.objects.create(title="Available", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.member)
        response = self.client.patch(f"/api/tasks/{task.id}/", {"assignee": self.member.id}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        task.refresh_from_db()
        self.assertIsNone(task.assignee)

    def test_member_cannot_assign_another_member(self):
        task = Task.objects.create(title="Available", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.member)
        response = self.client.patch(f"/api/tasks/{task.id}/", {"assignee": self.member2.id}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        task.refresh_from_db()
        self.assertIsNone(task.assignee)

    def test_coordinator_can_assign_team_member(self):
        task = Task.objects.create(title="Assigned work", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.coordinator)
        response = self.client.patch(f"/api/tasks/{task.id}/", {"assignee": self.member.id}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        task.refresh_from_db()
        self.assertEqual(task.assignee, self.member)

    def test_coordinator_cannot_assign_outsider(self):
        task = Task.objects.create(title="Assigned work", team=self.team, creator=self.coordinator)
        self.client.force_authenticate(self.coordinator)
        response = self.client.patch(f"/api/tasks/{task.id}/", {"assignee": self.outsider.id}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        task.refresh_from_db()
        self.assertIsNone(task.assignee)
