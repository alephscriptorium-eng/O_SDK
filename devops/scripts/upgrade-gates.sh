#!/usr/bin/env bash
# =============================================================================
# upgrade-gates.sh — gates de un upgrade de Oasis: medir antes, recrear, medir después.
#
# La pregunta que responde no es «¿arrancó?» sino «¿qué ha publicado cada nodo con su
# identidad al subir de versión?». Un mensaje SSB no se retira; un upgrade que publica algo
# que nadie esperaba es un daño irreversible con todo en verde.
#
# Uso:
#   bash devops/scripts/upgrade-gates.sh (--local|--remote) <subcomando> [args]
#
#   --local    stack local (pub/docker-compose.pub.yml + pub/.env.local + volumes-dev/), identidades desechables
#   --remote   el host de la instancia (devops/hosts/<DEVOPS_HOST>/host.env), por SSH. En remoto solo existen
#              snapshot, check, hub y smoke: ninguno toca un nodo vivo (smoke arranca contenedores EFÍMEROS
#              de la imagen, sin red ni volúmenes, y los borra).
#
# Subcomandos:
#   snapshot <tag>      Foto de cada nodo (pub, hub, bot): estado, versión dentro del contenedor, feed,
#                       formato del log (flume o db2), sequence propio (del log y del sbot vivo),
#                       mensajes propios por tipo (cifrados incluidos), flag de primer contacto, segundos
#                       desde el último arranque, pares conectados y, en los nodos de soporte, el ENLACE
#                       con el pub medido por su propio conn.peers() (pub_link: connected in|out, ausente, ?);
#                       en el bot además dirección, modo del motor, épocas abiertas.
#                       Se guarda en devops/logs/upgrade/<tag>.<local|remote>.snap
#   check <tag> [--expect '<esperado>' | --expect 0] [--wait] [--max N] [--every N] [--stable N] [--min-age N]
#                       Foto nueva y comparación con <tag>. Por nodo: mismo feed; Δsequence == suma de
#                       Δ por tipo (si no cuadra, la medida no vale); y ese delta es el esperado.
#                       <esperado>: 'pub:oasisVersion=+1 hub:oasisVersion=+1,karmaScore=+0..1 …'
#                       (todo nodo, también el pub en modo server, anuncia su versión al cambiarla;
#                       `nodo:=0` declara «nada»). Lo que no se nombra debe ser 0. Sin --expect se lee
#                       upgrade-invariants.d/expect.conf (el delta vigente, una línea por nodo);
#                       --expect 0 = todo a cero. Además: errores en los logs desde la foto.
#                       --wait: repite la foto cada --every s (20) hasta que el delta es el esperado Y
#                       ningún sequence cambió en los últimos --stable s (60); tope --max s (600). Verde
#                       solo por estabilidad, nunca por tiempo: una desviación firme (tipo no esperado,
#                       más de lo declarado, feed o dirección cambiados, errores en el log) corta en la
#                       primera vuelta; agotado el tope sin alcanzar el delta → DESVIACIÓN.
#                       --min-age N: un nodo recreado hace menos de N s hace la medida PREMATURA (NO
#                       MEDIBLE): lo que un nodo publica solo no sale todo al arrancar. Por defecto 300
#                       en --remote y 0 en --local; con --wait, el bucle espera a cumplirlo.
#                       Exige además que cada nodo de GATE_LINK_NODES tenga el pub como par conectado
#                       (pub_link): «ausente» es «todavía no» con --wait y DESVIACIÓN sin él; «?» es NO MEDIBLE.
#   link <alias> [--yes] Repone el enlace con el pub (WP-O143, D-O38; 0 publicaciones) y vuelve a medirlo.
#                       <alias> de soporte: pub-link.js --ensure dentro del nodo (conn.connect si falta).
#                       <alias> = pub: el pub RECUERDA a cada nodo de GATE_LINK_NODES por nombre de servicio
#                       (conn.remember autoconnect): para ellos la conexión será entrante, fuera de su cupo.
#                       En --remote exige --yes: toca un nodo vivo (su libreta y sus conexiones), no su feed.
#   hub [--strict]      Matriz del visor clearnet por delante de la caché: 200, MISS→HIT, mismo /c con
#                       distinto Accept-Language y con cookies (D-O25), ?lang=, cruce de idiomas con
#                       peticiones concurrentes, sitemap y RSS con URLs https. Solo GET.
#                       --strict: lo que es nuevo de 1.1.10 (?lang=, sitemap, RSS) y de 1.2.1 (Files)
#                       pasa de aviso a fallo.
#   smoke <imagen[:tag]> [--max N]
#                       Humo de una imagen recién construida, en local o en el host, con contenedores
#                       efímeros (--network none, sin volúmenes, se borran al acabar): versión, node --check,
#                       0 ficheros `secret`, nada de .env*/volumes-*/src.old*/devops/client dentro de /app;
#                       modo server hasta que exista el socket del sbot y modo backend hasta GET /c = 200
#                       (sondeo cada 2 s, tope --max s, 120); los 3 parches del entrypoint; 0 errores.
#                       Sustituye la receta a mano de U2 y del paso 6 del host (UPGRADE §3.4, §4).
#   backup <tag>        (local) Copia volumes-dev/{oasis-pub,oasis-hub,oasis-wallet-bot} a
#                       volumes-dev/.gates/<tag>/ con los contenedores PARADOS.
#   restore <tag> --yes (local) Repone esa copia. Sin esto el gate no es repetible: tras una pasada el
#                       log ya tiene el oasisVersion nuevo y la segunda daría delta 0 (falso verde).
#   up <pub|hub|bot>    (local) Recrea un nodo con la imagen actual y espera a healthy (tope GATE_UP_TIMEOUT s).
#                       No duerme: lo que el nodo publica solo lo mide después `check <tag> --wait`.
#                       GATE_SETTLE=N repone el settle fijo antiguo (opt-in).
#   worst               (local) Peor caso del bot: GET por loopback a las páginas donde el backend refresca
#                       la cartera solo (/banking, /transfers…; /wallet no: ver el código).
#                       Después: check u5 --wait --expect 'bot:karmaScore=+0..1'.
#
# Variables: GATE_NODES="alias:contenedor:servicio …" (por defecto pub, hub y bot de esta casa) ·
#   GATE_PUB_ALIAS (pub) · GATE_LINK_NODES (alias de soporte que deben tener el pub conectado; por defecto
#   todos menos GATE_PUB_ALIAS) · GATE_PUB_LINK_HOST (oasis-pub: nombre de servicio del pub en la red del compose) ·
#   GATE_UP_TIMEOUT (300) · GATE_WAIT_MAX (600) · GATE_WAIT_EVERY (20) · GATE_STABLE (60) · GATE_MIN_AGE ·
#   GATE_SMOKE_MAX (120) · GATE_WORST_PATHS · GATE_RSS_MODULE (feed) · HUB_CACHE_CONTAINER · GATE_SETTLE.
# Códigos de salida: 0 ok · 1 desviación · 3 no medible o precondición · 64 uso.
# Bot retro de la casa: DEPRECATED desde D-O36 (parado; no se mide). Si una instancia opera uno:
#   GATE_NODES='retro:oasis-pub-retro-bot:oasis-retro-bot', solo snapshot/check (nunca backup/restore/up).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-node.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"
SNAP_DIR="$DEVOPS_DIR/logs/upgrade"
EXPECT_FILE="$SCRIPT_DIR/upgrade-invariants.d/expect.conf"

