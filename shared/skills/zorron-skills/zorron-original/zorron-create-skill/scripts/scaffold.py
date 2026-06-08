#!/usr/bin/env python3
"""
scaffold.py — Generate a new Claude Code skill directory from answers

Usage:
    python scripts/scaffold.py --name <skill-name> --output <dir>
    python scripts/scaffold.py --package <skill-dir> --output <dist-dir>
    python scripts/scaffold.py --interactive

Options:
    --name <n>         Skill kebab-case name (e.g. pr-review)
    --output <dir>     Directory to create the skill in (default: .)
    --package <dir>    Package an existing skill dir into a .skill file
    --interactive      Step-by-step prompts (default when no --name given)
    --with-hooks       Include a starter hooks/ directory and check_secrets.sh
    --with-references  Include a references/ directory with placeholder files

Exit codes:
    0 = success
    1 = failure
"""

import sys
import re
import json
import shutil
import argparse
import zipfile
from pathlib import Path
from textwrap import dedent
from datetime import date


# ─── Templates ─────────────────────────────────────────────────────────────────

SKILL_MD_TEMPLATE = """\
---
name: {name}
description: {description}
version: 1.0.0
argument-hint: {argument_hint}
allowed-tools: [{allowed_tools}]
---

# {title}

{summary}

## When to invoke
- {trigger_1}
- {trigger_2}
- DO NOT invoke when: {exclusion}

## 📦 Prerequisites & Context
- **Runtime**: {runtime}
- **Assumptions**: {assumptions}
- **Exclusions**: {skill_exclusions}

## 🛠 Toolchain
| Tool | Purpose | Constraint |
|------|---------|------------|
| `{tool_1}` | {tool_1_purpose} | {tool_1_constraint} |

## 📋 Execution Workflow

### Phase 1: Analysis & Planning
1. Parse the user's request and extract key requirements
2. Identify files/resources to read
- ✅ Success: Clear understanding of scope and constraints
- 🔄 Fallback: If requirements are ambiguous, ask ONE targeted clarifying question

### Phase 2: Implementation
1. Execute the core workflow steps
2. Validate output against requirements
- ✅ Success: Output matches spec; all quality gates pass
- 🔄 Fallback: On failure, isolate the root cause and retry targeted fix only

### Phase 3: Delivery
1. Present output in the specified format
2. Provide one-liner verification command
- ✅ Success: User can reproduce and verify the result independently
- 🔄 Fallback: If verification fails, output exact remediation steps

## ⚠️ Rules & Guardrails
- **MUST**: {must_rule}
- **MUST NOT**: Hardcode secrets, modify out-of-scope files, or skip error handling
- **SHOULD**: {should_rule}
- **Quality Gate**: `{quality_gate}`

## 📤 Output Specification
- All code blocks MUST include language tags (`bash`, `python`, `json`, etc.)
- Deliverables: {deliverables}
- Validation: `{validation_cmd}`

## 💡 Examples & Edge Cases
- **Typical**: `"{typical_example}"`
- **Limitations**: {limitations}
"""

CHECK_SECRETS_TEMPLATE = """\
#!/usr/bin/env bash
# check_secrets.sh — PreToolUse hook: scan for hardcoded secrets before Write/Edit
# Returns JSON: { "continue": bool, "suppressOutput": bool, "systemMessage": str }
set -euo pipefail

# Read the tool input from stdin (Claude Code passes it as JSON)
INPUT=$(cat)

# Extract file content to scan (works for Write and Edit tools)
CONTENT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# Write tool uses 'content'; Edit uses 'new_str'
print(d.get('content', d.get('new_str', '')))
" 2>/dev/null || echo "")

# Pattern list: AWS keys, generic API keys, private keys
PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'sk-[a-zA-Z0-9]{32,}'
  '-----BEGIN (RSA |EC )?PRIVATE KEY-----'
  'password\\s*=\\s*["\\'"][^\\"'\\']+["\\'"]'
  'api_key\\s*=\\s*["\\'"][^\\"'\\']+["\\'"]'
)

FOUND=""
for PATTERN in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qE "$PATTERN"; then
    FOUND="$FOUND [$PATTERN]"
  fi
done

if [ -n "$FOUND" ]; then
  python3 -c "
import json
print(json.dumps({
  'continue': False,
  'suppressOutput': False,
  'systemMessage': '🚨 Secret detected in output: $FOUND. Replace with environment variable references (e.g. os.environ[\\'API_KEY\\']) before proceeding.'
}))
"
else
  python3 -c "
import json
print(json.dumps({'continue': True, 'suppressOutput': True, 'systemMessage': ''}))
"
fi
"""

