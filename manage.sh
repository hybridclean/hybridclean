#!/bin/bash
# ============================================================
# HYBRIDCLEAN MANAGER – Vollbild mit Netlify + GitHub Deploy
# + Erweiterte Backup-Funktionen
# ============================================================

set -e
PROJECT_DIR="$HOME/hybridclean/netlify_redirect"
FRONTEND_DIR="$HOME/hybridclean/frontend_web"
BACKEND_DIR="$HOME/hybridclean/backend_gas"
BACKUP_DIR="$HOME/hybridclean/backups"
SETTINGS_FILE="$PROJECT_DIR/.settings"
GITHUB_BRANCH="main"
NETLIFY_SITE_ID="bbbe8e08-ddd6-46c1-beb6-60dc1abd2159"
cd "$PROJECT_DIR" || exit 1

# Farben
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; NC="\033[0m"

mkdir -p "$BACKUP_DIR"

# Standardwert für Smoke-Test falls Datei fehlt
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "SMOKETEST=on" > "$SETTINGS_FILE"
fi
source "$SETTINGS_FILE"

timestamp() { date +"%Y-%m-%d_%H-%M-%S"; }

backup_frontend() {
  local file="$BACKUP_DIR/frontend_$(timestamp).zip"
  echo -e "\n${YELLOW}📦 Backup: Frontend${NC}"
  zip -r "$file" "$FRONTEND_DIR" -x "*.git*" > /dev/null
  echo -e "${GREEN}✅ Frontend-Backup erstellt:${NC} $file"
}

backup_backend() {
  local file="$BACKUP_DIR/backend_$(timestamp).zip"
  echo -e "\n${YELLOW}📦 Backup: Backend${NC}"
  zip -r "$file" "$BACKEND_DIR" -x "*.git*" > /dev/null
  echo -e "${GREEN}✅ Backend-Backup erstellt:${NC} $file"
}

backup_all() {
  local file="$BACKUP_DIR/hybridclean_full_$(timestamp).zip"
  echo -e "\n${YELLOW}📦 Backup: Komplettes Projekt${NC}"
  zip -r "$file" "$FRONTEND_DIR" "$BACKEND_DIR" "$PROJECT_DIR" -x "*.git*" > /dev/null
  echo -e "${GREEN}✅ Gesamt-Backup erstellt:${NC} $file"
}

