from django.db import transaction
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from teams.models import TeamMembership
from .models import Task
from .serializers import TaskSerializer


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

    def perform_create(self, serializer):
        serializer.save(creator=self.request.user)


class TaskDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = TaskSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Task.objects.filter(team__memberships__user=self.request.user).select_related("team", "creator", "assignee").distinct()


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

        return Response(TaskSerializer(task, context={"request": request}).data, status=status.HTTP_200_OK)
