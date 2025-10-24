#!/usr/bin/env bash
# ============================================================================
# deploy_netlify.sh
# HybridSheetApp – Vereinheitlichtes Skript
# Generiert: 2025-10-24 15:36:48
# ============================================================================
set -Eeu -o pipefail

# Projekt-Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zentrale Konfiguration und Helferfunktionen laden
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

LOGFILE=${PROJECT_DIR}/deploy_log.txt
DEPLOY_DIR=${PROJECT_DIR}/netlify_redirect
BACKUP_DIR=${BACKUP_DIR}
INDEX_FILE="$DEPLOY_DIR/index.html"
DATE=$(date "+%Y-%m-%d %H:%M:%S")
VERSION=$(date "+v%Y-%m-%d_%H-%M")

echo "🧭 [HybridSheetApp] Starte Deployment $VERSION um $DATE"
echo "---------------------------------------------------------------"

mkdir -p "$BACKUP_DIR"

# 🔹 Prüfen, ob Netlify installiert
if ! command -v netlify &> /dev/null; then
  echo "❌ Netlify CLI fehlt. Installiere mit: npm install -g netlify-cli"
  exit 1
fi

# 🔹 Login prüfen
if ! netlify status &> /dev/null; then
  echo "⚠️  Nicht eingeloggt. Bitte: netlify login"
  exit 1
fi

# 🔹 Prüfen, ob index.html vorhanden ist
if [ ! -f "$INDEX_FILE" ]; then
  echo "❌ index.html fehlt in $DEPLOY_DIR"
  exit 1
fi

# 🔹 Redirect-Link extrahieren
REDIRECT_URL=$(grep -Eo 'https://script\.google\.com/macros/s/[A-Za-z0-9_-]+/(exec|dev|edit)?' "$INDEX_FILE" | head -n 1)
STATUS_MSG="Unbekannt"
STATUS_CODE="---"

if [ -z "$REDIRECT_URL" ]; then
  STATUS_MSG="⚠️ Keine URL gefunden"
  echo "⚠️  Keine Google-Apps-Script-URL gefunden!"
else
  echo "🔗 Redirect-Link:"
  echo "   $REDIRECT_URL"

  if [[ "$REDIRECT_URL" =~ /edit ]]; then
    STATUS_MSG="❌ /edit-Link – falscher Typ"
    echo "❌ FEHLER: /edit-Link erkannt!"
  elif [[ "$REDIRECT_URL" =~ /dev ]]; then
    STATUS_MSG="⚠️ /dev-Link – Entwicklermodus"
    echo "⚠️ Warnung: /dev-Link erkannt."
  else
    STATUS_MSG="✅ /exec-Link erkannt"
  fi

  STATUS_CODE=$(curl -Is "$REDIRECT_URL" | head -n 1 | awk '{print $2}')
  if [[ "$STATUS_CODE" =~ ^(200|302|303)$ ]]; then
    STATUS_MSG+=" | HTTP $STATUS_CODE OK"
    echo "✅ Redirect erreichbar (HTTP $STATUS_CODE)."
  else
    STATUS_MSG+=" | HTTP $STATUS_CODE Problem"
    echo "⚠️ Redirect antwortet mit HTTP $STATUS_CODE"
  fi
fi

# 🔹 Backup erstellen
BACKUP_FILE="$BACKUP_DIR/hybridclean_${VERSION}.zip"
echo "📦 Erstelle Backup: $BACKUP_FILE"
zip -r -q "$BACKUP_FILE" ${PROJECT_DIR} >/dev/null 2>&1
echo "✅ Backup fertig."

# 🔹 Deployment starten
echo "---------------------------------------------------------------"
echo "🚀 Starte Deployment zu Netlify ($VERSION)..."
DEPLOY_OUTPUT=$(netlify deploy --prod --dir "$DEPLOY_DIR" --message "AutoDeploy $VERSION" 2>&1)

if echo "$DEPLOY_OUTPUT" | grep -q "Site is live"; then
  SITE_URL=$(echo "$DEPLOY_OUTPUT" | grep -Eo 'https://[a-z0-9.-]+\.netlify\.app' | head -n 1)
  echo "✅ Deployment erfolgreich!"
  echo "🌐 Live unter: $SITE_URL"
  STATUS_MSG+=" | ✅ Deployment erfolgreich"
else
  echo "❌ Deployment fehlgeschlagen!"
  STATUS_MSG+=" | ❌ Deployment fehlgeschlagen"
fi

# 🔹 Log schreiben
{
  echo "📦 [HybridSheetApp] Deployment $VERSION – $DATE"
  echo "➡️  URL: ${REDIRECT_URL:-keine URL}"
  echo "📊 Ergebnis: ${STATUS_MSG}"
  echo "🌐 Site: ${SITE_URL:-keine Site}"
  echo "💾 Backup: ${BACKUP_FILE}"
  echo "---------------------------------------------------------------"
} >> "$LOGFILE"

echo "🪵 Logeintrag gespeichert: $LOGFILE"
echo "---------------------------------------------------------------"
