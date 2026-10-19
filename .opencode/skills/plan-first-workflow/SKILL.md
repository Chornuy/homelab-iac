---
name: plan-first-workflow
description: Use when approaching any task that involves changing files, running commands, or modifying infrastructure. Triggers on plan, approval, review requests.
---

# Plan-First Workflow

1. **Explore first** — read the relevant files to understand context.
2. **Present a plan** — summary of changes, files affected, commands to run.
3. **Wait for approval** — do not execute until the user says yes/go/execute/approve/proceed.
4. **Execute** — only the approved plan, in the approved order.
5. **Verify** — run tests/lint/validate and report results.

If the user's request is purely informational (a question), skip the plan and answer directly.
