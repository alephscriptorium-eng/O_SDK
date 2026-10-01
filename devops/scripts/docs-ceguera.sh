#!/usr/bin/env bash
# =============================================================================
# docs-ceguera.sh — la cara pública no cuenta más de la cuenta, por ámbito (BASE-3 §C, D-O26).
#
# El repo separa MÉTODO (genérico) e INSTANCIA (la demo). Quien llega a montar su nodo no debe
# leer el de la demo por todas partes. Tres ámbitos:
#
#   1) CIEGO — docs/roles/** y docs/PUB/INSTANCIA-PLANTILLA.md: cero menciones al nombre de la demo
#      o a su dominio. Excepciones exactas: la URL de la forja y el enlace a la ficha de la demo.
#   2) TRINQUETE — protocolos de método ya publicados: el recuento de menciones no puede SUBIR
#      respecto a la base (docs-ceguera.base). Bajarlo es el objetivo; al bajar, `--update`.
#   3) EN TODO lo publicado: ni la cuenta de origen anulada ni su feed.
#
# Uso: bash devops/scripts/docs-ceguera.sh [--update]
# Sale 0 si todo cuadra, 1 si hay fuga. Solo lee (salvo --update, que reescribe la base).
# =============================================================================
set -uo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 2
BASE_FILE="devops/scripts/docs-ceguera.base"
DEMO='escrivivir|[Ss]criptorium|SCRIPTORIUM'
ANULADA='escrivivir-co/|@tMJzSfcZ'
fail=0

echo "== ceguera del portal"

# 1) ámbito ciego
ciego="$(ls docs/roles/*.md docs/PUB/INSTANCIA-PLANTILLA.md 2>/dev/null)"
fugas="$(for f in $ciego; do
  sed -e 's#github\.com/alephscriptorium-eng/O_SDK##g' -e 's#/PUB/INSTANCIA-SCRIPTORIUM##g' "$f" \
    | grep -nE "$DEMO" | sed "s#^#$f:#"
done)"
if [ -n "$fugas" ]; then
  echo "  FALLA ámbito ciego (puertas y plantilla nombran a la demo):"; echo "$fugas" | cut -c1-160 | sed 's/^/    /'; fail=1
else
  echo "  ok    ámbito ciego: $(echo "$ciego" | wc -w | tr -d ' ') ficheros, 0 menciones a la demo"
fi

# 2) trinquete en los protocolos de método
metodo="docs/AGENTES.md docs/CLIENT-PROTOCOL.md $(ls docs/PUB/*-PROTOCOL.md)"
actual="$(for f in $metodo; do printf '%s\t%s\n' "$f" "$(grep -cE "$DEMO" "$f")"; done)"
if [ "${1:-}" = "--update" ]; then
  { echo "# Menciones a la demo por protocolo de método (docs-ceguera.sh). No puede subir; bajar es el objetivo."; echo "$actual"; } > "$BASE_FILE"
  echo "  base reescrita: $BASE_FILE"
fi
if [ ! -f "$BASE_FILE" ]; then echo "  FALLA no existe $BASE_FILE (créala con --update)"; exit 1; fi
sube=""; total=0; total_base=0
while IFS=$'\t' read -r f n; do
  b="$(awk -F'\t' -v f="$f" '$1==f{print $2}' "$BASE_FILE" | tr -d '\r')"
  total=$((total + n)); total_base=$((total_base + ${b:-0}))
  if [ -z "$b" ]; then sube="$sube\n    $f: no está en la base (añádelo con --update)"
  elif [ "$n" -gt "$b" ]; then sube="$sube\n    $f: $b → $n"; fi
done <<< "$actual"
if [ -n "$sube" ]; then
  echo "  FALLA trinquete (un protocolo de método nombra a la demo más que antes):"; printf '%b\n' "$sube"; fail=1
else
  echo "  ok    trinquete: $total menciones en los protocolos de método (base $total_base)"
fi

# 3) la cuenta anulada, en todo lo que se publica
pub="$(grep -rnE "$ANULADA" docs --include=*.md --include=*.vue --include=*.mjs --include=*.html 2>/dev/null \
  | grep -v '^docs/\.vitepress/\(dist\|cache\)/' \
  | grep -vE '^docs/(AI|devs|install)/|^docs/(CHANGELOG|security)\.md|^docs/PUB/(deploy|clearnet)\.md')"
if [ -n "$pub" ]; then
  echo "  FALLA la cuenta de origen anulada o su feed aparecen en lo publicado:"; echo "$pub" | cut -c1-160 | sed 's/^/    /'; fail=1
else
  echo "  ok    ni la cuenta anulada ni su feed en lo publicado"
fi

[ "$fail" = 0 ] && echo "CEGUERA OK" || echo "CEGUERA: FUGA"
exit $fail
