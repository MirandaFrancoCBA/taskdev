from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer


def publish_task_event(task, event):
    channel_layer = get_channel_layer()
    async_to_sync(channel_layer.group_send)(
        f"team_{task.team_id}",
        {
            "type": "task.event",
            "event": event,
            "task_id": task.id,
            "team_id": task.team_id,
            "status": task.status,
            "assignee_id": task.assignee_id,
        },
    )
