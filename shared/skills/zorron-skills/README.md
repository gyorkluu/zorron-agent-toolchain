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
| `browser-harness` | Direct browser control via CDP. Use when the user wants to automate, scrape, test, or interact wi... |
| `chrome-devtools-cli` | Use this skill to write shell scripts or run shell commands to automate tasks in the browser or o... |

### bun-ecosystem/
| Skill | Description |
|---|---|
| `bun` | Skill for using the Bun JavaScript runtime and package manager. Use when you need to install depe... |
| `elysiajs` | Create backend with ElysiaJS, a type-safe, high-performance framework. |
| `hono` | Build web APIs and edge applications with Hono, an ultrafast lightweight framework on Web Standar... |
| `zorron-elysia-commands` | Project-local command guide for the Zorron ElysiaJS workspace. Use when Codex needs to start, sto... |

### docs/
| Skill | Description |
|---|---|
| `doc-coauthoring` | Guide users through a structured workflow for co-authoring documentation. Use when user wants to ... |
| `humanizer-zh` | 去除文本中的 AI 生成痕迹。适用于编辑或审阅文本，使其听起来更自然、更像人类书写。 基于维基百科的"AI 写作特征"综合指南。检测并修复以下模式：夸大的象征意义、 宣传性语言、以 -ing 结... |
| `xhs` | 编写或润色小红书（Xiaohongshu/XHS）引流与干货笔记。 要求：纯文本输出（无 Markdown 粗体、斜体、列表点或代码块），直接适配复制粘贴； 应用人性化中文，去除 AI 写作痕迹... |

### frontend/
| Skill | Description |
|---|---|
| `algorithmic-art` | Creating algorithmic art using p5.js with seeded randomness and interactive parameter exploration... |
| `deploy-edgeone` | Deploy frontend applications and static websites to Tencent Cloud EdgeOne Pages using the EdgeOne... |
| `deploy-github-actions-ssh` | Use this skill to configure, debug, and automate project deployments from GitHub Actions to any t... |
| `frontend-design` | Create distinctive, production-grade frontend interfaces with high design quality. Use this skill... |
| `frontend-skill` | Use when the task asks for a visually strong landing page, website, app, prototype, demo, or game... |
| `gsap-core` | Official GSAP skill for the core API — gsap.to(), from(), fromTo(), easing, duration, stagger, de... |
| `gsap-frameworks` | Official GSAP skill for Vue, Svelte, and other non-React frameworks — lifecycle, scoping selector... |
| `gsap-performance` | Official GSAP skill for performance — prefer transforms, avoid layout thrashing, will-change, bat... |
| `gsap-plugins` | Official GSAP skill for GSAP plugins — registration, ScrollToPlugin, ScrollSmoother, Flip, Dragga... |
| `gsap-react` | Official GSAP skill for React — useGSAP hook, refs, gsap.context(), cleanup. Use when the user wa... |
| `gsap-scrolltrigger` | Official GSAP skill for ScrollTrigger — scroll-linked animations, pinning, scrub, triggers. Use w... |
| `gsap-timeline` | Official GSAP skill for timelines — gsap.timeline(), position parameter, nesting, playback. Use w... |
| `gsap-utils` | Official GSAP skill for gsap.utils — clamp, mapRange, normalize, interpolate, random, snap, toArr... |
| `iga-pages` | Deploy frontend and full-stack projects to IGA Pages. Use when the user mentions IGA Pages or req... |
| `publish-astro-edgeone` | A guide on writing markdown articles and deploying Astro static sites to Tencent Cloud EdgeOne Pa... |
| `react-best-practices` | React and Next.js performance optimization guidelines from Vercel Engineering. This skill should ... |
| `react-native-skills` | React Native and Expo best practices for building performant mobile apps. Use when building React... |
| `react-view-transitions` | Guide for implementing smooth, native-feeling animations using React's View Transition API (`<Vie... |
| `shadcn` | Manages shadcn components and projects — adding, searching, fixing, debugging, styling, and compo... |
| `web-artifacts-builder` | Suite of tools for creating elaborate, multi-component claude.ai HTML artifacts using modern fron... |
| `web-design-guidelines` | Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check ... |

### git/
| Skill | Description |
|---|---|
| `gh-cli` | GitHub CLI (gh) comprehensive reference for repositories, issues, pull requests, Actions, project... |
| `git-commit` | Execute git commit with conventional commit message analysis, intelligent staging, and message ge... |

### openai/
| Skill | Description |
|---|---|
| `image-to-outline` | Convert any image or illustration into high-quality sketch outlines using optimized Difference of... |
| `imagegen` | Generate or edit raster images when the task benefits from AI-created bitmap visuals such as phot... |
| `openai-docs` | Use when the user asks how to build with OpenAI products or APIs, asks about Codex itself or choo... |

### zorron-original/
| Skill | Description |
|---|---|
| `agent-reach` | MUST USE when user asks to search, browse, read, or interact with content from any supported plat... |
| `bt-cli` |  |
| `find-skills` | Helps users discover and install agent skills when they ask questions like "how do I do X", "find... |
| `plugin-creator` | Create and scaffold plugin directories for Codex with a required `.codex-plugin/plugin.json`, opt... |
| `port-manager` | Manage local development port allocation. Prevent port conflicts when starting or creating projec... |
| `skill-creator` | Guide for creating effective skills. This skill should be used when users want to create a new sk... |
| `skill-installer` | Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when ... |
| `sub2api-admin` | Manage Sub2API admin APIs for accounts, redeem codes, groups, proxies, error passthrough rules, T... |
| `zorron-create-skill` | Use this skill to analyze and distill an AI agent's session conversation history, debugging logs,... |

## Sources

Skills were aggregated from:
- `~/.trae-cn/skills/` — primary canonical source
- `~/.claude/skills/`
- `~/.codex/skills/.system/`
