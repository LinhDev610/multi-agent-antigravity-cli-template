---
name: broken-agent
description: "Agent specifying an invalid model ID instead of a model tier."
model: gemini-3.8-flash-high
tools:
  - view_file
---

# Broken Agent
This agent uses a concrete model ID in the frontmatter, which is rejected by Antigravity CLI 1.4.10.
