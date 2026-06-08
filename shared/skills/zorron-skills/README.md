# zorron-skills

Centralized collection of agent skills used across gyorkluu's tooling (Qwen Code, Claude, Codex, Trae-CN, etc.).

## Structure

```
zorron-skills/
├── browser/          # Browser automation & DevTools
├── bun-ecosystem/    # Bun runtime & ElysiaJS framework
├── docs/             # Documentation authoring
├── frontend/         # React & frontend tooling
├── git/              # Git & GitHub CLI
├── openai/           # OpenAI API & image generation
└── zorron-original/  # Custom zorron-crafted skills
```

## Skills

### browser/
| Skill | Description |
|---|---|
| `browser-harness` | Direct browser control via CDP. Use when the user wants to automate, scrape, test, or interact with web pages. Connec... |
| `chrome-devtools-cli` | Use this skill to write shell scripts or run shell commands to automate tasks in the browser or otherwise use Chrome ... |

### bun-ecosystem/
| Skill | Description |
|---|---|
| `bun` | Skill for using the Bun JavaScript runtime and package manager. Use when you need to install dependencies, run script... |
| `elysiajs` | Create backend with ElysiaJS, a type-safe, high-performance framework. |
| `hono` | Build web APIs and edge applications with Hono, an ultrafast lightweight framework on Web Standards. Triggers on "hon... |
| `zorron-elysia-commands` | Project-local command guide for the Zorron ElysiaJS workspace. Use when Codex needs to start, stop, inspect, test, bu... |

### docs/
| Skill | Description |
|---|---|
| `doc-coauthoring` | Guide users through a structured workflow for co-authoring documentation. Use when user wants to write documentation,... |
| `humanizer-zh` | 去除文本中的 AI 生成痕迹。适用于编辑或审阅文本，使其听起来更自然、更像人类书写。 基于维基百科的"AI 写作特征"综合指南。检测并修复以下模式：夸大的象征意义、 宣传性语言、以 -ing 结尾的肤浅分析、模糊的归因、破折号过度使用... |
| `xhs` | 编写或润色小红书（Xiaohongshu/XHS）引流与干货笔记。 要求：纯文本输出（无 Markdown 粗体、斜体、列表点或代码块），直接适配复制粘贴； 应用人性化中文，去除 AI 写作痕迹；遵循科学养号与合规防封导流策略。 |

### frontend/
| Skill | Description |
|---|---|
| `algorithmic-art` | Creating algorithmic art using p5.js with seeded randomness and interactive parameter exploration. Use this when user... |
| `frontend-design` | Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks ... |
| `frontend-skill` | Use when the task asks for a visually strong landing page, website, app, prototype, demo, or game UI. This skill enfo... |
| `publish-astro-edgeone` | A guide on writing markdown articles and deploying Astro static sites to Tencent Cloud EdgeOne Pages via the EdgeOne ... |
| `react-best-practices` | React and Next.js performance optimization guidelines from Vercel Engineering. This skill should be used when writing... |
| `react-view-transitions` | Guide for implementing smooth, native-feeling animations using React's View Transition API (`<ViewTransition>` compon... |
| `shadcn` | Manages shadcn components and projects — adding, searching, fixing, debugging, styling, and composing UI. Provides pr... |
| `web-artifacts-builder` | Suite of tools for creating elaborate, multi-component claude.ai HTML artifacts using modern frontend web technologie... |
| `web-design-guidelines` | Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "aud... |

### git/
| Skill | Description |
|---|---|
| `gh-cli` | GitHub CLI (gh) comprehensive reference for repositories, issues, pull requests, Actions, projects, releases, gists, ... |
| `git-commit` | Execute git commit with conventional commit message analysis, intelligent staging, and message generation. Use when u... |

### openai/
| Skill | Description |
|---|---|
| `imagegen` | Generate or edit raster images when the task benefits from AI-created bitmap visuals such as photos, illustrations, t... |
| `openai-docs` | Use when the user asks how to build with OpenAI products or APIs, asks about Codex itself or choosing Codex surfaces,... |

### zorron-original/
| Skill | Description |
|---|---|
| `plugin-creator` | Create and scaffold plugin directories for Codex with a required `.codex-plugin/plugin.json`, optional plugin folders... |
| `skill-creator` | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an ex... |
| `skill-installer` | Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when a user asks to list ... |
| `zorron-create-skill` | Use this skill to analyze and distill an AI agent's session conversation history, debugging steps, and problem-solvin... |


## Sources

Skills were aggregated from:
- `~/.trae-cn/skills/` — primary canonical source
- `~/.claude/skills/`
- `~/.codex/skills/.system/`
