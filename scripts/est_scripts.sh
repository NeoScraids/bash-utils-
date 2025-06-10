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