#!/usr/bin/env bash
# test-ai-service.sh — prueba el servicio de IA del cliente (src/AI/ai_service.mjs, puerto 4001).
# El :4001 NO se publica en el compose y solo existe dentro del contenedor (lo lanza backend.js
# bajo demanda con startAI()), así que la prueba se ejecuta DENTRO de oasis-client con `docker compose exec`.
# El servicio solo expone POST /ai y POST /ai/train (no hay /health).
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

INPUT="${1:-Say hello in one short sentence.}"
PROMPT="You are a helpful assistant. Answer briefly."

if [ "$(docker inspect -f '{{.State.Running}}' oasis-client 2>/dev/null || echo false)" != "true" ]; then
  echo "❌ oasis-client no está corriendo (docker compose up -d)"; exit 1
fi

echo "🤖 Modelo en el volumen:"
docker compose exec -T oasis-client sh -lc 'ls -la /app/src/AI/models/*.gguf 2>/dev/null || echo "  (sin modelo: aiMod queda off; OASIS_SKIP_AI_MODEL o descarga pendiente)"'

# backend.js lanza ai_service.mjs bajo demanda (startAI) al visitar /ai: lo disparamos y esperamos a que :4001 escuche
docker compose exec -T oasis-client sh -lc "curl -s -o /dev/null http://127.0.0.1:3000/ai; for i in $(seq 20); do curl -s -o /dev/null --max-time 2 -X POST http://127.0.0.1:4001/ai && break; sleep 3; done" || true
echo "🤖 POST /ai dentro del contenedor (la primera respuesta carga el modelo: puede tardar)…"
payload=$(printf '{"input":%s,"context":"","prompt":%s}' "$(node -pe 'JSON.stringify(process.argv[1])' "$INPUT")" "$(node -pe 'JSON.stringify(process.argv[1])' "$PROMPT")")
code=$(docker compose exec -T oasis-client sh -lc "curl -s -o /tmp/ai.out -w '%{http_code}' --max-time 180 -H 'Content-Type: application/json' --data '$payload' http://127.0.0.1:4001/ai" 2>/dev/null || true)
code="${code:-000}"
if [ "$code" = "000" ]; then
  echo "ℹ️  :4001 no responde aún. El backend lo lanza al usar la IA desde la GUI (/ai). Reintenta tras usarla una vez."
  exit 2
fi
echo "HTTP $code"
docker compose exec -T oasis-client sh -lc 'head -c 1200 /tmp/ai.out; echo'
[ "$code" = "200" ]
