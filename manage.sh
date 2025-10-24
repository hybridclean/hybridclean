#!/usr/bin/env bash
# ============================================================================
# manage.sh – HybridSheetApp Management-Menü
# ============================================================================
set -Eeu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib.sh"

# Optionales --smoke Flag
if [[ "${1:-}" == "--smoke" ]]; then
  export SMOKE=1
  echo "🧪 Smoke-Test-Modus aktiviert über --smoke"
  shift
fi

# Wenn Parameter angegeben → direkt ausführen
if [[ $# -ge 1 ]]; then
  CMD="$1"; shift || true
  case "$CMD" in
    help|-h|--help)
      echo "Verwendung: ./manage.sh <befehl>"
      echo "Oder einfach ./manage.sh für Menü."
      exit 0 ;;
    *)
      if [[ -x "${SCRIPT_DIR}/${CMD}.sh" ]]; then
        log "Starte $CMD ..."
        "${SCRIPT_DIR}/${CMD}.sh" "$@"
        exit 0
      else
        err "Unbekannter Befehl: $CMD"
        exit 1
      fi ;;
  esac
fi

# ============================================================================
# Interaktives Menü
# ============================================================================
while true; do
  clear

  # Statusanzeige für Smoke-Test
  if [[ "${SMOKE:-0}" == "1" ]]; then
    SMOKE_STATUS="🧪 Smoke-Test: AKTIV"
  else
    SMOKE_STATUS="🚀 Smoke-Test: AUS"
  fi

  echo "=========================================="
  echo " HybridSheetApp – Management-Menü"
  echo "=========================================="
  echo " $SMOKE_STATUS"
  echo
  echo "[1]  Backup erstellen"
  echo "[2]  Alle Deployments ausführen"
  echo "[3]  Netlify Deployment"
  echo "[4]  Deployment-Status anzeigen"
  echo "[5]  Backup wiederherstellen"
  echo "[6]  Smoke-Test aktivieren/deaktivieren"
  echo "[0]  Beenden"
  echo
  read -rp "Bitte Auswahl eingeben (0–6): " choice
  echo

  case $choice in
    1) "${SCRIPT_DIR}/create_backup.sh" ;;
    2) "${SCRIPT_DIR}/deploy_all.sh" ;;
    3) "${SCRIPT_DIR}/deploy_netlify.sh" ;;
    4) "${SCRIPT_DIR}/deploy_status.sh" ;;
    5) "${SCRIPT_DIR}/restore_backup.sh" ;;
    6)
       if [[ "${SMOKE:-0}" == "1" ]]; then
         unset SMOKE
         echo "🧪 Smoke-Test deaktiviert."
       else
         export SMOKE=1
         echo "🧪 Smoke-Test aktiviert."
       fi
       sleep 1
       ;;
    0) echo "Programm beendet."; exit 0 ;;
    *) echo "Ungültige Auswahl."; sleep 1 ;;
  esac
done