usage() { sed -n '3,/^# ====/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'; }

MODE=""; CMD=""; ARGS=(); EXPECT=""; EXPECT_SET=0; YES=0; STRICT=0; WAIT=0; WMAX=""; WMAX_SET=0; WEVERY=""; WSTABLE=""; MINAGE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --local) MODE=local ;;
    --remote) MODE=remote ;;
    --expect) EXPECT="${2:-}"; EXPECT_SET=1; shift ;;
    --wait) WAIT=1 ;;
    --max) WMAX="${2:-}"; WMAX_SET=1; shift ;;
    --every) WEVERY="${2:-}"; shift ;;
    --stable) WSTABLE="${2:-}"; shift ;;
    --min-age) MINAGE="${2:-}"; shift ;;
    --yes) YES=1 ;;
    --strict) STRICT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) if [ -z "$CMD" ]; then CMD="$1"; else ARGS+=("$1"); fi ;;
  esac
  shift
done
[ -n "$MODE" ] && [ -n "$CMD" ] || { usage; exit 64; }
case "$CMD" in
  snapshot|check|hub|smoke) ;;
  link) [ "$MODE" = local ] || [ "$YES" = 1 ] || { echo "ERROR: 'link' en --remote toca la libreta y las conexiones de un nodo vivo (no su feed): repite con --yes tras el GO." >&2; exit 64; } ;;
  backup|restore|up|worst) [ "$MODE" = local ] || { echo "ERROR: '$CMD' solo existe en --local: en el host este script no toca ningún nodo." >&2; exit 64; } ;;
  *) usage; exit 64 ;;
esac
WMAX="${WMAX:-${GATE_WAIT_MAX:-600}}"; WEVERY="${WEVERY:-${GATE_WAIT_EVERY:-20}}"; WSTABLE="${WSTABLE:-${GATE_STABLE:-60}}"
if [ -z "$MINAGE" ]; then
  if [ -n "${GATE_MIN_AGE:-}" ]; then MINAGE="$GATE_MIN_AGE"; elif [ "$MODE" = remote ]; then MINAGE=300; else MINAGE=0; fi
fi
# El delta esperado por defecto es el vigente (expect.conf): el que se copia de memoria se queda viejo
# (en el ciclo 1.2.8 el «normal» del protocolo ya no llevaba karmaScore ni about).
EXPECT_SRC=""
if [ "$EXPECT_SET" = 0 ] && [ -f "$EXPECT_FILE" ]; then
  EXPECT="$(grep -v '^[[:space:]]*#' "$EXPECT_FILE" | tr -d '\r' | grep . | tr '\n' ' ' | sed 's/ *$//')"; EXPECT_SRC=" (expect.conf)"
fi
[ "$EXPECT" = 0 ] && EXPECT=""

GATE_NODES="${GATE_NODES:-pub:${PUB_CONTAINER:-oasis-pub-scriptorium}:oasis-pub hub:oasis-pub-hub:oasis-hub bot:oasis-pub-wallet-bot:oasis-wallet-bot}"
GATE_PUB_ALIAS="${GATE_PUB_ALIAS:-pub}"
GATE_PUB_LINK_HOST="${GATE_PUB_LINK_HOST:-oasis-pub}"
# Nodos de soporte que deben tener el pub como par conectado (WP-O143, D-O38): todos menos el pub.
if [ -z "${GATE_LINK_NODES:-}" ]; then GATE_LINK_NODES=""; for n in $GATE_NODES; do [ "${n%%:*}" = "$GATE_PUB_ALIAS" ] || GATE_LINK_NODES="$GATE_LINK_NODES ${n%%:*}"; done; GATE_LINK_NODES="${GATE_LINK_NODES# }"; fi
is_link_node() { for l in $GATE_LINK_NODES; do [ "$l" = "$1" ] && return 0; done; return 1; }
LOG_ERR_RE='EROFS|EACCES|ReferenceError|TypeError|Cannot find module|Another Oasis|no inicializada|UnhandledPromiseRejection'

trap node_run_cleanup EXIT
if [ "$MODE" = local ]; then node_run_setup 1 || exit 3; else node_run_setup 0 || exit 3; fi
compose_local() { (cd "$REPO_ROOT/pub" && MSYS_NO_PATHCONV=1 docker compose -f docker-compose.pub.yml --env-file .env.local --profile wallet "$@"); }   # sin --profile retro (D-O36)
container_of() { for n in $GATE_NODES; do [ "${n%%:*}" = "$1" ] && { n="${n#*:}"; echo "${n%%:*}"; return 0; }; done; return 1; }
service_of()   { for n in $GATE_NODES; do [ "${n%%:*}" = "$1" ] && { echo "${n##*:}"; return 0; }; done; return 1; }

