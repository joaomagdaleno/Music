#!/bin/bash
# Hermes 📦 Local Sentinel - Bash
# Logic parity with .github/workflows/quality-gate.yml

set -e

echo -e "\n📦 Hermes: Iniciando Portão de Qualidade Local...\n"

cd music_tag_editor

echo "🧼 [1/3] Limpeza e Dependências..."
flutter pub get

echo "✨ [2/3] Verificando Formatação e Análise..."
if ! dart format --set-exit-if-changed . ; then
    echo -e "\n❌ Erro de Formatação detectado! Execute 'dart format .' para corrigir."
    exit 1
fi

flutter analyze --no-fatal-infos --no-fatal-warnings

echo "🧪 [3/3] Executando Testes Unitários..."
flutter test

echo -e "\n✅ Portão de Qualidade Local: PASSOU! O código está pronto para o Hermes 📦\n"
exit 0
