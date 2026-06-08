#!/usr/bin/env python3
"""
validate.py — Claude Code SKILL.md structural linter

Usage:
    python scripts/validate.py <path-to-SKILL.md> [--json] [--strict]

Options:
    --json      Output results as JSON (default: human-readable)
    --strict    Treat warnings as errors (exits 1 if any warnings)

Exit codes:
    0 = PASS (no errors; warnings may exist unless --strict)
    1 = FAIL (errors found, or warnings found with --strict)
"""

import sys
import re
import json
import argparse
from pathlib import Path


# ─── Thresholds ────────────────────────────────────────────────────────────────
DESCRIPTION_MIN_WORDS = 40
DESCRIPTION_MAX_WORDS = 100  # parser truncates near here
BODY_MAX_LINES = 500
HOOK_TIMEOUT_MAX = 30


# ─── Helpers ───────────────────────────────────────────────────────────────────
def count_words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Returns (frontmatter_dict, body_text). Raises ValueError on bad format."""
    if not content.startswith("---"):
        raise ValueError("SKILL.md must begin with a YAML frontmatter block (---)")
    parts = content.split("---", 2)
    if len(parts) < 3:
        raise ValueError("Frontmatter block not properly closed with ---")
    raw_fm = parts[1].strip()
    body = parts[2].strip()
    fm: dict = {}
    for line in raw_fm.splitlines():
        if ":" in line:
            key, _, val = line.partition(":")
            fm[key.strip()] = val.strip()
    return fm, body


def check_allowed_tools(fm: dict, body: str) -> list[str]:
    """Warn if body references tools not in allowed-tools."""
    warnings = []
    tools_in_body = set(re.findall(r'\b(Bash|Read|Write|Edit|Glob|Grep|MultiEdit|WebFetch|WebSearch|Task)\b', body))
    raw_allowed = fm.get("allowed-tools", "")
    declared = set(re.findall(r'[A-Za-z]+', raw_allowed))
    missing = tools_in_body - declared
    if missing:
        warnings.append(f"Tools used in body but not in allowed-tools: {', '.join(sorted(missing))}")
    return warnings


def check_code_blocks(body: str) -> list[str]:
    """Warn about top-level fenced code blocks missing a language tag.

    Ignores inner ``` lines that are content inside an outer fenced block
    (common in meta-skills that show markdown templates as examples).
    """
    issues = []
    depth = 0
    for i, line in enumerate(body.splitlines(), 1):
        m = re.match(r"^(`{3,})(\S*)", line)
        if m:
            lang = m.group(2)
            if depth == 0:
                depth = 1
                if not lang:
                    issues.append(f"Line {i}: fenced code block missing language tag (e.g. ```bash)")
            else:
                depth -= 1
        elif re.match(r"^`{3,}\s*$", line) and depth > 0:
            depth -= 1
    return issues


