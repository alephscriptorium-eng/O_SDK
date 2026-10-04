#!/usr/bin/env bash
# =============================================================================
# upgrade-behaviour-diff.sh — qué CAMBIA DE COMPORTAMIENTO entre dos versiones de upstream.
#
# Los guards de src/ dicen si el fork sigue siendo el fork. Los greps de presencia dicen si
# algo «sigue existiendo». Ninguno dice si Oasis SE COMPORTA igual: una ruta nueva que publica,
# una cabecera que ahora decide el idioma, un fichero de estado que se muda. Este script saca
# esos CANDIDATOS de forma mecánica, para que nadie dependa de leer 15.000 líneas de diff con
# suerte. No da veredictos: cada línea se dispone a mano en el registro del ciclo
# (el reporte del WP; docs/PUB/UPGRADE-PROTOCOL.md §3.1 y §7) con una de: no-afecta · adaptado en <commit> · documentado
# en <sección> · gate <id>.
#
# Uso:
#   bash devops/scripts/upgrade-behaviour-diff.sh <OLD> <NEW> [--section S[,S…]] [--check <registro.md>]
#   OLD/NEW: commits de upstream (los da upgrade-preflight.sh: OLD_REF / NEW_REF).
#
# Secciones:
#   roles     ficheros que cambian por rol (pub en modo server = cierre de requires de SSB_server.js,
#             calculado con upgrade-closure.js; backends y cliente = todo src/)
#   files     ficheros añadidos o borrados en src/
#   routes    rutas HTTP añadidas o quitadas en backend.js
#   loopback  rutas protegidas por isLoopbackRequest añadidas o quitadas
#   publish   líneas añadidas o quitadas que publican en SSB (publish, sendMessage, notifyBot…)
#   timers    líneas añadidas o quitadas con setInterval/setTimeout (lo que corre solo)
#   headers   líneas añadidas o quitadas que leen o escriben cabeceras, cookies, protocolo o host
#   env       variables process.env.* nuevas o desaparecidas
#   state     ficheros de estado (state-manager.js) nuevos o retirados
#   config    cambios en los JSON de src/configs/
#   deps      cambios en src/server/package.json
#             Lo vendorizado en src/base no entra en ninguna sección salvo como una línea de `deps`.
#   outside   ficheros de upstream que cambian FUERA de src/ (no los importa el overlay)
#   annex     invariantes de las piezas del fork (devops/scripts/upgrade-invariants.d/*.tsv),
#             evaluados sobre el ÁRBOL DE TRABAJO (overlay y guards ya aplicados)
#
# Salida: TSV  ID  sección  signo  fichero  texto     (signo: + añadido · - quitado · ! invariante roto · = dato)
#   El ID es estable entre ejecuciones (sha1 corto de sección+signo+fichero+texto).
#
# --check <registro.md>: sale 1 si algún ID con signo + - o ! no aparece en ese fichero.
# Códigos: 0 ok · 1 hay IDs sin disponer (solo con --check) · 2 refs inválidas o uso incorrecto.
# Solo lectura: git y grep.
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 2
INV_DIR="$REPO_ROOT/devops/scripts/upgrade-invariants.d"

OLD=""; NEW=""; SECTIONS=""; CHECK=""
while [ $# -gt 0 ]; do
  case "$1" in
    --section) SECTIONS="${2:-}"; shift ;;
    --check) CHECK="${2:-}"; shift ;;
    -h|--help) sed -n '2,39p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) if [ -z "$OLD" ]; then OLD="$1"; elif [ -z "$NEW" ]; then NEW="$1"; else echo "argumento de más: $1" >&2; exit 2; fi ;;
  esac
  shift
done
[ -n "$OLD" ] && [ -n "$NEW" ] || { echo "uso: upgrade-behaviour-diff.sh <OLD> <NEW> [--section S] [--check registro.md]" >&2; exit 2; }
git rev-parse -q --verify "$OLD^{commit}" >/dev/null || { echo "ref inválida: $OLD" >&2; exit 2; }
git rev-parse -q --verify "$NEW^{commit}" >/dev/null || { echo "ref inválida: $NEW" >&2; exit 2; }
[ -z "$CHECK" ] || [ -f "$CHECK" ] || { echo "no existe el registro: $CHECK" >&2; exit 2; }
ALL="roles files routes loopback publish timers headers env state config deps outside annex"
SECTIONS="${SECTIONS:-$ALL}"; SECTIONS="${SECTIONS//,/ }"

