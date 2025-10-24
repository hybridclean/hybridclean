#!/usr/bin/env bash
# ============================================================================
# create_backup.sh
# HybridSheetApp – Vereinheitlichtes Skript
# Generiert: 2025-10-24 15:36:48
# ============================================================================
set -Eeu -o pipefail

# Projekt-Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zentrale Konfiguration und Helferfunktionen laden
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

BACKUP_DIR=${PROJECT_DIR}
DEST_DIR=~
DATE=$(date +%Y-%m-%d_%H-%M)

# Benutzerbeschreibung abfragen
read -p "📝 Bitte kurze Beschreibung für das Backup eingeben: " DESC

# Leerzeichen und Sonderzeichen aus Beschreibung entfernen
SAFE_DESC=$(echo "$DESC" | tr ' ' '_' | tr -cd '[:alnum:]_-')

ZIPFILE=$DEST_DIR/hybridclean_backup_${DATE}_${SAFE_DESC}.zip
LOGFILE=$BACKUP_DIR/backup_log.txt

echo "📦 Erstelle Backup..."
cd $BACKUP_DIR || exit

# Relevante Dateien sichern
zip -r $ZIPFILE src appsscript.json .clasp.json *.sh HybridSheetApp_Deployment_Anleitung.md \
  -x "*/node_modules/*" "*/.git/*" >/dev/null

# Backup in Log eintragen
echo "$(date '+%Y-%m-%d %H:%M:%S') – $ZIPFILE – $DESC" >> $LOGFILE

echo "✅ Backup abgeschlossen!"
echo "📁 Datei: $ZIPFILE"
echo "🗒️  Beschreibung: $DESC"
echo "🧾 Log aktualisiert: $LOGFILE"
echo "⬇️ Zum Download: $ZIPFILE"
