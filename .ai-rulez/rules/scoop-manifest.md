---
type: Reference
title: Scoop Manifest Layout
paths:
  - "scripts/publish/ts-pack.json.tmpl"
  - "scripts/publish/scoop.json"
  - ".github/workflows/publish.yaml"
x-ai-rulez:
  kind: rule
  id: scoop-manifest
  metadata:
    priority: medium
---

- The Windows zip is flat: `ts-pack.exe` sits at the archive root, so the manifest has no `extract_dir`. Do not add one. The layout is set by the `Package CLI (Windows)` step in .github/workflows/publish.yaml.