# ---------------------------------------------------------------------------
# Foto: una sesión en destino; salida «nodo|clave|valor»
# ---------------------------------------------------------------------------
take_snapshot() { # take_snapshot [<desde: fecha ISO para los logs>]
  { node_remote_preamble; node_remote_lib
    printf 'GATE_NODES=%q; SINCE=%q; LOG_ERR_RE=%q\n' "$GATE_NODES" "${1:-}" "$LOG_ERR_RE"
    cat <<'EOS'
# Segundos desde el último arranque del contenedor (StartedAt, RFC 3339 con nanosegundos). 0 = desconocido.
started_age() { local st t; st="$(docker inspect -f '{{.State.StartedAt}}' "$1" 2>/dev/null | sed -E 's/\.[0-9]+Z$/Z/')"
  [ -n "$st" ] && t="$(date -d "$st" +%s 2>/dev/null)" && [ -n "$t" ] && echo $(( $(date +%s) - t )) || echo 0; }
echo "meta|ts|$(date -u +%FT%TZ)"
for n in $GATE_NODES; do
  a="${n%%:*}"; c="${n#*:}"; c="${c%%:*}"
  echo "$a|container|$c"
  echo "$a|state|$(node_state "$c")"
  echo "$a|version|$(node_version "$c")"
  echo "$a|image|$(node_image "$c")"
  echo "$a|mode|$(docker inspect -f '{{join .Config.Cmd " "}}' "$c" 2>/dev/null)"
  echo "$a|started_age|$(started_age "$c")"
  d="$(node_ssb_dir "$c")"
  f="$(node_feed "$d")"
  echo "$a|feed|$f"
  [ -n "$f" ] || continue
  scan="$(node_own_scan "$d" "$f" "$c")"
  echo "$a|log|$(printf '%s\n' "$scan" | sed -n 's/^F //p')"
  seq="$(printf '%s\n' "$scan" | sed -n 's/^S //p')"; recs="$(printf '%s\n' "$scan" | sed -n 's/^R //p')"
  echo "$a|seq|${seq:-?}"
  # Un log ilegible no tiene «0 registros»: tiene `?`, para que no cuadre por casualidad con seq.
  if [ "${seq:-?}" = "?" ]; then echo "$a|records|?"; else echo "$a|records|$(printf '%s' "$recs" | grep -c .)"; fi
  printf '%s\n' "$recs" | grep . | sort | uniq -c | while read -r k t; do echo "$a|type:$t|$k"; done
  # Oasis no envía el PM de bienvenida si el flag EXISTE (firstContactSeen): ausente = lo enviaría
  # un backend al arrancar. En un nodo en modo server no hay backend y el flag no aplica.
  ff="$d/oasis/flags/oasis-first-contact"
  if ! $SUDO test -f "$ff"; then echo "$a|first_contact_flag|ausente"
  elif $SUDO grep -q -F "$f" "$ff" 2>/dev/null; then echo "$a|first_contact_flag|presente con su feed"
  else echo "$a|first_contact_flag|presente sin su feed"; fi
  map="$d/oasis/banking/wallet-addresses.json"
  addr="$($SUDO cat "$map" 2>/dev/null | grep -o '"E[A-Za-z0-9]\{25,40\}"' | head -1 | tr -d '"')"
  if [ -n "$addr" ]; then
    echo "$a|address|$addr"
    echo "$a|epochs|$($SUDO cat "$d/oasis/banking/banking-epochs.json" 2>/dev/null | grep -o '"[0-9]\{4\}-[0-9]\{2\}"' | tr -d '"' | sort -u | tr '\n' ',' | sed 's/,$//')"
    echo "$a|engine|pub=$(docker exec "$c" sh -c 'grep -o "\"pub\": *[a-z]*" /home/oasis/.ssb/config' 2>/dev/null | sed 's/.*: *//')"
  fi
  if [ -n "$SINCE" ]; then
    errs="$(docker logs --since "$SINCE" "$c" 2>&1 | grep -a -i -E "$LOG_ERR_RE")"
    echo "$a|log_errors|$(printf '%s\n' "$errs" | grep -c .)"
    printf '%s\n' "$errs" | grep . | sort | uniq -c | head -3 | cut -c1-160 | sed "s/^/$a|log_sample|/"
  fi
done
EOS
  } | run 2>/dev/null
}
add_probe() { # 2ª fuente del sequence (el sbot vivo), pares y enlace con el pub: UNA sonda por nodo. add_probe <fichero .snap>
  local a c f st j fields pf
  pf="$(awk -F'|' -v a="$GATE_PUB_ALIAS" '$1==a && $2=="feed"{print $3}' "$1")"
  for n in $GATE_NODES; do
    a="${n%%:*}"; c="${n#*:}"; c="${c%%:*}"
    f="$(awk -F'|' -v a="$a" '$1==a && $2=="feed"{print $3}' "$1")"
    st="$(awk -F'|' -v a="$a" '$1==a && $2=="state"{print $3}' "$1")"
    case "$st" in running*) ;; *) continue ;; esac
    [ -n "$f" ] || continue
    if is_link_node "$a" && [ -n "$pf" ]; then j="$(node_probe "$c" "$f" "$pf")"; else j="$(node_probe "$c" "$f")"; fi
    fields="$(node_probe_fields "$j")"
    echo "$a|seq_probe|$(printf '%s' "$fields" | cut -d'|' -f1)" >> "$1"
    echo "$a|peers|$(printf '%s' "$fields" | cut -d'|' -f2)" >> "$1"
    # pub_link: connected|ausente|? y la dirección (in|out). Sin feed del pub en la foto no se mide: «?» (NO MEDIBLE).
    if is_link_node "$a"; then
      if [ -n "$pf" ]; then echo "$a|pub_link|$(printf '%s' "$fields" | cut -d'|' -f3)|$(printf '%s' "$fields" | cut -d'|' -f4)" >> "$1"
      else echo "$a|pub_link|?|" >> "$1"; fi
    fi
  done
}
show_snapshot() {
  awk -F'|' '
    $2=="state"{st[$1]=$3} $2=="version"{v[$1]=$3} $2=="feed"{f[$1]=$3} $2=="seq"{s[$1]=$3} $2=="records"{r[$1]=$3}
    $2=="seq_probe"{p[$1]=$3} $2 ~ /^type:/{t[$1]=t[$1] " " substr($2,6) "=" $3}
    $2=="address"{x[$1]=x[$1] " dirección=" $3} $2=="epochs"{x[$1]=x[$1] " épocas=" $3} $2=="engine"{x[$1]=x[$1] " motor:" $3}
    $2=="mode"{md[$1]=$3} $2=="log"{lg[$1]=$3} $2=="started_age"{ag[$1]=$3}
    $2=="peers"{x[$1]=x[$1] " pares=" $3} $2=="pub_link"{x[$1]=x[$1] " enlace-pub=" $3 ($4!="" ? "(" $4 ")" : "")}
    $2=="first_contact_flag"{x[$1]=x[$1] " flag-primer-contacto=" $3; if ($3=="ausente") noflag[$1]=1}
    $1!="meta" && !seen[$1]++ {order[++n]=$1}
    END { for (i=1;i<=n;i++) { a=order[i]
      ok = (s[a]=="?") ? "LOG ILEGIBLE (medida no válida)" : ((s[a]==r[a]) ? "cuadra" : "NO CUADRA (medida no válida)")
      pr = (p[a]=="" ) ? "" : ((p[a]==s[a]) ? " · sbot=" p[a] : " · sbot=" p[a] " ≠ log")
      age = (ag[a]=="" || ag[a]=="0") ? "" : " · arrancó hace " ag[a] " s"
      printf "  %-4s %-16s v%-7s %-8s feed %s%s\n       log=%s seq=%s registros=%s → %s%s\n       tipos:%s\n      %s\n", a, st[a], (v[a]==""?"?":v[a]), md[a], f[a], age, (lg[a]==""?"?":lg[a]), s[a], r[a], ok, pr, t[a], x[a]
      if (s[a]=="0" && st[a] ~ /^running/) printf "       AVISO: el nodo corre y su feed no tiene ningún mensaje propio.\n"
      if (noflag[a] && md[a] ~ /backend|full/) printf "       AVISO: sin flag de primer contacto en un nodo con backend: al arrancar enviaría el PM de bienvenida (un cifrado).\n" } }' "$1"
}

