#!/usr/bin/env bash
# test-ai-service.sh — prueba el servicio de IA del cliente (src/AI/ai_service.mjs).
#
# Contrato desde Oasis 1.1.10 (antes: curl sin más a :4001):
#  - lo lanza backend.js bajo demanda (al visitar /ai) a través de src/AI/ai_client.js, que elige
#    un puerto libre desde 4001 y genera un TOKEN por sesión;
#  - el servicio escucha solo en 127.0.0.1 y responde 403 sin la cabecera `x-oasis-ai-token`;
#  - expone GET /status (estado de carga del modelo) y POST /ai ({input, …} → {answer}). Ya no hay /ai/train.
#
# El puerto y el token solo existen en el entorno del proceso ai_service, dentro del contenedor.
# Este script los lee allí (/proc/<pid>/environ) y los usa allí: no salen del contenedor ni se imprimen.
#
# Uso: npm run client:test-ai [-- "pregunta"]      (el contenedor oasis-client debe estar corriendo)
# Sale 0 si POST /ai devuelve 200 · 2 si el servicio no ha arrancado · 3 si falta el modelo · 1 en otro caso.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export MSYS_NO_PATHCONV=1

INPUT="${1:-Say hello in one short sentence.}"
CTR="${OASIS_CLIENT_CONTAINER:-oasis-client}"

if [ "$(docker inspect -f '{{.State.Running}}' "$CTR" 2>/dev/null || echo false)" != "true" ]; then
  echo "❌ $CTR no está corriendo (docker compose up -d)"; exit 1
fi

echo "🤖 Modelo en el volumen:"
docker exec "$CTR" sh -lc 'ls -la /app/src/AI/models/*.gguf 2>/dev/null || echo "  (sin modelo: aiMod queda off; OASIS_SKIP_AI_MODEL o descarga pendiente)"'

# Todo lo que toca el token corre dentro del contenedor, en un solo shell.
docker exec -i -e AI_INPUT="$INPUT" "$CTR" sh -s <<'IN_CONTAINER'
find_ai() {   # pid del proceso ai_service.mjs, sin depender de pgrep (la imagen slim no lo trae)
  for d in /proc/[0-9]*; do
    if tr '\0' ' ' < "$d/cmdline" 2>/dev/null | grep -q 'ai_service\.mjs'; then echo "${d#/proc/}"; return 0; fi
  done
  return 1
}
env_of() { tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null | sed -n "s/^$2=//p" | head -1; }

# backend.js lanza el servicio al visitar /ai: lo disparamos y esperamos al proceso.
curl -s -o /dev/null --max-time 20 http://127.0.0.1:3000/ai || true
pid=""; i=0
while [ $i -lt 20 ]; do pid="$(find_ai)" && break; i=$((i + 1)); sleep 3; done
if [ -z "$pid" ]; then
  echo "ℹ️  el servicio de IA no ha arrancado. ¿modules.aiMod = on en oasis-config.json? ¿hay modelo? Abre /ai en la GUI y reintenta."
  exit 2
fi
PORT="$(env_of "$pid" OASIS_AI_PORT)"; PORT="${PORT:-4001}"
TOKEN="$(env_of "$pid" OASIS_AI_TOKEN)"
echo "🤖 servicio: pid $pid · puerto $PORT · token $([ -n "$TOKEN" ] && echo 'presente (no se muestra)' || echo 'AUSENTE')"

code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$PORT/status")"
echo "   GET /status sin token → $code (se espera 403)"

# El modelo se carga al arrancar el servicio: esperar a ready (la primera vez tarda).
i=0; st=""
while [ $i -lt 60 ]; do
  st="$(curl -s --max-time 10 -H "x-oasis-ai-token: $TOKEN" "http://127.0.0.1:$PORT/status")"
  echo "$st" | grep -q '"ready":true' && break
  echo "$st" | grep -q '"error":"' && break
  i=$((i + 1)); sleep 5
done
echo "   GET /status con token → $(echo "$st" | cut -c1-200)"
if echo "$st" | grep -q 'model_missing'; then echo "❌ falta el modelo"; exit 3; fi

payload="$(node -e 'process.stdout.write(JSON.stringify({ input: process.env.AI_INPUT, maxTokens: 64 }))')"
code="$(curl -s -o /tmp/ai.out -w '%{http_code}' --max-time 300 -H 'Content-Type: application/json' -H "x-oasis-ai-token: $TOKEN" --data "$payload" "http://127.0.0.1:$PORT/ai")"
echo "🤖 POST /ai → HTTP $code"
head -c 1200 /tmp/ai.out; echo
[ "$code" = "200" ]
IN_CONTAINER
