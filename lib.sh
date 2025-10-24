#!/usr/bin/env bash
# ============================================================================
# HybridSheetApp – Gemeinsame Bash-Hilfsfunktionen
# ============================================================================

set -Eeo pipefail

# Farben (nur wenn TTY)
if [ -t 1 ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi

ts() { date +"%Y-%m-%d %H:%M:%S"; }

log()  { echo "[$(ts)] ${BOLD}INFO${RESET}  $*"; }
warn() { echo "[$(ts)] ${YELLOW}WARN${RESET}  $*"; }
err()  { echo "[$(ts)] ${RED}ERROR${RESET} $*" >&2; }

die()  { err "$*"; exit 1; }

require_cmd() {
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || die "Benötigtes Kommando nicht gefunden: $c"
  done
}

with_log() {
  # Leitet STDOUT/STDERR in Datei weiter (append), behält TTY-Ausgabe
  local logfile="$1"
  shift || true
  mkdir -p "$(dirname "$logfile")"
  {
    echo "========== $(ts) =========="
    "$@"
    rc=$?
    echo "Exit-Code: $rc"
    echo
    exit $rc
  } | tee -a "$logfile"
}

confirm() {
  local prompt="${1:-Fortfahren?} [y/N]: "
  read -r -p "$prompt" reply
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

trap 'err "Ein Fehler ist aufgetreten (Zeile $LINENO)."; exit 1' ERR
