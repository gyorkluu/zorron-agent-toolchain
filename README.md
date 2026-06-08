# Zorron Agent Toolchain

> 你的 AI 编程环境基础设施 — 一次配置，随处同步，零摩擦扩展

```
  __ _  ___ _ __ ___  _ __ __ _
 / _` |/ _ \ '_ ` _ \| '__/ _` |
| (_| |  __/ | | | | | | | (_| |
 \__, |\___|_| |_| |_|_|  \__,_|
 |___/
```

## 这是什么？

**Zorron Agent Toolchain** 是一个可克隆即用的 AI 编程工具配置管理方案。它解决了这样一个问题：你在不同的机器上使用不同的 AI 编程工具（Claude Code、Hermes Agent、OpenCode 等），每台机器的配置都不同，管理起来非常混乱。

通过 Zorron，你只需要维护一个 Git 仓库，在任何新机器上 `git clone && ./install.sh` 即可自动部署所有配置。

## 核心特性

- **环境智能适配** — 自动扫描已安装的工具，按需部署配置
- **一次配置，随处同步** — Git 仓库就是你的"配置母版"
- **零摩擦扩展** — 新增 Skill、MCP 服务、新工具只需创建文件，无需改核心脚本
- **多层级覆盖** — 通用 < 工具 < 主机 < 本地，灵活又不混乱
- **敏感信息隔离** — 密钥和内部地址不入库，安全可控
- **幂等安装** — 多次运行不会破坏已有配置

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/zorron-ai/zorron-agent-toolchain.git ~/zorron-agent-toolchain
cd ~/zorron-agent-toolchain
chmod +x install.sh scripts/zorron
```

### 2. 初始化本地配置

```bash
./scripts/zorron init
```

这会创建：
- `~/.zorron/secrets.local.json` — 密钥配置文件（不入 Git）
- `hosts/<你的主机名>/override/` — 主机级覆盖目录
- `.env.local.example` — 环境变量模板

### 3. 编辑密钥文件

```bash
# 编辑密钥文件，填入你的 API 密钥等敏感信息
vim ~/.zorron/secrets.local.json
```

### 4. 部署配置

```bash
./install.sh
```

脚本会自动检测已安装的工具并部署对应配置：

```
  __ _  ___ _ __ ___  _ __ __ _
 / _` |/ _ \ '_ ` _ \| '__/ _` |
