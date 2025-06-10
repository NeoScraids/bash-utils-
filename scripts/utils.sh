#!/usr/bin/env bash
# utils.sh: funciones y colores compartidos

# Colores ANSI
RED="\e[31m"   # Rojo
GREEN="\e[32m" # Verde
YELLOW="\e[33m"# Amarillo
BLUE="\e[34m"  # Azul
BOLD="\e[1m"  # Negrita
RESET="\e[0m" # Reset

# Banner de bienvenida
banner() {
  echo -e "${BLUE}${BOLD}======================================${RESET}"
  echo -e "${BLUE}${BOLD}     Bienvenido a Bash-Utils!         ${RESET}"
  echo -e "${BLUE}${BOLD}======================================${RESET}"
}

# Función de log con nivel y timestamp
log() {
  local level="$1" message="$2"
  echo -e "${BOLD}$(date +'%Y-%m-%d %H:%M:%S') [${level}]${RESET} ${message}"
}