from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import Team, TeamMembership

User = get_user_model()


class MembershipSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = TeamMembership
        fields = ("id", "user", "username", "role", "joined_at")
        read_only_fields = ("id", "username", "joined_at")


class TeamSerializer(serializers.ModelSerializer):
    memberships = MembershipSerializer(many=True, read_only=True)

    class Meta:
        model = Team
        fields = ("id", "name", "created_by", "created_at", "updated_at", "memberships")
        read_only_fields = ("id", "created_by", "created_at", "updated_at", "memberships")
