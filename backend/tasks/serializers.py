from rest_framework import serializers

from teams.models import TeamMembership
from .models import Task


class TaskSerializer(serializers.ModelSerializer):
    creator_username = serializers.CharField(source="creator.username", read_only=True)
    assignee_username = serializers.CharField(source="assignee.username", read_only=True)

    class Meta:
        model = Task
        fields = ("id", "title", "description", "team", "creator", "creator_username", "assignee", "assignee_username", "status", "priority", "due_date", "created_at", "updated_at")
        read_only_fields = ("id", "creator", "creator_username", "assignee_username", "created_at", "updated_at")

    def validate(self, attrs):
        request = self.context["request"]
        team = attrs.get("team", getattr(self.instance, "team", None))
        assignee = attrs.get("assignee", getattr(self.instance, "assignee", None))
        if team and not TeamMembership.objects.filter(team=team, user=request.user).exists():
            raise serializers.ValidationError({"team": "You are not a member of this team."})
        if assignee and team and not TeamMembership.objects.filter(team=team, user=assignee).exists():
            raise serializers.ValidationError({"assignee": "Assignee must belong to the task team."})
        return attrs
