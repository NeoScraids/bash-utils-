#!/usr/bin/env bash
# monitor.sh: Recolección de métricas y notificaciones.
set -euo pipefail
source "$(dirname "$0")/utils.sh"

banner
log "INFO" "Iniciando monitor"

# Parámetros y help
interval=60
webhook=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --interval) interval="$2"; shift 2;;
    --slack-webhook) webhook="$2"; shift 2;;
    *) log "WARN" "Opción desconocida: $1"; shift;;
  esac
done

while true; do
  cpu=$(top -bn1 | awk '/Cpu/ {print 100 - $8}')
  mem=$(free -m | awk '/Mem/ {printf "%d/%dMB", $3, $2}')
  disk=$(df -h / | awk 'NR==2 {print $5}')
  msg="CPU: ${cpu}% | MEM: ${mem} | DISK: ${disk}"

  if (( $(echo "$cpu > 80" | bc -l) )); then
    log "WARN" "$msg"
    [[ -n "$webhook" ]] && \
      curl -X POST -H 'Content-type: application/json' --data \
      '{"text":"'$msg'"}' "$webhook"
  else
    log "INFO" "$msg"
  fi
  sleep "$interval"
done
