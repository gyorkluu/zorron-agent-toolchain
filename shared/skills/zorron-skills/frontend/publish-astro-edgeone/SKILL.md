---
name: publish-astro-edgeone
description: "A guide on writing markdown articles and deploying Astro static sites to Tencent Cloud EdgeOne Pages via the EdgeOne CLI."
---

# Publish Astro EdgeOne

Write new markdown articles or notes, build the Astro static project, and deploy the build outputs to Tencent Cloud EdgeOne Pages using the EdgeOne CLI.

## When to use this skill
- When you want to publish a new article, note, or project on the blog.
- When you need to build and deploy the website to Tencent Cloud EdgeOne Pages using the command line.
- **DO NOT invoke when**: You are deploying to other platforms (like Vercel, Netlify, or standard VPS servers via SSH).

## 📦 Prerequisites & Context
- Node.js / Bun runtime environment installed.
- Global npm installation permission (for installing the EdgeOne CLI).
- A Tencent Cloud account with EdgeOne Pages service enabled.
- Access to the target EdgeOne Pages project name.

## 🛠 Toolchain
| Tool | Purpose | Constraint |
| --- | --- | --- |
| `bun` / `npm` | Dependency management and build scripts | Must use `bun run build` for compiling the site |
| `edgeone` CLI | Interacting with Tencent Cloud EdgeOne Pages | Must be installed globally via `npm install -g edgeone` |

## 📋 Execution Workflow

### Phase 1: Write New Content
1. **Choose content type** and create a new Markdown file:
   - **Articles** (Long-form posts): `src/content/articles/<slug>.md`
   - **Micro Notes / Thoughts** (Short notes, snippets, logs): `src/content/notes/<slug>.md`
   - **Projects**: `src/content/projects/<slug>.md`

2. **Add frontmatter headers** matching the collection schema:

   #### For Articles (`src/content/articles/`):
   ```yaml
   ---
   title: "My New Article"
   description: "A short summary of the article."
   pubDate: 2026-06-07
   tags: ["Tech", "Astro"]
   category: "Development"
   draft: false
   language: "cn"  # 'cn' or 'en'
   ---
   ```

   #### For Micro Notes / Thoughts (`src/content/notes/`):
   ```yaml
   ---
   date: 2026-06-07
   tags: ["AI", "UI Design"]
   category: "idea"      # 'idea' (amber badge), 'snippet' (blue badge), or 'log' (emerald badge)
   language: "cn"        # 'cn' or 'en'
   ---
   ```

   #### For Projects (`src/content/projects/`):
   ```yaml
   ---
   title: "My Project Name"
   description: "A short introduction to the project."
   status: "active"      # 'active' (active development), 'completed' (done), or 'experimental' (sandbox/testing)
   tags: ["Go", "React"]
   link: "https://github.com/zorron-labs/my-project"
   order: 1              # Sort weight for display ordering (lower numbers or custom sorting, default 0)
   language: "cn"        # 'cn' (Chinese view) or 'en' (English view)
   ---
   ```

3. **Write Content Body**:
   - For articles, write long-form Markdown.
   - For micro notes/thoughts, write short thoughts, snippets, or bulleted logs directly in the Markdown body. Code blocks inside micro notes are also supported and will be highlighted.
   - For projects, write a one-sentence summary or full description in Markdown that is rendered as detailed tooltip/info.

4. **Local Verification**:
   - Start the local dev server using `bun run dev`.
   - Open your browser to test rendering:
     - Articles: `http://localhost:3004/articles`
     - Micro-Thoughts / Notes: `http://localhost:3004/notes`
   - Verify that formatting looks correct, syntax highlighting works, and the correct category badges apply.

- ✅ **Success**: The new content is written, passes schema validation, and displays correctly locally.
- 🔄 **Fallback**: If frontmatter validation fails, Astro dev server will throw errors in the console. Correct the invalid fields according to the Zod schema in `src/content/config.ts`.

### Phase 2: Build & Compile
1. Run the production build command from the project root:
   ```bash
   bun run build
   ```
2. Verify that the static build succeeds and outputs files to the `dist/` directory.
- ✅ **Success**: Build completed with zero compilation errors, and `dist/index.html` exists.
- 🔄 **Fallback**: If the build fails, trace compile/type errors (e.g. invalid frontmatter dates or typescript interfaces) and fix them before proceeding.

### Phase 3: Deploy via EdgeOne CLI
1. **Install EdgeOne CLI** globally (if not already installed):
   ```bash
   npm install -g edgeone
   ```
2. **Log in** to your Tencent Cloud account:
   ```bash
   edgeone login
   ```
   *Follow the browser prompts to authenticate. Confirm status via `edgeone whoami`.*
3. **Initialize EdgeOne Pages** configuration (only needed once per project):
   ```bash
   edgeone pages init
   ```
   *Select the appropriate project or create a new one, and configure the build output directory as `dist`.*
4. **Deploy the compiled site**:
   ```bash
   edgeone pages deploy
   ```
   *If prompted, confirm the upload of the `dist/` directory.*
- ✅ **Success**: The CLI output confirms a successful upload and provides the deployment preview or production URL.
- 🔄 **Fallback**:
  - If deployment fails due to unauthorized access, run `edgeone login` again to refresh credentials.
  - If it fails due to incorrect output folder settings, review the `edgeone.json` configuration file in the project root and ensure the static output path is correctly set to `dist`.

## ⚠️ Rules & Guardrails
- **MUST**: Always run `bun run build` immediately before running `edgeone pages deploy` to ensure your deployment contains the latest content.
- **MUST**: Wrap the frontmatter description and title strings in double quotes if they contain special characters (like colons or single quotes).
- **MUST NOT**: Commit credentials or API keys to the repository.
- **SHOULD**: Set `draft: true` in the frontmatter if the article is still in progress, so it does not get published during deployment.

## 💡 Examples & Edge Cases
- **Typical user prompt**: "Build and deploy the blog to EdgeOne" or "Publish my new article to Tencent Cloud EdgeOne Pages."
- **Example: Publishing a Micro-thought**:
  1. Create `src/content/notes/my-new-thought.md`.
  2. Put the following content:
     ```yaml
     ---
     date: 2026-06-07
     tags: ["Astro", "Tailwind"]
     category: "snippet"
     language: "cn"
     ---
     这是一个关于 Astro 和 Tailwind 的代码片段。
     ```
  3. Run `bun run build` followed by `edgeone pages deploy`.
- **Edge Case - Large File Uploads**: If the deployment fails due to timeout or network errors because of many static files, package the build output or check the network connection:
  - Check the size of the `dist/` folder.
  - Re-run `edgeone pages deploy` to retry.
