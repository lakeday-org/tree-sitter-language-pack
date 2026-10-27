---
type: Reference
title: Scoop Manifest Layout
paths:
  - "scripts/publish/ts-pack.json.tmpl"
x-ai-rulez:
  kind: rule
  id: scoop-manifest
  metadata:
    priority: medium
---

- The Windows zip is flat: `ts-pack.exe` sits at the archive root, so the manifest has no `extract_dir`. Do not add one.
- The template is rendered into the scoop-bucket manifest at release. A wrong `extract_dir` still hashes and validates but installs a shim that resolves to nothing; check `unzip -l` on the release asset after changing the archive layout.
