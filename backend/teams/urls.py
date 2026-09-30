from django.urls import path

from .views import MembershipCreateView, MembershipDetailView, TeamDetailView, TeamListCreateView

urlpatterns = [
    path("", TeamListCreateView.as_view(), name="team-list-create"),
    path("<int:pk>/", TeamDetailView.as_view(), name="team-detail"),
    path("<int:team_id>/members/", MembershipCreateView.as_view(), name="membership-create"),
    path("<int:team_id>/members/<int:pk>/", MembershipDetailView.as_view(), name="membership-detail"),
]
