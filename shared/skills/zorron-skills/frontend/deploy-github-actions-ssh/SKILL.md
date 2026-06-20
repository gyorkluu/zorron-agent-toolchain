---
name: deploy-github-actions-ssh
description: "Use this skill to configure, debug, and automate project deployments from GitHub Actions to any target server via SSH, supporting direct routing, proxy jump hosts, and key troubleshooting. DO NOT invoke for serverless platform deployments (e.g., Vercel, Netlify) that do not require SSH access."
---

# Deploy GitHub Actions SSH

A highly generic and reusable skill designed to guide developers through configuring, debugging, and automating project deployments from GitHub Actions to any remote Linux/Unix target server using SSH. It handles direct routing, NAT traversal (via VPS proxies/jump hosts), and common SSH authentication/key-parsing issues.

## When to use this skill

- Setting up a continuous deployment (CD) pipeline using GitHub Actions to push code or trigger rebuilds on a remote server.
- Resolving SSH connectivity problems during workflow runs (e.g., runner timeouts, connection refused, or `ssh.ParsePrivateKey` failures).
- Securing remote SSH connections from public runners to private hosting environments or homelabs.
- **DO NOT invoke when**: Setting up local-only CI (lint/test), deploying to serverless platforms, or using agent-specific push mechanisms that bypass SSH.

---

## 📦 Prerequisites & Context

Before setting up the deployment, ensure the following parameters are gathered or configured:
- **Target Host**: The destination IP address or domain name. If behind NAT, a proxy VPS or jump host may be required.
- **SSH Credentials**: A dedicated user account on the target machine with limited privileges (to minimize security risks).
- **SSH Key Pair**: Ed25519 or RSA keys. The **public key** must be appended to the target user's `~/.ssh/authorized_keys`, and the **private key** must be saved as a GitHub Repository Secret.

---

## 📋 Execution Workflow

### Phase 1: Set up Remote SSH Access
Ensure the target server accepts connections from the GitHub Actions runner.
1. **Generate Keys**: Recommend generating a dedicated key pair for deployment (Ed25519 is preferred):
   ```bash
   ssh-keygen -t ed25519 -C "github-actions-deploy" -f ./id_ed25519_deploy
   ```
2. **Authorize Key**: Append the public key (`id_ed25519_deploy.pub`) to the target server's authorized list:
   ```bash
   cat id_ed25519_deploy.pub >> ~/.ssh/authorized_keys
   ```
3. **Verify Directory Permissions**: Target folder permissions must be strict:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

*   ✅ **Success**: A local terminal can connect to the target server using the newly generated private key.
*   🔄 **Fallback**: If access is denied, check `sshd_config` for `PubkeyAuthentication yes` and inspect `/var/log/auth.log` on the target server.

### Phase 2: Route Through NAT (If target is behind private network)
If the runner cannot directly reach the target server:
- **Option A: VPS Port Forwarding (TCP Tunnel)**: Configure a public VPS to forward a specific TCP port (e.g. `802`) to the target server's SSH port using Nginx stream proxy:
  ```nginx
  stream {
      server {
          listen <FORWARD_PORT>;
          proxy_pass <INTERNAL_TARGET_IP>:22;
      }
  }
  ```
- **Option B: SSH Jump Host**: Configure the Actions workflow to tunnel SSH through an intermediate jump host.

*   ✅ **Success**: The proxy endpoint is reachable externally via SSH.
*   🔄 **Fallback**: Confirm VPS firewall allows traffic on the custom port, and verify Nginx stream module is loaded.

### Phase 3: Configure GitHub Secrets
Store credentials as Repository Secrets (`Settings` -> `Secrets and variables` -> `Actions`):
- `DEPLOY_HOST`: Public target IP or domain (e.g., `deploy.example.com`).
- `DEPLOY_PORT`: SSH port (default is `22`, or proxy port).
- `DEPLOY_USER`: Deployment user (e.g., `deployer` or `root`).
- `DEPLOY_KEY`: The complete multiline **private key** (including headers/footers).

*   ✅ **Success**: All deployment variables are securely saved in GitHub Secrets.
*   🔄 **Fallback**: Double check that the private key was copied, not the public key (common mistake).

### Phase 4: Write standard GitHub Actions Workflow
Create `.github/workflows/deploy.yml` with generic deployment instructions:
```yaml
name: Deploy Application
on:
  push:
    branches:
      - main  # Trigger on push to main branch
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.DEPLOY_HOST }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_KEY }}
          port: ${{ secrets.DEPLOY_PORT }}
          script: |
            # Navigate to application directory
            cd /var/www/my-app || cd ~/apps/my-app
            
            # Pull latest changes
            git pull origin main
            
            # Restart or rebuild container/process
            if [ -f "docker-compose.yml" ]; then
              docker compose down && docker compose up -d --build
            elif [ -f "package.json" ]; then
              npm install --production && pm2 restart all
            else
              sudo systemctl restart my-service
            fi
```

*   ✅ **Success**: Runner deploys, code pulls, and processes restart successfully.
*   🔄 **Fallback**: Run simple checks first (e.g., `script: uname -a`) to decouple network issues from project build errors.

---

## ⚠️ Rules & Guardrails

- **MUST**: Ensure `DEPLOY_KEY` secret begins with `-----BEGIN ...` and ends with `-----END ...`.
- **MUST**: Target specific path folders (use `cd ... || exit 1`) in execution scripts to prevent commands from running in the home directory on pull failure.
- **MUST NOT**: Store plain-text secrets in the repository's `.github/workflows/` files.
- **SHOULD**: Use a non-root deployment user with limited sudo privileges to run only necessary restart commands.

---

## 💡 Examples & Edge Cases

### Edge Case: SSH Parse Private Key Error
**Error**: `ssh.ParsePrivateKey: ssh: no key found`.
**Cause**: The secret contains the public key, the private key is missing a trailing newline, or copy-pasting introduced corrupted spaces.
**Fix**: Generate a clean PEM-formatted key pair and update the GitHub secret, ensuring the entire block (with header and footer) is copied exactly.