# ---------------------------------------------------------------------------
# Comparación de dos fotos. compare_snaps <base> <ahora> <wait 0|1>
# Imprime el informe por nodo y devuelve: 0 delta esperado · 1 desviación · 3 no medible ·
# 4 (solo con wait=1) «todavía no»: falta un tipo declarado, o está por debajo del mínimo, o el nodo
# aún no está healthy. Lo que esperar no arregla (más de lo declarado, un tipo no esperado, otro feed,
# otra dirección, errores en el log) es desviación firme también con wait=1.
# ---------------------------------------------------------------------------
compare_snaps() {
  awk -F'|' -v expect="$EXPECT" -v wait="$3" '
    function setexp(   i, j, n, parts, kv, node, spec, m, items, rng) {
      n = split(expect, parts, " ")
      for (i = 1; i <= n; i++) { if (parts[i] == "") continue
        node = parts[i]; sub(/:.*/, "", node); spec = parts[i]; sub(/^[^:]*:/, "", spec)
        named[node] = 1
        if (spec == "=0") continue
        m = split(spec, items, ",")
        for (j = 1; j <= m; j++) { split(items[j], kv, "="); rng = kv[2]; sub(/^\+/, "", rng)
          if (rng ~ /\.\./) { lo[node, kv[1]] = rng; sub(/\.\..*/, "", lo[node, kv[1]]); hi[node, kv[1]] = rng; sub(/.*\.\./, "", hi[node, kv[1]]) }
          else { lo[node, kv[1]] = rng; hi[node, kv[1]] = rng }
          has[node, kv[1]] = 1; exptypes[node] = exptypes[node] " " kv[1] } } }
    BEGIN { setexp() }
    FNR == 1 { file++ }
    $1 == "meta" { next }
    { v[file, $1, $2] = $3; if (!seen[$1]++) order[++nn] = $1; if ($2 ~ /^type:/) types[$1, substr($2, 6)] = 1
      if ($2 == "pub_link") { v[file, $1, "pub_link_dir"] = $4; haslink[file, $1] = 1 } }
    END {
      firm = 0; soft = 0; unmeasurable = 0
      for (i = 1; i <= nn; i++) { a = order[i]; line = ""; sum = 0; nfirm = 0; nsoft = 0; why[a] = ""
        if (v[1, a, "feed"] != v[2, a, "feed"]) { printf "  %-4s DESVIACIÓN: el feed ha cambiado (%s → %s)\n", a, v[1, a, "feed"], v[2, a, "feed"]; firm = 1; continue }
        if (v[2, a, "feed"] == "") { printf "  %-4s NO MEDIBLE: sin feed\n", a; unmeasurable = 1; continue }
        if (v[1, a, "seq"] == "?" || v[2, a, "seq"] == "?") { printf "  %-4s NO MEDIBLE: el log no se puede leer (formato: %s → %s)\n", a, v[1, a, "log"], v[2, a, "log"]; unmeasurable = 1; continue }
        if (v[1, a, "seq"] != v[1, a, "records"] || v[2, a, "seq"] != v[2, a, "records"]) { printf "  %-4s NO MEDIBLE: sequence y registros no cuadran\n", a; unmeasurable = 1; continue }
        # La sonda no contesta «?» por casualidad: o el sbot no responde o no entiende la consulta.
        if (v[2, a, "seq_probe"] != "" && v[2, a, "seq_probe"] != v[2, a, "seq"]) { printf "  %-4s NO MEDIBLE: el sbot dice seq=%s y el log %s\n", a, v[2, a, "seq_probe"], v[2, a, "seq"]; unmeasurable = 1; continue }
        dseq = v[2, a, "seq"] - v[1, a, "seq"]
        for (k in types) { split(k, kk, SUBSEP); if (kk[1] != a) continue; t = kk[2]
          d = v[2, a, "type:" t] - v[1, a, "type:" t]; sum += d
          if (d != 0) line = line sprintf(" %s%+d", t, d)
          if (has[a, t]) {
            if (d > hi[a, t]) { nfirm = 1; why[a] = why[a] sprintf(" %s%+d fuera de [%s..%s];", t, d, lo[a, t], hi[a, t]) }
            else if (d < lo[a, t]) { nsoft = 1; why[a] = why[a] sprintf(" %s%+d por debajo de [%s..%s];", t, d, lo[a, t], hi[a, t]) } }
          else if (d != 0) { nfirm = 1; why[a] = why[a] sprintf(" %s%+d no esperado;", t, d) } }
        n2 = split(exptypes[a], et, " ")
        for (j = 1; j <= n2; j++) if (!((a, et[j]) in types) && lo[a, et[j]] > 0) { nsoft = 1; why[a] = why[a] " falta " et[j] ";" }
        if (sum != dseq) { printf "  %-4s NO MEDIBLE: Δsequence=%d pero la suma por tipos es %d\n", a, dseq, sum; unmeasurable = 1; continue }
        ver = (v[1, a, "version"] == v[2, a, "version"]) ? "v" v[2, a, "version"] : "v" v[1, a, "version"] " → v" v[2, a, "version"]
        extra = ""
        if (v[1, a, "log"] != "" && v[1, a, "log"] != v[2, a, "log"]) extra = extra " · log: " v[1, a, "log"] " → " v[2, a, "log"]
        if (v[1, a, "address"] != v[2, a, "address"]) { nfirm = 1; why[a] = why[a] " la dirección ECOin ha cambiado;" }
        if (v[1, a, "epochs"] != v[2, a, "epochs"]) extra = extra " · épocas: " v[1, a, "epochs"] " → " v[2, a, "epochs"]
        if (v[1, a, "engine"] != v[2, a, "engine"]) extra = extra " · motor: " v[1, a, "engine"] " → " v[2, a, "engine"]
        if (v[2, a, "state"] !~ /healthy/) { nsoft = 1; why[a] = why[a] " estado «" v[2, a, "state"] "»;" }
        # Enlace con el pub (WP-O143, D-O38): la sonda no pudo leer → NO MEDIBLE; ausente → «todavía no» (soft).
        if ((2, a) in haslink) {
          if (v[2, a, "pub_link"] == "?") { printf "  %-4s NO MEDIBLE: la sonda no pudo leer conn.peers() (enlace con el pub)\n", a; unmeasurable = 1; continue }
          if (v[2, a, "pub_link"] == "ausente") { nsoft = 1; why[a] = why[a] " sin enlace con el pub (pub_link ausente);" }
          extra = extra " · enlace-pub " v[2, a, "pub_link"] (v[2, a, "pub_link_dir"] != "" ? "(" v[2, a, "pub_link_dir"] ")" : "") }
        if (v[2, a, "log_errors"] + 0 > 0) { nfirm = 1; why[a] = why[a] " " v[2, a, "log_errors"] " líneas de error en el log;" }
        verdict = nfirm ? "DESVIACIÓN:" why[a] : (nsoft ? ((wait == 1) ? "todavía no:" why[a] : "DESVIACIÓN:" why[a]) : "ok")
        printf "  %-4s %s · Δseq=%d ·%s%s → %s\n", a, ver, dseq, (line == "" ? " sin publicaciones" : line), extra, verdict
        if (nfirm) firm = 1; else if (nsoft) soft = 1 }
      if (unmeasurable) exit 3
      if (firm) exit 1
      if (soft) exit (wait == 1 ? 4 : 1)
      exit 0 }' "$1" "$2"
}
# Nodos en marcha recreados hace menos de MINAGE s (o de edad desconocida): la medida sería prematura.
premature_nodes() { # premature_nodes <foto>  → líneas «nodo edad»
  [ "$MINAGE" -gt 0 ] 2>/dev/null || return 0
  awk -F'|' -v m="$MINAGE" '$2=="state"{st[$1]=$3} $2=="started_age"{ag[$1]=$3}
    END{for(a in ag) if (st[a] ~ /^running/ && (ag[a]+0) < m) print a, ag[a]}' "$1" | sort
}
print_premature() { sed "s/^\([a-z]*\) 0$/  \1   PREMATURO: edad del contenedor desconocida (--min-age $MINAGE)/; s/^\([a-z]*\) \([0-9]*\)$/  \1   PREMATURO: recreado hace \2 s (< $MINAGE; --min-age)/"; }

