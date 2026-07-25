#!/usr/bin/env bash
# lib-host.sh — carga la configuración de la instancia (host) sobre la que operar.
#
# Método vs datos: los scripts de devops/ son genéricos; los datos de CADA
# instancia (IP, usuario, dominio, cap de red, nombre de clave) viven en
# devops/hosts/<nombre>/host.env. Las claves privadas viven en devops/.ssh/
# (ignorado por git) y NUNCA se versionan.
#
# Selección de instancia:
#   DEVOPS_HOST=<nombre>   (por defecto: contenido de devops/hosts/default)
#
# Prioridad de valores: entorno del usuario > host.env > default del script.
# (host.env usa el patrón VAR="${VAR:-valor}", así que nunca pisa el entorno.)
#
# Uso desde un script en devops/scripts/:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib-host.sh"

LIB_HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVOPS_DIR="$(cd "$LIB_HOST_DIR/.." && pwd)"
SSH_DIR="$DEVOPS_DIR/.ssh"

if [ -z "${DEVOPS_HOST:-}" ] && [ -f "$DEVOPS_DIR/hosts/default" ]; then
  DEVOPS_HOST="$(head -n1 "$DEVOPS_DIR/hosts/default" | tr -d '[:space:]')"
fi
DEVOPS_HOST="${DEVOPS_HOST:-}"

HOST_ENV="$DEVOPS_DIR/hosts/${DEVOPS_HOST}/host.env"
if [ -n "$DEVOPS_HOST" ] && [ -f "$HOST_ENV" ]; then
  # shellcheck disable=SC1090
  . "$HOST_ENV"
fi

# Derivar la ruta de la clave privada a partir de KEY_FILE si no vino dada.
if [ -z "${KEY_PATH:-}" ] && [ -n "${KEY_FILE:-}" ]; then
  KEY_PATH="$SSH_DIR/$KEY_FILE"
fi
