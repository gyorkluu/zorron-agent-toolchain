# Annotated Example: Full Production-Grade Skill

This is a **complete, production-ready skill** that demonstrates all features: multi-phase workflow, scripts, references, hooks, quality gates, and output specifications.

---

## Skill: `pr-review`

### Directory layout
```
pr-review/
├── SKILL.md
├── scripts/
│   ├── validate.py           ← structural self-check
│   ├── analyze_diff.py       ← parses git diff into structured review targets
│   └── hooks/
│       ├── check_secrets.sh  ← PreToolUse: blocks secret commits
│       └── settings-snippet.json
├── references/
│   ├── field-spec.md         ← linked from body when deep-dive needed
│   ├── security-checklist.md ← loaded during Phase 3
│   └── examples/
│       └── review-output-sample.md
└── assets/
    └── review-template.md    ← blank review report template
```

---

### SKILL.md (fully annotated)

```markdown
---
name: pr-review
description: Use this skill when the user wants to review a pull request, analyze
a git diff, check code quality, identify security issues, or generate a structured
PR review report. Triggers on: "review this PR", "check my diff", "code review",
"audit this change", "give feedback on my PR". DO NOT invoke for general code
explanation, refactoring, or non-git workflows.
version: 2.1.0
argument-hint: <branch-or-diff-path> [--security-only] [--summary-only]
allowed-tools: [Read, Bash, Glob, Grep, Write]
---

# PR Review

Generate structured, actionable pull request reviews: security audit, code quality
analysis, and a machine-readable report — all from a git diff or branch name.

## When to invoke
- User provides a branch name, PR URL, or diff file to review
- User says "review", "audit", "check my changes", or "give feedback"
- Workflow involves git, GitHub, GitLab, or any VCS diff format
- DO NOT invoke when: the user wants code explanation, test generation,
  or refactoring without a diff — use the appropriate task-specific skill instead

## 📦 Prerequisites & Context
- **Runtime**: Git ≥ 2.30, Python ≥ 3.10
- **Hook dependency**: `check_secrets.sh` PreToolUse hook MUST be active
  (merge `scripts/hooks/settings-snippet.json` into `~/.claude/settings.json`)
- **Assumptions**: Working directory is a git repository; the target branch exists
- **Exclusions**: Does not create PRs, merge branches, or run CI pipelines

## 🛠 Toolchain
| Tool | Purpose | Constraint |
|------|---------|------------|
| `Bash` | Run git commands, call analyze_diff.py | Only git read commands allowed |
| `Grep` | Scan for patterns in changed files | Read-only |
| `Write` | Output review report | Only to designated output path |
| `Read` | Read changed files for context | Changed files only |

## 📋 Execution Workflow

### Phase 1: Diff Extraction
1. Accept input: branch name, diff file path, or raw diff in chat
2. If branch name: `git diff main...<branch> --stat --unified=5`
3. Parse with: `python scripts/analyze_diff.py --input <diff> --json`
4. Output: structured list of changed files, line ranges, and change types
- ✅ Success: Diff parsed; at least one changed file identified
- 🔄 Fallback: If git command fails, ask user to paste the diff directly

### Phase 2: Code Quality Analysis
1. For each changed file:
   - Check complexity (functions > 20 lines, nesting > 3 levels)
   - Check naming conventions (language-appropriate)
   - Check error handling (try/catch, None guards, type assertions)
   - Check test coverage (new functions without tests)
2. Severity tagging: 🔴 Critical | 🟡 Warning | 🟢 Suggestion
- ✅ Success: Every changed file has at least one review comment or explicit LGTM
- 🔄 Fallback: If file is binary or auto-generated (check header), skip with a note

### Phase 3: Security Audit
1. Load and follow `references/security-checklist.md`
2. Scan for: secrets, SQL injection, XSS vectors, insecure deserialization,
   path traversal, hardcoded credentials, unsafe eval/exec usage
3. Any Critical security finding MUST block the review with a top-level ⛔ warning
- ✅ Success: All items in security checklist checked; findings documented
- 🔄 Fallback: If uncertain about a pattern, flag as 🟡 Warning with reasoning

### Phase 4: Report Generation
1. Copy `assets/review-template.md` to `/tmp/pr-review-<branch>-<date>.md`
2. Fill in all sections (summary, per-file findings, security audit, decision)
3. Decision: APPROVE ✅ | REQUEST CHANGES 🔄 | BLOCK ⛔
4. Print report path and one-liner verification
- ✅ Success: Report file exists, is valid Markdown, has all required sections
- 🔄 Fallback: If Write fails, print report to chat and note the permission issue

## ⚠️ Rules & Guardrails
- **MUST**: Review every changed file — never skip without logging a reason
- **MUST**: Block (BLOCK ⛔) if any Critical security finding exists
- **MUST NOT**: Suggest changing files outside the diff scope
- **MUST NOT**: Hardcode paths — use relative paths from repository root
- **SHOULD**: Link each finding to a specific line number in the diff
- **SHOULD**: Provide a suggested fix for every 🔴 Critical finding
- **Quality Gate**: `python scripts/validate.py SKILL.md && markdownlint /tmp/pr-review-*.md`
- **Security**: If check_secrets.sh hook fires, halt immediately and report to user

## 📤 Output Specification
- Review report: `/tmp/pr-review-<branch>-<timestamp>.md`
- Format: Markdown with required sections (see `assets/review-template.md`)
- Code blocks: language-tagged (```python, ```bash, ```diff)
- Required sections: Summary, Per-file Findings, Security Audit, Decision
- Validation: `markdownlint <report-path>` must exit 0

## 💡 Examples & Edge Cases
- **Typical**: `"Review my feature/auth-refactor branch"`
- **Paste diff**: User pastes raw diff — skip Phase 1 git step, go straight to analyze
- **Security only**: `"--security-only flag"` → skip Phase 2, focus Phase 3
- **Large diff (>500 files)**: Warn user, review top 20 by risk score only
- **Limitations**: No GitHub API access; cannot check CI status or existing review comments

> 📖 For security checklist details, read: `references/security-checklist.md`
> 📖 For review report format, see: `references/examples/review-output-sample.md`
```

---

## Annotation Notes

**Why multi-phase?**
Each phase can fail independently. By separating diff extraction (Phase 1) from security analysis (Phase 3), a failing `git diff` command doesn't abort the security review of a pasted diff.

**Why `scripts/analyze_diff.py` instead of inline Bash?**
Diff parsing is complex (binary files, renames, mode changes). Externalizing it keeps SKILL.md readable and makes the parser testable in isolation.

**Why `references/security-checklist.md`?**
A security checklist grows. Keeping it in a reference file lets it be updated independently of the skill version, and it's only loaded during Phase 3 — saving tokens on quick Phase 1 failures.

**Why `assets/review-template.md`?**
Ensures consistent output structure across all reviews. Claude copies it rather than generating structure from scratch each time.

**Why the hook dependency?**
PR reviews should NEVER commit secrets. Declaring the hook dependency in Prerequisites makes it clear this is a hard runtime requirement, not a nice-to-have.
