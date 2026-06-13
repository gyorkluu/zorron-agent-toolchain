---
name: baota-skill
description: "Deploy and manage websites using cli-anything-baota, a CLI harness for BaoTa (宝塔) Panel. Covers site creation, reverse proxy, SSL certificates, DNS via DNSPod/Aliyun/Cloudflare, database management, Nginx config, firewall, and cron tasks. DO NOT invoke for general Nginx or server management without BaoTa Panel."
allowed-tools: Bash, Read, Write
version: 1.0.0
---

# BaoTa Panel Deployment via cli-anything-baota

This skill enables AI agents to deploy and manage websites, reverse proxies, SSL certificates, databases, firewall rules, and DNS records on servers running BaoTa (宝塔) Panel using the `cli-anything-baota` tool.

## When to invoke
- When you need to deploy, configure, or manage static sites or web applications on a server running BaoTa Panel.
- When the user mentions `baota`, `baotapanel`, `btcli`, `宝塔`, or `cli-anything-baota`.
- When automating domain bindings, SSL generation, DNS records mapping, database setups, or firewall ports on a BaoTa-managed VPS.
- **DO NOT invoke when**: The user is managing a server without BaoTa Panel, or doing manual Nginx configurations directly in `/etc/nginx` without utilizing the panel's API/CLI wrappers.

## 📦 Prerequisites & Context
- **BaoTa Panel**: Installed on the target server (default path: `/www/server/panel/`).
- **Python Runtime**: Python 3.7+ installed on the target server.
- **Root Permissions**: sudo/root access is required to invoke local bridge commands.
- **Software Dependencies**: Nginx and MySQL/MariaDB installed via the BaoTa App Store.
- **CLI Harness**: `cli-anything-baota` must be installed on the server:
  ```bash
  pip install git+https://github.com/gyorkluu/CLI-Anything.git@feat/baota#subdirectory=baota/agent-harness
  ```

## 🛠 Toolchain
| Tool | Purpose | Constraint |
| --- | --- | --- |
| `Bash` | Execute CLI queries and operations | Must run directly on the server hosting the BaoTa panel. |
| `Read` | View panel vhost Nginx config files | Target file: `/www/server/panel/vhost/nginx/*.conf`. |
| `Write` | Write or update custom Nginx vhost files | Used for applying WebSocket or proxy header optimizations. |

## 📋 Execution Workflow

### Phase 1: Target System Status Check
1. Run system diagnosis commands to verify panel status and gather public network IPs:
   ```bash
   cli-anything-baota system status
   cli-anything-baota system info
   cli-anything-baota system network
   ```
2. Parse returned logs. Check if the panel is responding and locate the public IPv4/IPv6 addresses.
- ✅ Success: The panel responds successfully (`"status": true`) and public IP is identified.
- 🔄 Fallback: Restart panel services via `cli-anything-baota system restart` or raise a connection warning.

### Phase 2: Database Creation
1. Scan for conflicting databases:
   ```bash
   cli-anything-baota databases list
   ```
2. Create the target MySQL database with custom UTF8MB4 parameters:
   ```bash
   cli-anything-baota databases create \
     --name <db_name> \
     --username <db_user> \
     --password <secure_password> \
     --encoding utf8mb4
   ```
- ✅ Success: Database entry is recorded in the panel and test connection succeeds.
- 🔄 Fallback: Change credentials, verify MySQL service status, or drop the entry and retry.

### Phase 3: Site Creation
Choose the target deployment architecture:
- **Option A (Static Site)**:
  ```bash
  cli-anything-baota sites create --domain <domain> --path <root_path> --php-version 00
  ```
- **Option B (Site + Reverse Proxy)**:
  1. Create static vhost placeholder first:
     ```bash
     cli-anything-baota sites create --domain <domain> --path <root_path> --php-version 00
     ```
  2. Query the generated ID using `--json` mapping:
     ```bash
     cli-anything-baota --json sites list
     ```
  3. Bind the proxy pointing to the local application port:
     ```bash
     cli-anything-baota sites proxy create <SITE_ID> --target http://127.0.0.1:<port> --dir /
     ```
- ✅ Success: Vhost is generated and local endpoint successfully responds to test curl.
- 🔄 Fallback: Validate domain uniqueness, inspect port occupancy, or clean up folders and retry.

