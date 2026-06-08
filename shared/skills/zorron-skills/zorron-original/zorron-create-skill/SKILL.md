---
name: zorron-create-skill
description: "Use this skill to analyze and distill an AI agent's session conversation history, debugging steps, and problem-solving experiences into a reusable agent skill (SKILL.md). Triggers on: 'distill session to skill', 'convert conversation to skill', 'turn this session into a skill', 'extract skill from conversation', 'write skill from debugging logs'. DO NOT invoke for general chat summarization or unrelated markdown writing."
---

# Zorron Create Skill (Session Distillation)

A meta-skill designed to analyze AI agent conversation histories, extract successful workflows and problem-solving experiences, and package them into highly structured, reusable agent skills (`SKILL.md`) compatible with various agent CLI platforms (including `agy` / `antigravity-cli`, `Claude Code`, `Trae`, `Qwen Code`, etc.).

## When to invoke

- The user asks to "convert this conversation/session into a skill".
- The user provides debugging logs or execution history and wants to "make a skill out of it".
- The user has resolved a complex coding, configuration, or environment issue and wants to formalize the experience into a reusable automation package.
- **DO NOT invoke when**: The user just wants a general summary of a chat session, or when creating basic text documentation unrelated to agent instruction packages.

---

## 📋 Execution Workflow

### Phase 1: Analyze & Distill the Session
1. **Locate the Source**: Retrieve the conversation history. This can be:
   - The active conversation history (available in context).
   - An explicit log file (e.g., `history.jsonl` or `.system_generated/logs/transcript.jsonl`).
   - Copy-pasted chat logs provided by the user.
2. **Identify the Core Elements**:
   - **The Problem**: What was the initial issue or task?
   - **The Resolution**: What was the final, successful sequence of steps, commands, and code changes that solved the problem?
   - **The Learnings & Traps**: What errors were encountered, and what rules/guardrails prevent those errors from happening again?
3. **Formulate the Skill Goal**: Define a single, action-oriented verb-noun name for the target skill (e.g., `deploy-docker-ssh`, `debug-postgres-ports`).

*   ✅ **Success**: You have extracted a clear workflow, pre-requisites, command sequences, and guardrails from the session.
*   🔄 **Fallback**: If the logs are incomplete or ambiguous, interview the user to clarify the successful steps and constraints.

### Phase 2: Draft Multi-Platform Compatible `SKILL.md`
Generate the `SKILL.md` document matching the standard structure.

#### ⚠️ Frontmatter Compatibility Rules (Critical)
To ensure the skill can be loaded by `agy-cli` (antigravity-cli), `Trae`, `Qwen Code`, and `Claude Code`, follow these strict YAML frontmatter rules:
- **`name`**: Must be kebab-case, matching the directory name exactly.
- **`description`**: **MUST** be enclosed in double quotes (`"..."`) if it contains colons (`:`), single quotes, double quotes, or special characters. Colons without quoting will break the YAML parser. Keep it under 90 words.
- **Minimal YAML format**: Do not include optional metadata fields unless necessary. The basic structure is:
  ```yaml
  ---
  name: kebab-case-name
  description: "A quoted description string."
  ---
  ```

#### Canonical Body Structure
```markdown
# Skill Title

<1-2 sentence description of the skill's purpose>

## When to use this skill
- Scenario 1
- Scenario 2
- **DO NOT invoke when**: <exclusion scenario>

## 📦 Prerequisites & Context
- Required global/project tools (e.g., `ssh`, `docker-compose`, `npm`)
- Environment variables or secrets required (e.g., `SERVER_SSH_KEY`)

## 🛠 Toolchain
| Tool | Purpose | Constraint |

## 📋 Execution Workflow
### Phase 1: <Phase Title>
- Step 1...
- Step 2...
- ✅ **Success**: <what success looks like>
- 🔄 **Fallback**: <what to do if steps fail>

## ⚠️ Rules & Guardrails
- **MUST**: <positive constraint, e.g., 'always use double quotes in description if colons are present'>
- **MUST NOT**: <negative constraint, e.g., 'never overwrite a production database without checking the branch name'>
- **SHOULD**: <best practice>

## 💡 Examples & Edge Cases
- Typical user prompt: "..."
- Edge case: <how to handle typical failures>
```

*   ✅ **Success**: The `SKILL.md` file is written with valid YAML frontmatter and standard sections.
*   🔄 **Fallback**: Use the built-in validator script to find and correct structure or syntax errors.

### Phase 3: Extract Helper Scripts & References
If the session workflow involved complex, multi-line scripts or heavy documentation:
1. **Helper Scripts**: Extract them to `scripts/` (e.g., `scripts/deploy.sh` or `scripts/validate.py`). Make sure they are executable (`chmod +x`).
2. **On-demand Reference Docs**: Save them to `references/` (e.g., `references/nginx-stream-config.md`) and point to them in `SKILL.md`.

*   ✅ **Success**: Helper files are successfully created and organized under their respective subfolders.

### Phase 4: Deploy and Verify
Install the compiled skill to the corresponding CLI platforms:
1. **agy / antigravity-cli**:
   - Register it globally:
     ```bash
     npx skills add ./<skill-directory> -g -a '*' -y
     ```
   - Sync to local settings directory:
     ```bash
     cp -R ./<skill-directory> ~/.gemini/antigravity-cli/skills/
     cp -R ./<skill-directory> ~/.gemini/config/skills/
     ```
2. **Claude Code**:
   ```bash
   cp -R ./<skill-directory> ~/.claude/skills/
   ```
3. **Trae CN**:
   ```bash
   cp -R ./<skill-directory> ~/.trae-cn/skills/
   ```

*   ✅ **Success**: Running `npx skills list -g` or checking target directories confirms the skill is registered and loaded by the respective agents.

---

## ⚠️ Rules & Guardrails

- **MUST**: Always wrap the frontmatter `description` value in double quotes (`"..."`) to avoid YAML parsing failures on colons or quotes.
- **MUST NOT**: Include unfinished scripts or `TODO` placeholders in the generated skill folder.
- **SHOULD**: Verify the generated `SKILL.md` using the local validation tool (`python3 scripts/validate.py SKILL.md`) before installing.
