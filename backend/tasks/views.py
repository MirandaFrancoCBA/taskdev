from rest_framework import generics, permissions

from teams.models import TeamMembership
from .models import Task
from .serializers import TaskSerializer


class TaskListCreateView(generics.ListCreateAPIView):
    serializer_class = TaskSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Task.objects.filter(team__memberships__user=self.request.user).select_related("team", "creator", "assignee").distinct()
        team_id = self.request.query_params.get("team")
        status = self.request.query_params.get("status")
        pool = self.request.query_params.get("pool")
        if team_id:
            queryset = queryset.filter(team_id=team_id)
        if status:
            queryset = queryset.filter(status=status)
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
