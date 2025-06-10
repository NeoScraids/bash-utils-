# bash-utils

> Colección profesional de scripts Bash para automatización, monitoreo y tareas de sistema. Incluye guías avanzadas sobre diferencias entre `sh` y `bash`, uso de colores, banners y ejemplos detallados de cada script para máxima claridad y mantenimiento.

```
bash-utils/
├── .gitignore
├── LICENSE
├── README.md
└── scripts/
    ├── utils.sh
    ├── backup.sh
    ├── monitor.sh
    ├── cleanup_logs.sh
    └── deploy_app.sh
tests/
└── test_scripts.sh
```

---

## 1. Shells: `sh` vs `bash`

**`sh`** (shell Bourne/POSIX):
- Máxima portabilidad en sistemas Unix/Linux.
- Sintaxis reducida: carece de arrays, funciones avanzadas y extensiones.
- Útil para scripts que deben correr en entornos muy mínimos.

**`bash`** (Bourne Again Shell):
- Superset de `sh` con arrays, expresiones regulares, manejo mejorado de cadenas.
- Facilita scripting complejo y uso de características modernas.

**Recomendación de Shebang**:
- Portabilidad: `#!/usr/bin/env sh`
- Funcionalidad: `#!/usr/bin/env bash`

---

## 2. Colores y Banners: interfaz amigable

En `scripts/utils.sh`, definimos lo básico:

```bash
#!/usr/bin/env bash
# utils.sh: funciones comunes y variables de estilo para todos los scripts.

# === Colores ANSI para realce ===
RED="\e[31m"     # Errores/críticos
GREEN="\e[32m"   # Éxitos
YELLOW="\e[33m"  # Advertencias
BLUE="\e[34m"    # Información general
BOLD="\e[1m"     # Texto en negrita
RESET="\e[0m"    # Resetear estilo

# === Banner de bienvenida ===
banner() {
  echo -e "${BLUE}${BOLD}======================================${RESET}"
  echo -e "${BLUE}${BOLD}       Bienvenido a Bash-Utils         ${RESET}"
  echo -e "${BLUE}${BOLD}======================================${RESET}"
}

# === Función de logging con timestamp ===
# Uso: log "LEVEL" "Mensaje"
log() {
  local level="$1" message="$2"
  local color="${RESET}"
  case "$level" in
    ERROR) color="${RED}";;
    WARN)  color="${YELLOW}";;
    INFO)  color="${BLUE}";;
    SUCCESS) color="${GREEN}";;
  esac
  echo -e "${BOLD}$(date +'%Y-%m-%d %H:%M:%S')${RESET} [${color}${level}${RESET}] ${message}"
}
```

- **banner()** llama un encabezado estilizado.
- **log()** imprime con timestamp y nivel en color.
- Importa `utils.sh` al inicio de cada script:
  ```bash
  source "$(dirname "$0")/utils.sh"
  banner
  log "INFO" "Iniciando script $0"
  ```

---

## 3. Script: `utils.sh`

Este archivo centraliza estilos y funciones compartidas:
- **Reseteo de entorno** (`set -euo pipefail` y manejo de IFS).
- **Variables** para colores y formato.
- **Funciones**: `banner()` y `log()`.

### Contenido completo de `scripts/utils.sh`
```bash
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
```

- Se recomienda mantener este archivo limpio y solo para utilidades.

---

## 4. Script: `backup.sh`

**Objetivo**: comprimir un directorio y subirlo a S3 o FTP, con retención configurable.

### 4.1 Encabezado y configuración
```bash
#!/usr/bin/env bash
# backup.sh: Respaldo de directorios con subida a S3/FTP y limpieza local.
set -euo pipefail
IFS=$'\n\t'
source "$(dirname "$0")/utils.sh"

banner
log "INFO" "Iniciando backup"
```
- `set -euo pipefail`: detiene el script ante errores.
- `IFS=$'\n\t'`: evita split inesperado.
- `source utils.sh`: incorpora colores y logging.

### 4.2 Parseo de argumentos
declara variables y soporte `--help`:
```bash
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
```

### 4.3 Validaciones y operaciones
a) Validar existencia de origen:
```bash
t[[ -d "$src" ]] || { log "ERROR" "Directorio no encontrado: $src"; exit 2; }
```
b) Crear archivo tar.gz:
```bash
archive_file="/tmp/$(basename "$src")-$(date +%F).tar.gz"
tar czf "$archive_file" -C "$(dirname "$src")" "$(basename "$src")"
log "INFO" "Archivo comprimido: $archive_file"
```
c) Subida condicional:
```bash
if [[ "$dest" == s3://* ]]; then
  aws s3 cp "$archive_file" "$dest"
  log "SUCCESS" "Subido a S3: $dest"
else
  curl -T "$archive_file" "$dest"
  log "SUCCESS" "Subido a FTP: $dest"
fi
```
d) Limpieza local:
```bash
rm "$archive_file"
log "INFO" "Archivo temporal eliminado"
```

### 4.4 Cierre
```bash
log "SUCCESS" "Backup completado. Retención: $retention días"
exit 0
```

---

## 5. Script: `monitor.sh`

**Objetivo**: monitorear CPU, memoria y disco; alertar vía Slack si supera umbrales.

### 5.1 Encabezado y parseo
```bash
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
```

### 5.2 Bucle principal
ejecuta métricas cada `interval` segundos:
```bash
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
```

---

## 6. Script: `cleanup_logs.sh`

**Objetivo**: eliminar archivos de log con más de N días.

### 6.1 Encabezado y opciones
```bash
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
```

### 6.2 Proceso de limpieza
```bash
find "$log_dir" -type f -mtime +"$days" -print0 | \
  while IFS= read -r -d '' file; do
    log "INFO" "Eliminando archivo: $file"
    rm "$file"
done
log "SUCCESS" "Limpieza completada"
exit 0
```

---

## 7. Script: `deploy_app.sh`

**Objetivo**: desplegar o actualizar una aplicación remota gestionada por systemd.

### 7.1 Cabecera y parámetros
```bash
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
```

### 7.2 Conexión SSH y despliegue
ejecuta comandos remotos seguros:
```bash
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
```

---

## 8. Pruebas y CI
- Integra **ShellCheck** para linting.
- Usa **GitHub Actions** para ejecutar `test_scripts.sh` en cada push.

---

## 9. Buenas Prácticas
- Siempre usar `set -euo pipefail` y definir `IFS`.
- Centralizar utilidades en `utils.sh`.
- Documentar opciones con `--help`.
- Mantener código modular y legible.
- Versionar y revisar con PRs.

---

## Licencia
MIT — consulta [LICENSE](LICENSE) para detalles.
