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
#   --remote   el host de la instancia (devops/hosts/<DEVOPS_HOST>/host.env), por SSH. SOLO LECTURA:
#              en remoto solo existen snapshot, check y hub.
#
# Subcomandos:
#   snapshot <tag>      Foto de cada nodo (pub, hub, bot): estado, versión dentro del contenedor, feed,
#                       sequence propio (del log y del sbot vivo), mensajes propios por tipo (cifrados
#                       incluidos), flag de primer contacto; en el bot además dirección, modo del motor,
#                       épocas abiertas. Se guarda en devops/logs/upgrade/<tag>.<local|remote>.snap
#   check <tag> [--expect '<esperado>']
#                       Foto nueva y comparación con <tag>. Por nodo: mismo feed; Δsequence == suma de
#                       Δ por tipo (si no cuadra, la medida no vale); y ese delta es el esperado.
#                       <esperado>: 'pub:oasisVersion=+1 hub:oasisVersion=+1 bot:oasisVersion=+1,pubAvailability=+0..1'
#                       (todo nodo, también el pub en modo server, anuncia su versión al cambiarla;
#                       `nodo:=0` declara «nada»). Lo que no se nombra debe ser 0. Sin --expect, todo 0.
#                       Además: errores en los logs desde la foto (EROFS, ReferenceError…).
#   hub [--strict]      Matriz del visor clearnet por delante de la caché: 200, MISS→HIT, mismo /c con
#                       distinto Accept-Language y con cookies (D-O25), ?lang=, cruce de idiomas con
#                       peticiones concurrentes, sitemap y RSS con URLs https. Solo GET.
#                       --strict: lo que es nuevo de 1.1.10 (?lang=, sitemap, RSS) pasa de aviso a fallo.
#   backup <tag>        (local) Copia volumes-dev/{oasis-pub,oasis-hub,oasis-wallet-bot} a
#                       volumes-dev/.gates/<tag>/ con los contenedores PARADOS.
#   restore <tag> --yes (local) Repone esa copia. Sin esto el gate no es repetible: tras una pasada el
#                       log ya tiene el oasisVersion nuevo y la segunda daría delta 0 (falso verde).
#   up <pub|hub|bot>    (local) Recrea un nodo con la imagen actual y espera a healthy.
#   worst               (local) Peor caso del bot: GET /banking y /wallet por loopback (las páginas que
#                       autopublican la dirección). Después: check … con wallet sin cambios.
#
# Códigos de salida: 0 ok · 1 desviación · 3 no medible o precondición · 64 uso.
# Nodos: GATE_NODES="alias:contenedor:servicio …" (por defecto pub, hub y bot de esta casa).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-node.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"
SNAP_DIR="$DEVOPS_DIR/logs/upgrade"

usage() { sed -n '2,39p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

MODE=""; CMD=""; ARGS=(); EXPECT=""; YES=0; STRICT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --local) MODE=local ;;
    --remote) MODE=remote ;;
    --expect) EXPECT="${2:-}"; shift ;;
    --yes) YES=1 ;;
    --strict) STRICT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) if [ -z "$CMD" ]; then CMD="$1"; else ARGS+=("$1"); fi ;;
  esac
  shift
done
[ -n "$MODE" ] && [ -n "$CMD" ] || { usage; exit 64; }
case "$CMD" in
  snapshot|check|hub) ;;
  backup|restore|up|worst) [ "$MODE" = local ] || { echo "ERROR: '$CMD' solo existe en --local: en el host este script es de solo lectura." >&2; exit 64; } ;;
  *) usage; exit 64 ;;
esac

GATE_NODES="${GATE_NODES:-pub:${PUB_CONTAINER:-oasis-pub-scriptorium}:oasis-pub hub:oasis-pub-hub:oasis-hub bot:oasis-pub-wallet-bot:oasis-wallet-bot}"
LOG_ERR_RE='EROFS|EACCES|ReferenceError|TypeError|Cannot find module|Another Oasis|no inicializada|UnhandledPromiseRejection'

trap node_run_cleanup EXIT
if [ "$MODE" = local ]; then node_run_setup 1 || exit 3; else node_run_setup 0 || exit 3; fi
compose_local() { (cd "$REPO_ROOT/pub" && MSYS_NO_PATHCONV=1 docker compose -f docker-compose.pub.yml --env-file .env.local --profile wallet "$@"); }
container_of() { for n in $GATE_NODES; do [ "${n%%:*}" = "$1" ] && { n="${n#*:}"; echo "${n%%:*}"; return 0; }; done; return 1; }
service_of()   { for n in $GATE_NODES; do [ "${n%%:*}" = "$1" ] && { echo "${n##*:}"; return 0; }; done; return 1; }

