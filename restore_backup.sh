cat <<'EOF' > ~/hybridclean/restore_backup.sh
#!/usr/bin/env bash
# ============================================================================
# restore_backup.sh – Stellt das letzte oder ein angegebenes Backup wieder her
# ============================================================================
set -Eeu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

log "Starte Wiederherstellung..."

# Prüfe, ob ein Argument übergeben wurde
BACKUP_FILE="${1:-}"

# Falls kein Backup angegeben ist → neuestes suchen
if [[ -z "$BACKUP_FILE" ]]; then
  log "Kein Backup angegeben. Suche das neueste ZIP im Projekt..."
  BACKUP_FILE=$(ls -t "${PROJECT_DIR}"/*.zip 2>/dev/null | head -n 1 || true)
  if [[ -z "$BACKUP_FILE" ]]; then
    err "Kein Backup gefunden! Bitte zuerst eines erstellen mit ./manage.sh create_backup"
    exit 1
  fi
  log "Verwende neuestes Backup: $BACKUP_FILE"
else
  log "Verwende angegebenes Backup: $BACKUP_FILE"
fi

# Prüfe, ob Datei existiert
if [[ ! -f "$BACKUP_FILE" ]]; then
  err "Backup-Datei nicht gefunden: $BACKUP_FILE"
  exit 1
fi

# Zielverzeichnis
RESTORE_DIR="${PROJECT_DIR}/restore_tmp"

# Backup entpacken
log "Entpacke Backup in $RESTORE_DIR ..."
run "rm -rf \"$RESTORE_DIR\""
run "mkdir -p \"$RESTORE_DIR\""
run "unzip -o \"$BACKUP_FILE\" -d \"$RESTORE_DIR\""

# Optional: Inhalte zurückkopieren
if [[ -d "$RESTORE_DIR/src" ]]; then
  log "Kopiere wiederhergestellte Dateien nach src/ ..."
  run "cp -r \"$RESTORE_DIR/src/\"* \"$PROJECT_DIR/src/\""
else
  warn "Kein src/-Verzeichnis im Backup gefunden."
fi

log "Wiederherstellung abgeschlossen."
EOF