restore_backup() {
  echo -e "\n${YELLOW}🔄 Wiederherstellen eines Backups${NC}"
  ls -1t "$BACKUP_DIR"/*.zip 2>/dev/null | nl
  read -p "Nummer des Backups zum Wiederherstellen: " num
  FILE=$(ls -1t "$BACKUP_DIR"/*.zip | sed -n "${num}p")
  if [ -z "$FILE" ]; then
    echo -e "${RED}❌ Ungültige Auswahl.${NC}"
  else
    unzip -o "$FILE" -d "$HOME/hybridclean/"
    echo -e "${GREEN}✅ Wiederhergestellt aus:${NC} $FILE"
  fi
  read -p "↩️  Weiter mit [Enter]" enter
}

backup_menu() {
  while true; do
    clear
    echo -e "${YELLOW}╔════════════════════════════════════════╗"
    echo "║         BACKUP- UND RESTOREMENÜ         ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo "1️⃣  Frontend sichern"
    echo "2️⃣  Backend sichern"
    echo "3️⃣  Komplettes Projekt sichern"
    echo "4️⃣  Wiederherstellen"
    echo "5️⃣  Zurück"
    echo "--------------------------------------------"
    read -p "Auswahl [1–5]: " bchoice
    case $bchoice in
      1) backup_frontend ;;
      2) backup_backend ;;
      3) backup_all ;;
      4) restore_backup ;;
      5) break ;;
      *) echo -e "${RED}❌ Ungültige Auswahl${NC}"; sleep 1 ;;
    esac
    read -p "↩️  Weiter mit [Enter]" enter
  done
}

deploy_github() {
  echo -e "\n${YELLOW}🚀 Deployment auf GitHub Pages...${NC}"
  git add .
  git commit -m "auto publish $(date '+%Y-%m-%d %H:%M:%S')" || echo "ℹ️ Keine Änderungen zu committen"
  git push -u origin "$GITHUB_BRANCH"
  echo -e "\n${GREEN}🌐 Live unter:${NC} https://hybridclean.github.io/hybridclean/"
  if [ "$SMOKETEST" = "on" ]; then
    echo -e "\n${YELLOW}💨 Führe automatischen Smoke-Test aus...${NC}"
    smoke silent
  fi
  read -p "↩️  Weiter mit [Enter]" enter
}

deploy_netlify() {
  echo -e "\n${YELLOW}🚀 Deployment zu Netlify...${NC}"
  if ! command -v netlify >/dev/null; then
    echo -e "${RED}❌ Netlify CLI nicht installiert.${NC}"
    echo "Installiere mit: npm install -g netlify-cli"
  else
    netlify deploy --dir "$PROJECT_DIR" --site "$NETLIFY_SITE_ID" --prod || \
      echo -e "${RED}⚠️ Deployment fehlgeschlagen (evtl. Login erforderlich: 'netlify login').${NC}"
  fi
  if [ "$SMOKETEST" = "on" ]; then
    echo -e "\n${YELLOW}💨 Führe automatischen Smoke-Test aus...${NC}"
    smoke silent
  fi
  read -p "↩️  Weiter mit [Enter]" enter
}

smoke() {
  local mode=${1:-manual}
  echo -e "\n${YELLOW}💨 Smoke-Test läuft...${NC}\n"
  echo "GitHub Pages:"
  curl -s -o /dev/null -w "  ↳ Status: %{http_code}, Zeit: %{time_total}s\n" https://hybridclean.github.io/hybridclean/
  echo
  echo "Netlify:"
  curl -s -o /dev/null -w "  ↳ Status: %{http_code}, Zeit: %{time_total}s\n" https://gami25.netlify.app/
  echo -e "\n${GREEN}✅ Test abgeschlossen.${NC}"
  [[ "$mode" == "manual" ]] && read -p "↩️  Weiter mit [Enter]" enter
}

toggle_smoke() {
  if [ "$SMOKETEST" = "on" ]; then
    SMOKETEST="off"
    echo -e "${RED}💤 Automatischer Smoke-Test deaktiviert.${NC}"
  else
    SMOKETEST="on"
    echo -e "${GREEN}💨 Automatischer Smoke-Test aktiviert.${NC}"
  fi
  echo "SMOKETEST=$SMOKETEST" > "$SETTINGS_FILE"
  sleep 1
}

status() {
  echo -e "\n${YELLOW}📊 Projektstatus:${NC}"
  echo "-----------------------------------------"
  echo "📂 Verzeichnis: $PROJECT_DIR"
  echo "🕓 Letztes Backup:"
  ls -1t "$BACKUP_DIR"/*.zip 2>/dev/null | head -n 3 || echo "— kein Backup gefunden —"
  echo "🌍 GitHub Pages:"
  curl -s -I "https://hybridclean.github.io/hybridclean/" | grep "HTTP" || echo "— keine Verbindung —"
  echo "💨 Automatischer Smoke-Test: $SMOKETEST"
  echo "-----------------------------------------"
  read -p "↩️  Weiter mit [Enter]" enter
}

clean() {
  echo -e "\n${YELLOW}🧹 Bereinige temporäre Dateien...${NC}"
  find "$PROJECT_DIR" -name "*.tmp" -delete
  find "$PROJECT_DIR" -name "*~" -delete
  echo -e "\n${GREEN}✅ Projektverzeichnis bereinigt.${NC}"
  read -p "↩️  Weiter mit [Enter]" enter
}

while true; do
  clear
  echo -e "${YELLOW}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║          H Y B R I D C L E A N   M A N A G E R           ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  echo -e "${NC}"
  echo "1️⃣  Backup-Menü"
  echo "2️⃣  Deployment → GitHub Pages"
  echo "3️⃣  Deployment → Netlify"
  echo "4️⃣  Smoke-Test (GitHub + Netlify)"
  echo "5️⃣  Status anzeigen"
  echo "6️⃣  Bereinigung"
  echo "7️⃣  Smoke-Test Auto-Modus: ${SMOKETEST^^}"
  echo "8️⃣  Beenden"
  echo "------------------------------------------------------------"
  read -p "Auswahl [1–8]: " choice
  case $choice in
    1) backup_menu ;;
    2) deploy_github ;;
    3) deploy_netlify ;;
    4) smoke ;;
    5) status ;;
    6) clean ;;
    7) toggle_smoke ;;
    8) clear; echo "👋 Tschüss!"; break ;;
    *) echo -e "${RED}❌ Ungültige Auswahl${NC}"; sleep 1 ;;
  esac
done
