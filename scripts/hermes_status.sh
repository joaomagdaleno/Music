#!/bin/bash

echo "🏰 Hermes: The Architect's Citadel - Status Check"
echo "=================================================="

# Check for critical scripts
verify_component() {
  if [ -f "$1" ]; then
    echo "✅ $2 found ($1)"
  else
    echo "❌ $2 MISSING! ($1)"
    exit 1
  fi
}

verify_component "scripts/hermes_gate.sh" "The Sentinel (Web/Linux)"
verify_component "scripts/hermes_gate.ps1" "The Sentinel (Windows)"
verify_component "scripts/asset_guard.py" "The Alchemist (Asset Guard)"
verify_component "scripts/license_warden.py" "The Warden (License Check)"

# Check for configuration files
verify_component ".github/workflows/quality-gate.yml" "The Gate (Workflow)"
verify_component ".github/workflows/build-and-package.yml" "The Factory (Workflow)"
verify_component ".jules/hermes.md" "The Journal"

echo "=================================================="
echo "✨ All Systems Operational. The Citadel is Secure."
