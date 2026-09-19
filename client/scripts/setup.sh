#!/usr/bin/env bash
# setup.sh — crea los directorios que el compose raíz (rol cliente) bindea como volúmenes.
# Idempotente. Ejecutar desde la raíz del repo (npm run setup). No toca datos existentes.
# Son los directorios que docker-compose.yml bindea (`device:` y ./volumes-dev/client-state): sin ellos
# el montaje falla. La cartera ECOin NO vive aquí: va en el volumen docker externo
# o-sdk-client-ecoin-data (client/scripts/ecoin-init.sh), que este script ni crea ni toca.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mkdir -p volumes-dev/{ssb-data,ai-models,logs,client-state}

# Permisos (no-op en binds NTFS de Docker Desktop; útiles en Linux)
chmod 755 volumes-dev/ 2>/dev/null || true
chmod 700 volumes-dev/ssb-data 2>/dev/null || true
chmod 755 volumes-dev/ai-models volumes-dev/client-state 2>/dev/null || true
chmod 777 volumes-dev/logs 2>/dev/null || true

echo "Volúmenes del cliente (volumes-dev/):"
echo "- ssb-data/    <- identidad (secret) + log + blobs  $( [ -f volumes-dev/ssb-data/secret ] && echo '[ya hay secret: no se toca]' || echo '[vacío: el primer arranque crea una identidad NUEVA; para traer una existente: client/scripts/import-identity.sh]')"
echo "- ai-models/   <- oasis-42-1-chat.Q4_K_M.gguf       $( [ -f volumes-dev/ai-models/oasis-42-1-chat.Q4_K_M.gguf ] && echo '[presente]' || echo '[ausente: el entrypoint lo descarga (3,8 GB) salvo OASIS_SKIP_AI_MODEL=true]')"
echo "- logs/        <- /app/logs"
echo "- client-state/ <- /app/state: oasis-config.json de la GUI (el estado bancario vive en ssb-data/oasis/banking desde Oasis 1.1.3); sobrevive a recreate/rebuild"
echo "La cartera ECOin (wallet.dat) NO está en volumes-dev/: volumen docker externo o-sdk-client-ecoin-data → npm run client:ecoin:init"
if [ -d volumes-dev/ecoin-data ]; then
  echo "AVISO: existe volumes-dev/ecoin-data (esquema anterior a WP-O103). Ya no se usa ni se toca; si contiene una wallet.dat, guárdala antes de borrarlo a mano." >&2
fi
