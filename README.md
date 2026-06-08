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

### 2. 初始化本地配置（交互式密钥向导）

在终端中执行以下初始化指令：

```bash
./scripts/zorron init
```

**执行详情**：
1. **自动建目录**：自动创建 Zorron 主配置目录 `~/.zorron`。
2. **主机标识映射**：在 `hosts/` 目录下生成匹配当前机器 hostname 的独立主机级覆盖目录 `hosts/$(hostname -s)/override/`。
3. **🔑 敏感密钥配置向导**：控制台将安全地提示您输入第三方 API Key（例如 `ANTHROPIC_API_KEY`、`OPENAI_API_KEY`）。此阶段通过 `read -s` 隐藏您的终端键入内容防止窥屏，并自动将其生成写入为：
   - `~/.zorron/secrets.local.json` — 本地 MCP 敏感信息配置（不入 Git）
   - `.env.local` — 本地 shell 环境变量（不入 Git）
4. **生成模板**：生成 `.env.local.example` 环境变量模板和 `secrets.local.json.example` JSON 模板。

### 3. 部署配置 (幂等安装)

运行工具链核心部署脚本：

```bash
./install.sh [选项]
```

**命令行可用选项**：
- `--force` 或 `-f`：强制重新部署，不经过交互询问直接覆盖已有配置或冲突的软链接。
- `--dry-run` 或 `-n`：模拟运行（干跑），显示即将执行的操作但不修改任何文件。
- `--verbose` 或 `-v`：详细输出模式，展示扫描路径、版本匹配等底层调试日志。
- `--host <主机名>` 或 `-H <主机名>`：强行指定当前部署的主机名（用于跨机器模拟调试主机覆盖配置）。

**部署步骤逻辑**：
- **第一步 (环境自愈)**：检查共享技能子模块 `shared/skills/zorron-skills` 是否拉取。若为空，自动拉取最新的技能内容。
- **第二步 (工具扫描)**：智能扫描已安装的工具（如 `opencode`、`claude-code`）。
- **第三步 (配置部署)**：部署对应工具配置并应用主机覆盖配置，对 `.json`、`.yaml`、`.md`、`.conf` 等配置文件中的 `{{HOME}}`、`{{HOSTNAME}}` 等环境变量占位符进行自动渲染。
- **第四步 (MCP 合并)**：合并全局 `shared/mcp-servers.json` 与独立文件，生成对应的 MCP 配置（缺少 `jq` 时自动降级）。
- **第五步 (校验与部署 Skill)**：对 Skill 进行静态语法结构校验，并在 `~/.config/<工具名>/skills/` 下建立对应的符号链接。
- **第六步 (规则与备份清理)**：建立全局编程规范软链接，清理超过 30 天的旧备份。

---

## 💻 功能模块与使用指南

### 1. 📚 共享技能模块 (Shared Skills)

该模块负责管理、分发、列表以及校验所有 Agent Skills 资产。

#### 📥 添加新 Skill 模板
```bash
./scripts/zorron add skill <Skill名称> [分类路径]
```
- **示例**：`./scripts/zorron add skill test-helper zorron-skills/frontend`
- **参数说明**：
  - `<Skill名称>`（必需）：Skill 的 kebab-case 英文标识（如 `react-helper`）。
  - `[分类路径]`（可选）：子模块相对目录路径。默认为 `zorron-skills/zorron-original`。
- **动作详情**：在 `shared/skills/[分类路径]/<Skill名称>/` 目录下生成最符合规范的 `SKILL.md` 骨架模板，该模板带有标准的 YAML 头部信息和 "When to invoke"、“Rules & Guardrails” 等字段。

#### 📋 列出已配置的 Skill
```bash
./scripts/zorron list
```
- **动作详情**：递归检索 `shared/skills` 下所有包含 `SKILL.md`/`skill.md` 的文件夹，提取其 YAML 头部的 `description` 值（支持 YAML block scalar `description: |` 读取），并以 `[分类名]/[Skill名称] - [描述]` 格式带有绿色高亮终端彩色输出。

#### 🛡️ 静态结构校验 Skill 规范
```bash
python3 scripts/validate_skill.py <SKILL.md 文件路径> [--strict] [--json]
```
- **参数说明**：
  - `--strict`：严格模式，任何 Warning 警告均会被当做 Error 处理，使退出码变为 1。
  - `--json`：以 JSON 格式输出扫描报告，便于 CI/CD 或 Agent 机器解析。
