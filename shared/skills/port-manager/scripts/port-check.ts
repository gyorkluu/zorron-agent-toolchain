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
      const local = await Bun.file(LOCAL_PATH).json()
      return local as PortRegistry
    } catch {
      console.error("No PORTS_REGISTRY_URL set and no local cache found at " + LOCAL_PATH)
      console.error("Set PORTS_REGISTRY_URL to your remote registry URL")
      process.exit(1)
    }
  }

  try {
    const res = await fetch(REGISTRY_URL)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json() as PortRegistry
    await Bun.write(LOCAL_PATH, JSON.stringify(data, null, 2))
    return data
  } catch (err) {
    console.error(`Failed to fetch registry from ${REGISTRY_URL}: ${err}`)
    try {
      const local = await Bun.file(LOCAL_PATH).json()
      console.error("Using cached local copy")
      return local as PortRegistry
    } catch {
      console.error("No local cache available either")
      process.exit(1)
    }
  }
}

function getAllAllocatedPorts(registry: PortRegistry): number[] {
  const systemPorts = Object.values(registry.reservedSystemPorts).map(e => e.port)
  const projectPorts = registry.projectPorts.flatMap(p => p.ports.map(e => e.port))
  return [...new Set([...systemPorts, ...projectPorts])].sort((a, b) => a - b)
}

function isPortAllocated(registry: PortRegistry, port: number): boolean {
  return getAllAllocatedPorts(registry).includes(port)
}

async function checkOsPort(port: number): Promise<boolean> {
  try {
    const proc = Bun.spawn(["lsof", "-i", `:${port}`, "-P", "-n"], {
      stdout: "pipe",
      stderr: "pipe",
    })
    await proc.exited
    return proc.exitCode === 0
  } catch {
    return false
  }
}

function findNextAvailable(registry: PortRegistry, rangeStart: number, rangeEnd: number): number | null {
  const allocated = new Set(getAllAllocatedPorts(registry))
  for (let p = rangeStart; p <= rangeEnd; p++) {
    if (!allocated.has(p)) return p
  }
  return null
}

function findPortOwner(registry: PortRegistry, port: number): string | null {
  for (const sysKey of Object.keys(registry.reservedSystemPorts)) {
    if (registry.reservedSystemPorts[sysKey].port === port) {
      return `system:${sysKey} (${registry.reservedSystemPorts[sysKey].service})`
    }
  }
  for (const project of registry.projectPorts) {
    for (const pe of project.ports) {
      if (pe.port === port) {
        return `project:${project.project} (${pe.service})`
      }
    }
  }
  return null
}

async function main() {
  const { values } = parseArgs({
    options: {
      port: { type: "string", short: "p" },
      range: { type: "string", short: "r" },
      list: { type: "boolean", short: "l", default: false },
      os: { type: "boolean", short: "o", default: false },
      project: { type: "string" },
      help: { type: "boolean", short: "h", default: false },
    },
    strict: true,
  })

  if (values.help) {
    console.log(`Usage: port-check [options]

Options:
  -p, --port <number>     Check if a specific port is available
  -r, --range <start-end> Find next available port in range (e.g. 3000-3999)
  -l, --list              List all allocated ports from registry
  -o, --os                Also check OS-level port availability
      --project <name>    Filter list by project name
  -h, --help              Show this help

Environment:
  PORTS_REGISTRY_URL       Remote URL for the port registry
  PORTS_REGISTRY_LOCAL_PATH  Local cache path (default: /tmp/ports-registry.json)`)
    return
  }

  const registry = await fetchRegistry()

  if (values.list) {
    const ports = getAllAllocatedPorts(registry)
    console.log(`\nAllocated ports (${ports.length} total):\n`)

    console.log("System Reserved:")
    for (const [key, entry] of Object.entries(registry.reservedSystemPorts)) {
      if (values.project && values.project !== "system") continue
      console.log(`  ${String(entry.port).padStart(5)}  ${entry.service.padEnd(25)} ${entry.note ?? ""}`)
    }

    console.log("\nProject Allocations:")
    for (const project of registry.projectPorts) {
      if (values.project && project.project !== values.project) continue
      console.log(`  [${project.project}] (${project.location})`)
      for (const pe of project.ports) {
        console.log(`    ${String(pe.port).padStart(5)}  ${pe.service.padEnd(25)} ${pe.protocol}`)
      }
    }
    return
  }

  if (values.port) {
    const port = parseInt(values.port, 10)
    if (isNaN(port) || port < 1 || port > 65535) {
      console.error(`Invalid port: ${values.port}`)
      process.exit(1)
    }

    const owner = findPortOwner(registry, port)
    if (owner) {
      console.log(`❌ Port ${port} is ALLOCATED by: ${owner}`)
    } else {
      console.log(`✅ Port ${port} is AVAILABLE in registry`)
    }

    if (values.os) {
      const osInUse = await checkOsPort(port)
      if (osInUse) {
        console.log(`⚠️  Port ${port} is in use at OS level (lsof)`)
      } else {
        console.log(`✅ Port ${port} is free at OS level`)
      }
    }
    return
  }

  if (values.range) {
    const parts = values.range.split("-")
    if (parts.length !== 2) {
      console.error("Range format: start-end (e.g. 3000-3999)")
      process.exit(1)
    }
    const start = parseInt(parts[0], 10)
    const end = parseInt(parts[1], 10)
    if (isNaN(start) || isNaN(end)) {
      console.error("Invalid range numbers")
      process.exit(1)
    }

    const next = findNextAvailable(registry, start, end)
    if (next !== null) {
      console.log(`✅ Next available port in range ${start}-${end}: ${next}`)

      if (values.os) {
        const osInUse = await checkOsPort(next)
        if (osInUse) {
          console.log(`⚠️  Port ${next} is in use at OS level, checking next...`)
          for (let p = next + 1; p <= end; p++) {
            const allocated = isPortAllocated(registry, p)
            if (allocated) continue
            const osCheck = await checkOsPort(p)
            if (!osCheck) {
              console.log(`✅ Next truly available port: ${p}`)
              return
            }
          }
          console.log(`❌ No available ports in range ${start}-${end} (OS level)`)
        }
      }
    } else {
      console.log(`❌ No available ports in range ${start}-${end}`)
    }
    return
  }

  console.log("Use --help for usage information")
}

main().catch(console.error)