case "$CMD" in
  snapshot)
    tag="${ARGS[0]:-}"; [ -n "$tag" ] || { echo "uso: snapshot <tag>" >&2; exit 64; }
    mkdir -p "$SNAP_DIR"; out="$SNAP_DIR/$tag.$MODE.snap"
    take_snapshot > "$out.tmp"
    grep -q '|feed|@' "$out.tmp" || { echo "NO MEDIBLE: ningún nodo devolvió su feed (¿Docker/SSH/rutas?)" >&2; rm -f "$out.tmp"; exit 3; }
    add_probe "$out.tmp"; mv "$out.tmp" "$out"
    echo "== foto «$tag» ($MODE) · $(awk -F'|' '$2=="ts"{print $3}' "$out")"; show_snapshot "$out"
    echo "guardada en ${out#"$REPO_ROOT/"}"
    awk -F'|' '$2=="seq"{s[$1]=$3} $2=="records"{r[$1]=$3} $2=="seq_probe"{p[$1]=$3}
      END{for(a in s) if(s[a]=="?" || s[a]!=r[a] || ((a in p) && p[a]!=s[a])) e=1; exit e}' "$out" \
      || { echo "NO MEDIBLE: en algún nodo el log no se puede leer, o sequence, registros y sbot no cuadran." >&2; exit 3; }
    ;;

  check)
    tag="${ARGS[0]:-}"; base="$SNAP_DIR/$tag.$MODE.snap"
    [ -f "$base" ] || { echo "no existe la foto $base (haz antes: snapshot $tag)" >&2; exit 3; }
    since="$(awk -F'|' '$2=="ts"{print $3}' "$base")"
    rep="$(mktemp)"; t0=$(date +%s); last_seqs=""; stable_since=$t0
    [ "$WAIT" = 1 ] && echo "== check «$tag» ($MODE) con --wait: cada $WEVERY s, estable $WSTABLE s, tope $WMAX s, min-age $MINAGE s · esperado: ${EXPECT:-todo 0}$EXPECT_SRC"
    while :; do
      now="$(mktemp)"; take_snapshot "$since" > "$now"; add_probe "$now"
      compare_snaps "$base" "$now" "$WAIT" > "$rep"; rc=$?
      prem="$(premature_nodes "$now")"
      el=$(( $(date +%s) - t0 ))
      seqs="$(awk -F'|' '$2=="seq"{printf "%s=%s ", $1, $3}' "$now")"
      if [ "$seqs" != "$last_seqs" ]; then last_seqs="$seqs"; stable_since=$(date +%s); fi
      stable=$(( $(date +%s) - stable_since ))
      finish() { # finish <rc> <mensaje>
        echo "== ahora ($MODE)"; show_snapshot "$now"
        echo "== delta desde «$tag» ($since) · esperado: ${EXPECT:-todo 0}$EXPECT_SRC"; cat "$rep"
        [ -n "$prem" ] && printf '%s\n' "$prem" | print_premature
        grep '|log_sample|' "$now" | sed 's/^\([a-z]*\)|log_sample|/  log \1: /'
        rm -f "$now" "$rep"; echo "$2"; exit "$1"; }
      if [ "$WAIT" = 0 ]; then
        # Una medida prematura no es un verde: NO MEDIBLE. Una desviación sigue siendo desviación.
        [ -n "$prem" ] && [ $rc = 0 ] && rc=3
        case $rc in 0) finish 0 "GATE OK";; 1) finish 1 "GATE: DESVIACIÓN — parar y contarlo (AGENTES §2.2)";; *) finish 3 "GATE: NO MEDIBLE";; esac
      fi
      [ $rc = 1 ] && finish 1 "GATE: DESVIACIÓN a los $el s — parar y contarlo (AGENTES §2.2)"
      if [ $rc = 0 ] && [ -z "$prem" ] && [ "$stable" -ge "$WSTABLE" ]; then
        finish 0 "GATE OK (delta esperado y sequence estable $WSTABLE s; $el s en total)"
      fi
      if [ "$el" -ge "$WMAX" ]; then
        if [ $rc = 3 ]; then finish 3 "GATE: NO MEDIBLE (tope $WMAX s)"; else finish 1 "GATE: DESVIACIÓN — el delta esperado no se alcanzó en $WMAX s"; fi
      fi
      printf '  … %4d s: %src=%d estable=%d s%s\n' "$el" "$seqs" "$rc" "$stable" "${prem:+ · prematuro}"
      rm -f "$now"; sleep "$WEVERY"
    done
    ;;

  hub)
    if [ "$MODE" = local ]; then
      port="$(grep -m1 '^OASIS_PUB_HTTP_PORT=' "$REPO_ROOT/pub/.env.local" 2>/dev/null | cut -d= -f2 | tr -d '\r')"
      BASE="http://localhost:${port:-8088}"
    else
      BASE="https://${PUB_HOST:?PUB_HOST vacío (host.env)}"
    fi
    RSS_MODULE="${GATE_RSS_MODULE:-feed}"; stamp="g$(date +%s)"; fail=0; warn=0
    ok() { echo "  ok    $1"; }; ko() { echo "  FALLA $1"; fail=1; }
    soft() { if [ "$STRICT" = 1 ]; then ko "$1"; else echo "  aviso $1"; warn=1; fi; }
    get() { curl -s -o "$tmp/body" -D "$tmp/hdr" -w '%{http_code}' --max-time 60 "$@"; }
    lang_of() { grep -o '<html lang="[^"]*"' "$1" | head -1 | cut -d'"' -f2; }
    cache_of() { grep -i '^x-cache-status:' "$tmp/hdr" | tr -d '\r' | awk '{print $2}'; }
    tmp="$(mktemp -d)"
    echo "== gate del visor clearnet · $BASE"
    code="$(get "$BASE/c")"; [ "$code" = 200 ] && ok "/c → 200" || ko "/c → $code"
    get "$BASE/c?$stamp=a" >/dev/null; c1="$(cache_of)"; get "$BASE/c?$stamp=a" >/dev/null; c2="$(cache_of)"
    case "$c2" in HIT|STALE|UPDATING) ok "caché: $c1 → $c2" ;; *) ko "caché: $c1 → $c2 (se esperaba HIT en la segunda)" ;; esac
    ncsp="$(grep -i -c '^content-security-policy:' "$tmp/hdr")"
    [ "$ncsp" = 1 ] && ok "una sola cabecera Content-Security-Policy" || ko "$ncsp cabeceras Content-Security-Policy (se espera 1: el backend o el edge, no los dos)"
    # D-O25: lo que depende del visitante no puede cambiar la página. Cada petición lleva una
    # URL distinta para que la respuesta salga del backend y no de la caché.
    get -H 'Accept-Language: de' "$BASE/c?$stamp=b1" >/dev/null; l1="$(lang_of "$tmp/body")"
    get -H 'Accept-Language: es' "$BASE/c?$stamp=b2" >/dev/null; l2="$(lang_of "$tmp/body")"
    get -H 'Accept-Language: fr' -H 'Cookie: language=it; theme=Clear-SNH' "$BASE/c?$stamp=b3" >/dev/null; l3="$(lang_of "$tmp/body")"
    get "$BASE/c?$stamp=b4" >/dev/null; l0="$(lang_of "$tmp/body")"
    if [ -n "$l0" ] && [ "$l1" = "$l0" ] && [ "$l2" = "$l0" ] && [ "$l3" = "$l0" ]; then ok "idioma por defecto «$l0» igual con Accept-Language de/es/fr y con cookies"
    else ko "el idioma de /c depende del visitante: sin cabecera «$l0», de «$l1», es «$l2», fr+cookie «$l3»"; fi
    get "$BASE/c?lang=de&$stamp=c1" >/dev/null; ld="$(lang_of "$tmp/body")"
    get "$BASE/c?lang=es&$stamp=c2" >/dev/null; le="$(lang_of "$tmp/body")"
    if [ "$ld" = de ] && [ "$le" = es ]; then
      ok "?lang= elige el idioma (de, es)"
      # Cruce: el idioma es una variable global del proceso. Peticiones simultáneas en seis idiomas, tres
      # tandas (WP-O132: con dos idiomas y una tanda el cruce no asomaba; con seis y tres salían 6 de 18 en el host).
      cross=0; total=0
      for i in 1 2 3; do
        for l in de es fr ar ru zh; do ( curl -s --max-time 60 "$BASE/c?lang=$l&$stamp=x$i$l" | grep -o '<html lang="[^"]*"' | head -1 | cut -d'"' -f2 > "$tmp/x.$i.$l" ) & done
        wait
      done
      for f in "$tmp"/x.*; do total=$((total + 1)); want="${f##*.}"; [ "$(cat "$f")" = "$want" ] || cross=$((cross + 1)); done
      [ "$cross" = 0 ] && ok "sin cruce de idiomas en $total peticiones concurrentes (6 idiomas)" || ko "cruce de idiomas: $cross de $total páginas salieron en el idioma de otra petición (guard WP-O132 ausente o roto)"
      # Selector y <html lang> coherentes con la petición (el guard re-afirma el idioma antes del render).
      get "$BASE/c?lang=ar&$stamp=c3" >/dev/null; sel="$(grep -o 'cn-lang-current">[^<]*' "$tmp/body" | head -1 | cut -d'>' -f2)"
      [ "$(lang_of "$tmp/body")" = ar ] && [ "$sel" = AR ] && ok "?lang=ar: <html lang> y selector en AR" || ko "?lang=ar: <html lang> «$(lang_of "$tmp/body")», selector «$sel»"
    else soft "?lang= no cambia el idioma (de→«$ld», es→«$le»): visor anterior a 1.1.10"; fi
    # Tema (WP-O132, D-O30): por defecto el de la config del HUB; el visitante lo cambia con ?theme=, que viaja en la
    # URL y entra en la clave de caché; un valor desconocido no cambia nada; los enlaces conservan lang y theme.
    bg_of() { grep -o -- '--bg:#[0-9A-Fa-f]*' "$1" | head -1; }
    get "$BASE/c?$stamp=t0" >/dev/null; t0="$(bg_of "$tmp/body")"; has_sel="$(grep -c 'cn-theme-current' "$tmp/body")"
    if [ "$has_sel" -ge 1 ]; then
      ok "selector de tema presente (por defecto $t0)"
      get "$BASE/c?theme=Clear-SNH&$stamp=t1" >/dev/null; t1="$(bg_of "$tmp/body")"
      get "$BASE/c?theme=Matrix-SNH&$stamp=t2" >/dev/null; t2="$(bg_of "$tmp/body")"
      get "$BASE/c?theme=xx&$stamp=t3" >/dev/null; t3="$(bg_of "$tmp/body")"
      [ "$t1" = '--bg:#F9F9F9' ] && [ "$t2" = '--bg:#000000' ] && [ "$t3" = "$t0" ] && ok "?theme= elige la paleta (Clear $t1, Matrix $t2) y un tema desconocido deja la de la config ($t3)" || ko "?theme=: Clear «$t1», Matrix «$t2», desconocido «$t3» (por defecto «$t0»)"
      get "$BASE/c?theme=Clear-SNH&lang=de&$stamp=t4" >/dev/null
      nl="$(grep -o 'href="/c[^"]*"' "$tmp/body" | grep -c 'lang=de')"; nt="$(grep -o 'href="/c[^"]*"' "$tmp/body" | grep -c 'theme=Clear-SNH')"
      [ "$nl" -gt 0 ] && [ "$nt" -gt 0 ] && ok "los enlaces /c… conservan lang y theme ($nl con lang, $nt con theme)" || ko "los enlaces /c… no conservan lang/theme ($nl con lang, $nt con theme)"
      get "$BASE/c?theme=Clear-SNH&$stamp=t1" >/dev/null; c2="$(cache_of)"
      case "$c2" in HIT|STALE|UPDATING) ok "la variante ?theme= se cachea aparte ($c2)" ;; *) soft "variante ?theme=: $c2 en la segunda petición" ;; esac
      tcross=0; ttotal=0
      for i in 1 2 3; do
        for t in Clear-SNH Matrix-SNH Purple-SNH; do ( curl -s --max-time 60 "$BASE/c?theme=$t&$stamp=y$i$t" | grep -o -- '--bg:#[0-9A-Fa-f]*' | head -1 > "$tmp/y.$i.$t" ) & done
        wait
      done
      for f in "$tmp"/y.*; do ttotal=$((ttotal + 1)); case "${f##*.}" in Clear-SNH) want='--bg:#F9F9F9' ;; Matrix-SNH) want='--bg:#000000' ;; *) want='--bg:#4B0A6D' ;; esac; [ "$(cat "$f")" = "$want" ] || tcross=$((tcross + 1)); done
      [ "$tcross" = 0 ] && ok "sin cruce de temas en $ttotal peticiones concurrentes" || ko "cruce de temas: $tcross de $ttotal"
    else soft "sin selector de tema en /c (visor sin el guard WP-O132)"; fi
    # Listado por tipo: la página de Files (1.2.1) sale por la misma location genérica que el resto.
    code="$(get "$BASE/c?type=files&$stamp=f")"
    [ "$code" = 200 ] && ok "/c?type=files → 200" || soft "/c?type=files → $code (tipo nuevo de 1.2.1)"
    for path in "/c/sitemap.xml" "/c/rss/$RSS_MODULE" "/c/rss/files"; do
      code="$(get "$BASE$path")"
      if [ "$code" != 200 ]; then soft "$path → $code (ruta nueva de 1.1.10; /c/rss/files, de 1.2.1)"; continue; fi
      # En local el backend ve Host=localhost y construye las URLs con la IP de la LAN: no sirve para
      # probar la reescritura a https. Se pregunta a la caché desde dentro, con un Host de mentira.
      if [ "$MODE" = local ]; then
        MSYS_NO_PATHCONV=1 docker exec "${HUB_CACHE_CONTAINER:-oasis-pub-hub-cache}" wget -qO- --header 'Host: gate.example.org' "http://127.0.0.1$path" > "$tmp/body" 2>/dev/null
      fi
      plain="$(grep -o '<\(loc\|link\)>http://[^<]*' "$tmp/body" | head -1)"
      n="$(grep -o '<\(loc\|link\)>https://' "$tmp/body" | wc -l | tr -d ' ')"
      if [ -z "$plain" ] && [ "$n" -gt 0 ]; then ok "$path → 200, $n URLs, todas https"
      elif [ -z "$plain" ]; then ok "$path → 200, sin URLs todavía (nadie ha publicado de ese tipo)"
      else ko "$path publica URLs http:// (${plain#*>})"; fi
    done
    rm -rf "$tmp"
    [ "$fail" = 0 ] && { echo "GATE OK$([ "$warn" = 1 ] && echo ' (con avisos)')"; exit 0; } || { echo "GATE: DESVIACIÓN"; exit 1; }
    ;;

  smoke)
    img="${ARGS[0]:-}"; [ -n "$img" ] || { echo "uso: smoke <imagen[:tag]> [--max N]" >&2; exit 64; }
    if [ "$WMAX_SET" = 1 ]; then smax="$WMAX"; else smax="${GATE_SMOKE_MAX:-120}"; fi
    # El mismo guion en local y en el host (viaja por stdin a `run`, como la foto). Nada de lo que hace
    # toca un nodo: contenedores efímeros sin red ni volúmenes, que se borran al salir.
    echo "== humo de la imagen $img ($MODE) · tope $smax s por modo"
    { printf 'IMG=%q; MAX=%q; LOG_ERR_RE=%q\n' "$img" "$smax" "$LOG_ERR_RE"
      cat <<'EOS'
fail=0; CIDS=""
ok() { echo "  ok    $1"; }; ko() { echo "  FALLA $1"; fail=1; }
cleanup() { [ -n "$CIDS" ] && docker rm -f $CIDS >/dev/null 2>&1; return 0; }; trap cleanup EXIT
sh0() { docker run --rm --network none --entrypoint sh "$IMG" -c "$1" 2>/dev/null; }
docker image inspect "$IMG" >/dev/null 2>&1 || { ko "la imagen $IMG no existe aquí"; echo "SMOKE: DESVIACIÓN"; exit 1; }
v="$(sh0 'grep -m1 "\"version\"" /app/src/server/package.json' | sed 's/.*: *"\([^"]*\)".*/\1/')"
[ -n "$v" ] && ok "versión de Oasis dentro de la imagen: $v" || ko "sin /app/src/server/package.json legible"
sh0 'node --check /app/src/backend/backend.js && node --check /app/src/views/clearnet_view.js && node --check /app/src/server/SSB_server.js' \
  && ok "node --check: backend.js, clearnet_view.js, SSB_server.js" || ko "node --check falla en backend.js, clearnet_view.js o SSB_server.js"