- **动作详情**：静态分析 Skill 文件结构，验证 YAML 头部的 description 词数限制（推荐 40~100 字）、YAML 头部属性完整性、是否包含 `## When to invoke` 判定条件、是否包含 "DO NOT" 负向排除短语、文件字数是否过长、代码块是否缺失语言 tag 等。

---

### 2. 🔗 MCP 服务集成模块 (MCP Servers)

该模块管理和部署 Model Context Protocol 服务。

#### 📥 声明新的 MCP 服务
```bash
./scripts/zorron add mcp <MCP名称>
```
- **示例**：`./scripts/zorron add mcp filesystem`
- **参数说明**：
  - `<MCP名称>`（必需）：新 MCP 服务器的唯一键值。
- **动作详情**：开启命令行交互：
  1. 选择服务器类型：`stdio`（标准 IO 本地进程）或 `sse`（SSE 远程连接）。
  2. 输入执行命令（如 `bunx`、`node`）、运行参数以及是否需要注入环境变量。
  3. 配置自动写入到 `shared/mcp-servers/` 独立配置文件中，在 `install.sh` 时会自动与全局 `shared/mcp-servers.json` 及 `secrets.local.json` 进行深度合并渲染。

---

### 3. 💾 系统备份与灾备恢复模块 (Backup & Restore)

在任何文件被写入覆盖之前，Zorron 会自动进行本地备份。

#### 📋 查看当前备份清单
```bash
./scripts/zorron backup list [前缀路径]
```
- **示例**：`./scripts/zorron backup list`
- **参数说明**：
  - `[前缀路径]`（可选）：限制只列出该目录下的备份文件。默认为 `$HOME`（用户主目录）。
- **动作详情**：递归扫描并以列表形式打印出当前主机上所有的备份记录（带时间戳 `.backup.YYYYMMDD_HHMMSS` 或符号链接信息 `.symlink`），并展示备份文件/目录的大小。

#### ⏪ 从备份恢复配置
```bash
./scripts/zorron backup restore <原始配置路径> [备份时间戳]
```
- **示例 1（恢复到最近一次备份）**：`./scripts/zorron backup restore ~/.claude/settings.json`
- **示例 2（指定恢复版本）**：`./scripts/zorron backup restore ~/.claude/settings.json 20260608_102917`
- **参数说明**：
  - `<原始配置路径>`（必需）：您想要复原的配置文件/目录路径。
  - `[备份时间戳]`（可选）：格式为 `YYYYMMDD_HHMMSS`。若省略，则自动还原最新生成的一个备份。
- **动作详情**：自动替换损坏的配置为备份版本，并恢复符号链接指针。

---

### 4. 📜 编程规范与规则模块 (Global Rules)

管理 Agent 的全局系统指令。

#### 📝 添加全局编码规则
- **动作**：直接在 `shared/rules/` 目录下新增 `.md` 格式的规则规范文档（例如 `typescript-esm.md`）。
- **执行效果**：无需修改任何配置，在下次执行 `./install.sh` 时，系统会自动将这些规则作为符号链接部署到对应 Agent 的规则目录下（如 Claude Code 的 `~/.claude/CLAUDE.d/rules/`）。

---

### ⌨️ Zsh 命令行自动补全 (Autocomplete)

为了在使用 `zorron` 命令时获得快速输入体验（例如对 `backup restore` 的路径补全，或者 `add skill` 的分类补全）：

在您的 `~/.zshrc` 中添加以下代码来启用补全：

```bash
# 激活 Zorron 自动补全
source ~/Documents/workspace/zorron-agent-toolchain/scripts/completion.zsh
```

重新加载终端即可生效：`source ~/.zshrc`。

---

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

## 🍴 Fork 独立定制与长期使用指南

Zorron Agent Toolchain 鼓励开发者 Fork 并定制专属于您（或您团队）的个人 AI 编程基础设施配置库。

### 1. ⚙️ Fork 后的独立使用 (无须提 PR)
- **长期独立维护**：Fork 本仓库后，您**不需要**向原作者仓库（Upstream）提交 Pull Request / 变更合并。您完全可以将其作为一个独立项目，长期维护并推送到您自己的 Fork 仓库。
- **多设备配置同步**：在您的多台开发设备上（如公司电脑、个人 Mac、云服务器），直接 Clone 您的 **Fork 仓库**，这样任何一处配置更改，通过 `git commit & push` 之后，在其他设备运行 `git pull && ./install.sh` 即可瞬间同步环境。

### 2. 🔄 如何同步上游（主仓库）的最新修改？

当主仓库更新后，由于本项目由 **主工具链仓库** 和 **共享技能子模块 (`zorron-skills`)** 两部分组成，同步时需要根据您的定制方式分别处理。

