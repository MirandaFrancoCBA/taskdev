from rest_framework.permissions import BasePermission

from .models import TeamMembership


class IsTeamMember(BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.memberships.filter(user=request.user).exists()


def is_coordinator(user, team):
    return team.memberships.filter(user=user, role=TeamMembership.Role.COORDINATOR).exists()
