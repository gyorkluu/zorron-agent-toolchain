import { parseArgs } from "node:util"

const REGISTRY_URL = process.env.PORTS_REGISTRY_URL
const LOCAL_PATH = process.env.PORTS_REGISTRY_LOCAL_PATH ?? "/tmp/ports-registry.json"

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
  if (!REGISTRY_URL) {
    try {
      return await Bun.file(LOCAL_PATH).json() as PortRegistry
    } catch {
      console.error("No PORTS_REGISTRY_URL and no local cache at " + LOCAL_PATH)
      process.exit(1)
    }
  }
  const res = await fetch(REGISTRY_URL)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  const data = await res.json() as PortRegistry
  await Bun.write(LOCAL_PATH, JSON.stringify(data, null, 2))
  return data
}

function getAllAllocatedPorts(registry: PortRegistry): Set<number> {
  const systemPorts = Object.values(registry.reservedSystemPorts).map(e => e.port)
  const projectPorts = registry.projectPorts.flatMap(p => p.ports.map(e => e.port))
  return new Set([...systemPorts, ...projectPorts])
}

function findNextAvailable(registry: PortRegistry, rangeStart: number, rangeEnd: number): number | null {
  const allocated = getAllAllocatedPorts(registry)
  for (let p = rangeStart; p <= rangeEnd; p++) {
    if (!allocated.has(p)) return p
  }
  return null
}