FIELD_SPEC_PLACEHOLDER = """\
# Field Specification Reference
# See references/field-spec.md in the zorron-create-skill package for full content.
# This file is populated by the skill creator — replace with actual content.
"""


# ─── Helpers ───────────────────────────────────────────────────────────────────

def kebab(name: str) -> str:
    name = name.lower().strip()
    name = re.sub(r'[^a-z0-9]+', '-', name)
    name = name.strip('-')
    return name


def title_case(name: str) -> str:
    return " ".join(w.capitalize() for w in name.split("-"))


def prompt(question: str, default: str = "") -> str:
    suffix = f" [{default}]" if default else ""
    answer = input(f"{question}{suffix}: ").strip()
    return answer if answer else default


def interactive_answers() -> dict:
    print("\n🛠  zorron-create-skill — Interactive Scaffold\n")
    print("Answer each question (press Enter to use the default).\n")
    name = kebab(prompt("Skill name (kebab-case)", "my-skill"))
    title = prompt("Human-readable title", title_case(name))
    summary = prompt("One-line summary of what this skill does", f"A Claude Code skill for {title}.")
    description = prompt(
        "Routing description (60-90 words; include triggers and a DO NOT clause)",
        f"Use this skill when the user wants to {summary.lower().rstrip('.')}. "
        "DO NOT invoke for unrelated tasks."
    )
    trigger_1 = prompt("Trigger scenario 1", f"User asks to {summary.lower().rstrip('.')}")
    trigger_2 = prompt("Trigger scenario 2", "User mentions a related keyword or workflow")
    exclusion = prompt("Exclusion scenario (DO NOT invoke when…)", "the task is unrelated to this domain")
    allowed_tools = prompt("Allowed tools (comma-separated)", "Read, Write, Bash")
    runtime = prompt("Runtime requirements", "Python ≥ 3.10 / Node ≥ 18")
    assumptions = prompt("Project state assumptions", "Project is initialized and dependencies are installed")
    skill_exclusions = prompt("What this skill does NOT cover", "Infrastructure setup, auth, or deployment")
    argument_hint = prompt("CLI argument hint", "<input-file> [--dry-run]")
    must_rule = prompt("Primary MUST rule", "Validate all inputs before processing")
    should_rule = prompt("Primary SHOULD rule", "Provide a one-liner verification command in output")
    quality_gate = prompt("Quality gate command", "echo 'No automated gate — verify manually'")
    deliverables = prompt("Output deliverables", "Modified files, summary report")
    validation_cmd = prompt("Validation command", "echo 'Done'")
    typical_example = prompt("Typical user prompt example", f"Please {summary.lower().rstrip('.')}")
    limitations = prompt("Known limitations", "Does not handle edge cases beyond the happy path")
    with_hooks = prompt("Include starter hooks? (y/n)", "n").lower() == "y"
    with_references = prompt("Include references/ directory? (y/n)", "y").lower() == "y"
    tool_1 = allowed_tools.split(",")[0].strip()
    return dict(
        name=name, title=title, summary=summary, description=description,
        trigger_1=trigger_1, trigger_2=trigger_2, exclusion=exclusion,
        allowed_tools=allowed_tools, runtime=runtime, assumptions=assumptions,
        skill_exclusions=skill_exclusions, argument_hint=argument_hint,
        must_rule=must_rule, should_rule=should_rule, quality_gate=quality_gate,
        deliverables=deliverables, validation_cmd=validation_cmd,
        typical_example=typical_example, limitations=limitations,
        with_hooks=with_hooks, with_references=with_references,
        tool_1=tool_1, tool_1_purpose="Primary operation", tool_1_constraint="Use responsibly",
    )


