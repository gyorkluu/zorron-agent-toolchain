---
name: bun
description: Skill for using the Bun JavaScript runtime and package manager. Use when you need to install dependencies, run scripts, or execute JavaScript/TypeScript with Bun.
---

# Bun Skill

## What is Bun?
Bun is a fast all-in-one JavaScript runtime and package manager. It can replace Node.js, npm, yarn, or pnpm for many tasks.

## Common Commands

### Install Dependencies
```bash
bun install
```

### Add a Dependency
```bash
bun add <package-name>
bun add -d <package-name>  # dev dependency
```

### Run Scripts
If your package.json has scripts, you can run them with:
```bash
bun run <script-name>
```

### Execute a File
```bash
bun run <file.js>
bun run <file.ts>  # TypeScript is supported natively
```

### Check Version
```bash
bun --version
```