async function pushToGist(filePath: string): Promise<void> {
  const gistId = process.env.GIST_ID
  const githubToken = process.env.GITHUB_TOKEN
  if (!gistId || !githubToken) {
    console.log("Set GIST_ID and GITHUB_TOKEN to push updates to GitHub Gist")
    console.log("Alternatively, manually upload the updated file to your remote host")
    return
  }

  const content = await Bun.file(filePath).text()
  const res = await fetch(`https://api.github.com/gists/${gistId}`, {
    method: "PATCH",
    headers: {
      "Authorization": `token ${githubToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      files: {
        "ports-registry.json": { content },
      },
    }),
  })

  if (res.ok) {
    console.log("✅ Registry updated on GitHub Gist")
  } else {
    console.error(`❌ Failed to update gist: ${res.status} ${await res.text()}`)
  }
}

async function pushToGitHubRepo(filePath: string): Promise<void> {
  const repo = process.env.GITHUB_REPO
  const githubToken = process.env.GITHUB_TOKEN
  const branch = process.env.GITHUB_BRANCH ?? "main"
  const path = process.env.REGISTRY_FILE_PATH ?? "ports-registry.json"

  if (!repo || !githubToken) {
    console.log("Set GITHUB_REPO and GITHUB_TOKEN to push updates to a GitHub repository")
    return
  }

  const content = btoa(await Bun.file(filePath).text())

  const shaRes = await fetch(
    `https://api.github.com/repos/${repo}/contents/${path}?ref=${branch}`,
    { headers: { "Authorization": `token ${githubToken}` } }
  )
  const sha = shaRes.ok ? (await shaRes.json() as any).sha : undefined

  const body: Record<string, any> = {
    message: "chore: update port registry",
    content,
    branch,
  }
  if (sha) body.sha = sha

  const res = await fetch(
    `https://api.github.com/repos/${repo}/contents/${path}`,
    {
      method: "PUT",
      headers: {
        "Authorization": `token ${githubToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    }
  )

  if (res.ok) {
    console.log("✅ Registry updated on GitHub Repository")
  } else {
    console.error(`❌ Failed to update repo: ${res.status} ${await res.text()}`)
  }
}

async function main() {
  const { values } = parseArgs({
    options: {
      project: { type: "string" },
      location: { type: "string" },
      port: { type: "string", short: "p" },
      service: { type: "string", short: "s" },
      protocol: { type: "string", default: "HTTP" },
      range: { type: "string", short: "r" },
      auto: { type: "boolean", short: "a", default: false },
      push: { type: "string" },
      dry: { type: "boolean", default: false },
      help: { type: "boolean", short: "h", default: false },
    },
    strict: true,
  })

  if (values.help) {
    console.log(`Usage: port-assign [options]

Options:
      --project <name>       Project name (required)
      --location <path>      Project directory path
  -p, --port <number>        Specific port to assign
  -s, --service <name>       Service name for the port
      --protocol <proto>     Protocol (default: HTTP)
  -r, --range <start-end>    Port range to search (e.g. 3000-3999)
  -a, --auto                 Auto-assign from project-appropriate range
      --push <gist|repo>     Push update to remote (gist or repo)
      --dry                  Dry run — show what would change without writing
  -h, --help                 Show this help

Environment:
  PORTS_REGISTRY_URL         Remote URL for the port registry
  PORTS_REGISTRY_LOCAL_PATH  Local cache path (default: /tmp/ports-registry.json)
  GITHUB_TOKEN               GitHub PAT for pushing updates
  GIST_ID                    GitHub Gist ID (for --push gist)
  GITHUB_REPO                GitHub repo in owner/repo format (for --push repo)
  GITHUB_BRANCH              Branch name (default: main)
  REGISTRY_FILE_PATH         File path in repo (default: ports-registry.json)`)
    return
  }

  if (!values.project) {
    console.error("--project is required")
    process.exit(1)
  }

  const registry = await fetchRegistry()
  const allocated = getAllAllocatedPorts(registry)
  let portToAssign: number | null = null

  if (values.port) {
    portToAssign = parseInt(values.port, 10)
    if (isNaN(portToAssign) || portToAssign < 1 || portToAssign > 65535) {
      console.error(`Invalid port: ${values.port}`)
      process.exit(1)
    }
    if (allocated.has(portToAssign)) {
      console.error(`❌ Port ${portToAssign} is already allocated`)
      process.exit(1)
    }
  } else if (values.range) {
    const parts = values.range.split("-")
    const start = parseInt(parts[0], 10)
    const end = parseInt(parts[1], 10)
    portToAssign = findNextAvailable(registry, start, end)
    if (portToAssign === null) {
      console.error(`❌ No available ports in range ${start}-${end}`)
      process.exit(1)
    }
  } else if (values.auto) {
    const rangeMap: Record<string, [number, number]> = {
      "nextjs": [3000, 3099],
      "react": [3000, 3009],
      "nest": [3100, 3199],
      "nestjs": [3100, 3199],
      "elysia": [3200, 3299],
      "elysiajs": [3200, 3299],
      "express": [3300, 3399],
      "fastify": [3300, 3399],
      "api": [4000, 4099],
      "angular": [4200, 4299],
      "flask": [5000, 5099],
      "python": [5000, 5099],
      "vite": [5173, 5199],
      "vue": [5173, 5199],
      "django": [8000, 8099],
      "webpack": [8000, 8099],
      "storybook": [6006, 6099],
      "strapi": [1337, 1349],
    }
    const projectLower = values.project.toLowerCase()
    let rangeFound = false
    for (const [keyword, [start, end]] of Object.entries(rangeMap)) {
      if (projectLower.includes(keyword)) {
        portToAssign = findNextAvailable(registry, start, end)
        rangeFound = true
        break
      }
    }
    if (!rangeFound) {
      portToAssign = findNextAvailable(registry, 3000, 3999)
    }
    if (portToAssign === null) {
      console.error("❌ No available ports in default range 3000-3999")
      process.exit(1)
    }
  } else {
    console.error("Specify --port, --range, or --auto")
    process.exit(1)
  }

  const serviceName = values.service ?? "Dev Server"
  const protocol = values.protocol
  const location = values.location ?? process.cwd()

  console.log(`\n📋 Port Assignment:`)
  console.log(`   Project:  ${values.project}`)
  console.log(`   Location: ${location}`)
  console.log(`   Port:     ${portToAssign}`)
  console.log(`   Service:  ${serviceName}`)
  console.log(`   Protocol: ${protocol}`)
  console.log()

  if (values.dry) {
    console.log("🔍 Dry run — no changes written")
    return
  }

  const existingProject = registry.projectPorts.find(p => p.project === values.project)
  const newEntry: PortEntry = { port: portToAssign, service: serviceName, protocol }

  if (existingProject) {
    existingProject.ports.push(newEntry)
    console.log(`➕ Added port ${portToAssign} to existing project "${values.project}"`)
  } else {
    registry.projectPorts.push({
      project: values.project!,
      location,
      ports: [newEntry],
    })
    console.log(`🆕 Created new project "${values.project}" with port ${portToAssign}`)
  }

  registry.lastUpdated = new Date().toISOString().split("T")[0] as any

  const outputPath = LOCAL_PATH.replace(".json", "-updated.json")
  await Bun.write(outputPath, JSON.stringify(registry, null, 2))
  console.log(`💾 Updated registry saved to: ${outputPath}`)

  await Bun.write(LOCAL_PATH, JSON.stringify(registry, null, 2))
  console.log(`💾 Local cache updated: ${LOCAL_PATH}`)

  if (values.push === "gist") {
    await pushToGist(outputPath)
  } else if (values.push === "repo") {
    await pushToGitHubRepo(outputPath)
  } else if (values.push) {
    console.error(`Unknown push target: ${values.push}. Use "gist" or "repo".`)
  } else {
    console.log("\n💡 To push to remote, re-run with --push gist or --push repo")
  }
}

main().catch(console.error)
