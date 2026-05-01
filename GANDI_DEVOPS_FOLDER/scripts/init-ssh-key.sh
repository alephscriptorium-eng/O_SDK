#!/usr/bin/env bash
# init-ssh-key.sh
#
# Crea (idempotente) el par de claves SSH ed25519 para conectar al
# GandiCloud VPS del PUB OASIS SCRIPTORIUM.
#
# Uso:
#   bash GANDI_DEVOPS_FOLDER/scripts/init-ssh-key.sh
#
# Variables opcionales:
#   SSH_PASSPHRASE  Passphrase para la clave (por defecto vacío).
#   SSH_COMMENT     Comentario embebido en la clave pública.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVOPS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SSH_DIR="$DEVOPS_DIR/.ssh"
KEY_NAME="gandi_pub_ed25519"
KEY_PATH="$SSH_DIR/$KEY_NAME"

PASSPHRASE="${SSH_PASSPHRASE:-}"
COMMENT="${SSH_COMMENT:-oasis-pub-scriptorium@gandi-vps}"

if ! command -v ssh-keygen >/dev/null 2>&1; then
  echo "ERROR: ssh-keygen no está disponible en PATH." >&2
  echo "En Windows usa Git Bash o instala OpenSSH." >&2
  exit 1
fi

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR" 2>/dev/null || true

if [ -f "$KEY_PATH" ]; then
  echo "✔ Clave ya existe en: $KEY_PATH"
else
  echo "→ Generando nueva clave ed25519 en: $KEY_PATH"
  ssh-keygen -t ed25519 -C "$COMMENT" -f "$KEY_PATH" -N "$PASSPHRASE" >/dev/null
  chmod 600 "$KEY_PATH" 2>/dev/null || true
  chmod 644 "$KEY_PATH.pub" 2>/dev/null || true
  echo "✔ Clave creada."
fi

echo
echo "============================================================"
echo " Clave pública (copiar y pegar en Gandi -> SSH Keys)"
echo "============================================================"
cat "$KEY_PATH.pub"
echo "============================================================"
echo
echo "Ruta absoluta de la clave privada:"
echo "  $KEY_PATH"
echo
echo "Ejemplo de conexión cuando tengas la IP del VPS:"
echo "  ssh -i \"$KEY_PATH\" admin@<IP_DEL_VPS>"
