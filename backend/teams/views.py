from django.db import transaction
from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied

from .models import Team, TeamMembership
from .permissions import IsTeamMember, is_coordinator
from .serializers import MembershipSerializer, TeamSerializer


class TeamListCreateView(generics.ListCreateAPIView):
    serializer_class = TeamSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Team.objects.filter(memberships__user=self.request.user).distinct().prefetch_related("memberships__user")

    @transaction.atomic
    def perform_create(self, serializer):
        team = serializer.save(created_by=self.request.user)
        TeamMembership.objects.create(team=team, user=self.request.user, role=TeamMembership.Role.COORDINATOR)


class TeamDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = TeamSerializer
    permission_classes = [permissions.IsAuthenticated, IsTeamMember]

    def get_queryset(self):
        return Team.objects.filter(memberships__user=self.request.user).distinct().prefetch_related("memberships__user")

    def perform_update(self, serializer):
        if not is_coordinator(self.request.user, self.get_object()):
            raise PermissionDenied("Only coordinators can update the team.")
        serializer.save()


class MembershipCreateView(generics.CreateAPIView):
    serializer_class = MembershipSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        team = generics.get_object_or_404(Team, pk=self.kwargs["team_id"])
        if not is_coordinator(self.request.user, team):
            raise PermissionDenied("Only coordinators can add team members.")
        serializer.save(team=team)