def scaffold(answers: dict, output_dir: Path, with_hooks: bool = False, with_references: bool = True) -> Path:
    name = answers["name"]
    skill_dir = output_dir / name
    skill_dir.mkdir(parents=True, exist_ok=True)
    (skill_dir / "scripts").mkdir(exist_ok=True)

    # SKILL.md
    skill_md = SKILL_MD_TEMPLATE.format(**answers)
    (skill_dir / "SKILL.md").write_text(skill_md)

    # Minimal validate.py stub (full version is in the zorron-create-skill scripts/)
    validate_stub = dedent(f"""\
        #!/usr/bin/env python3
        \"\"\"validate.py — copy the full version from zorron-create-skill/scripts/validate.py\"\"\"
        # Stub generated by scaffold.py on {date.today()}
        # Replace with: cp zorron-create-skill/scripts/validate.py {name}/scripts/
        print("Replace this stub with the full validate.py from zorron-create-skill/scripts/")
    """)
    p = skill_dir / "scripts" / "validate.py"
    p.write_text(validate_stub)
    p.chmod(0o755)

    if with_hooks or answers.get("with_hooks"):
        hooks_dir = skill_dir / "scripts" / "hooks"
        hooks_dir.mkdir(exist_ok=True)
        hook_path = hooks_dir / "check_secrets.sh"
        hook_path.write_text(CHECK_SECRETS_TEMPLATE)
        hook_path.chmod(0o755)

        settings_snippet = {
            "PreToolUse": [{
                "matcher": "Write|Edit",
                "hooks": [{
                    "type": "command",
                    "command": f"bash ~/.claude/skills/{name}/scripts/hooks/check_secrets.sh",
                    "timeout": 15
                }]
            }]
        }
        (skill_dir / "scripts" / "hooks" / "settings-snippet.json").write_text(
            json.dumps(settings_snippet, indent=2)
        )

    if with_references or answers.get("with_references"):
        refs_dir = skill_dir / "references"
        refs_dir.mkdir(exist_ok=True)
        (refs_dir / "field-spec.md").write_text(FIELD_SPEC_PLACEHOLDER)
        examples_dir = refs_dir / "examples"
        examples_dir.mkdir(exist_ok=True)
        (examples_dir / "minimal.md").write_text(
            "# Minimal Skill Example\n\nSee zorron-create-skill/references/examples/minimal.md\n"
        )
        (examples_dir / "full.md").write_text(
            "# Full Skill Example\n\nSee zorron-create-skill/references/examples/full.md\n"
        )

    assets_dir = skill_dir / "assets"
    assets_dir.mkdir(exist_ok=True)

    print(f"✅  Scaffolded skill at: {skill_dir}")
    print(f"    Next step: edit {skill_dir}/SKILL.md, then run:")
    print(f"    python {skill_dir}/scripts/validate.py {skill_dir}/SKILL.md\n")
    return skill_dir


def package(skill_dir: Path, output_dir: Path) -> Path:
    """Zip a skill directory into a .skill file."""
    output_dir.mkdir(parents=True, exist_ok=True)
    name = skill_dir.name
    out_path = output_dir / f"{name}.skill"
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in sorted(skill_dir.rglob("*")):
            if f.is_file():
                zf.write(f, f.relative_to(skill_dir.parent))
    print(f"📦  Packaged: {out_path}")
    print(f"    Install: unzip {out_path} -d ~/.claude/skills/")
    return out_path


# ─── Entry point ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Scaffold a new Claude Code skill")
    parser.add_argument("--name", help="Skill kebab-case name")
    parser.add_argument("--output", default=".", help="Output directory")
    parser.add_argument("--package", metavar="SKILL_DIR", help="Package existing skill dir into .skill")
    parser.add_argument("--interactive", action="store_true")
    parser.add_argument("--with-hooks", action="store_true")
    parser.add_argument("--with-references", action="store_true", default=True)
    args = parser.parse_args()

    output_dir = Path(args.output)

    if args.package:
        skill_dir = Path(args.package)
        if not skill_dir.is_dir():
            print(f"Error: {skill_dir} is not a directory", file=sys.stderr)
            sys.exit(1)
        package(skill_dir, output_dir)
        return

    if args.name:
        name = kebab(args.name)
        answers = dict(
            name=name, title=title_case(name),
            summary=f"A Claude Code skill for {title_case(name)}.",
            description=(
                f"Use this skill when the user wants to {title_case(name).lower()}. "
                "DO NOT invoke for unrelated tasks."
            ),
            trigger_1=f"User asks to {title_case(name).lower()}",
            trigger_2="User mentions a related keyword or workflow",
            exclusion="the task is unrelated to this domain",
            allowed_tools="Read, Write, Bash",
            runtime="Python ≥ 3.10",
            assumptions="Project is initialized",
            skill_exclusions="Infrastructure, auth, deployment",
            argument_hint="<input> [--dry-run]",
            must_rule="Validate all inputs before processing",
            should_rule="Provide a verification command in output",
            quality_gate="echo 'verify manually'",
            deliverables="Modified files, summary",
            validation_cmd="echo 'Done'",
            typical_example=f"{title_case(name)}",
            limitations="Happy path only",
            tool_1="Bash", tool_1_purpose="Execute commands", tool_1_constraint="Use sparingly",
            with_hooks=args.with_hooks,
            with_references=args.with_references,
        )
    elif args.interactive or not args.name:
        answers = interactive_answers()
    else:
        parser.print_help()
        sys.exit(1)

    scaffold(answers, output_dir, with_hooks=args.with_hooks, with_references=args.with_references)


if __name__ == "__main__":
    main()
