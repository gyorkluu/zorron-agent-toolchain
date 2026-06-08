---
name: port-manager
description: "Manage local development port allocation. Prevent port conflicts when starting or creating projects by checking a centralized port registry fetched from a remote source. DO NOT invoke for other unrelated tasks. This skill covers detailed instructions, workflows, prerequisites, and safety guidelines for the task."
allowed-tools: Bash
version: 1.0.0
---

# Port Manager Skill

## Overview

This skill helps agents allocate conflict-free ports for local development projects. It maintains a centralized port registry that can be hosted remotely (GitHub Gist, S3, raw GitHub file, etc.) and fetched via HTTP. When an agent starts a project, creates a new project, or configures services, it **MUST** consult this registry first to avoid port collisions.

## When to invoke

Trigger this skill when the user asks to:
- Create a new project (any web/backend project)
- Start a development server
- Configure a service that needs a port (database, API, frontend, etc.)
- Set up Docker containers or docker-compose with port mappings
- Add a new microservice to an existing project
- Change or reassign ports for an existing project
- **DO NOT invoke when**: The requested task is outside this scope.

## Core Workflow

### Step 1: Fetch the Remote Port Registry

The port registry is a JSON file hosted remotely. Fetch it before any port allocation:

```bash
# Using curl
curl -sL <REMOTE_REGISTRY_URL> -o /tmp/ports-registry.json

# Using bun
bun -e "const r = await fetch('<REMOTE_REGISTRY_URL>'); await Bun.write('/tmp/ports-registry.json', await r.text())"

# Using wget
wget -qO /tmp/ports-registry.json <REMOTE_REGISTRY_URL>
```

**Recommended remote hosting options:**
- **GitHub Gist** (easiest): Create a gist with `ports-registry.json`, use the raw URL
  - URL format: `https://gist.githubusercontent.com/<user>/<gist-id>/raw/ports-registry.json`
- **GitHub Repository**: Store in a private repo, use raw URL
  - URL format: `https://raw.githubusercontent.com/<user>/<repo>/<branch>/ports-registry.json`
- **S3 / Cloudflare R2**: Host as a public or pre-signed URL
- **Self-hosted**: Any HTTP server that serves the JSON file

### Step 2: Check for Port Conflicts

After fetching the registry, check if the desired port is already allocated:

```bash
# Check if a specific port is in use
cat /tmp/ports-registry.json | jq '.projectPorts[].ports[].port' | grep -qx 3000 && echo "CONFLICT" || echo "AVAILABLE"

# List all allocated ports
cat /tmp/ports-registry.json | jq '[.projectPorts[].ports[].port] | sort'

# Check system-level reserved ports
cat /tmp/ports-registry.json | jq '[.reservedSystemPorts[] | .port] | sort'

# Check if a port is occupied by the OS
lsof -i :<PORT> 2>/dev/null || echo "Port is free at OS level"
```

### Step 3: Allocate a New Port

If the desired port is taken, find the next available port in the appropriate range:

```bash
# Find next available port in development range (3000-3999)
ALLOCATED=$(cat /tmp/ports-registry.json | jq '[.projectPorts[].ports[].port, .reservedSystemPorts[] | .port] | flatten | sort | unique')
for port in $(seq 3000 3999); do
  echo "$ALLOCATED" | grep -qw $port || { echo "Next available: $port"; break; }
done
```

### Step 4: Update the Remote Registry

After allocating a port, update the registry and push it back:

```bash
# Add a new project entry using jq
jq --arg name "my-new-project" \
   --arg location "/path/to/project" \
   '.projectPorts += [{
     "project": $name,
     "location": $location,
     "ports": [
       {"port": 3200, "service": "API Server", "protocol": "HTTP"},
       {"port": 3201, "service": "WebSocket", "protocol": "WS"}
     ]
   }]' /tmp/ports-registry.json > /tmp/ports-registry-updated.json
```

**Push updates back to remote:**

For **GitHub Gist**:
```bash
# Using GitHub CLI (gh)
gh gist edit <gist-id> /tmp/ports-registry-updated.json

# Using curl with GitHub API
curl -X PATCH \
  -H "Authorization: token <GITHUB_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"files":{"ports-registry.json":{"content":'"$(cat /tmp/ports-registry-updated.json | jq -c .)"'}}}' \
  https://api.github.com/gists/<gist-id>
```

