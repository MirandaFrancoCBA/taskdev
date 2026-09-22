from django.urls import path

from .views import TaskActivityListView, TaskClaimView, TaskDetailView, TaskListCreateView

urlpatterns = [
    path("", TaskListCreateView.as_view(), name="task-list-create"),
    path("<int:pk>/", TaskDetailView.as_view(), name="task-detail"),
    path("<int:pk>/claim/", TaskClaimView.as_view(), name="task-claim"),
    path("<int:pk>/activity/", TaskActivityListView.as_view(), name="task-activity"),
]
