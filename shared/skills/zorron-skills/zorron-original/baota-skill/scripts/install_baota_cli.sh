#!/usr/bin/env bash
# ============================================================================
# Install and Verify cli-anything-baota
# ============================================================================
set -euo pipefail

echo "🔄 Installing cli-anything-baota from repository..."
pip install git+https://github.com/gyorkluu/CLI-Anything.git@feat/baota#subdirectory=baota/agent-harness

echo "🔍 Verifying installation..."
if command -v cli-anything-baota &>/dev/null; then
    echo "✅ cli-anything-baota installed successfully!"
    echo "📊 System Status:"
    cli-anything-baota system status || echo "⚠️ Warning: Failed to connect to BaoTa API. Please check panel settings."
else
    echo "❌ Error: Installation failed or cli-anything-baota is not in your PATH."
    exit 1
fi