For **GitHub Repository**:
```bash
# Using GitHub CLI
gh api repos/<owner>/<repo>/contents/ports-registry.json \
  -X PUT \
  -f message="chore: update port registry" \
  -f content="$(base64 < /tmp/ports-registry-updated.json)" \
  -f sha="$(gh api repos/<owner>/<repo>/contents/ports-registry.json --jq '.sha')"
```

For **S3**:
```bash
aws s3 cp /tmp/ports-registry-updated.json s3://<bucket>/ports-registry.json
```

## Port Allocation Rules

1. **Always check the registry first** before assigning any port
2. **Never use system reserved ports** (see `reservedSystemPorts` in the registry)
3. **Use the appropriate port range** for the service type (see `portRanges` in the registry)
4. **Prefer sequential allocation** within a range — find the lowest available port
5. **Document every allocation** — update the registry immediately after assigning
6. **Check OS-level availability** with `lsof -i :<PORT>` as a final verification
7. **Group related services** — a project's ports should be in the same range when possible

## Port Range Reference

| Range | Purpose | Default |
|-------|---------|---------|
| 3000–3099 | Next.js / React / general dev | 3000 |
| 3100–3199 | NestJS dev servers | 3100 |
| 3200–3299 | ElysiaJS dev servers | 3200 |
| 3300–3399 | Express / Fastify dev | 3300 |
| 4000–4099 | General backend APIs | 4000 |
| 4200–4299 | Angular dev servers | 4200 |
| 5000–5099 | Flask / Python dev | 5000 |
| 5173–5199 | Vite dev servers | 5173 |
| 5601–5699 | Kibana | 5601 |
| 6006–6099 | Storybook | 6006 |
| 8000–8099 | Django / Webpack dev | 8000 |
| 8080–8089 | Jenkins / Vue CLI / Hasura | 8080 |
| 8443–8499 | HTTPS dev servers | 8443 |
| 9000–9099 | MinIO / PHP-FPM | 9000 |

See `references/common-ports.md` for the complete list of system and service ports.

## Quick Reference: Programmatic Port Check (Bun/TypeScript)

```typescript
const REGISTRY_URL = process.env.PORTS_REGISTRY_URL
  ?? "https://gist.githubusercontent.com/<user>/<gist-id>/raw/ports-registry.json"

interface PortEntry {
  port: number
  service: string
  protocol: string
}

interface ProjectEntry {
  project: string
  location: string
  ports: PortEntry[]
}

interface PortRegistry {
  reservedSystemPorts: Record<string, PortEntry & { note?: string }>
  projectPorts: ProjectEntry[]
  portRanges: Record<string, { start: number; end: number; note: string }>
}

async function fetchRegistry(): Promise<PortRegistry> {
  const res = await fetch(REGISTRY_URL)
  if (!res.ok) throw new Error(`Failed to fetch registry: ${res.status}`)
  return res.json()
}

function getAllAllocatedPorts(registry: PortRegistry): number[] {
  const systemPorts = Object.values(registry.reservedSystemPorts).map(e => e.port)
  const projectPorts = registry.projectPorts.flatMap(p => p.ports.map(e => e.port))
  return [...systemPorts, ...projectPorts].sort((a, b) => a - b)
}

function isPortAvailable(registry: PortRegistry, port: number): boolean {
  return !getAllAllocatedPorts(registry).includes(port)
}

function findNextAvailable(registry: PortRegistry, rangeStart: number, rangeEnd: number): number | null {
  const allocated = new Set(getAllAllocatedPorts(registry))
  for (let p = rangeStart; p <= rangeEnd; p++) {
    if (!allocated.has(p)) return p
  }
  return null
}
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORTS_REGISTRY_URL` | Remote URL for the port registry JSON | (required) |
| `PORTS_REGISTRY_LOCAL_PATH` | Local cache path for the registry | `/tmp/ports-registry.json` |
| `GITHUB_TOKEN` | GitHub PAT for pushing registry updates | (optional) |

## Files in This Skill

### templates/
- `ports-registry.json` — Full template for the remote port registry file. Copy this to your remote host and customize.

### references/
- `common-ports.md` — Comprehensive list of commonly used system and service ports
- `remote-config-guide.md` — Step-by-step guide for setting up the remote registry on different platforms

### scripts/
- `port-check.ts` — CLI tool to check port availability against the registry and OS
- `port-assign.ts` — CLI tool to allocate a port and update the remote registry