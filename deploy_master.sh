#!/usr/bin/env bash
# ============================================================================
# deploy_master.sh
# HybridSheetApp – Vereinheitlichtes Skript
# Generiert: 2025-10-24 15:36:48
# ============================================================================
set -Eeu -o pipefail

# Projekt-Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zentrale Konfiguration und Helferfunktionen laden
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

PROJECT_DIR="$HOME/hybridclean"
SRC_DIR="$PROJECT_DIR/src"
BACKUP_DIR="$PROJECT_DIR/backups"
LOG_FILE="$PROJECT_DIR/deploy_log.txt"
DATE_TAG=$(date +"%Y-%m-%d_%H-%M-%S")
NETLIFY_DIR="$PROJECT_DIR/netlify_redirect"
APP_NAME="HybridSheetApp"

echo "🧭 Starte Deployment für $APP_NAME ..."
mkdir -p "$BACKUP_DIR"

# --------------------------------------------------------
# 1️⃣ Backup
# --------------------------------------------------------
BACKUP_FILE="$BACKUP_DIR/backup_${DATE_TAG}.zip"
echo "📦 Erstelle Backup..."
zip -r "$BACKUP_FILE" "$SRC_DIR" >/dev/null 2>&1
echo "✅ Backup gespeichert: $BACKUP_FILE" | tee -a "$LOG_FILE"

# --------------------------------------------------------
# 2️⃣ Alte JS-Dateien entfernen
# --------------------------------------------------------
echo "🧹 Entferne alte JS-Dateien..."
find "$SRC_DIR" -name "*.js" -type f -delete
echo "✅ Alte JS-Dateien gelöscht." | tee -a "$LOG_FILE"

# --------------------------------------------------------
# 3️⃣ Neuste Version vom Script Editor abrufen
# --------------------------------------------------------
echo "⬇️  Lade aktuelle Script-Dateien aus Google Apps Script..."
cd "$PROJECT_DIR"
clasp pull >/dev/null 2>&1
echo "✅ Aktuelle Version synchronisiert." | tee -a "$LOG_FILE"

# --------------------------------------------------------
# 4️⃣ Alte Deployments löschen (außer HEAD)
# --------------------------------------------------------
echo "🗑️  Entferne alte Deployments..."
DEPLOYMENTS=$(clasp deployments | grep -Eo 'AKfy[a-zA-Z0-9_-]+')
HEAD_DEPLOY=$(clasp deployments | grep '@HEAD' | grep -Eo 'AKfy[a-zA-Z0-9_-]+')

for DEPLOY_ID in $DEPLOYMENTS; do
  if [[ "$DEPLOY_ID" != "$HEAD_DEPLOY" ]]; then
    clasp undeploy "$DEPLOY_ID" >/dev/null 2>&1
    echo "🗑️  Entfernt: $DEPLOY_ID" | tee -a "$LOG_FILE"
  fi
done
echo "✅ Bereinigung abgeschlossen." | tee -a "$LOG_FILE"

# --------------------------------------------------------
# 5️⃣ Neues Deployment erstellen
# --------------------------------------------------------
NEW_DESC="AutoDeploy_${DATE_TAG}"
echo "🚀 Erstelle neues Deployment: $NEW_DESC"
NEW_DEPLOY=$(clasp deploy --description "$NEW_DESC" 2>/dev/null | grep -Eo 'AKfy[a-zA-Z0-9_-]+')

if [[ -z "$NEW_DEPLOY" ]]; then
  echo "❌ Keine neue Deployment-URL gefunden!" | tee -a "$LOG_FILE"
  exit 1
fi

APP_URL="https://script.google.com/macros/s/${NEW_DEPLOY}/exec"
echo "✅ Neues Deployment erfolgreich: $APP_URL" | tee -a "$LOG_FILE"

# --------------------------------------------------------
# 6️⃣ Netlify aktualisieren
# --------------------------------------------------------
if [ -d "$NETLIFY_DIR" ]; then
  echo "🌐 Aktualisiere Netlify-Startseite..."
  INDEX_FILE="$NETLIFY_DIR/index.html"
  if [ -f "$INDEX_FILE" ]; then
    sed -i "s|https://script.google.com/macros/s/.*|$APP_URL|" "$INDEX_FILE"
  else
    echo "⚠️  index.html nicht gefunden, erstelle neu."
    echo "<meta http-equiv=\"refresh\" content=\"2; url=${APP_URL}\">" > "$INDEX_FILE"
  fi
  cd "$NETLIFY_DIR"
  netlify deploy --prod --dir="$NETLIFY_DIR" --message "AutoDeploy $DATE_TAG" >/dev/null 2>&1
  echo "✅ Netlify aktualisiert." | tee -a "$LOG_FILE"
fi

# --------------------------------------------------------
# 7️⃣ Ergebnis anzeigen
# --------------------------------------------------------
echo "----------------------------------------------------------"
echo "✅ Deployment abgeschlossen!"
echo "🌐 App-Link: $APP_URL"
echo "🕓 Zeitstempel: $DATE_TAG"
echo "📄 Log-Datei: $LOG_FILE"
echo "----------------------------------------------------------"