# ---------------------------------------------------------------------------
# Foto: una sesión en destino; salida «nodo|clave|valor»
# ---------------------------------------------------------------------------
take_snapshot() { # take_snapshot [<desde: fecha ISO para los logs>]
  { node_remote_preamble; node_remote_lib
    printf 'GATE_NODES=%q; SINCE=%q; LOG_ERR_RE=%q\n' "$GATE_NODES" "${1:-}" "$LOG_ERR_RE"
    cat <<'EOS'
echo "meta|ts|$(date -u +%FT%TZ)"
for n in $GATE_NODES; do
  a="${n%%:*}"; c="${n#*:}"; c="${c%%:*}"
  echo "$a|container|$c"
  echo "$a|state|$(node_state "$c")"
  echo "$a|version|$(node_version "$c")"
  echo "$a|image|$(node_image "$c")"
  echo "$a|mode|$(docker inspect -f '{{join .Config.Cmd " "}}' "$c" 2>/dev/null)"
  d="$(node_ssb_dir "$c")"
  f="$(node_feed "$d")"
  echo "$a|feed|$f"
  [ -n "$f" ] || continue
  echo "$a|seq|$(node_own_seq "$d" "$f")"
  recs="$(node_own_records "$d" "$f")"
  echo "$a|records|$(printf '%s' "$recs" | grep -c .)"
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
    echo "$a|log_errors|$(docker logs --since "$SINCE" "$c" 2>&1 | grep -a -i -E -c "$LOG_ERR_RE")"
    docker logs --since "$SINCE" "$c" 2>&1 | grep -a -i -E "$LOG_ERR_RE" | sort | uniq -c | head -3 | cut -c1-160 | sed "s/^/$a|log_sample|/"
  fi
done
EOS
  } | run 2>/dev/null
}
add_probe() { # 2ª fuente del sequence: el sbot vivo. add_probe <fichero .snap>
  local a c f st s
  for n in $GATE_NODES; do
    a="${n%%:*}"; c="${n#*:}"; c="${c%%:*}"
    f="$(awk -F'|' -v a="$a" '$1==a && $2=="feed"{print $3}' "$1")"
    st="$(awk -F'|' -v a="$a" '$1==a && $2=="state"{print $3}' "$1")"
    case "$st" in running*) ;; *) continue ;; esac
    [ -n "$f" ] || continue
    s="$(node_probe_seq "$c" "$f")"
    echo "$a|seq_probe|${s:-?}" >> "$1"
  done
}
show_snapshot() {
  awk -F'|' '
    $2=="state"{st[$1]=$3} $2=="version"{v[$1]=$3} $2=="feed"{f[$1]=$3} $2=="seq"{s[$1]=$3} $2=="records"{r[$1]=$3}
    $2=="seq_probe"{p[$1]=$3} $2 ~ /^type:/{t[$1]=t[$1] " " substr($2,6) "=" $3}
    $2=="address"{x[$1]=x[$1] " dirección=" $3} $2=="epochs"{x[$1]=x[$1] " épocas=" $3} $2=="engine"{x[$1]=x[$1] " motor:" $3}
    $2=="mode"{md[$1]=$3}
    $2=="first_contact_flag"{x[$1]=x[$1] " flag-primer-contacto=" $3; if ($3=="ausente") noflag[$1]=1}
    $1!="meta" && !seen[$1]++ {order[++n]=$1}
    END { for (i=1;i<=n;i++) { a=order[i]
      ok = (s[a]==r[a]) ? "cuadra" : "NO CUADRA (medida no válida)"
      pr = (p[a]=="" ) ? "" : ((p[a]==s[a]) ? " · sbot=" p[a] : " · sbot=" p[a] " ≠ log")
      printf "  %-4s %-16s v%-7s %-8s feed %s\n       seq=%s registros=%s → %s%s\n       tipos:%s\n      %s\n", a, st[a], (v[a]==""?"?":v[a]), md[a], f[a], s[a], r[a], ok, pr, t[a], x[a]
      if (noflag[a] && md[a] ~ /backend|full/) printf "       AVISO: sin flag de primer contacto en un nodo con backend: al arrancar enviaría el PM de bienvenida (un cifrado).\n" } }' "$1"
}

