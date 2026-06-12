# Annotated Example: Minimal Skill

This is the **smallest valid skill** that passes `validate.py`. Use it as a starting point when the workflow is simple enough to fit in the body without phases or scripts.

---

## The Skill

```markdown
---
name: json-prettifier                          ← kebab-case, matches directory name
description: Use this skill when the user wants to format, pretty-print, or beautify
JSON files or JSON strings. Triggers on: "format this JSON", "prettify JSON",
"make this JSON readable", "indent my JSON". DO NOT invoke for YAML, TOML, XML,
or non-JSON data formats.
version: 1.0.0                                 ← semver required
allowed-tools: [Read, Write, Bash]             ← minimum required set
---

# JSON Prettifier

Format JSON files or strings with consistent 2-space indentation and sorted keys.

## When to invoke
- User pastes or references a JSON string/file and asks to format it
- User says "prettify", "beautify", "format", or "indent" in a JSON context
- DO NOT invoke when: the input is YAML, TOML, XML, or any non-JSON format

## 📋 Execution Workflow

### Phase 1: Parse & Validate
1. Read the input (pasted string or file path)
2. Validate it is parseable JSON
- ✅ Success: JSON parses without error
- 🔄 Fallback: If parse fails, report the exact error location and exit — do not guess at fixes

### Phase 2: Format & Output
1. Pretty-print with 2-space indent, sorted keys
2. Write back to file if a file path was given; print to chat if a string was given
- ✅ Success: Output is valid JSON, indented, human-readable
- 🔄 Fallback: If write fails (permissions), print output to chat instead

## ⚠️ Rules & Guardrails
- **MUST**: Preserve all data — never drop keys or alter values
- **MUST NOT**: Modify files other than the one specified
- **SHOULD**: Confirm before overwriting if the file is > 10 KB
- **Quality Gate**: `python3 -c "import json,sys; json.load(open(sys.argv[1]))" <output-file>`

## 📤 Output Specification
- Formatted JSON in a ```json code block
- If writing to file: confirm path and byte count
- Validation: `python3 -m json.tool <file>` — must exit 0
```

---

## Why this works

| Requirement | How it's met |
|-------------|-------------|
| `name` matches dir | `json-prettifier/SKILL.md` ← name: json-prettifier |
| `description` 60-90 words | 67 words ✅ |
| Has `DO NOT` clause | "DO NOT invoke when: YAML, TOML..." ✅ |
| `## When to invoke` present | ✅ |
| `## When to invoke` has exclusion | "DO NOT invoke when:" ✅ |
| Each Phase has ✅ + 🔄 | ✅ |
| All code blocks tagged | ```json, ```bash ✅ |
| `allowed-tools` minimal | [Read, Write, Bash] ✅ |
| No TODO/placeholder | ✅ |
| Body < 500 lines | ~40 lines ✅ |

---

## What it doesn't need

- `scripts/` — the workflow is simple enough to execute inline with Bash
- `references/` — no overflow content
- `assets/` — no static files needed
- `hooks/` — no security interceptors needed for this low-risk operation
- `argument-hint` — not using slash command invocation

This is valid and will be accepted by `validate.py --strict`.
