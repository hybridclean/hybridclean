#!/usr/bin/env bash
# ============================================================================
# clean_push_deploy.sh
# HybridSheetApp – Vereinheitlichtes Skript
# Generiert: 2025-10-24 15:36:48
# ============================================================================
set -Eeu -o pipefail

# Projekt-Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zentrale Konfiguration und Helferfunktionen laden
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

cd ${PROJECT_DIR}

echo "🧹 Lösche doppelte JS-Dateien..."
rm -f src/*.js

echo "🔍 Prüfe verbleibende Dateien..."
ls src

echo "⬇️ Alte Deployments löschen (außer HEAD)..."
clasp deployments | awk '/- AKfy/{print $2}' | tail -n +2 | xargs -I {} clasp undeploy {}

echo "⬆️ Lade Code hoch..."
clasp push --force

echo "🚀 Erstelle neue Version..."
clasp deploy --description "Auto deploy $(date +%Y-%m-%d_%H-%M)"

echo "✅ Fertig."
