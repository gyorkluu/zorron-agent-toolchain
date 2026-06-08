---
name: zorron-create-skill
description: "Use this skill to analyze and distill an AI agent's session conversation history, debugging logs, or experience into a reusable agent skill (SKILL.md), or update an existing skill. Triggers on: 'distill session to skill', 'create a new skill', 'update existing skill', 'add gotchas to skill', 'extract skill from conversation'. DO NOT invoke for general chat summarization or unrelated markdown writing."
allowed-tools: Bash
version: 1.1.1
---

# Zorron Create & Update Skill (Session Distillation & Refinement)

A meta-skill designed to analyze AI agent conversation histories, extract successful workflows, and package or update them into structured, reusable agent skills (`SKILL.md`) compatible with various agent CLI platforms (including `agy` / `antigravity-cli`, `Claude Code`, `Trae`, `Qwen Code`, etc.).

## When to invoke
- The user asks to "convert this conversation/session into a skill".
- The user provides debugging logs or execution history and wants to "make a skill out of it" or "create a new skill".
- The user wants to "update an existing skill", "add a new gotcha to a skill", "add a rule to a skill", or "bump a skill's version".
- **DO NOT invoke when**: The user just wants a general summary of a chat session, or when creating basic text documentation unrelated to agent instruction packages.

---

## 📋 Execution Workflow
### Phase 1: Analyze & Distill the Session
1. **Locate the Source**: Retrieve the conversation history (context), log files (e.g., `transcript.jsonl`), or copy-pasted chat logs.
2. **Identify the Core Elements**:
   - **The Problem**: What was the initial issue?
   - **The Resolution**: What was the final, successful sequence of steps and commands?
   - **The Gotchas**: What errors were encountered (tricky details, traps, things the model wouldn't know by default)?
   - **The Rules**: What hard constraints prevent errors from reoccurring?
3. **Formulate the Skill Goal**: Define a single, action-oriented kebab-case name for the skill (e.g., `deploy-docker-ssh`).

- ✅ Success: Clean workflow, triggers, prerequisites, command sequences, and gotchas extracted.
- 🔄 Fallback: Interview the user to clarify successful steps and constraints if logs are incomplete.

### Phase 2: Create or Update the Skill
1. **Creation Mode**: Run the scaffold script to create a new skill directory:
   ```bash
   python3 scripts/scaffold.py --name <skill-name> --output <dir>
   ```
2. **Update Mode**: Run the scaffold script with `--update` to modify or append content to an existing skill:
   ```bash
   python3 scripts/scaffold.py --update <skill-dir> --gotcha "staging returning 200 doesn't mean success" --version-bump patch
   ```
   *Sub-options available: `--gotcha`, `--rule`, `--trigger`, `--description`, `--version-bump`.*

- ✅ Success: The skill directory and `SKILL.md` are updated or created.
- 🔄 Fallback: If `SKILL.md` fails parsing, manually edit the file to fix any invalid Markdown or YAML structures.

### Phase 3: Extract Helper Scripts & References
Following the principles of **Context Engineering**:
1. Move heavy procedural code and repetitive operations into executable scripts under `scripts/`. Make sure they are executable:
   ```bash
   chmod +x <skill-dir>/scripts/<script-file>
   ```
2. Place API specifications, checklists, and documentation under `references/`.
3. Reference these files using markdown links inside `SKILL.md` (e.g., `[pages_spec](references/pages_spec.md)`).

- ✅ Success: Helpers and references are created and successfully linked.
- 🔄 Fallback: Document manual commands directly in the `SKILL.md` body if scripts are unnecessary.

### Phase 4: Deploy and Verify
1. Run the local validator on `SKILL.md` to ensure structural compliance:
   ```bash
   python3 scripts/validate.py <skill-dir>/SKILL.md
   ```
2. Sync the compiled skill to the corresponding CLI platforms:
   ```bash
   # Sync to local antigravity-cli settings
   cp -R ./<skill-directory> ~/.gemini/antigravity-cli/skills/
   ```

- ✅ Success: Running the validation script returns a `PASS` and files are copied to the active skills folder.
- 🔄 Fallback: Correct the errors reported by the validation script and retry.

---

## ⚠️ Rules & Guardrails
- **MUST**: Always wrap the frontmatter `description` value in double quotes (`"..."`) to avoid YAML parsing failures on colons or quotes.
- **MUST**: Ensure the skill `name` in frontmatter matches the directory name exactly.
- **MUST NOT**: Put long tables or bulky API documentations directly in `SKILL.md`; instead, push them to `references/` for clean context engineering.
- **SHOULD**: Extract repetitive commands to `scripts/` instead of listing them step-by-step in the instructions.

---

## ⚠️ Gotchas & Tricky Details (常踩的坑)
- **Description is a Router**: The `description` in YAML frontmatter is not a simple feature summary. The LLM uses it to route queries. If it lacks clear trigger intents or is too vague, the skill will not be loaded when needed. Always include an intent-based trigger phrase and a "DO NOT invoke" exclusion rule.
- **Double Quote YAML Frontmatter**: If the YAML frontmatter description contains a colon (`:`), bracket (`[`), or quotes, you must quote the entire string (`"..."`). Otherwise, the YAML parser will throw a syntax error and fail to load the skill.
- **Script Executability**: Any script placed in `scripts/` must be marked executable via `chmod +x` before distribution, otherwise executing it will fail with permission denied errors.
- **Progressive Context Disclosure**: Do not inflate the token cost by stuffing examples and raw docs in `SKILL.md`. Use `SKILL.md` as an index, and link files in `references/` or `examples/` so the model only pulls them when needed.

---
- **Gotcha**: Avoid spaces in custom action parameters.

## 💡 Examples & Edge Cases
- **Typical Creation Prompt**: "distill this session into a new skill named deploy-edgeone"
- **Typical Update Prompt**: "add a gotcha to deploy-edgeone skill about the dist directory requirement"
  *Workflow*:
  ```bash
  python3 scripts/scaffold.py --update ./deploy-edgeone --gotcha "Manual CLI deploys must copy edge-functions into the output dir" --version-bump patch
  ```
- **Edge Case**: YAML parser error on loading.
  *Remediation*: Check for colons in `description` and verify they are enclosed in double quotes.