# ─── Main validation ────────────────────────────────────────────────────────────
def validate(skill_path: Path) -> dict:
    errors: list[str] = []
    warnings: list[str] = []

    # 1. File naming
    if skill_path.name != "SKILL.md":
        errors.append(f"File must be named exactly 'SKILL.md' (case-sensitive), got: {skill_path.name}")

    # 2. Read content
    try:
        content = skill_path.read_text(encoding="utf-8")
    except Exception as e:
        errors.append(f"Cannot read file: {e}")
        return {"pass": False, "errors": errors, "warnings": warnings}

    # 3. Parse frontmatter
    try:
        fm, body = parse_frontmatter(content)
    except ValueError as e:
        errors.append(str(e))
        return {"pass": False, "errors": errors, "warnings": warnings}

    # 4. Required frontmatter fields
    for field in ("name", "description", "version"):
        if field not in fm or not fm[field]:
            errors.append(f"Missing required frontmatter field: '{field}'")

    # 5. name == directory name
    if "name" in fm:
        dir_name = skill_path.parent.name
        if fm["name"] != dir_name:
            errors.append(
                f"'name' field ('{fm['name']}') must match directory name ('{dir_name}')"
            )
        if not re.match(r'^[a-z][a-z0-9-]*$', fm.get("name", "")):
            errors.append(f"'name' must be kebab-case (lowercase, hyphens only): got '{fm['name']}'")

    # 6. description word count
    desc = fm.get("description", "")
    word_count = count_words(desc)
    if word_count < DESCRIPTION_MIN_WORDS:
        errors.append(
            f"'description' too short ({word_count} words). Minimum: {DESCRIPTION_MIN_WORDS}."
        )
    elif word_count > DESCRIPTION_MAX_WORDS:
        warnings.append(
            f"'description' may be truncated by parser ({word_count} words > {DESCRIPTION_MAX_WORDS} limit)."
        )

    # 7. description must have DO NOT clause
    if desc and "DO NOT" not in desc.upper() and "do not" not in desc.lower():
        warnings.append(
            "'description' lacks a 'DO NOT' exclusion clause. This helps prevent mis-routing."
        )

    # 8. version semver
    version = fm.get("version", "")
    if version and not re.match(r'^\d+\.\d+\.\d+$', version):
        errors.append(f"'version' must follow semver (MAJOR.MINOR.PATCH), got: '{version}'")

    # 9. Body: ## When to invoke section
    if "## When to invoke" not in body and "## when to invoke" not in body.lower():
        errors.append("Body missing required section: '## When to invoke'")
    else:
        invoke_section = re.search(
            r'## When to invoke(.*?)(?=\n## |\Z)', body, re.DOTALL | re.IGNORECASE
        )
        if invoke_section:
            invoke_text = invoke_section.group(1)
            if "DO NOT" not in invoke_text.upper():
                warnings.append("'## When to invoke' section lacks a 'DO NOT invoke' exclusion clause.")

    # 10. Body line count
    body_lines = len(body.splitlines())
    if body_lines > BODY_MAX_LINES:
        warnings.append(
            f"SKILL.md body is {body_lines} lines (>{BODY_MAX_LINES}). "
            "Consider moving long content to references/ for better performance."
        )

    # 11. allowed-tools coverage
    tool_warnings = check_allowed_tools(fm, body)
    warnings.extend(tool_warnings)

    # 12. Code blocks with language tags
    code_warnings = check_code_blocks(body)
    warnings.extend(code_warnings)

    # 13. No placeholder text — scan only outside fenced code blocks
    body_outside_blocks = re.sub(r'`{3}.*?`{3}', '', body, flags=re.DOTALL)
    body_outside_blocks = re.sub(r'`[^`]+`', '', body_outside_blocks)
    placeholders = re.findall(r'\bTODO\b|\bFIXME\b', body_outside_blocks)
    if placeholders:
        warnings.append(
            f"Body contains {len(placeholders)} placeholder(s) (TODO/FIXME). Remove before shipping."
        )

    # 14. Phases should have success + fallback markers
    phases = re.findall(r'### Phase \d+', body)
    if phases:
        success_count = len(re.findall(r'✅ Success', body))
        fallback_count = len(re.findall(r'🔄 Fallback', body))
        if success_count < len(phases):
            warnings.append(
                f"Found {len(phases)} Phase(s) but only {success_count} '✅ Success' marker(s). "
                "Each phase should have explicit success criteria."
            )
        if fallback_count < len(phases):
            warnings.append(
                f"Found {len(phases)} Phase(s) but only {fallback_count} '🔄 Fallback' marker(s). "
                "Each phase should have a fallback strategy."
            )

    passed = len(errors) == 0
    return {
        "pass": passed,
        "skill": str(skill_path),
        "name": fm.get("name", "unknown"),
        "version": fm.get("version", "unknown"),
        "description_words": word_count,
        "body_lines": body_lines,
        "errors": errors,
        "warnings": warnings,
        "summary": f"{'PASS' if passed else 'FAIL'} — {len(errors)} error(s), {len(warnings)} warning(s)",
    }


def print_human(result: dict) -> None:
    status = "✅ PASS" if result["pass"] else "❌ FAIL"
    print(f"\n{status}  {result.get('skill', '')}")
    print(f"  Skill: {result.get('name')}  v{result.get('version')}")
    print(f"  Description: {result.get('description_words')} words  |  Body: {result.get('body_lines')} lines\n")
    if result["errors"]:
        print("ERRORS:")
        for e in result["errors"]:
            print(f"  ✗ {e}")
    if result["warnings"]:
        print("WARNINGS:")
        for w in result["warnings"]:
            print(f"  ⚠ {w}")
    if not result["errors"] and not result["warnings"]:
        print("  Everything looks great! 🎉")
    print()


def main():
    parser = argparse.ArgumentParser(description="Validate a Claude Code SKILL.md file")
    parser.add_argument("skill_path", help="Path to SKILL.md")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--strict", action="store_true", help="Treat warnings as errors")
    args = parser.parse_args()

    path = Path(args.skill_path)
    if not path.exists():
        print(f"Error: file not found: {path}", file=sys.stderr)
        sys.exit(1)

    result = validate(path)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print_human(result)

    failed = not result["pass"] or (args.strict and result["warnings"])
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
