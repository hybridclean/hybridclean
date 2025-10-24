#!/usr/bin/env bash
# ============================================================================
# HybridSheetApp – Zentrale Konfiguration
# ============================================================================
# Passe diese Variablen bei Bedarf an. Werte aus der Umgebung überschreiben diese Defaults.
: "${PROJECT_DIR:=${HOME}/hybridclean}"
: "${BACKUP_DIR:=${PROJECT_DIR}/backups}"
: "${LOG_DIR:=${PROJECT_DIR}/logs}"
: "${SCRIPT_ID:=1aXTftYkEgKB9NYXMvc5qiV94FpeV9GSSII_VfM3dQqNMkjkc1DrX2_fA}"
: "${NODE_BIN:=node}"
: "${NPM_BIN:=npm}"
: "${NETLIFY_BIN:=netlify}"
: "${CLASP_BIN:=clasp}"

mkdir -p "${BACKUP_DIR}" "${LOG_DIR}"