| (_| |  __/ | | | | | | | (_| |
 \__, |\___|_| |_| |_|_|  \__,_|
 |___/

  Agent Toolchain — 你的 AI 编程环境基础设施

ℹ  前置检查...
ℹ  🔍 扫描已安装的 Agent 工具...
✔  检测到工具: claude-code (claude)
ℹ  共检测到 1 个工具: claude-code

ℹ  📦 开始部署配置...
   ➜ 部署 claude-code 配置...
   ✔ 符号链接: ~/.claude/settings.json → ...
   ✔ 符号链接: ~/.claude/CLAUDE.md → ...

ℹ  🔗 合并全局 MCP 服务...
ℹ  📚 部署共享 Skills...
ℹ  📜 部署全局规则...

✔  ✅ Zorron Agent Toolchain 已就绪！
```

## 日常使用

### 同步配置

在任意机器上修改后：

```bash
cd ~/zorron-agent-toolchain
git add -A && git commit -m "update claude settings" && git push
```

在其他机器上更新：

```bash
cd ~/zorron-agent-toolchain && git pull && ./install.sh
```

### 管理助手

```bash
# 查看所有配置
./scripts/zorron list

# 添加新 Skill
./scripts/zorron add skill my-skill

# 添加新 MCP 服务
./scripts/zorron add mcp my-server

# 添加新工具
./scripts/zorron add tool new-agent

# 查看部署状态
./scripts/zorron status

# 管理备份
./scripts/zorron backup list
./scripts/zorron backup restore ~/.claude
```

### ⌨️ 命令行自动补全 (Zsh)

为了在使用 `zorron` 助手时获得子命令和参数的智能补全，可以直接在您的 `~/.zshrc` 中 source 补全脚本：

```bash
source ~/Documents/workspace/zorron-agent-toolchain/scripts/completion.zsh
```

## 目录结构

```
zorron-agent-toolchain/
├── install.sh                   # 核心部署脚本
├── scripts/
│   ├── zorron                   # 命令行助手
│   ├── lib.sh                   # 公共函数库
│   └── backup.sh                # 备份工具
├── shared/                      # 跨工具共享配置
│   ├── skills/                  # 通用 Skills
│   ├── mcp-servers.json         # 全局 MCP 服务定义
│   ├── mcp-servers/             # 拆分式 MCP 服务（自动合并）
│   └── rules/                   # 通用编码规范
├── tools/                       # 各工具专属配置
│   ├── claude-code/
│   ├── hermes-agent/
│   ├── opencode/
│   └── qwen-code/               # 示例模板
├── hosts/                       # 主机级差异化覆盖
│   ├── macbook-pro/
│   └── linux-server/
└── .gitignore
```

## 扩展指南

### 添加新工具

只需三步，核心脚本无需修改：

1. 创建工具目录：`tools/my-agent/`
2. 编写 `target.conf`：

```
DEF_GLOBAL_DIR=~/.my-agent
DEF_PROJECT_DIR=.my-agent
LINK_TYPE=symlink
CLI_CMD=my-agent
```

3. 添加配置文件（如 `config.json`）

或使用快捷命令：

```bash
./scripts/zorron add tool my-agent
```

### 添加新 Skill

```bash
./scripts/zorron add skill my-skill
# 编辑 shared/skills/my-skill/SKILL.md
```

### 添加新 MCP 服务

```bash
./scripts/zorron add mcp my-server
# 或手动创建 shared/mcp-servers/my-server.json
```

### 主机差异化配置

如果某台机器需要特殊配置：

```bash
# 创建主机覆盖目录
mkdir -p hosts/$(hostname -s)/override

# 添加 MCP 覆盖
echo '{"mcpServers":{...}}' > hosts/$(hostname -s)/override/mcp-servers.json

# 添加工具配置覆盖
mkdir -p hosts/$(hostname -s)/override/tools/claude-code
echo '{...}' > hosts/$(hostname -s)/override/tools/claude-code/settings.json

# 重新部署
./install.sh
```

## 配置覆盖优先级

部署时遵循以下覆盖顺序（后面的覆盖前面的）：

1. **shared/** — 通用基础配置
2. **tools/<工具名>/** — 工具默认配置
3. **hosts/<主机名>/override/** — 主机特定覆盖
4. **本地文件** — `*.local.*` 和 `secrets.local.json`（最高优先级）

## 占位符系统

配置文件中支持以下占位符，部署时自动替换：

| 占位符 | 替换为 |
|--------|--------|
| `{{HOME}}` | 当前用户主目录 |
| `{{HOSTNAME}}` | 当前主机名 |
| `{{PROJECT_DIR}}` | 当前项目根目录 |
| `{{USER_HOME}}` | 同 {{HOME}} |

## 安全说明

- **敏感信息不入库** — `.gitignore` 已配置忽略 `*.local*`、`secrets.local.json` 等文件
- **密钥管理** — 通过 `~/.zorron/secrets.local.json` 管理密钥，部署时自动合并
- **自动备份** — 安装前自动备份已有配置，防止误操作

## 依赖

- **必需**: Bash 4+
- **推荐**: `jq`（JSON 处理）、`envsubst`（占位符替换）
- **可选**: 各 Agent 工具的 CLI（claude、hermes、opencode 等）

## Fork 与定制

欢迎 Fork 此项目并改成你自己的品牌：

1. Fork 仓库
2. 修改 `install.sh` 中的品牌信息
3. 替换 `shared/rules/global.md` 为你的编码规范
4. 添加你常用的工具配置
5. 推送到你自己的仓库

## License

MIT License - 详见 [LICENSE](LICENSE)

## 更新日期

最后更新：2026-04-25


---
Updated: 2026-04-25T23:11:24+08:00


---
Sync test: Sat Apr 25 11:18:59 PM CST 2026


---
Auto sync test: Sat Apr 25 11:21:42 PM CST 2026


---
Auto sync test: Sat Apr 25 11:26:13 PM CST 2026
