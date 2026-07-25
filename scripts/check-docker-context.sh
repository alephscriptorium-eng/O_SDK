#!/bin/bash
# =============================================================================
# check-docker-context.sh — diagnóstico del contexto de build de la imagen.
#
# Fuente de verdad: .dockerignore (no duplica su lista aquí).
# Muestra el peso de las entradas de primer nivel y marca cuáles quedan
# excluidas del contexto según el .dockerignore real.
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

[ -f .dockerignore ] || { echo "No hay .dockerignore en $REPO_ROOT"; exit 1; }

# Patrones efectivos (sin comentarios ni vacíos)
mapfile -t PATTERNS < <(grep -vE '^\s*(#|$)' .dockerignore)

is_excluded() {
    local entry="$1" pat base
    for pat in "${PATTERNS[@]}"; do
        base="${pat%%/*}"            # primer segmento del patrón
        base="${base%\*\*}"          # quitar ** finales
        [ -z "$base" ] && continue
        case "$entry" in
            $base) return 0 ;;
        esac
    done
    return 1
}

echo "🔍 Contexto de build según .dockerignore (${#PATTERNS[@]} patrones)"
echo
printf '%-28s %10s  %s\n' "ENTRADA" "TAMAÑO" "ESTADO"
printf '%-28s %10s  %s\n' "-------" "------" "------"

for entry in * .[!.]*; do
    [ -e "$entry" ] || continue
    size="$(du -sh "$entry" 2>/dev/null | cut -f1)"
    if is_excluded "$entry"; then
        printf '%-28s %10s  ❌ excluida\n' "$entry" "$size"
    else
        printf '%-28s %10s  ✅ entra en la imagen\n' "$entry" "$size"
    fi
done

echo
echo "Nota: aproximación a primer nivel; la resolución exacta la hace Docker."
echo "Regla de oro: devops/, client/, .ssh/ y .gpg/ deben salir SIEMPRE ❌."