sh0 'test -L /app/src/server/node_modules && test -d /app/src/base/node_modules/ssb-db2' \
  && ok "src/server/node_modules es un enlace y src/base trae lo vendorizado" || ko "src/server/node_modules no es un enlace o falta src/base/node_modules/ssb-db2"
n="$(sh0 'find / -xdev -name secret 2>/dev/null | wc -l' | tr -d ' ')"
[ "${n:-x}" = 0 ] && ok "0 ficheros «secret» en la imagen" || ko "${n:-?} ficheros «secret» en la imagen (identidad dentro del contexto de build: .dockerignore)"
# Lo que .dockerignore debe dejar fuera (UPGRADE §3.4 U2 y §4): carpetas del fork en la raíz de /app (src/client es
# de upstream) y cualquier .env* a dos niveles (la carpeta del compose del host va dentro del contexto); los
# *.example no son secretos y el host los re-incluye a propósito.
leak="$(sh0 'find /app -maxdepth 1 \( -name "volumes-*" -o -name "src.old*" -o -name "src.new*" -o -name devops -o -name client -o -name ARCHIVO \) 2>/dev/null; find /app -maxdepth 2 -name ".env*" ! -name "*.example" 2>/dev/null')"
[ -z "$leak" ] && ok "sin .env* (salvo *.example), volumes-*, src.old*/src.new*, devops/, client/ ni ARCHIVO/ en /app" || ko "en /app sobra: $(printf '%s' "$leak" | tr '\n' ' ')"
for mode in server backend; do
  cid="$(docker run -d --network none -e OASIS_SKIP_AI_MODEL=true -e OASIS_PUBLIC=true -e OASIS_OPEN=false -e HOME=/home/oasis -e SSB_PATH=/home/oasis/.ssb "$IMG" $mode 2>/dev/null)"
  [ -n "$cid" ] || { ko "$mode: docker run falló"; continue; }
  CIDS="$CIDS $cid"; t=0; up=0
  while [ $t -lt "$MAX" ]; do
    [ "$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null)" = running ] || break
    if [ $mode = server ]; then docker exec "$cid" test -S /home/oasis/.ssb/socket 2>/dev/null && { up=1; break; }
    else [ "$(docker exec "$cid" curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:3000/c 2>/dev/null)" = 200 ] && { up=1; break; }; fi
    sleep 2; t=$((t + 2))
  done
  if [ $up = 1 ]; then ok "$mode: $([ $mode = server ] && echo 'socket del sbot' || echo 'GET /c → 200') a los $t s"
  else ko "$mode: $([ "$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null)" = running ] && echo "sin respuesta en $MAX s" || echo "el contenedor se cayó a los $t s")"; fi
  logs="$(docker logs "$cid" 2>&1)"
  # El keepalive del enlace con el pub (WP-O143) solo se mide en que arranca o se declara desactivado: sin red no hay enlace.
  if [ $mode = backend ]; then printf '%s\n' "$logs" | grep -a -q 'Enlace con el pub' && ok "$mode: el entrypoint anuncia el enlace con el pub (start_pub_link)" || ko "$mode: el entrypoint no anuncia «Enlace con el pub» (¿pub-link.js en la imagen? ¿start_pub_link?)"; fi
  p="$(printf '%s\n' "$logs" | grep -a -c -E 'patcheado|ya parcheado')"; miss="$(printf '%s\n' "$logs" | grep -a -c -E 'no se encontr|no necesita patch')"
  [ "$p" -ge 3 ] && [ "$miss" = 0 ] && ok "$mode: $p parches del entrypoint aplicados o ya presentes" || ko "$mode: $p parches aplicados, $miss sin anclaje (se esperan 3 «patcheado»/«ya parcheado»)"
  e="$(printf '%s\n' "$logs" | grep -a -i -E -c "$LOG_ERR_RE")"
  [ "$e" = 0 ] && ok "$mode: 0 líneas de error en el log" || { ko "$mode: $e líneas de error en el log"; printf '%s\n' "$logs" | grep -a -i -E "$LOG_ERR_RE" | head -3 | cut -c1-160 | sed 's/^/        /'; }
  docker rm -f "$cid" >/dev/null 2>&1; CIDS="${CIDS// $cid/}"
