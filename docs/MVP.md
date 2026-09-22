# TaskDev MVP

## Problem

Operational teams often need a lightweight answer to a simple question: **what work needs to be done right now, and who is doing it?**

TaskDev focuses on this workflow instead of trying to reproduce a complete project-management suite.

## Users

### Team administrator / coordinator
Creates or manages a team, adds members, creates tasks, assigns work and sees current team activity.

### Team member
Sees available and assigned work, claims tasks when allowed, changes status and completes tasks.

## Core workflow

1. A task is created for a team.
2. It remains unassigned in the shared pool or is assigned to a member.
3. A member can claim an available task.
4. The task moves through pending, in-progress, blocked or completed.
5. Changes become visible to connected team members in real time.
6. Relevant changes are recorded in task history.

## MVP entities

- User
- Team
- TeamMembership
- Task
- TaskActivity

## Minimum task data

- title
- optional description
- team
- creator
- optional assignee
- status
- priority
- optional due date
- created/updated timestamps

## Outside the MVP

- Internal chat
- AI features
- Gantt charts
- Complex workflow builders
- Time tracking/payroll
- Push notifications
- Deep analytics

These are evaluated only after the core workflow is usable.

## Success criterion

A small real team can use TaskDev during a normal workday to create, discover, claim, execute and complete tasks without needing another tool to know the current state of work.
