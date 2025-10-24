#!/usr/bin/env bash
# ============================================================================
# deploy_status.sh
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
INDEX_FILE="$DEPLOY_DIR/index.html"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "📋 HybridSheetApp – Statusbericht ($DATE)"
echo "------------------------------------------"

# 🔹 Prüfen, ob Netlify installiert
if ! command -v netlify &> /dev/null; then
  echo "❌ Netlify CLI nicht installiert. Installiere mit: npm install -g netlify-cli"
  exit 1
fi

# 🔹 Prüfen, ob tree installiert
if ! command -v tree &> /dev/null; then
  echo "🪵 'tree' ist nicht installiert. Installiere es mit:"
  echo "    sudo apt-get update -y && sudo apt-get install tree -y"
else
  echo "📁 Projektstruktur:"
  tree -L 2 ${PROJECT_DIR}
  echo "------------------------------------------"
fi

# 🔹 Login prüfen
if netlify status &> /dev/null; then
  echo "✅ Netlify-Login aktiv."
else
  echo "⚠️  Du bist nicht eingeloggt. Bitte: netlify login"
  exit 1
fi

# 🔹 Site-Info anzeigen
SITE_INFO=$(netlify status | grep -E "Site name|Site URL|Site ID" || true)
if [ -z "$SITE_INFO" ]; then
  echo "⚠️  Keine Site verknüpft. Bitte zuerst Deployment ausführen."
else
  echo "$SITE_INFO"
fi

# 🔹 Letzter Deploy-Logeintrag
if [ -f "$LOGFILE" ]; then
  echo
  echo "🕓 Letzter Deployment-Eintrag:"
  tail -n 5 "$LOGFILE"
else
  echo
  echo "ℹ️  Noch kein Deployment-Log gefunden."
fi

# 🔹 index.html-Prüfung
echo
if [ -f "$INDEX_FILE" ]; then
  SIZE=$(du -h "$INDEX_FILE" | cut -f1)
  echo "📄 index.html vorhanden (${SIZE})"
else
  echo "❌ index.html fehlt im Deployment-Ordner!"
  exit 1
fi

# 🔹 Redirect-URL-Prüfung mit Logging
echo "------------------------------------------"
echo "🔍 Prüfe Redirect-Ziel in index.html ..."

REDIRECT_URL=$(grep -Eo 'https://script\.google\.com/macros/s/[A-Za-z0-9_-]+/(exec|dev|edit)?' "$INDEX_FILE" | head -n 1)
STATUS_MSG="Unbekannt"
STATUS_CODE="---"

if [ -z "$REDIRECT_URL" ]; then
  STATUS_MSG="Keine URL gefunden"
  echo "⚠️  Keine Google-Apps-Script-URL gefunden!"
else
  echo "🔗 Gefundene URL:"
  echo "   $REDIRECT_URL"

  # Falsche Typen erkennen
  if [[ "$REDIRECT_URL" =~ /edit ]]; then
    STATUS_MSG="❌ /edit-Link (falsch)"
    echo "❌ FEHLER: Dies ist ein /edit-Link – du brauchst den /exec-Link!"
  elif [[ "$REDIRECT_URL" =~ /dev ]]; then
    STATUS_MSG="⚠️ /dev-Link (Entwicklermodus)"
    echo "⚠️  Warnung: /dev-Link erkannt – das ist nur der Entwicklermodus."
  elif [[ "$REDIRECT_URL" =~ /exec ]]; then
    STATUS_MSG="✅ /exec-Link erkannt"
  else
    STATUS_MSG="⚠️ Kein /exec-Link erkannt"
  fi

  # Live-HTTP-Test
  STATUS_CODE=$(curl -Is "$REDIRECT_URL" | head -n 1 | awk '{print $2}')

  if [[ "$STATUS_CODE" =~ ^(200|302|303)$ ]]; then
    STATUS_MSG+=" | HTTP $STATUS_CODE OK"
    echo "✅ Redirect funktioniert (HTTP $STATUS_CODE)."
  elif [[ "$STATUS_CODE" == "403" ]]; then
    STATUS_MSG+=" | HTTP 403 Zugriff verweigert"
    echo "⚠️  Zugriff verweigert (403) – App eventuell nicht öffentlich."
  elif [[ "$STATUS_CODE" == "404" ]]; then
    STATUS_MSG+=" | HTTP 404 Seite nicht gefunden"
    echo "❌ Seite nicht gefunden (404) – falsche oder alte Script-ID?"
  elif [[ "$STATUS_CODE" == "500" ]]; then
    STATUS_MSG+=" | HTTP 500 Serverfehler"
    echo "❌ Serverfehler (500) – Script-Fehler im Backend?"
  else
    STATUS_MSG+=" | HTTP $STATUS_CODE (Unbekannt)"
    echo "⚠️  Unerwarteter Statuscode: $STATUS_CODE"
  fi
fi

echo "------------------------------------------"

# 🔹 Log speichern
{
  echo "📦 [HybridSheetApp] Status-Check am $DATE"
  echo "➡️  URL: ${REDIRECT_URL:-keine URL}"
  echo "📊 Ergebnis: ${STATUS_MSG}"
  echo "------------------------------------------"
} >> "$LOGFILE"

echo "🪵 Logeintrag hinzugefügt: $LOGFILE"
