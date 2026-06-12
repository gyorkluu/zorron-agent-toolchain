# Claude Code Hook System Reference

> **When to read this**: Read when adding hooks to a skill, when a hook is failing, or when designing security guardrails for a workflow.

---

## What are Hooks?

Hooks are shell commands that Claude Code executes **before or after** specific tool invocations. They form a security and automation layer that sits beneath the skill's workflow logic.

```
User prompt
   ↓
Skill workflow (SKILL.md)
   ↓
Tool call (e.g. Write, Bash)
   ↓  ← PreToolUse hook fires here
Tool executes
   ↓  ← PostToolUse hook fires here
Result returned to Claude
```

---

## Hook Types

| Hook | Fires | Common uses |
|------|-------|-------------|
| `PreToolUse` | Before a tool call | Secret scanning, access control, dry-run mode |
| `PostToolUse` | After a tool call | Audit logging, auto-formatting, notification |

---

## Configuration (`~/.claude/settings.json`)

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/skills/my-skill/scripts/hooks/check_secrets.sh",
          "timeout": 15
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "python3 ~/.claude/skills/my-skill/scripts/hooks/audit.py",
          "timeout": 10
        }
      ]
    }
  ]
}
```

### `matcher` field

A pipe-separated (`|`) list of tool names to match. Supports exact names only — no regex patterns.

Available tool names: `Read`, `Write`, `Edit`, `MultiEdit`, `Bash`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `Task`

### `timeout` field

Maximum seconds the hook may run. **MUST be ≤ 30**. Hook processes exceeding this are killed; Claude Code logs a timeout warning and may treat the call as blocked.

Recommendation: target < 5s for `PreToolUse` hooks (they're on the critical path).

---

## Hook Script Contract

### Input

Claude Code passes the tool call parameters as **JSON on stdin**:

```json
{
  "tool": "Write",
  "path": "/project/src/api.py",
  "content": "import os\nAPI_KEY = 'hardcoded-secret'\n"
}
```

For `Edit` / `str_replace`:
```json
{
  "tool": "Edit",
  "path": "/project/src/api.py",
  "old_str": "API_KEY = 'old'",
  "new_str": "API_KEY = os.environ['API_KEY']"
}
```

### Output (REQUIRED — 3 fields, exactly)

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Optional message injected into Claude's context"
}
```

| Field | Type | Meaning |
|-------|------|---------|
| `continue` | bool | `true` = allow tool to proceed; `false` = block tool call |
| `suppressOutput` | bool | `true` = hide hook stdout from user; `false` = show it |
| `systemMessage` | string | Message appended to Claude's system context (can be empty `""`) |

**If output is malformed** (not valid JSON, missing fields), Claude Code may treat it as a hard block or log an error. Always validate your hook output format.

### Python helper for output

```python
import json, sys

def hook_result(continue_: bool, message: str = "", suppress: bool = True) -> None:
    print(json.dumps({
        "continue": continue_,
        "suppressOutput": suppress,
        "systemMessage": message
    }))
    sys.exit(0)

# Block with message
hook_result(False, "🚨 Secret detected — replace with env var")

# Allow silently
hook_result(True, suppress=True)
```

---

## Common Hook Patterns

### 1. Secret Scanner (PreToolUse on Write/Edit)

See `scripts/hooks/check_secrets.sh` — fully implemented.

### 2. Restricted File Guard

Prevent writes outside the project directory:

```bash
#!/usr/bin/env bash
INPUT=$(cat)
PATH_VAL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('path',''))")

if [[ "$PATH_VAL" != /project/* ]]; then
  python3 -c "import json; print(json.dumps({
    'continue': False,
    'suppressOutput': False,
    'systemMessage': f'🚫 Write outside /project/ is not allowed: {\"$PATH_VAL\"}'
  }))"
else
  python3 -c "import json; print(json.dumps({'continue': True, 'suppressOutput': True, 'systemMessage': ''}))"
fi
```

### 3. Bash Command Allowlist (PreToolUse on Bash)

```python
#!/usr/bin/env python3
import sys, json, re

data = json.load(sys.stdin)
cmd = data.get("command", "")

ALLOWED = [r'^npm (run|install|test)', r'^python3? ', r'^pytest', r'^git (status|diff|log)']
blocked = not any(re.match(p, cmd) for p in ALLOWED)

print(json.dumps({
    "continue": not blocked,
    "suppressOutput": not blocked,
    "systemMessage": f"🚫 Bash command not in allowlist: {cmd}" if blocked else ""
}))
```

### 4. Audit Logger (PostToolUse on Bash)

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "$TIMESTAMP $INPUT" >> ~/.claude/audit.log
python3 -c "import json; print(json.dumps({'continue': True, 'suppressOutput': True, 'systemMessage': ''}))"
```

---

## Hook Debugging

```bash
# Test hook manually
echo '{"tool":"Write","path":"/tmp/test.py","content":"API_KEY='\''secret'\''"}' \
  | bash scripts/hooks/check_secrets.sh

# Should return:
# {"continue": false, "suppressOutput": false, "systemMessage": "🚨 ..."}

# Check Claude Code hook logs
tail -f ~/.claude/logs/hooks.log
```

---

## Declaring Hook Dependency in SKILL.md

When your skill depends on a hook being active, declare it explicitly in the Rules section:

```markdown
## ⚠️ Rules & Guardrails
- **HOOK DEPENDENCY**: This skill requires the `check_secrets.sh` PreToolUse hook.
  Install it by merging `scripts/hooks/settings-snippet.json` into `~/.claude/settings.json`.
  Without this hook, secret leakage is possible.
```

And in Prerequisites:
```markdown
## 📦 Prerequisites & Context
- **Hooks**: `PreToolUse` secret scanner must be active (see `scripts/hooks/settings-snippet.json`)
```
