# bash-utils

> Colección profesional de scripts Bash para automatización, monitoreo y tareas de sistema. Incluye guías sobre diferencias entre `sh` y `bash`, uso de colores, banners y buenas prácticas para scripts más atractivos.

```
bash-utils/
├── .gitignore
├── LICENSE
├── README.md
├── scripts/
│   ├── utils.sh
│   ├── backup.sh
│   ├── monitor.sh
│   ├── cleanup_logs.sh
│   └── deploy_app.sh
└── tests/
    └── test_scripts.sh
```

---

## 1. Shells: `sh` vs `bash`
- **`sh`**: shell POSIX estándar (alta portabilidad). Evita características específicas.
- **`bash`**: extiende `sh` con arrays, expresiones regulares, mejoras en `read`, funciones avanzadas.

**Shebang recomendado**:
- Para scripts portables: `#!/usr/bin/env sh`
- Para scripts avanzados: `#!/usr/bin/env bash`

---

## 2. Uso de colores y banners
### 2.1 Definir colores ANSI
En `scripts/utils.sh`, coloca:
```bash
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
```

### 2.2 Uso en scripts
Al inicio de cada script:
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
source "$(dirname "$0")/utils.sh"
banner
log "INFO" "Iniciando script $0"
```

Y para mensajes:
```bash
log "ERROR" "Algo falló en la operación"
echo -e "${YELLOW}Advertencia:${RESET} espacio en disco bajo"
``` 

---

## 3. Ejemplo: `backup.sh` con banner y colores
```bash
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
```

---

## 4. Pruebas básicas
```bash
#!/usr/bin/env bash
# test_scripts.sh\set -euo pipefail
source ../scripts/utils.sh

test_backup_help() {
  if ../scripts/backup.sh --help | grep -q "Uso:"; then
    log "PASS" "backup.sh muestra ayuda"
  else
    log "FAIL" "backup.sh no mostró ayuda"
  fi
test_cleanup_logs() {
  if ../scripts/cleanup_logs.sh --help | grep -q "Uso:"; then
    log "PASS" "cleanup_logs.sh muestra ayuda"
  else
    log "FAIL" "cleanup_logs.sh no mostró ayuda"
  fi
}

test_backup_help
 test_cleanup_logs
```

---

## 5. Buenas Prácticas
- Usa `set -euo pipefail` y `IFS` seguro.
- Centraliza logging y colores en `utils.sh`.
- Incluye `banner` para UI amigable.
- Documenta cada parámetro en `--help`.
- Versiona y prueba con ShellCheck y CI (GitHub Actions).

---

## Licencia
MIT — véase [LICENSE](LICENSE) para detalles.