case "$CMD" in
  snapshot)
    tag="${ARGS[0]:-}"; [ -n "$tag" ] || { echo "uso: snapshot <tag>" >&2; exit 64; }
    mkdir -p "$SNAP_DIR"; out="$SNAP_DIR/$tag.$MODE.snap"
    take_snapshot > "$out.tmp"
    grep -q '|feed|@' "$out.tmp" || { echo "NO MEDIBLE: ningún nodo devolvió su feed (¿Docker/SSH/rutas?)" >&2; rm -f "$out.tmp"; exit 3; }
    add_probe "$out.tmp"; mv "$out.tmp" "$out"
    echo "== foto «$tag» ($MODE) · $(awk -F'|' '$2=="ts"{print $3}' "$out")"; show_snapshot "$out"
    echo "guardada en ${out#"$REPO_ROOT/"}"
    awk -F'|' '$2=="seq"{s[$1]=$3} $2=="records"{r[$1]=$3} END{for(a in s) if(s[a]!=r[a]) e=1; exit e}' "$out" || { echo "NO MEDIBLE: sequence y registros no cuadran en algún nodo." >&2; exit 3; }
    ;;

  check)
    tag="${ARGS[0]:-}"; base="$SNAP_DIR/$tag.$MODE.snap"
    [ -f "$base" ] || { echo "no existe la foto $base (haz antes: snapshot $tag)" >&2; exit 3; }
    since="$(awk -F'|' '$2=="ts"{print $3}' "$base")"
    now="$(mktemp)"; take_snapshot "$since" > "$now"; add_probe "$now"
    echo "== ahora ($MODE)"; show_snapshot "$now"
    echo "== delta desde «$tag» ($since) · esperado: ${EXPECT:-todo 0}"
    awk -F'|' -v expect="$EXPECT" '
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
      { v[file, $1, $2] = $3; if (!seen[$1]++) order[++nn] = $1; if ($2 ~ /^type:/) types[$1, substr($2, 6)] = 1 }
      END {
        bad = 0; unmeasurable = 0
        for (i = 1; i <= nn; i++) { a = order[i]; line = ""; sum = 0; nodebad = 0
          if (v[1, a, "feed"] != v[2, a, "feed"]) { printf "  %-4s DESVIACIÓN: el feed ha cambiado (%s → %s)\n", a, v[1, a, "feed"], v[2, a, "feed"]; bad = 1; continue }
          if (v[2, a, "feed"] == "") { printf "  %-4s NO MEDIBLE: sin feed\n", a; unmeasurable = 1; continue }
          if (v[1, a, "seq"] != v[1, a, "records"] || v[2, a, "seq"] != v[2, a, "records"]) { printf "  %-4s NO MEDIBLE: sequence y registros no cuadran\n", a; unmeasurable = 1; continue }
          if (v[2, a, "seq_probe"] != "" && v[2, a, "seq_probe"] != "?" && v[2, a, "seq_probe"] != v[2, a, "seq"]) { printf "  %-4s NO MEDIBLE: el sbot dice seq=%s y el log %s\n", a, v[2, a, "seq_probe"], v[2, a, "seq"]; unmeasurable = 1; continue }
          dseq = v[2, a, "seq"] - v[1, a, "seq"]
          for (k in types) { split(k, kk, SUBSEP); if (kk[1] != a) continue; t = kk[2]
            d = v[2, a, "type:" t] - v[1, a, "type:" t]; sum += d
            if (d != 0) line = line sprintf(" %s%+d", t, d)
            if (has[a, t]) { if (d < lo[a, t] || d > hi[a, t]) { nodebad = 1; why[a] = why[a] sprintf(" %s%+d fuera de [%s..%s];", t, d, lo[a, t], hi[a, t]) } }
            else if (d != 0) { nodebad = 1; why[a] = why[a] sprintf(" %s%+d no esperado;", t, d) } }
          n2 = split(exptypes[a], et, " ")
          for (j = 1; j <= n2; j++) if (!((a, et[j]) in types) && lo[a, et[j]] > 0) { nodebad = 1; why[a] = why[a] " falta " et[j] ";" }
          if (sum != dseq) { printf "  %-4s NO MEDIBLE: Δsequence=%d pero la suma por tipos es %d\n", a, dseq, sum; unmeasurable = 1; continue }
          ver = (v[1, a, "version"] == v[2, a, "version"]) ? "v" v[2, a, "version"] : "v" v[1, a, "version"] " → v" v[2, a, "version"]
          extra = ""
          if (v[1, a, "address"] != v[2, a, "address"]) { nodebad = 1; why[a] = why[a] " la dirección ECOin ha cambiado;" }
          if (v[1, a, "epochs"] != v[2, a, "epochs"]) extra = extra " · épocas: " v[1, a, "epochs"] " → " v[2, a, "epochs"]
          if (v[1, a, "engine"] != v[2, a, "engine"]) extra = extra " · motor: " v[1, a, "engine"] " → " v[2, a, "engine"]
          if (v[2, a, "state"] !~ /healthy/) { nodebad = 1; why[a] = why[a] " estado «" v[2, a, "state"] "»;" }
          if (v[2, a, "log_errors"] + 0 > 0) { nodebad = 1; why[a] = why[a] " " v[2, a, "log_errors"] " líneas de error en el log;" }
          printf "  %-4s %s · Δseq=%d ·%s%s → %s\n", a, ver, dseq, (line == "" ? " sin publicaciones" : line), extra, (nodebad ? "DESVIACIÓN:" why[a] : "ok")
          if (nodebad) bad = 1 }
        if (unmeasurable) exit 3
        exit bad }' "$base" "$now"
    rc=$?
    grep '|log_sample|' "$now" | sed 's/^\([a-z]*\)|log_sample|/  log \1: /'
    rm -f "$now"
    case $rc in 0) echo "GATE OK";; 1) echo "GATE: DESVIACIÓN — parar y contarlo (AGENTES §2.2)";; *) echo "GATE: NO MEDIBLE";; esac
    exit $rc
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
      # Cruce: el idioma es una variable global del proceso. Peticiones simultáneas en dos idiomas.
      cross=0; total=0
      for i in 1 2 3 4 5 6 7 8; do
        for l in de es; do ( curl -s --max-time 60 "$BASE/c?lang=$l&$stamp=x$i$l" | grep -o '<html lang="[^"]*"' | head -1 | cut -d'"' -f2 > "$tmp/x.$i.$l" ) & done
      done; wait
      for f in "$tmp"/x.*; do total=$((total + 1)); want="${f##*.}"; [ "$(cat "$f")" = "$want" ] || cross=$((cross + 1)); done
      [ "$cross" = 0 ] && ok "sin cruce de idiomas en $total peticiones concurrentes" || ko "cruce de idiomas: $cross de $total páginas salieron en el idioma de otra petición"
    else soft "?lang= no cambia el idioma (de→«$ld», es→«$le»): visor anterior a 1.1.10"; fi
    for path in "/c/sitemap.xml" "/c/rss/$RSS_MODULE"; do
      code="$(get "$BASE$path")"
      if [ "$code" != 200 ]; then soft "$path → $code (ruta nueva de 1.1.10)"; continue; fi
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

  backup|restore)
    tag="${ARGS[0]:-}"; [ -n "$tag" ] || { echo "uso: $CMD <tag>" >&2; exit 64; }
    store="$REPO_ROOT/volumes-dev/.gates/$tag"; dirs="oasis-pub oasis-hub oasis-wallet-bot"
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
      echo "repuesta la copia «$tag»"
    fi
    ;;

  up)
    alias="${ARGS[0]:-}"; svc="$(service_of "$alias")" || { echo "uso: up <pub|hub|bot>" >&2; exit 64; }
    c="$(container_of "$alias")"
    compose_local up -d --no-deps --force-recreate "$svc" 2>&1 | tail -1
    n=0; until [ "$(docker inspect -f '{{.State.Health.Status}}' "$c" 2>/dev/null)" = healthy ] || [ $n -ge 60 ]; do sleep 5; n=$((n + 1)); done
    st="$(docker inspect -f '{{.State.Status}} {{.State.Health.Status}}' "$c" 2>/dev/null)"
    echo "$alias ($c): $st · v$(docker exec "$c" sh -c 'grep -m1 "\"version\"" /app/src/server/package.json' 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')"
    case "$st" in *healthy) sleep 25 ;; *) echo "DESVIACIÓN: $c no llegó a healthy" >&2; exit 1 ;; esac   # 25 s: primer tick de arranque (oasisVersion, motor)
    ;;

  worst)
    c="$(container_of bot)"
    for p in /banking /wallet; do
      code="$(MSYS_NO_PATHCONV=1 docker exec "$c" curl -s -o /dev/null -w '%{http_code}' --max-time 60 -H 'Host: localhost:3000' "http://127.0.0.1:3000$p")"
      echo "GET $p por loopback en el bot → $code"
    done
    sleep 10
    echo "Ahora: upgrade-gates.sh --local check <tag> --expect '…' (wallet no debe moverse; karmaScore puede)."
    ;;
esac
