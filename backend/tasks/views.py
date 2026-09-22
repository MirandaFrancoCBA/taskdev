from django.db import transaction
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from teams.models import TeamMembership
from .models import Task, TaskActivity
from .serializers import TaskActivitySerializer, TaskSerializer
from .realtime import publish_task_event


class TaskListCreateView(generics.ListCreateAPIView):
    serializer_class = TaskSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Task.objects.filter(team__memberships__user=self.request.user).select_related("team", "creator", "assignee").distinct()
        team_id = self.request.query_params.get("team")
        task_status = self.request.query_params.get("status")
        pool = self.request.query_params.get("pool")
        if team_id:
            queryset = queryset.filter(team_id=team_id)
        if task_status:
            queryset = queryset.filter(status=task_status)
        if pool == "true":
            queryset = queryset.filter(assignee__isnull=True, status=Task.Status.PENDING)
        return queryset

    @transaction.atomic
    def perform_create(self, serializer):
        task = serializer.save(creator=self.request.user)
        TaskActivity.objects.create(task=task, actor=self.request.user, event=TaskActivity.Event.CREATED)
        transaction.on_commit(lambda: publish_task_event(task, "task.created"))


class TaskDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = TaskSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Task.objects.filter(team__memberships__user=self.request.user).select_related("team", "creator", "assignee").distinct()

    @transaction.atomic
    def perform_update(self, serializer):
        task = self.get_object()
        old_status = task.status
        old_assignee_id = task.assignee_id
        updated = serializer.save()

        if old_assignee_id != updated.assignee_id:
            TaskActivity.objects.create(task=updated, actor=self.request.user, event=TaskActivity.Event.ASSIGNEE_CHANGED, previous_value={"assignee_id": old_assignee_id}, new_value={"assignee_id": updated.assignee_id})

        if old_status != updated.status:
            event = TaskActivity.Event.COMPLETED if updated.status == Task.Status.COMPLETED else TaskActivity.Event.STATUS_CHANGED
            TaskActivity.objects.create(task=updated, actor=self.request.user, event=event, previous_value={"status": old_status}, new_value={"status": updated.status})

        transaction.on_commit(lambda: publish_task_event(updated, "task.updated"))


class TaskClaimView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        try:
            task = Task.objects.select_for_update().select_related("team", "assignee").get(pk=pk)
        except Task.DoesNotExist:
            return Response({"detail": "Task not found."}, status=status.HTTP_404_NOT_FOUND)

        if not TeamMembership.objects.filter(team=task.team, user=request.user).exists():
            return Response({"detail": "Task not found."}, status=status.HTTP_404_NOT_FOUND)
        if task.status != Task.Status.PENDING:
            return Response({"detail": "Only pending tasks can be claimed."}, status=status.HTTP_409_CONFLICT)
        if task.assignee_id is not None:
            return Response({"detail": "Task has already been claimed."}, status=status.HTTP_409_CONFLICT)

        task.assignee = request.user
        task.status = Task.Status.IN_PROGRESS
        task.save(update_fields=("assignee", "status", "updated_at"))
        TaskActivity.objects.create(task=task, actor=request.user, event=TaskActivity.Event.CLAIMED, previous_value={"assignee_id": None, "status": Task.Status.PENDING}, new_value={"assignee_id": request.user.id, "status": Task.Status.IN_PROGRESS})
        transaction.on_commit(lambda: publish_task_event(task, "task.claimed"))
        return Response(TaskSerializer(task, context={"request": request}).data, status=status.HTTP_200_OK)


class TaskActivityListView(generics.ListAPIView):
    serializer_class = TaskActivitySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return TaskActivity.objects.filter(task_id=self.kwargs["pk"], task__team__memberships__user=self.request.user).select_related("actor").distinct()
