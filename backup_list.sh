#!/usr/bin/env bash
# ============================================================================
# backup_list.sh
# HybridSheetApp – Vereinheitlichtes Skript
# Generiert: 2025-10-24 15:36:48
# ============================================================================
set -Eeu -o pipefail

# Projekt-Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Zentrale Konfiguration und Helferfunktionen laden
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

BACKUP_DIR=${BACKUP_DIR}
LOGFILE=${PROJECT_DIR}/deploy_log.txt

if [ ! -d "$BACKUP_DIR" ]; then
  echo "❌ Kein Backup-Ordner gefunden: $BACKUP_DIR"
  exit 1
fi

echo "🗂 HybridSheetApp – Backup Übersicht"
echo "---------------------------------------------------------------------------------------------"

# Prüfen, ob Backups existieren
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.zip 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -eq 0 ]; then
  echo "ℹ️ Keine Backups gefunden in $BACKUP_DIR"
  exit 0
fi

# Kopfzeile
printf "%-35s | %-15s | %-20s | %-8s | %-12s\n" "📦 Datei" "Version" "Datum" "Größe" "Status"
echo "----------------------------------------------------------------------------------------------------"

# Durchlaufe alle ZIP-Dateien
for file in "$BACKUP_DIR"/*.zip; do
  filename=$(basename "$file")
  version=$(echo "$filename" | grep -Eo "v[0-9_-]{10,}" || echo "–")
  mod_date=$(date -r "$file" "+%Y-%m-%d %H:%M")
  size=$(du -h "$file" | cut -f1)

  # Standardstatus
  status="❔ Unbekannt"

  # Wenn Logdatei existiert: Status prüfen
  if [ -f "$LOGFILE" ] && [ "$version" != "–" ]; then
    # Suche Eintrag zu dieser Version im Log
    if grep -q "$version" "$LOGFILE"; then
      if grep -A3 "$version" "$LOGFILE" | grep -q "✅"; then
        status="✅ Erfolgreich"
      elif grep -A3 "$version" "$LOGFILE" | grep -q "❌"; then
        status="❌ Fehler"
      else
        status="⚠️ Unvollständig"
      fi
    fi
  fi

  printf "%-35s | %-15s | %-20s | %-8s | %-12s\n" "$filename" "$version" "$mod_date" "$size" "$status"
done

echo "----------------------------------------------------------------------------------------------------"
echo "📁 Ordner: $BACKUP_DIR"
echo "🪵 Log: $LOGFILE"
echo "🕓 Stand: $(date '+%Y-%m-%d %H:%M:%S')"
