#!/usr/bin/env bash
# cleanup_logs.sh: Rotación y eliminación de logs antiguos.
set -euo pipefail
source "$(dirname "$0")/utils.sh"

banner
log "INFO" "Iniciando limpieza de logs"

# Parametrización
days=30
log_dir=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --dir) log_dir="$2"; shift 2;;
    --days) days="$2"; shift 2;;
    *) log "ERROR" "Opción inválida: $1"; exit 1;;
  esac
done
[[ -d "$log_dir" ]] || { log "ERROR" "Directorio inválido: $log_dir"; exit 2; }
find "$log_dir" -type f -mtime +"$days" -print0 | \
  while IFS= read -r -d '' file; do
    log "INFO" "Eliminando archivo: $file"
    rm "$file"
done
log "SUCCESS" "Limpieza completada"
exit 0