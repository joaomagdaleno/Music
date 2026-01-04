Write-Host "🏰 Hermes: The Architect's Citadel - Status Check" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Gray

function Verify-Component ($Path, $Name) {
    if (Test-Path $Path) {
        Write-Host "✅ $Name found ($Path)" -ForegroundColor Green
    }
    else {
        Write-Host "❌ $Name MISSING! ($Path)" -ForegroundColor Red
        exit 1
    }
}

Verify-Component "scripts/hermes_gate.sh" "The Sentinel (Web/Linux)"
Verify-Component "scripts/hermes_gate.ps1" "The Sentinel (Windows)"
Verify-Component "scripts/asset_guard.py" "The Alchemist (Asset Guard)"
Verify-Component "scripts/license_warden.py" "The Warden (License Check)"

Verify-Component ".github/workflows/quality-gate.yml" "The Gate (Workflow)"
Verify-Component ".github/workflows/build-and-package.yml" "The Factory (Workflow)"
Verify-Component ".jules/hermes.md" "The Journal"

Write-Host "==================================================" -ForegroundColor Gray
Write-Host "✨ All Systems Operational. The Citadel is Secure." -ForegroundColor Cyan
