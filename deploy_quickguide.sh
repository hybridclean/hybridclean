#!/usr/bin/env bash
# ============================================================================
# deploy_quickguide.sh
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
ROOT_DIR=${PROJECT_DIR}

cd $ROOT_DIR || exit

echo "🧹 Entferne doppelte JS-Dateien..."
rm -f src/*.js

echo "📋 Liste aktuelle Deployments:"
clasp deployments

echo "❌ Lösche alte Deployments (außer HEAD)..."
clasp deployments | awk '/- AKfy/{print $2}' | tail -n +2 | xargs -I {} clasp undeploy {}

echo "⬆️ Lade Code in die Cloud..."
clasp push --force

echo "🚀 Erstelle neue Version..."
clasp deploy --description "Auto deploy $(date +%Y-%m-%d_%H-%M)"

echo "🔍 Prüfe aktive Deployments über Script API..."
curl -s -X GET \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://script.googleapis.com/v1/projects/${SCRIPT_ID}/deployments" \
  | jq '.deployments[] | {deploymentId, updateTime, entryPointType, description}'

echo "✅ Fertig! Siehe oben, welche Deployments aktiv sind."
