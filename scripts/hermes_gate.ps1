# Hermes 📦 Local Sentinel - Windows (PowerShell)
# Logic parity with .github/workflows/quality-gate.yml

$ErrorActionPreference = "Stop"

Write-Host "`n📦 Hermes: Iniciando Portão de Qualidade Local...`n" -ForegroundColor Cyan

Set-Location -Path "music_tag_editor"

Write-Host "🧼 [1/3] Limpeza e Dependências..." -ForegroundColor Yellow
flutter pub get

Write-Host "✨ [2/3] Verificando Formatação e Análise..." -ForegroundColor Yellow
dart format --set-exit-if-changed .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro de Formatação detectado! Execute 'dart format .' para corrigir." -ForegroundColor Red
    exit 1
}

flutter analyze --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro de Análise (Linter) detectado!" -ForegroundColor Red
    exit 1
}

Write-Host "🧪 [3/3] Executando Testes Unitários..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Falha nos Testes!" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Portão de Qualidade Local: PASSOU! O código está pronto para o Hermes 📦`n" -ForegroundColor Green
exit 0