done
[ $fail = 0 ] && { echo "SMOKE OK"; exit 0; } || { echo "SMOKE: DESVIACIÓN"; exit 1; }
EOS
    } | run
    ;;

  link)
    alias="${ARGS[0]:-}"; [ -n "$alias" ] || { echo "uso: link <alias> [--yes]" >&2; exit 64; }
    c="$(container_of "$alias")" || { echo "alias desconocido: $alias (GATE_NODES)" >&2; exit 64; }
    pubc="$(container_of "$GATE_PUB_ALIAS")"
    # El feed del pub se lee de su secret (solo el campo público), en destino, como hace la foto.
    pf="$({ node_remote_preamble; node_remote_lib; printf 'echo "$(node_feed "$(node_ssb_dir %q)")"\n' "$pubc"; } | run 2>/dev/null | tail -1)"
    [ -n "$pf" ] || { echo "NO MEDIBLE: no se pudo leer el feed del pub ($pubc)" >&2; exit 3; }
    rc=0
    if [ "$alias" = "$GATE_PUB_ALIAS" ]; then
      # Capa pub (D-O38): el pub recuerda a cada nodo de soporte por su nombre de servicio; la conexión les llegará entrante.
      for n in $GATE_NODES; do a="${n%%:*}"; is_link_node "$a" || continue; nc="${n#*:}"; nc="${nc%%:*}"; svc="${n##*:}"
        nf="$({ node_remote_preamble; node_remote_lib; printf 'echo "$(node_feed "$(node_ssb_dir %q)")"\n' "$nc"; } | run 2>/dev/null | tail -1)"
        [ -n "$nf" ] || { echo "  $a: sin feed legible, no se recuerda"; rc=3; continue; }
        k44="${nf#@}"; k44="${k44%.ed25519}"
        out="$({ node_remote_preamble; node_remote_lib; printf 'node_pub_link %q --remember %q --type pub\n' "$pubc" "net:$svc:8008~shs:$k44"; } | run 2>/dev/null | tail -1)"
        echo "  pub recuerda a $a ($svc): ${out:-sin respuesta}"
      done
      sleep 5
    else
      is_link_node "$alias" || { echo "uso: link <alias de soporte|$GATE_PUB_ALIAS> (GATE_LINK_NODES=$GATE_LINK_NODES)" >&2; exit 64; }
      # Con la clave del pub, --ensure crea la entrada por nombre de servicio si el nodo solo lo conocía por IP.
      k44="${pf#@}"; k44="${k44%.ed25519}"
      out="$({ node_remote_preamble; node_remote_lib; printf 'node_pub_link %q --ensure %q --key %q --now\n' "$c" "$GATE_PUB_LINK_HOST" "$k44"; } | run 2>/dev/null | tail -1)"
      echo "  $alias: ${out:-sin respuesta de pub-link.js}"
    fi
    echo "== enlace con el pub tras link ($MODE)"
    for n in $GATE_NODES; do a="${n%%:*}"; is_link_node "$a" || continue; nc="${n#*:}"; nc="${nc%%:*}"
      st="$({ node_remote_preamble; node_remote_lib; printf 'node_link %q %q\n' "$nc" "$pf"; } | run 2>/dev/null | tail -1)"
      echo "  $a|pub_link|${st:-?}"
      case "$st" in connected*) ;; ausente) [ $rc = 0 ] && rc=1 ;; *) rc=3 ;; esac
    done
    case $rc in 0) echo "LINK OK";; 1) echo "LINK: ausente en algún nodo (repite tras unos segundos; si persiste, mira su log [pub-link])";; *) echo "LINK: NO MEDIBLE";; esac
    exit $rc
    ;;

  backup|restore)
    tag="${ARGS[0]:-}"; [ -n "$tag" ] || { echo "uso: $CMD <tag>" >&2; exit 64; }
    store="$REPO_ROOT/volumes-dev/.gates/$tag"; dirs="oasis-pub oasis-hub oasis-wallet-bot"   # nunca el retro: identidad real en volumes-real/ (D-O33, D-O36)
    for n in $GATE_NODES; do c="${n#*:}"; c="${c%%:*}"
      [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = true ] && { echo "ERROR: $c está corriendo: para los nodos antes (un log copiado en caliente puede quedar a medias)." >&2; exit 3; }
    done
    if [ "$CMD" = backup ]; then
      [ -e "$store" ] && { echo "ERROR: ya existe $store" >&2; exit 3; }
      mkdir -p "$store"; for d in $dirs; do [ -d "$REPO_ROOT/volumes-dev/$d" ] && cp -a "$REPO_ROOT/volumes-dev/$d" "$store/"; done
      echo "copia «$tag»: $(du -sh "$store" | cut -f1) en volumes-dev/.gates/$tag"
    else
      [ -d "$store" ] || { echo "ERROR: no existe $store" >&2; exit 3; }
      [ "$YES" = 1 ] || { echo "restore SUSTITUYE volumes-dev/{oasis-pub,oasis-hub,oasis-wallet-bot} por la copia «$tag» (identidades desechables). Repite con --yes." >&2; exit 64; }
      for d in $dirs; do [ -d "$store/$d" ] || continue; rm -rf "${REPO_ROOT:?}/volumes-dev/$d"; cp -a "$store/$d" "$REPO_ROOT/volumes-dev/"; done
      echo "repuesta la copia «$tag» (la config renderizada del bot también: vuelve a renderizarla si el ciclo la cambió)"
    fi
    ;;

  up)
    alias="${ARGS[0]:-}"; svc="$(service_of "$alias")" || { echo "uso: up <pub|hub|bot>" >&2; exit 64; }
    c="$(container_of "$alias")"
    compose_local up -d --no-deps --force-recreate "$svc" 2>&1 | tail -1
    # El primer arranque en una versión con otro motor de base de datos migra el log ANTES de abrir
    # el sbot (1.2: flume → db2): hasta que acaba no hay socket ni healthy. Tope: GATE_UP_TIMEOUT s.
    # Con start_interval en el compose el healthy llega en segundos: se sondea cada 2 s.
    tries=$(( ${GATE_UP_TIMEOUT:-300} / 2 ))
    n=0; until [ "$(docker inspect -f '{{.State.Health.Status}}' "$c" 2>/dev/null)" = healthy ] || [ $n -ge "$tries" ]; do sleep 2; n=$((n + 1)); done
    st="$(docker inspect -f '{{.State.Status}} {{.State.Health.Status}}' "$c" 2>/dev/null)"
    echo "$alias ($c): $st · v$(docker exec "$c" sh -c 'grep -m1 "\"version\"" /app/src/server/package.json' 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')"
    case "$st" in *healthy) ;; *) echo "DESVIACIÓN: $c no llegó a healthy en $((n * 2)) s (¿migración larga? GATE_UP_TIMEOUT)" >&2; exit 1 ;; esac
    echo "  healthy a los $((n * 2)) s"
    # Un nodo no publica solo «al arrancar»: el sbot anuncia versión a los 7 s, el motor hace su
    # primer tick a los 15 s, y los avisos del backend se disparan con una petición cuando los índices
    # ya están. Eso lo mide `check <tag> --wait` (verde solo cuando el delta es el esperado y el
    # sequence lleva GATE_STABLE s quieto). GATE_SETTLE repone el settle fijo antiguo, opt-in.
    if [ -n "${GATE_SETTLE:-}" ]; then
      settle="$GATE_SETTLE"; sleep $((settle / 2))
      MSYS_NO_PATHCONV=1 docker exec "$c" sh -c 'curl -s -o /dev/null --max-time 20 http://127.0.0.1:3000/c/inhabitant/@AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=.ed25519' 2>/dev/null || true
      sleep $((settle - settle / 2)); echo "  settle fijo de $settle s (GATE_SETTLE)"
    fi
    echo "Ahora: upgrade-gates.sh --local check <tag> --wait"
    ;;

  worst)
    c="$(container_of bot)"
    # Las páginas donde el backend refresca la cartera por su cuenta (WALLET_CHIP_PATHS de backend.js).
    # /wallet NO entra por defecto: en CUALQUIER versión, con el motor encendido, republica la
    # dirección con la última que haya emitido la cartera (cada pubAvailability pide una nueva).
    # No es una regresión que medir en cada upgrade: es una trampa (AGENTES §4, ECOIN §9).
    # GATE_WORST_PATHS permite pedir otras rutas a propósito.
    for p in ${GATE_WORST_PATHS:-/banking /transfers /shops /market /school}; do
      code="$(MSYS_NO_PATHCONV=1 docker exec "$c" curl -s -o /dev/null -w '%{http_code}' --max-time 60 -H 'Host: localhost:3000' "http://127.0.0.1:3000$p")"
      echo "GET $p por loopback en el bot → $code"
    done
    echo "Ahora: upgrade-gates.sh --local check u5 --wait --expect 'bot:karmaScore=+0..1' (wallet y (cifrado) no deben moverse)."
    ;;
esac
