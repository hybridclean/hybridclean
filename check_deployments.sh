#!/usr/bin/env bash
# ============================================================================
# check_deployments.sh
# HybridSheetApp – Vereinheitlichtes Skript
# Generiert: 2025-10-24 15:36:48
# ============================================================================
set -Eeu -o pipefail

# Projekt-Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zentrale Konfiguration und Helferfunktionen laden
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

SCRIPT_ID="1aXTftYkEgKB9NYXMvc5qiV94FpeV9GSSII_VfM3dQqNMkjkc1DrX2_fA"

echo "📋 Lokale Deployments laut clasp:"
clasp deployments

echo ""
echo "🌐 Serverseitige Deployments laut Google Script API:"
curl -s -X GET \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://script.googleapis.com/v1/projects/${SCRIPT_ID}/deployments" \
  | jq '.deployments[] | {deploymentId, updateTime, entryPointType, description}'

echo ""
echo "✅ Prüfung abgeschlossen. Alle hier angezeigten IDs sind serverseitig aktiv."
