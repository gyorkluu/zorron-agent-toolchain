---
name: deploy-edgeone
description: "Deploy frontend applications and static websites to Tencent Cloud EdgeOne Pages using the EdgeOne CLI. This skill covers EdgeOne CLI installation, project linkage, local development, environment variable management, and automated GitHub Actions CI/CD workflows. DO NOT invoke for standard VPS server deployments via SSH, Vercel deployments, or backend API server setup."
allowed-tools: Bash, Edit, Read, Write
version: 1.0.0
---

# Deploy EdgeOne

Scaffold, build, and deploy frontend projects (e.g., React, Vue, Next.js static, Astro) to Tencent Cloud EdgeOne Pages using the EdgeOne CLI.

## When to invoke
- When you need to build and deploy a static web application to Tencent Cloud EdgeOne Pages.
- When configuring local development, linking folders, or pulling environment variables for EdgeOne Pages.
- When setting up CI/CD automation pipelines (e.g., GitHub Actions) to deploy to EdgeOne Pages.
- **DO NOT invoke when**: You are deploying backend server endpoints directly, configuring standard VPS platforms via SSH/Docker, or deploying to Vercel/Netlify.

## 📦 Prerequisites & Context
- Node.js or Bun runtime environment installed on the target machine.
- A Tencent Cloud account with EdgeOne Pages service enabled.
- API Token generated from the EdgeOne Pages Console for non-interactive/CI deployments.

## 🛠 Toolchain
| Tool | Purpose | Constraint |
| --- | --- | --- |
| `edgeone` CLI | Direct interaction with EdgeOne Pages API | Must be installed globally via npm or bun |
| `edgeone.json` | Configuration of project build parameters | Placed in the frontend root directory |

## 📋 Execution Workflow

### Phase 1: Install and Verify EdgeOne CLI
1. Verify if the `edgeone` CLI is already installed:
   ```bash
   edgeone -v
   ```
2. If it is not found, install it globally using npm or the bundled installer script:
   ```bash
   npm install -g edgeone
   # OR run the helper script: ./scripts/install_edgeone_cli.sh
   ```
- ✅ Success: Running `edgeone -v` prints the version details successfully.
- 🔄 Fallback: If global installation fails due to permissions, retry with `sudo npm install -g edgeone` or install locally within project dependencies and use `npx edgeone`.

### Phase 2: Project Linkage & Configuration
1. Navigate to the frontend project directory and run the initialization/linking process:
   ```bash
   # Initialize EdgeOne Pages local environment configuration
   edgeone pages init
   # Link the directory to an existing EdgeOne Pages project
   edgeone pages link
   ```
2. Confirm the presence of `edgeone.json` in the root directory. If missing, create it using the template in [edgeone_config.json](references/edgeone_config.json):
   ```json
   {
     "buildCommand": "npm run build",
     "outputDirectory": "dist",
     "installCommand": "npm install",
     "devCommand": "npm run dev"
   }
   ```
- ✅ Success: Local configuration `edgeone.json` is set, and the folder is linked to the EdgeOne cloud project.
- 🔄 Fallback: If `edgeone pages link` fails because the cloud project does not exist yet, the CLI will guide you through creating a new project interactively. Follow the prompts to configure project details.

### Phase 3: Local Dev & Environment Variables
1. Run local development with unified function debugging support:
   ```bash
   edgeone pages dev
   ```
   *Note: This starts the server on port 8088 (default) serving both the frontend assets and Edge Functions.*
2. Synchronize environment variables from the cloud console to the local environment:
   ```bash
   edgeone pages env pull
   ```
3. Set or modify environment variables on the cloud console:
   ```bash
   edgeone pages env set VITE_API_URL "https://api.my-app.com"
   ```
- ✅ Success: Dev server starts without errors, and local `.env` values are synchronized via `env pull`.
- 🔄 Fallback: If `env pull` fails due to login expiration, run `edgeone login` (selecting `China` or `Global`) to refresh the authentication session and retry.

### Phase 4: Local Build & Manual Deployment
1. Build the production build locally:
   ```bash
   npm run build
   ```
2. Deploy the built static assets to EdgeOne Pages:
   ```bash
   # For production environment
   edgeone pages deploy ./dist
   # For preview/staging environment
   edgeone pages deploy ./dist -e preview
   ```
- ✅ Success: CLI reports successful upload and returns a preview or production URL (e.g., `project-xxxxx.edgeone.app`).
- 🔄 Fallback: If local deployment fails with a timeout or large bundle error, compress/zip the folder and try `edgeone pages deploy ./dist.zip`.

### Phase 5: CI/CD Pipeline Integration
1. Set up GitHub Actions for automatic deploy on push.
2. Obtain the EdgeOne API Token from the project settings in the console.
3. Save the token as a secret named `EDGEONE_API_TOKEN` in the repository settings.
4. Add the GitHub Action workflow configuration in `.github/workflows/deploy-frontend.yml` using the template in [github_action.yaml](references/github_action.yaml).
- ✅ Success: GitHub Actions runner builds the assets and deploys them using the API token.
- 🔄 Fallback: If CI deployment fails, verify that the API token has sufficient permissions and has not expired, and ensure the project name specified with `-n` is exactly correct.

## ⚠️ Rules & Guardrails
- **MUST**: Always wrap the frontmatter description and configuration values in double quotes if they contain special characters.
- **MUST**: Configure `edgeone.json` with appropriate build/dev commands matching the package manager (`npm`, `pnpm`, or `yarn`) used in the project.
- **MUST NOT**: Commit the generated `.env` file containing secrets to version control.
- **SHOULD**: Run `edgeone pages env pull` prior to starting local development to ensure environment variables are in sync.

## 💡 Examples & Edge Cases

### Example 1: Static Website Deployment Prompt
*User Prompt*: "Deploy the React app under the client folder to EdgeOne Pages."
*Agent Workflow*:
1. Install CLI: `npm install -g edgeone`
2. Navigate: `cd client`
3. Check config: verify `client/edgeone.json` exists
4. Link: `edgeone pages link` and specify project name
5. Deploy: `edgeone pages deploy` (or `edgeone pages deploy ./dist`)

### Example 2: API Gateway Proxy Setup
*Scenario*: The frontend needs to route API requests via Edge Functions instead of direct CORS requests to the backend.
*Resolution*:
- Scaffold Edge Functions inside `edge-functions/api/[[default]].js`.
- Set the proxy endpoint inside the edge function code pointing to the backend origin.
- Use `edgeone pages dev` to test routing locally before deploying.
