#!/usr/bin/env bash
# backup.sh: Respaldo de directorios con subida a S3/FTP y limpieza local.
set -euo pipefail
IFS=$'\n\t'
source "$(dirname "$0")/utils.sh"

banner
log "INFO" "Iniciando backup"
usage() {
  cat <<EOF
${BOLD}Uso:${RESET} $0 --source <dir> --dest <s3://...|ftp://...> [--retention N]
EOF
  exit 1
}

# Valores por defecto
retention=7
while [[ $# -gt 0 ]]; do
  case $1 in
    --source) src="$2"; shift 2;;
    --dest)   dest="$2"; shift 2;;
    --retention) retention="$2"; shift 2;;
    *) usage;;
  esac
done
t[[ -d "$src" ]] || { log "ERROR" "Directorio no encontrado: $src"; exit 2; }
archive_file="/tmp/$(basename "$src")-$(date +%F).tar.gz"
tar czf "$archive_file" -C "$(dirname "$src")" "$(basename "$src")"
log "INFO" "Archivo comprimido: $archive_file"
if [[ "$dest" == s3://* ]]; then
  aws s3 cp "$archive_file" "$dest"
  log "SUCCESS" "Subido a S3: $dest"
else
  curl -T "$archive_file" "$dest"
  log "SUCCESS" "Subido a FTP: $dest"
fi
rm "$archive_file"
log "INFO" "Archivo temporal eliminado"
log "SUCCESS" "Backup completado. Retención: $retention días"
exit 0