BACKEND="src/backend/backend.js"
# Código, no texto ni estilos: las traducciones y el CSS no deciden comportamiento.
# src/base (desde Oasis 1.2) son las dependencias vendorizadas: ~19 000 ficheros de terceros. No se
# leen línea a línea: su cambio se resume en `deps` y lo deciden los gates (parches, invite, arranque).
VENDOR='src/base'
CODE=(src ':!src/client/assets' ":!$VENDOR" ':!src/**/package-lock.json')

OUT="$(mktemp)"; trap 'rm -f "$OUT"' EXIT
emit() { # emit <sección> <signo> <fichero> <texto>
  local text; text="$(printf '%s' "$4" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]\{1,\}/ /g' | cut -c1-170)"
  local id; id="$(printf '%s|%s|%s|%s' "$1" "$2" "$3" "$text" | sha1sum | cut -c1-8)"
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$1" "$2" "$3" "$text" >> "$OUT"
}
head_of() { printf '# == %s — %s\n' "$1" "$2" >> "$OUT"; }

# Líneas añadidas/quitadas del diff de código que casan con un patrón: "signo<TAB>fichero<TAB>línea"
diff_lines() { # diff_lines <regex-extendida> [-i]
  git diff -U0 "$OLD" "$NEW" -- "${CODE[@]}" | tr -d '\r' | awk '
    /^--- a\//    { fa = substr($0, 7); next }
    /^--- /       { next }
    /^\+\+\+ b\// { f = substr($0, 7); next }
    /^\+\+\+ /    { f = fa; next }
    /^[+-]/       { l = substr($0, 2); if (l !~ /^[[:space:]]*\/\//) printf "%s\t%s\t%s\n", substr($0, 1, 1), f, l }' \
    | grep -E ${2:+"$2"} -- $'^[+-]\t[^\t]*\t.*('"$1"')'
}
# Diferencia de conjuntos entre dos listas: imprime "+<TAB>x" y "-<TAB>x"
set_diff() { # set_diff <fichero-viejo> <fichero-nuevo>
  comm -13 <(sort -u "$1") <(sort -u "$2") | sed 's/^/+\t/'
  comm -23 <(sort -u "$1") <(sort -u "$2") | sed 's/^/-\t/'
}
# backend.js declara rutas con comillas dobles y simples (.get("/c") y .post('/ai')): se unifican antes.
backend_of() { git show "$1:$BACKEND" 2>/dev/null | tr -d '\r' | tr "'" '"'; }
routes_of() { backend_of "$1" | grep -oE '\.(get|post|put|del|delete|patch)\("/[^"]*"' | sed -E 's/^\.([a-z]+)\("/\U\1 /; s/"$//'; }
loopback_of() { # rutas cuya primera línea de cuerpo comprueba isLoopbackRequest
  backend_of "$1" | awk '
    match($0, /\.(get|post|put|del|delete|patch)\("\/[^"]*"/) { r = substr($0, RSTART + 1, RLENGTH - 1); n = NR }
    /isLoopbackRequest\(ctx\)/ && r != "" && NR - n <= 2 { print r; r = "" }' | sed -E 's/^([a-z]+)\("/\U\1 /; s/"$//'
}

for s in $SECTIONS; do
  case "$s" in
    roles)
      head_of roles "qué código cambia para cada rol. El pub (modo server) carga el cierre de requires de SSB_server.js, que sale de src/server; HUB, bots y cliente, todo src/"
      closure="$(node "$REPO_ROOT/devops/scripts/upgrade-closure.js" "$NEW" src/server/SSB_server.js 2>/dev/null)"
      if [ -z "$closure" ]; then closure="$(git ls-tree -r --name-only "$NEW" -- src/server)"; emit roles '!' "src/server/SSB_server.js" "no pude calcular el cierre de requires (¿node?): solo cuento src/server"; fi
      emit roles = "src/server/SSB_server.js" "pub (modo server): carga $(printf '%s\n' "$closure" | grep -c .) ficheros"
      git diff --name-only "$OLD" "$NEW" -- src | grep -Fx -f <(printf '%s\n' "$closure") | grep -v 'package-lock.json' \
        | while read -r f; do emit roles + "$f" "cambia código que carga el pub en modo server"; done
      for d in backend models views client AI configs; do
        emit roles = "src/$d" "backends y cliente: $(git diff --name-only "$OLD" "$NEW" -- "src/$d" ':!src/client/assets' | wc -l | tr -d ' ') ficheros"
      done ;;
    files)
      head_of files "ficheros de src/ que nacen o desaparecen (un borrado sin 'git rm' previo deja restos)"
      git diff --name-status --no-renames "$OLD" "$NEW" -- src ":!$VENDOR" | awk '$1 != "M"' | while read -r st f; do
        [ "$st" = A ] && emit files + "$f" "nuevo" || emit files - "$f" "borrado por upstream"
      done ;;
    routes)
      head_of routes "superficie HTTP. Una GET nueva bajo /c/ sale al clearnet; una POST nueva es una acción nueva de la GUI"
      routes_of "$OLD" > "$OUT.a"; routes_of "$NEW" > "$OUT.b"
      set_diff "$OUT.a" "$OUT.b" | while IFS=$'\t' read -r sg r; do emit routes "$sg" "$BACKEND" "$r"; done ;;
    loopback)
      head_of loopback "acciones que Oasis reserva al loopback (cartera, banca, ajustes): tocan dinero o identidad"
      loopback_of "$OLD" > "$OUT.a"; loopback_of "$NEW" > "$OUT.b"
      set_diff "$OUT.a" "$OUT.b" | while IFS=$'\t' read -r sg r; do emit loopback "$sg" "$BACKEND" "$r"; done ;;
    publish)
      head_of publish "sitios que publican en SSB. Un mensaje publicado no se retira: cada + es una publicación posible que antes no existía"
      diff_lines '\.publish\(|publish[A-Z][A-Za-z]*\(|sendMessage\(|notifyBot\(|setUserAddress\(|addAddress\(|removeAddress\(' \
        | while IFS=$'\t' read -r sg f l; do emit publish "$sg" "$f" "$l"; done ;;
    timers)
      head_of timers "lo que corre sin que nadie lo pida (arranque y periódico): es lo que hará un bot recién subido"
      diff_lines 'setInterval\(|setTimeout\(' | while IFS=$'\t' read -r sg f l; do emit timers "$sg" "$f" "$l"; done ;;
    headers)
      head_of headers "lo que depende de quién pide y no de la URL: rompe una caché compartida si no viaja en la clave"
      diff_lines 'ctx\.set\(|setheader\(|accept-language|ctx\.cookies\.|vary|ctx\.protocol|ctx\.secure|ctx\.host|x-forwarded|ctx\.ip' -i \
        | while IFS=$'\t' read -r sg f l; do emit headers "$sg" "$f" "$l"; done ;;
    env)
      head_of env "variables de entorno que el código lee: una nueva puede cambiar el modo de arranque (OASIS_TEST, 1.1.3)"
      git grep -ohE 'process\.env\.[A-Za-z_0-9]+' "$OLD" -- "${CODE[@]}" 2>/dev/null > "$OUT.a"
      git grep -ohE 'process\.env\.[A-Za-z_0-9]+' "$NEW" -- "${CODE[@]}" 2>/dev/null > "$OUT.b"
      set_diff "$OUT.a" "$OUT.b" | while IFS=$'\t' read -r sg v; do
        ref="$NEW"; [ "$sg" = "-" ] && ref="$OLD"
        f="$(git grep -lF "$v" "$ref" -- "${CODE[@]}" 2>/dev/null | head -1 | sed "s/^$ref://")"
        emit env "$sg" "${f:-?}" "$v"
      done
      # Una variable que ya existía puede pasar a leerse en más sitios (OASIS_TEST empezó a decidir
      # el arranque en 1.1.3 sin ser nueva): se avisa del cambio en el número de usos.
      comm -12 <(sort -u "$OUT.a") <(sort -u "$OUT.b") | while read -r v; do
        a="$(grep -cxF "$v" "$OUT.a")"; b="$(grep -cxF "$v" "$OUT.b")"
        [ "$a" = "$b" ] || emit env + "(varios)" "$v — usos: $a → $b"
      done ;;
    state)
      head_of state "dónde vive el estado. La migración es solo hacia delante: lo que se muda no vuelve con un rollback de imagen"
      for ref in "$OLD:$OUT.a" "$NEW:$OUT.b"; do
        git show "${ref%%:*}:src/configs/state-manager.js" 2>/dev/null | tr -d '\r' | grep -oE "'[^']+': *'[^']+'" > "${ref#*:}" || : > "${ref#*:}"
      done
      set_diff "$OUT.a" "$OUT.b" | while IFS=$'\t' read -r sg v; do emit state "$sg" "src/configs/state-manager.js" "$v"; done ;;
    config)
      head_of config "defaults de configuración. Las copias del fork (config del HUB, plantilla del bot) se regeneran si cambian"
      # solo ficheros modificados: las altas y bajas ya salen en `files`
      git diff -U0 --diff-filter=M "$OLD" "$NEW" -- 'src/configs/*.json' | tr -d '\r' | awk '
        /^\+\+\+ / { f = substr($0, 7); next } /^--- / { next }
        /^[+-]/ { printf "%s\t%s\t%s\n", substr($0, 1, 1), f, substr($0, 2) }' \
        | while IFS=$'\t' read -r sg f l; do emit config "$sg" "$f" "$l"; done ;;
    deps)
      head_of deps "dependencias. Si cambia un ssb-*, los parches de node_modules del entrypoint y el gate del invite se repiten"
      git diff -U0 "$OLD" "$NEW" -- src/server/package.json | tr -d '\r' | grep -E '^[+-][^+-]' \
        | while read -r l; do emit deps "${l:0:1}" "src/server/package.json" "${l:1}"; done
      nv="$(git diff --name-only "$OLD" "$NEW" -- "$VENDOR" | wc -l | tr -d ' ')"
      if [ "$nv" -gt 0 ]; then
        np="$(git diff --name-only "$OLD" "$NEW" -- "$VENDOR" | sed -E "s|^$VENDOR/node_modules/((@[^/]+/)?[^/]+)/.*|\\1|" | sort -u | wc -l | tr -d ' ')"
        emit deps + "$VENDOR" "dependencias vendorizadas: $nv ficheros en $np paquetes de primer nivel"
      fi ;;
    outside)
      head_of outside "lo que upstream cambia fuera de src/: el overlay no lo trae. Mirar instaladores, docs de despliegue y tests"
      git diff --name-status --no-renames "$OLD" "$NEW" -- . ':!src' | while read -r st f; do
        case "$f" in docs/*|*.md|*.png|*.jpg) continue ;; esac
        emit outside "$([ "$st" = D ] && echo - || echo +)" "$f" "upstream: $st"
      done
      emit outside = "docs/" "$(git diff --name-only "$OLD" "$NEW" -- docs '*.md' ':!src' | wc -l | tr -d ' ') ficheros de documentación cambian en upstream" ;;
    annex)
      head_of annex "invariantes de las piezas del fork sobre el árbol de trabajo (cada pieza depende de algo de upstream sin API estable)"
      for tsv in "$INV_DIR"/*.tsv; do
        [ -f "$tsv" ] || continue
        piece="$(basename "$tsv" .tsv)"
        while IFS=$'\t' read -r min file pat why; do
          case "$min" in ''|'#'*) continue ;; esac
          n="$(grep -c -F -- "$pat" "$REPO_ROOT/$file" 2>/dev/null)"; n="${n:-0}"
          if [ "$n" -ge "$min" ] 2>/dev/null; then emit annex = "$file" "[$piece] ok ($n) «$pat» — $why"
          else emit annex '!' "$file" "[$piece] ROTO ($n < $min) «$pat» — $why"; fi
        done < "$tsv"
      done ;;
    *) echo "sección desconocida: $s (válidas: $ALL)" >&2; exit 2 ;;
  esac
done
rm -f "$OUT.a" "$OUT.b"

cat "$OUT"
total="$(grep -vc '^#' "$OUT")"; todo="$(awk -F'\t' '!/^#/ && $3 != "="' "$OUT" | wc -l | tr -d ' ')"
echo "# $total líneas; $todo piden disposición en el registro del ciclo (signo + - !)" >&2

if [ -n "$CHECK" ]; then
  missing=0
  while IFS=$'\t' read -r id sec sg f text; do
    case "$id" in '#'*) continue ;; esac
    [ "$sg" = "=" ] && continue
    grep -qF "$id" "$CHECK" || { missing=$((missing + 1)); printf 'SIN DISPONER\t%s\t%s\t%s\t%s\t%s\n' "$id" "$sec" "$sg" "$f" "$text" >&2; }
  done < "$OUT"
  if [ "$missing" -gt 0 ]; then echo "# $missing IDs sin disposición en $CHECK" >&2; exit 1; fi
  echo "# todas las líneas tienen disposición en $CHECK" >&2
fi
exit 0
