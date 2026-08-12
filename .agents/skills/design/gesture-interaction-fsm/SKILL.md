---
name: gesture-interaction-fsm
description: Activate this skill when mapping canvas gesture recognizers, managing pointer events, configuring bubbling hierarchies, or building transition states for the interaction FSM.
---

# Skill: Gesture & Interaction FSM

Use this skill when designing or implementing user input gesture handlers, pointer event bubbling hierarchies, and Finite State Machine (FSM) transitions.

## Guidelines

- **FSM State Transitions**: Ensure canvas states (e.g. idle, panning, zoom, drag node, link port) follow structured, predictable state transitions.
- **Event Bubbling**: Adhere to the event bubbling hierarchy rules, allowing canvas interceptors to consume events before they propagate to lower states.
- **Gesture Recognizers**: Design touch, pointer, and keyboard listeners to integrate cleanly into Tier 2 (Interaction & Controllers).