### Phase 4: Configure DNS Records
1. Set up your DNS API provider secrets (Required for Let's Encrypt DNS verification):
   ```bash
   # DNSPod (Tencent Cloud)
   cli-anything-baota config dns set dnspod --id <DNSPOD_ID> --token <DNSPOD_TOKEN>
   
   # Aliyun DNS
   cli-anything-baota config dns set aliyun --id <ACCESS_KEY_ID> --token <ACCESS_KEY_SECRET>
   
   # Cloudflare
   cli-anything-baota config dns set cloudflare --id <EMAIL> --token <API_KEY>
   ```
2. Map subdomain records to your target server IP:
   ```bash
   cli-anything-baota config dns record add <domain> <sub> A <SERVER_IP>
   ```
- ✅ Success: DNS record successfully registered and propagates to local resolvers.
- 🔄 Fallback: Validate token expiration, verify API rate limits, or direct the user to check the DNS provider console.

### Phase 5: Request Let's Encrypt SSL & Enable Auto-Renewal
1. Trigger Let's Encrypt deployment (DNS validation method is highly recommended):
   ```bash
   # Apply SSL and registers renewal cron task
   cli-anything-baota sites ssl deploy <SITE_ID> --domains <domain> --auth dns
   ```
2. Verify SSL certificate metadata:
   ```bash
   cli-anything-baota sites ssl info <SITE_ID>
   ```
- ✅ Success: Certificate deployed, HTTPS works on the domain, and auto-renewal cron is active.
- 🔄 Fallback: Check domain propagation delays, verify firewall port 80/443 mapping, or fall back to HTTP validation (`--auth http`).

### Phase 6: Optimize Nginx Virtual Host Config
1. Read current vhost Nginx file:
   ```bash
   cli-anything-baota files read /www/server/panel/vhost/nginx/<domain>.conf
   ```
2. Inject custom proxy headers (e.g., WebSocket upgrade, file upload limits) and write back:
   ```bash
   cli-anything-baota files write /www/server/panel/vhost/nginx/<domain>.conf '<CONFIG_CONTENT>'
   ```
- ✅ Success: File writes successfully and Nginx configuration test (`nginx -t`) passes.
- 🔄 Fallback: Restore original configuration file or debug syntax.

### Phase 7: Adjust Panel Firewall Rules
1. Map open ports:
   ```bash
   cli-anything-baota system firewall-open 80 --desc "HTTP Port"
   cli-anything-baota system firewall-open 443 --desc "HTTPS Port"
   ```
2. Confirm active rules:
   ```bash
   cli-anything-baota system firewall-list
   ```
- ✅ Success: Firewalld/iptables rules updated and active.
- 🔄 Fallback: Check local system firewall rules manually (e.g. `ufw` or `firewalld`).

### Phase 8: Final Deployment Validation
1. Verify the setup end-to-end:
   ```bash
   cli-anything-baota sites info <SITE_ID>
   cli-anything-baota cron check-le
   ```
- ✅ Success: Website returns HTTP 200/301, HTTPS is fully active, and LE renewal cron is configured.
- 🔄 Fallback: Check application runtime logs and verify network configuration.

## ⚠️ Rules & Guardrails
- **MUST**: Always run `cli-anything-baota` directly on the server hosting the BaoTa panel.
- **MUST**: Use the `--json` option for all automated scripts and programmatic calls to parse returned structures reliably.
- **MUST**: Use `sites ssl deploy` instead of `ssl apply` to guarantee that auto-renewal tasks are correctly registered in the system crontab.
- **MUST**: Keep internal application ports (like 3201) closed via system firewall. Always route external traffic through Nginx reverse proxy (Port 80/443).
- **MUST NOT**: Execute site deletion (`sites delete`) or database deletion (`databases delete`) commands without explicit, double-confirmed user authorization.
- **MUST NOT**: Commit or expose any sensitive configurations, passwords, or DNS provider tokens in scripts or logs.

## 💡 Examples & Edge Cases

### Example 1: Full Automated Deployment Prompt
*User prompt*: "帮我把 www.my-app.com 部署 to baota, 程序运行在本地 5000 端口，并配置好阿里云解析和 HTTPS。"
*Agent workflow*:
1. Run `cli-anything-baota system status` to verify panel health.
2. Setup Aliyun DNS provider via `cli-anything-baota config dns set aliyun`.
3. Add DNS record A mapping `www` to target IP.
4. Run `cli-anything-baota sites create` to build a website shell.
5. Setup Nginx reverse proxy mapping `/` to `http://127.0.0.1:5000`.
6. Issue SSL certificate via `cli-anything-baota sites ssl deploy <id> --domains www.my-app.com --auth dns`.
7. Configure Nginx virtual host with WebSocket and proxy overrides.
8. Run `cli-anything-baota system firewall-open 80` & `443`.

### Example 2: SSL DNS Validation Fails
*Issue*: SSL deployment exits with error due to DNS propagation delay.
*Resolution*:
- Pause execution for 60 seconds to allow DNS sync.
- Retry the `cli-anything-baota sites ssl deploy` command.
- If failure persists, fall back to HTTP validation:
  ```bash
  cli-anything-baota sites ssl deploy <SITE_ID> --domains <domain> --auth http
  ```