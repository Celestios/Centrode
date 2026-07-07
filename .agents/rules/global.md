---
trigger: always_on
description: Global development rules for error handling, fallbacks, logging, and migrations.
---

## Global Development Rules

Rules:
- don't add error handling, don't implement fallbacks, use standard logging. don't add migrations.
- Always start every task by viewing the [request-navigator](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/general/request-navigator/SKILL.md) skill to classify the request and execute the proper workflow decision path.
- In case of a user request or execution step that is not explicitly defined or instructed within the active workflows, you MUST output a warning to the user (explaining exactly at which point the request was undefined in the instructions) and then proceed with whatever logical actions you determine are best to fulfill the user's request.