---

#### 📦 第一部分：同步主工具链仓库 (`zorron-agent-toolchain`)

##### 💡 方式一：通过 GitHub Web 页面一键同步 (最简单)
如果您使用 GitHub 托管您的 Fork 仓库：
1. 打开您的 GitHub Fork 仓库页面（例如：`https://github.com/您的用户名/zorron-agent-toolchain`）。
2. 在代码区域上方，找到 **"Sync fork"** 下拉菜单按钮。
3. 点击 **"Sync fork"**，然后点击 **"Update branch"**。GitHub 会在云端自动将主仓库的最新提交合并进您的分支。
4. 回到您的本地开发机，拉取代码并更新子模块：
   ```bash
   cd ~/zorron-agent-toolchain
   git pull
   git submodule update --init --recursive
   ./install.sh
   ```

##### 💻 方式二：通过 Git 命令行同步 (纯终端开发)
如果是在纯终端环境，或希望手动处理合并：
```bash
# 1. 进入本地工具链目录
cd ~/zorron-agent-toolchain

# 2. 将作者的源仓库添加为 "upstream" 远程源 (只需配置一次)
git remote add upstream https://github.com/gyorkluu/zorron-agent-toolchain.git

# 3. 获取上游主仓库的最新修改并合并
git fetch upstream
git checkout main
git merge upstream/main

# 4. 更新子模块到上游指定的 Commit
git submodule update --init --recursive

# 5. 推送合并后的最新状态到您自己的个人 Fork 远程库
git push origin main
```

---

#### 📚 第二部分：同步共享技能子模块 (`zorron-skills`)

同步子模块（`shared/skills/zorron-skills`）取决于您**是否 Fork 了技能仓库**：

##### 场景 A：您直接使用上游技能库（没有 Fork `zorron-skills`）
如果您的 `.gitmodules` 指向的是原作者的 `zorron-skills` 库，而您只想获取最新的 Skills：
* **方式 1**：如果主工具链仓库已经更新了子模块指针，您在主仓库下运行 `git submodule update --init --recursive` 即可。
* **方式 2**：如果想在主仓库更新前，强行拉取 `zorron-skills` 远程仓库的最新内容，请在工具链根目录下运行：
  ```bash
  git submodule update --remote --merge
  ```
  该命令会自动拉取最新的技能并合并到本地目录。

##### 场景 B：您也 Fork 了技能库，并希望同步上游技能更新
如果您将 `zorron-skills` 子模块也 Fork 到了您自己的账号下（例如 `https://github.com/您的用户名/zorron-skills.git`）：
1. **先在 GitHub Web 页面上同步您的技能库 Fork**：
   - 打开您的 `zorron-skills` Fork 仓库页面。
   - 点击 **"Sync fork"** -> **"Update branch"**.
2. **在本地拉取更新并提交到您的工具链仓库**：
   ```bash
   # 进入子模块目录
   cd ~/zorron-agent-toolchain/shared/skills/zorron-skills
   
   # 拉取您 Fork 仓库的最新代码
   git pull origin main
   
   # 返回工具链根目录
   cd ~/zorron-agent-toolchain
   
   # 将工具链对子模块的指针更新，并推送到您的工具链 Fork 中
   git add shared/skills/zorron-skills
   git commit -m "chore: sync skills submodule to latest fork commit"
   git push origin main
   ```
3. **或者，直接在本地子模块中添加上游源进行合并**：
   ```bash
   cd ~/zorron-agent-toolchain/shared/skills/zorron-skills
   git remote add upstream https://github.com/gyorkluu/zorron-skills.git   # (只需配置一次)
   git fetch upstream
   git merge upstream/main
   git push origin main
   ```

### 3. 🛡️ 最佳实践：如何避免与上游发生合并冲突 (Conflict)？
为了在后续同步上游更新时享受 "零冲突" 的平滑体验，建议您遵循以下**解耦设计规则**进行个人定制：
1. **不要直接修改公共基础文件**：例如不要直接修改 `tools/claude-code/settings.json` 的通用部分。
2. **充分使用主机覆盖 (Host Override)**：把所有个性化配置、独特的插件路径或临时参数，全部放在 `hosts/$(hostname -s)/override/` 对应的目录下。
3. **充分使用本地文件覆盖**：把敏感数据、IP 地址等利用 `~/.zorron/secrets.local.json` 或 `.env.local` 写入。这些文件被 `.gitignore` 自动忽略，永远不会进入版本控制，从而 100% 避免了合并冲突的可能。

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
