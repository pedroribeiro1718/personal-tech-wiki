# Maintenance rules

- Prefer maintained, standardized solutions. For Harness integrations, search
  its plugin ecosystem and established MCP servers before writing code.
- Add custom code or tools only when no suitable existing solution meets the
  requirement, and document that justification.
- Keep all maintained code and configuration in this directory at or below
  1,800 physical lines in aggregate. Count scripts, tests, Compose/YAML/JSON,
  Dockerfiles, manifests, and lockfiles. Only prose documentation is excluded.
  Generated files, file splitting, or moving configuration do not create an
  exception.
- Keep the `local-ai` orchestration script at or below 400 physical lines.
- Keep recovery documentation concise and never commit credentials, generated
  secrets, caches, runtime state, private addresses, or model weights.
