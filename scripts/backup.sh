#!/usr/bin/env bash
# backup.sh: respaldo y subida a S3/FTP con feedback coloreado
set -euo pipefail
IFS=$'\n\t'
source "$(dirname "$0")/utils.sh"

usage() {
  cat <<EOF
${BOLD}Uso:${RESET} $0 --source <dir> --dest <s3://...|ftp://...> [--retention N]
EOF
  exit 1
}

# Parámetros por defecto
retention=7
while [[ $# -gt 0 ]]; do
  case $1 in
    --source) src="$2"; shift 2;;
    --dest)   dest="$2"; shift 2;;
    --retention) retention="$2"; shift 2;;
    *) usage;;
  esac
done
[[ -d "$src" ]] || { log "ERROR" "No existe $src"; exit 1; }

banner
log "INFO" "Respaldando $src"
tmpfile="/tmp/$(basename "$src")-$(date +%F).tar.gz"
tar czf "$tmpfile" -C "$(dirname "$src")" "$(basename "$src")"
log "INFO" "Archivo creado: $tmpfile"

# Subida
if [[ "$dest" == s3://* ]]; then
  aws s3 cp "$tmpfile" "$dest"
  log "INFO" "Subido a S3: $dest"
else
  curl -T "$tmpfile" "$dest"
  log "INFO" "Subido a FTP: $dest"
fi

rm "$tmpfile"
log "SUCCESS" "Backup completado. Retención: $retention días"