#!/usr/bin/env bash
# ==============================================================================
# utils.sh
# Funciones y constantes compartidas para todos los scripts de bash-utils
# ============================================================================== 
set -euo pipefail
IFS=$'\n\t'

# Colores ANSI
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
BOLD="\e[1m"
RESET="\e[0m"

# Banner estilizado
env banner() {
  echo -e "${BLUE}${BOLD}======================================${RESET}"
  echo -e "${BLUE}${BOLD}       Bienvenido a Bash-Utils         ${RESET}"
  echo -e "${BLUE}${BOLD}======================================${RESET}"
}

# Logging con niveles y timestamp
env log() {
  local level="$1" message="$2"
  local color
  case "$level" in
    ERROR) color="$RED";;
    WARN)  color="$YELLOW";;
    INFO)  color="$BLUE";;
    SUCCESS) color="$GREEN";;
    *) color="$RESET";;
  esac
  echo -e "${BOLD}$(date +'%Y-%m-%d %H:%M:%S')${RESET} [${color}${level}${RESET}] ${message}"
}