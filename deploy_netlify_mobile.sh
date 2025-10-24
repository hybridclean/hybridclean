#!/usr/bin/env bash
# ============================================================================
# deploy_netlify_mobile.sh
# HybridSheetApp – Vereinheitlichtes Skript
# Generiert: 2025-10-24 15:36:48
# ============================================================================
set -Eeu -o pipefail

# Projekt-Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zentrale Konfiguration und Helferfunktionen laden
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

APPDIR="$HOME/hybridclean/netlify_redirect"
LOGFILE="$HOME/hybridclean/deploy_log.txt"
DATE=$(date "+%Y-%m-%d_%H-%M-%S")

echo "==========================================" | tee -a "$LOGFILE"
echo "🚀 Netlify Deployment gestartet um $DATE" | tee -a "$LOGFILE"

# Prüfen, ob Netlify installiert ist
if ! command -v netlify &> /dev/null; then
  echo "❌ Netlify CLI nicht installiert. Bitte ausführen: npm install -g netlify-cli" | tee -a "$LOGFILE"
  exit 1
fi

# ------------------------------------------
# 🔍 Bilder prüfen
# ------------------------------------------
echo "🖼  Suche nach neuen oder geänderten Bildern ..." | tee -a "$LOGFILE"
IMAGES=$(find "$APPDIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.svg" \))

if [ -z "$IMAGES" ]; then
  echo "ℹ️  Keine neuen Bilder gefunden." | tee -a "$LOGFILE"
else
  echo "📸 Gefundene Bilder:" | tee -a "$LOGFILE"
  echo "$IMAGES" | tee -a "$LOGFILE"
  
  # Automatische Übernahme (kein Benutzer-Input nötig, auch auf Handy)
  echo "✅ Bilder werden automatisch ins Deployment aufgenommen." | tee -a "$LOGFILE"
fi

# ------------------------------------------
# 🌐 Deployment starten
# ------------------------------------------
echo "------------------------------------------" | tee -a "$LOGFILE"
echo "📦 Starte Netlify Deployment (Produktion) ..." | tee -a "$LOGFILE"
cd "$APPDIR" || { echo "❌ Fehler: Ordner nicht gefunden."; exit 1; }

netlify deploy --prod --dir="$APPDIR" --message "📱 Automatisches Deployment vom $DATE" | tee -a "$LOGFILE"

if [ $? -eq 0 ]; then
  echo "✅ Deployment abgeschlossen." | tee -a "$LOGFILE"
else
  echo "❌ Deployment fehlgeschlagen!" | tee -a "$LOGFILE"
fi

# ------------------------------------------
# 📋 Log-Zusammenfassung
# ------------------------------------------
echo "------------------------------------------" | tee -a "$LOGFILE"
echo "🕓 Letztes Deployment: $DATE" | tee -a "$LOGFILE"
echo "📄 Log-Datei: $LOGFILE"
echo "=========================================="
