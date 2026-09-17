#!/usr/bin/env bash
# setup.sh — crea los directorios que el compose raíz (rol cliente) bindea como volúmenes.
# Idempotente. Ejecutar desde la raíz del repo (npm run setup). No toca datos existentes.
# Los cuatro directorios son los `device:` de docker-compose.yml: sin ellos el montaje falla.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mkdir -p volumes-dev/{ssb-data,ai-models,logs,ecoin-data}

# Permisos (no-op en binds NTFS de Docker Desktop; útiles en Linux)
chmod 755 volumes-dev/ 2>/dev/null || true
chmod 700 volumes-dev/ssb-data 2>/dev/null || true
chmod 755 volumes-dev/ai-models volumes-dev/ecoin-data 2>/dev/null || true
chmod 777 volumes-dev/logs 2>/dev/null || true

echo "Volúmenes del cliente (volumes-dev/):"
echo "- ssb-data/    <- identidad (secret) + log + blobs  $( [ -f volumes-dev/ssb-data/secret ] && echo '[ya hay secret: no se toca]' || echo '[vacío: el primer arranque crea una identidad NUEVA; para traer una existente: client/scripts/import-identity.sh]')"
echo "- ai-models/   <- oasis-42-1-chat.Q4_K_M.gguf       $( [ -f volumes-dev/ai-models/oasis-42-1-chat.Q4_K_M.gguf ] && echo '[presente]' || echo '[ausente: el entrypoint lo descarga (3,8 GB) salvo OASIS_SKIP_AI_MODEL=true]')"
echo "- logs/        <- /app/logs"
echo "- ecoin-data/  <- wallet ECOin (solo con --profile ecoin)"
