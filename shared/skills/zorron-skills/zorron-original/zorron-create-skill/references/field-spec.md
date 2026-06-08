# Claude Code SKILL.md Field Specification

> **When to read this**: Read this file when writing or reviewing a skill's frontmatter, when validate.py reports field errors, or when you need authoritative behavior details for a specific field.

---

## Frontmatter Fields

### `name` ✅ REQUIRED

| Attribute | Value |
|-----------|-------|
| Format | `kebab-case` — lowercase letters, digits, hyphens only |
| Match rule | MUST exactly equal the parent directory name |
| Used for | Skill cache key, `/skill-name` CLI invocation, internal routing |
| Max length | 64 characters |

**Examples:**
```yaml
# ✅ Correct
name: pr-review

# ❌ Wrong — spaces
name: pr review

# ❌ Wrong — uppercase
name: PR-Review

# ❌ Wrong — doesn't match directory name
# (skill is in ./code-review/ but name says pr-review)
name: pr-review
```

---

### `description` ✅ REQUIRED

| Attribute | Value |
|-----------|-------|
| Word limit | 60–100 words (parser truncates near 100; ~120 is hard limit) |
| Always loaded | YES — injected into every system prompt when skill is registered |
| Used for | Intent matching, vector routing, keyword search |
| Must start with | Action verb ("Use this skill when…", "Generates…", "Analyzes…") |

**Anatomy of a good description:**

```
Use this skill when [TRIGGER CONTEXT].
Covers [KEY CAPABILITIES / KEYWORDS].
Also triggers when [SECONDARY TRIGGER].
DO NOT invoke for [EXPLICIT EXCLUSIONS].
```

**Do:**
- Front-load the 3–5 most important trigger keywords
- Include a concrete `DO NOT invoke` clause to prevent mis-routing
- Mention the primary tool or technology the skill covers
- Make it "pushy" — lean toward over-triggering rather than under-triggering

**Don't:**
- Embed workflow steps — they belong in the body
- Use vague phrases like "helps with" or "assists in"
- Exceed 100 words — content past the limit is silently dropped by the parser
- Write in third person ("This skill does X") — use second person or imperative

**Word count check:**
```bash
echo "your description here" | wc -w
```

---

### `version` ✅ REQUIRED

| Attribute | Value |
|-----------|-------|
| Format | `MAJOR.MINOR.PATCH` (Semantic Versioning 2.0) |
| Used for | Cache invalidation, compatibility checks, update tracking |

**Bump rules:**

| Change type | Bump |
|-------------|------|
| Typo fix, clarification, no behavior change | `PATCH` (1.0.0 → 1.0.1) |
| New optional section, new example, new script | `MINOR` (1.0.0 → 1.1.0) |
| Renamed field, removed tool, workflow restructure | `MAJOR` (1.0.0 → 2.0.0) |

For breaking changes, also add `[BREAKING]` at the end of `description`:
```yaml
description: "... DO NOT invoke for unrelated tasks. [BREAKING: v2 restructures Phase 2]"
```

---

### `argument-hint` ❌ Optional

| Attribute | Value |
|-----------|-------|
| Purpose | Improves CLI UX when using `/skill-name` slash commands |
| Loaded into model | NO — display only, not passed to model |
| Format | `<required-arg> [optional-arg]` using angle brackets |

```yaml
# Example
argument-hint: <feature-name> [--strict] [--dry-run]
```

---

### `allowed-tools` ❌ Optional (but REQUIRED if the skill uses tools)

| Attribute | Value |
|-----------|-------|
| Format | YAML list: `[Tool1, Tool2, ...]` |
| Effect | Undeclared tool calls may be blocked or require user confirmation |
| Principle | Minimum necessary — never use `[All]` |

**Available tool names:**

| Tool | What it does |
|------|-------------|
| `Read` | Read file contents |
| `Write` | Create or overwrite files |
| `Edit` / `str_replace` | Make targeted edits to files |
| `MultiEdit` | Multiple edits in one call |
| `Bash` | Execute shell commands |
| `Glob` | Pattern-match file paths |
| `Grep` | Search file contents |
| `WebFetch` | Fetch a URL |
| `WebSearch` | Search the web |
| `Task` | Spawn a subagent |
| `TodoWrite` | Manage task list |

**Security notes:**
- `Bash` is the highest-risk tool — require it only if shell execution is truly needed
- Combine with a `PreToolUse` hook to audit `Bash` calls (see `hooks/check_secrets.sh`)
- `WebFetch` and `WebSearch` expose the network — declare only when the workflow genuinely needs external data

---

## Body Sections

### `## When to invoke` ✅ REQUIRED in body

This section handles **explicit rule-based routing** when multiple skills are loaded. The `description` field handles implicit embedding/keyword matching; this section resolves conflicts.

**Required elements:**
1. At least two positive trigger scenarios (bullet list)
2. One or more `DO NOT invoke when:` bullet(s)

**Format:**
```markdown
## When to invoke
- User requests X (scenario A)
- User mentions Y or Z keyword
- Workflow involves [specific file type / tech stack]
- DO NOT invoke when: [clear exclusion]
- DO NOT invoke when: [another exclusion]
```

---

### Other recommended sections

| Section | When to include |
|---------|----------------|
| `## 📦 Prerequisites & Context` | When runtime deps or env vars are required |
| `## 🛠 Toolchain` | When the skill uses specific CLI tools or APIs |
| `## 📋 Execution Workflow` | Always — the core of the skill |
| `## ⚠️ Rules & Guardrails` | Always — MUST / MUST NOT / SHOULD constraints |
| `## 📤 Output Specification` | When output format must be precise |
| `## 💡 Examples & Edge Cases` | Always — aids model understanding |

---

## Progressive Disclosure Reference

```
L0 — frontmatter description    (~100 words)  ← Always in context
L1 — SKILL.md body             (<500 lines)  ← Loaded when skill triggers
L2 — references/*.md           (unlimited)   ← Load on demand with explicit pointer
L3 — scripts/*                 (unlimited)   ← Executed via Bash, never loaded
```

**Rule:** If SKILL.md body approaches 500 lines, extract content into `references/` and add a pointer:
```markdown
> 📖 For AWS-specific configuration, read: `references/aws.md`
```

**Pointer format:** Always use a blockquote with 📖 emoji, followed by the relative path. Claude Code uses this pattern to locate on-demand content.
