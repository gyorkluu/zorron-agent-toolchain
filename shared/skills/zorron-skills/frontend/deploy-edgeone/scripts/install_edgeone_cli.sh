#!/bin/bash
# install_edgeone_cli.sh — Installs and verifies the Tencent Cloud EdgeOne CLI.
set -e

echo "=== EdgeOne CLI Installation ==="

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  echo "Error: npm (Node Package Manager) is required but not installed." >&2
  exit 1
fi

# Try to install edgeone globally
echo "Installing EdgeOne CLI globally..."
if npm install -g edgeone; then
  echo "Global installation successful."
else
  echo "Global installation failed, attempting local package installation..."
  npm install --save-dev edgeone
fi

# Verify the installation
echo "Verifying EdgeOne CLI installation..."
if command -v edgeone &> /dev/null; then
  echo "Success: EdgeOne CLI version $(edgeone -v) is installed and available."
elif npx edgeone -v &> /dev/null; then
  echo "Success: EdgeOne CLI version $(npx edgeone -v) is installed locally and available via npx."
else
  echo "Error: Failed to verify EdgeOne CLI installation." >&2
  exit 1
fi
