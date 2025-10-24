#!/usr/bin/env bash
# ============================================================================
# deploy_all.sh
# HybridSheetApp – Vereinheitlichtes Skript
# Generiert: 2025-10-24 15:36:48
# ============================================================================
set -Eeu -o pipefail

# Projekt-Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zentrale Konfiguration und Helferfunktionen laden
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

set -e

echo "🧭 Starte vollständiges Auto-Deployment inkl. JS-Cleanup, URL-Update, Deploy-Bereinigung..."
cd ${PROJECT_DIR}

LOGFILE="$HOME/hybridclean/deploy_all_log.txt"
BACKUP="$HOME/hybridclean/backup_src_$(date +'%Y-%m-%d_%H-%M-%S').zip"

echo "📄 Log-Datei: $LOGFILE"
echo "📦 Backup: $BACKUP"
echo "----------------------------------------"

# 1️⃣ Backup
zip -qr "$BACKUP" src >> "$LOGFILE" 2>&1
echo "✅ Backup erstellt."

# 2️⃣ JS-Dateien löschen
find src -type f -name "*.js" -delete
echo "✅ Alte JS-Dateien entfernt."

# 3️⃣ Aktuellen Code laden
clasp pull >> "$LOGFILE" 2>&1
echo "✅ Aktuelle Version aus Script-Editor geladen."

# 4️⃣ Alte Deployments entfernen (außer HEAD)
echo "🧹 Lösche alte Deployments..."
DEPLOY_IDS=$(clasp deployments | grep -Eo "AKfy[a-zA-Z0-9_-]+" | grep -v "@HEAD" || true)
if [ -n "$DEPLOY_IDS" ]; then
  for ID in $DEPLOY_IDS; do
    clasp undeploy "$ID" >> "$LOGFILE" 2>&1 || true
    echo "🗑️  Entfernt: $ID"
  done
else
  echo "Keine alten Deployments gefunden."
fi
echo "✅ Bereinigung abgeschlossen."

# 5️⃣ Neues Deployment anlegen
DESC="AutoDeploy $(date +'%Y-%m-%d_%H-%M-%S')"
clasp deploy --description "$DESC" >> "$LOGFILE" 2>&1

# 6️⃣ Neueste URL finden
DEPLOY_INFO=$(clasp deployments 2>&1)
NEW_URL=$(echo "$DEPLOY_INFO" | grep -Eo "https://script\.google\.com/macros/s/[A-Za-z0-9_-]+/exec" | tail -n 1)
if [ -z "$NEW_URL" ]; then
  echo "❌ Keine neue Deployment-URL gefunden!"
  echo "$DEPLOY_INFO" >> "$LOGFILE"
  exit 1
fi
echo "✅ Neue Script-URL erkannt: $NEW_URL"

# 7️⃣ index.html aktualisieren (schwarz-weiß)
INDEX_FILE="$HOME/hybridclean/netlify_redirect/index.html"
cat <<HTML > "$INDEX_FILE"
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <title>SchaustellerApp lädt...</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="3; url=$NEW_URL">
  <style>
    body {
      background: #111;
      color: #fff;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100vh;
      font-family: "Segoe UI", Roboto, sans-serif;
      margin: 0;
      text-align: center;
    }
    img {
      width: 100px;
      filter: grayscale(100%);
      opacity: 0.85;
      margin-bottom: 20px;
    }
    .spinner {
      border: 4px solid #333;
      border-top: 4px solid #fff;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 1s linear infinite;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <img src="bogen02.jpg" alt="Startbild">
  <h2>Schausteller App wird geladen…</h2>
  <div class="spinner"></div>
</body>
</html>
HTML

echo "✅ index.html aktualisiert."

# 8️⃣ Netlify Deployment starten
echo "🌐 Starte Netlify Deployment..."
$HOME/hybridclean/deploy_netlify_mobile.sh >> "$LOGFILE" 2>&1

echo "✅ Deployment komplett abgeschlossen!"
echo "🌍 App live unter: https://schaustellerapp.netlify.app"
date >> "$LOGFILE"
