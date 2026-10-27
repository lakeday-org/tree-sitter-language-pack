---
type: Reference
title: E2E Fixtures
description: "tree-sitter-language-pack e2e fixture schema: fixture categories, source_code and language input, process and detection calls, skip and assertion types. Use when adding or editing a tree-sitter-language-pack e2e fixture."
paths:
  - "fixtures/**"
  - "e2e/**"
x-ai-rulez:
  kind: skill
  id: e2e-fixtures
  metadata:
    name: e2e-fixtures
---

# tree-sitter-language-pack E2E Fixtures

- Files under `fixtures/<category>/` hold one fixture or an array; `category` and `docs.topic` both equal the directory. Categories: `smoke` (one per language), `process`, `data_extraction`, `language-detection`, `query`, `error-handling`, `download`, `registry`, `parsing`, plus `bench`.
- Fields: `id`, `description`, `category`, `tags`, `docs {topic, stem, title}`, `input`, `assertions`, and optionally `call` and `skip {languages, reason}`.
- `call` defaults to `process`, with `input.source_code` and `input.config` (`language`, plus flags such as `data_extraction`). `alef.toml` defines the other calls. Fixtures use 22 of them, for example `detect_extension`, `detect_path`, `get_language`, `has_language`, `download_languages`, `highlights`, `list_languages` and `clean_cache`.
- Assertion types in use: `not_error`, `equals`, `count_min`, `count_equals`, `is_true`, `is_false`, `greater_than_or_equal`, `contains`, `is_empty`, `not_empty`, `error`.
