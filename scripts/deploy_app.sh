#!/usr/bin/env bash
# deploy_app.sh: Clona o actualiza repositorio remoto y reinicia el servicio.
set -euo pipefail
source "$(dirname "$0")/utils.sh"

banner
log "INFO" "Iniciando despliegue"

usage() {
  cat <<EOF
${BOLD}Uso:${RESET} $0 --repo <git_url> --service <nombre> --host <user@host>
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo) repo="$2"; shift 2;;
    --service) svc="$2"; shift 2;;
    --host) host="$2"; shift 2;;
    *) usage;;
  esac
done
ssh "$host" bash <<EOF
  set -euo pipefail
  cd "/opt/$svc" 2>/dev/null || git clone "$repo" "/opt/$svc"
  log "INFO" "Actualizando $svc en $host"
  cd "/opt/$svc" && git pull origin main
  log "INFO" "Reiniciando servicio $svc"
  sudo systemctl restart "$svc"
  log "SUCCESS" "$svc desplegado correctamente"
EOF

log "SUCCESS" "Despliegue completado en $host"
exit 0