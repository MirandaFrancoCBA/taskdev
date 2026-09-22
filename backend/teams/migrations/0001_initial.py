from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True
    dependencies = [migrations.swappable_dependency(settings.AUTH_USER_MODEL)]
    operations = [
        migrations.CreateModel(name="Team", fields=[("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")), ("name", models.CharField(max_length=120)), ("created_at", models.DateTimeField(auto_now_add=True)), ("updated_at", models.DateTimeField(auto_now=True)), ("created_by", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="created_teams", to=settings.AUTH_USER_MODEL))]),
        migrations.CreateModel(name="TeamMembership", fields=[("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")), ("role", models.CharField(choices=[("coordinator", "Coordinator"), ("member", "Member")], default="member", max_length=20)), ("joined_at", models.DateTimeField(auto_now_add=True)), ("team", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="memberships", to="teams.team")), ("user", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="team_memberships", to=settings.AUTH_USER_MODEL))], options={"constraints": [models.UniqueConstraint(fields=("team", "user"), name="unique_team_membership")]}),
    ]
