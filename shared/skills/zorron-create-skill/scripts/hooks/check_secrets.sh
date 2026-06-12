#!/usr/bin/env bash
# check_secrets.sh — PreToolUse hook
# Scans Write/Edit tool input for hardcoded secrets.
# Claude Code calls this before every Write or Edit tool invocation.
#
# Input:  JSON on stdin (tool call parameters)
# Output: JSON on stdout — MUST have exactly these three fields:
#   { "continue": bool, "suppressOutput": bool, "systemMessage": string }
#
# Install: add to ~/.claude/settings.json under PreToolUse (see settings-snippet.json)
# Timeout: set to ≤ 30s in settings (this script targets < 5s)

set -euo pipefail

# Read the full tool JSON from stdin
INPUT=$(cat)

# Extract the text content being written/edited
CONTENT=$(python3 - <<'PYEOF'
import sys, json
try:
    d = json.loads(sys.stdin.read())
    # Write tool: "content" key
    # Edit / str_replace tool: "new_str" key
    print(d.get("content", d.get("new_str", "")))
except Exception:
    print("")
PYEOF
<<< "$INPUT")

# ─── Secret patterns ──────────────────────────────────────────────────────────
declare -A PATTERNS
PATTERNS["AWS Access Key"]='AKIA[0-9A-Z]{16}'
PATTERNS["Generic API key (sk-)"]='sk-[a-zA-Z0-9]{32,}'
PATTERNS["Private key header"]='-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
PATTERNS["Hardcoded password"]='(password|passwd|pwd)\s*[:=]\s*["\x27][^"\x27]{6,}["\x27]'
PATTERNS["Hardcoded api_key"]='api[_-]?key\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]'
PATTERNS["Hardcoded secret"]='(secret|token)\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]'

FOUND_PATTERNS=""
for LABEL in "${!PATTERNS[@]}"; do
    PATTERN="${PATTERNS[$LABEL]}"
    if echo "$CONTENT" | grep -qEi "$PATTERN" 2>/dev/null; then
        FOUND_PATTERNS="${FOUND_PATTERNS}• ${LABEL}\n"
    fi
done

# ─── Output JSON ──────────────────────────────────────────────────────────────
if [ -n "$FOUND_PATTERNS" ]; then
    # Escape for JSON string
    MSG="🚨 Possible hardcoded secret(s) detected:\\n${FOUND_PATTERNS}\\nReplace with environment variable references (e.g. os.environ['API_KEY'] or process.env.API_KEY) before proceeding."
    python3 -c "
import json, sys
msg = sys.argv[1]
print(json.dumps({
    'continue': False,
    'suppressOutput': False,
    'systemMessage': msg
}))
" "$MSG"
else
    # All clear — suppress noise, allow tool to proceed
    python3 -c "
import json
print(json.dumps({'continue': True, 'suppressOutput': True, 'systemMessage': ''}))
"
fi
