#!/bin/bash
# setup-env.sh — Environment check and auto-setup helper script for web-ppt-video skill

echo "🔍 Starting environment checks for web-ppt-video rendering..."

# 1. Check Node.js and Package Manager
if ! command -v node &> /dev/null; then
  echo "❌ Error: Node.js is not installed. Please install Node.js (>= 18) first."
  exit 1
else
  echo "✅ Node.js found: $(node -v)"
fi

if ! command -v pnpm &> /dev/null; then
  echo "⚠️ Warning: pnpm not found. Falling back to npm."
  PKG_MANAGER="npm"
else
  echo "✅ pnpm found: $(pnpm -v)"
  PKG_MANAGER="pnpm"
fi

# 2. Check guizang-ppt-skill installation
SKILLS_DIR_CLI="$HOME/.gemini/antigravity-cli/skills"
SKILLS_DIR_AGENTS="$HOME/.agents/skills"
GUIZANG_INSTALLED=false

if [ -d "$SKILLS_DIR_CLI/guizang-ppt-skill" ] || [ -d "$SKILLS_DIR_AGENTS/guizang-ppt-skill" ]; then
  echo "✅ guizang-ppt-skill is installed in agent toolchain."
  GUIZANG_INSTALLED=true
else
  echo "⚠️ Warning: guizang-ppt-skill not found in active skill folders."
  echo "👉 Prompt: Please copy or install guizang-ppt-skill to enable premium templates (Editorial Style / Swiss Style)."
fi

# 3. Check ffmpeg and ffprobe
FFMPEG_GLOBAL=false
FFPROBE_GLOBAL=false

if command -v ffmpeg &> /dev/null; then
  echo "✅ Global ffmpeg found: $(ffmpeg -version | head -n 1)"
  FFMPEG_GLOBAL=true
fi

if command -v ffprobe &> /dev/null; then
  echo "✅ Global ffprobe found: $(ffprobe -version | head -n 1)"
  FFPROBE_GLOBAL=true
fi

# If global binaries are missing, check/install local static binaries
if [ "$FFMPEG_GLOBAL" = false ] || [ "$FFPROBE_GLOBAL" = false ]; then
  echo "⚠️ Global ffmpeg or ffprobe is missing. Checking local node static fallback..."
  
  if [ ! -f "package.json" ]; then
    echo "📦 Initializing npm package.json in current directory to install static binaries..."
    $PKG_MANAGER init -y &> /dev/null
  fi
  
  # Check if ffmpeg-static and ffprobe-static are in package.json
  if ! grep -q "ffmpeg-static" package.json &> /dev/null || ! grep -q "ffprobe-static" package.json &> /dev/null; then
    echo "📦 Installing ffmpeg-static and ffprobe-static locally..."
    if [ "$PKG_MANAGER" = "pnpm" ]; then
      pnpm add -D ffmpeg-static ffprobe-static
    else
      npm install --save-dev ffmpeg-static ffprobe-static
    fi
  else
    echo "✅ Local static binaries already configured in package.json."
  fi
  
  # Determine static paths
  STATIC_FFMPEG_DIR="node_modules/ffmpeg-static"
  if [ -d "$STATIC_FFMPEG_DIR" ]; then
    echo "✅ Local ffmpeg-static verified."
  else
    echo "❌ Error: Failed to install/locate ffmpeg-static."
  fi
else
  echo "✅ Video compilation binaries are fully ready."
fi

# 4. Check hyperframes installation
if ! command -v hyperframes &> /dev/null && [ ! -f "node_modules/.bin/hyperframes" ]; then
  echo "📦 @hyperframes/cli not found. Installing globally or locally..."
  if [ "$PKG_MANAGER" = "pnpm" ]; then
    pnpm add -D @hyperframes/cli
  else
    npm install --save-dev @hyperframes/cli
  fi
else
  echo "✅ @hyperframes/cli found."
fi

echo "🎉 Environment setup check completed successfully!"
