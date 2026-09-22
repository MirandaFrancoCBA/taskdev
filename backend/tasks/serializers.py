from rest_framework import serializers

from teams.models import TeamMembership
from .models import Task, TaskActivity


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
        assignee_was_submitted = "assignee" in attrs
        status_was_submitted = "status" in attrs
        metadata_fields = {"title", "description", "priority", "due_date"}
        metadata_was_submitted = bool(metadata_fields.intersection(attrs))
        if self.instance is not None and "team" in attrs and attrs["team"].pk != self.instance.team_id:
            raise serializers.ValidationError({"team": "A task cannot be moved to another team after creation."})
        if team and not TeamMembership.objects.filter(team=team, user=request.user).exists():
            raise serializers.ValidationError({"team": "You are not a member of this team."})
        if assignee_was_submitted and team:
            is_coordinator = TeamMembership.objects.filter(team=team, user=request.user, role=TeamMembership.Role.COORDINATOR).exists()
            if not is_coordinator:
                raise serializers.ValidationError({"assignee": "Only coordinators can directly assign tasks. Use the claim endpoint to take available work."})
        if metadata_was_submitted and self.instance is not None and team:
            is_coordinator = TeamMembership.objects.filter(team=team, user=request.user, role=TeamMembership.Role.COORDINATOR).exists()
            if not is_coordinator:
                raise serializers.ValidationError({"detail": "Only coordinators can edit task metadata."})
        if status_was_submitted and self.instance is not None and team:
            is_coordinator = TeamMembership.objects.filter(team=team, user=request.user, role=TeamMembership.Role.COORDINATOR).exists()
            is_assignee = self.instance.assignee_id == request.user.id
            if not is_coordinator and not is_assignee:
                raise serializers.ValidationError({"status": "Only the assignee or a coordinator can change task status."})
        if assignee and team and not TeamMembership.objects.filter(team=team, user=assignee).exists():
            raise serializers.ValidationError({"assignee": "Assignee must belong to the task team."})
        return attrs


class TaskActivitySerializer(serializers.ModelSerializer):
    actor_username = serializers.CharField(source="actor.username", read_only=True)

    class Meta:
        model = TaskActivity
        fields = ("id", "event", "actor", "actor_username", "previous_value", "new_value", "created_at")
        read_only_fields = fields
