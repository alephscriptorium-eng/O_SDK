#!/usr/bin/env bash
# =============================================================================
# hub-wallet.sh — gestión de admin del motor de RBU del hub-wallet (bot de cartera).
#
# Oasis (1.1.3+) no trae panel de admin del motor: corre si el ssb-config del
# proceso dice `pub: true` y `wallet.url` no está vacía. Aquí el interruptor es
# QUÉ fichero se monta como ~/.ssb/config del bot:
#     config/wallet-bot/ssb-config            pub:false  → motor APAGADO (bootstrap, pausa)
#     config/wallet-bot/ssb-config.engine-on  pub:true   → motor ENCENDIDO
# y se elige con OASIS_WALLET_BOT_SSB_CONFIG_FILE en el env-file del host + recreate
# del bot. Doc viva: docs/PUB/ECOIN-PROTOCOL.md §9.
#
# Uso:
#   bash devops/scripts/hub-wallet.sh [--local] <subcomando>
#
# Subcomandos:
#   status    modo (pub:true/false montado), «[UBI] PUB engine on» en el log, mensajes
#             propios del bot por tipo, último pubAvailability, saldo, pool de la época
#             (min(saldo−500, 2000, 0,2·saldo)) y altura de la cadena.   [read-only]
#   ready     precondiciones para encender, SIN encender. exit 0 = listo.  [read-only]
#   on --yes  ready + apunta el env-file al ssb-config.engine-on + recreate del bot.
#             Publica un pubAvailability: IRREVERSIBLE, pide GO del custodio (AGENTES §3).
#   pause     vuelve al ssb-config (pub:false) + recreate. La tarjeta de Banking caduca
#             sola a los 3 días. No publica nada. Nunca toca wallet.dat.
#
#   --local   mismo flujo contra el stack local (pub/.env.local, volumes-dev/), sin SSH.
#
# Las credenciales RPC no salen del contenedor de ecoind: las consultas se hacen con
# `docker exec` usando las variables que ya tiene dentro. Este script nunca las imprime.
#
# Instancia: lib-host.sh (devops/hosts/<DEVOPS_HOST>/host.env). Variables opcionales:
#   REMOTE_REPO_DIR   carpeta del compose en el host     REMOTE_ENV_FILE  env-file (.env.prod)
#   WALLET_DATA_ROOT  raíz de datos (default /srv/oasis) BOT / ECOIN      nombres de contenedor
#   WALLET_BACKUP_MAX_H  antigüedad máxima del backup local de wallet.dat (24)
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

usage() { sed -n '13,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

LOCAL=0; YES=0; CMD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL=1 ;;
    --yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) [ -z "$CMD" ] && CMD="$1" ;;
  esac
  shift
done
CMD="${CMD:-status}"
case "$CMD" in status|ready|on|pause) ;; *) usage; exit 64 ;; esac

BOT="${BOT:-oasis-pub-wallet-bot}"
ECOIN="${ECOIN:-oasis-pub-ecoin}"
PUBC="${PUB_CONTAINER:-oasis-pub-scriptorium}"
CFG_OFF="./config/wallet-bot/ssb-config"
CFG_ON="./config/wallet-bot/ssb-config.engine-on"

TMP_WORK=""
cleanup() { [ -n "$TMP_WORK" ] && rm -rf "$TMP_WORK"; }
trap cleanup EXIT

if [ "$LOCAL" = 1 ]; then
  COMPOSE_DIR="$REPO_ROOT/pub"; ENV_FILE=".env.local"; DATA="$REPO_ROOT/volumes-dev"; SUDO=""
  run() { MSYS_NO_PATHCONV=1 bash -s; }
else
  COMPOSE_DIR="${REMOTE_REPO_DIR:?REMOTE_REPO_DIR vacío (host.env)}"; ENV_FILE="${REMOTE_ENV_FILE:-.env.prod}"
  DATA="${WALLET_DATA_ROOT:-/srv/oasis}"; SUDO="sudo -n"
  [ -n "${REMOTE_USER:-}" ] && [ -n "${REMOTE_HOST:-}" ] || { echo "ERROR: REMOTE_USER/REMOTE_HOST vacíos" >&2; exit 3; }
  [ -f "${KEY_PATH:-}" ] || { echo "ERROR: clave SSH no encontrada: ${KEY_PATH:-}" >&2; exit 3; }
  key_mode="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || echo 600)"
  if [ "$key_mode" != "600" ] && [ "$key_mode" != "400" ]; then
    TMP_WORK="$(mktemp -d)"; cat "$KEY_PATH" > "$TMP_WORK/key"; chmod 600 "$TMP_WORK/key"; KEY_PATH="$TMP_WORK/key"
  fi
  run() { ssh -i "$KEY_PATH" -o BatchMode=yes -o ServerAliveInterval=30 "$REMOTE_USER@$REMOTE_HOST" bash -s; }
fi

# Backup local reciente de wallet.dat (lo hace backup-ecoin.sh en la máquina del operador)
backup_ok=0
newest="$(ls -1d "$DEVOPS_DIR"/backups/ecoin/*/ 2>/dev/null | sort | tail -1)"
if [ -n "$newest" ] && [ -n "$(find "$newest" -maxdepth 1 -name 'wallet-*.dat' -mmin "-$(( ${WALLET_BACKUP_MAX_H:-24} * 60 ))" 2>/dev/null | head -1)" ]; then backup_ok=1; fi

# ---------------------------------------------------------------------------
# Bloque que se ejecuta en el host (o en local): una sola sesión, sin secretos en argv
# ---------------------------------------------------------------------------
run <<REMOTE
set -uo pipefail
CMD="$CMD"; YES="$YES"; BOT="$BOT"; ECOIN="$ECOIN"; PUBC="$PUBC"; SUDO="$SUDO"
DATA="$DATA"; ENV_FILE="$ENV_FILE"; CFG_OFF="$CFG_OFF"; CFG_ON="$CFG_ON"; BACKUP_OK="$backup_ok"
cd "$COMPOSE_DIR" || { echo "ERROR: no existe $COMPOSE_DIR"; exit 3; }
C="docker compose --env-file \$ENV_FILE -f docker-compose.pub.yml --profile wallet"
LOG="\$DATA/oasis-wallet-bot/ssb-data/flume/log.offset"
MAP="\$DATA/oasis-wallet-bot/ssb-data/oasis/banking/wallet-addresses.json"

rpc() { # rpc <method> [json-params]  — credenciales solo dentro del contenedor de ecoind
  docker exec -e M="\$1" -e P="\${2:-[]}" "\$ECOIN" sh -c 'curl -s --max-time 10 --user "\$RPC_USER:\$RPC_PASS" -H "content-type: text/plain;" --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"hw\",\"method\":\"\$M\",\"params\":\$P}" http://127.0.0.1:7474/' 2>/dev/null
}
num() { grep -o "\"\$1\" *: *[-0-9.]*" | head -1 | sed 's/.*: *//'; }

FEED="\$(\$SUDO cat "\$MAP" 2>/dev/null | grep -o '@[A-Za-z0-9+/]\{43\}=\.ed25519' | head -1)"
ADDR="\$(\$SUDO cat "\$MAP" 2>/dev/null | grep -o '"E[A-Za-z0-9]\{25,40\}"' | head -1 | tr -d '"')"
MOUNTED="\$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/home/oasis/.ssb/config"}}{{.Source}}{{end}}{{end}}' "\$BOT" 2>/dev/null)"
PUBFLAG="\$(docker exec "\$BOT" sh -c 'grep -o "\"pub\": *[a-z]*" /home/oasis/.ssb/config' 2>/dev/null | sed 's/.*: *//')"
ENGINE_LOG="\$(docker logs "\$BOT" 2>&1 | grep -a -c 'PUB engine on')"
INFO="\$(rpc getinfo)"
BAL="\$(printf '%s' "\$INFO" | num balance)"; BLOCKS="\$(printf '%s' "\$INFO" | num blocks)"; CONNS="\$(printf '%s' "\$INFO" | num connections)"
PEERH="\$(docker logs --tail 4000 "\$ECOIN" 2>&1 | grep -a -o 'receive version message.*blocks=[0-9]*' | grep -o 'blocks=[0-9]*' | cut -d= -f2 | sort -n | tail -1)"
own() { \$SUDO grep -a -o "\"author\":\"\$FEED[^{]*{\"type\":\"\$1\"" "\$LOG" 2>/dev/null | wc -l | tr -d ' '; }

status() {
  echo "== hub-wallet · \$(date -u +%FT%TZ)"
  echo "bot:        \$(docker inspect -f '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{end}}' "\$BOT" 2>/dev/null)   feed \${FEED:-?}"
  echo "modo:       pub=\${PUBFLAG:-?}  (\${MOUNTED##*/})   «PUB engine on» en el log: \$ENGINE_LOG"
  echo "mensajes:   wallet=\$(own wallet) about=\$(own about) pubAvailability=\$(own pubAvailability) ubiAllocation=\$(own ubiAllocation)"
  echo "anuncio:    \$(\$SUDO grep -a -o "\"author\":\"\$FEED[^{]*{\"type\":\"pubAvailability\"[^}]*" "\$LOG" 2>/dev/null | tail -1 | sed 's/.*"content"://' | cut -c1-200)"
  echo "ecoind:     \$(docker inspect -f '{{.State.Health.Status}}' "\$ECOIN" 2>/dev/null)  blocks=\${BLOCKS:-?} (pares: \${PEERH:-?})  conexiones=\${CONNS:-?}"
  echo "cartera:    \${ADDR:-?}  saldo=\${BAL:-?} ECO"
  awk -v b="\${BAL:-0}" 'BEGIN{a=b-500; if(a<0)a=0; p=a; if(2000<p)p=2000; if(0.2*b<p)p=0.2*b; printf "pool:       %.4f ECO esta época  (min(saldo-500, 2000, 0.2*saldo); con saldo <= 500 no se paga)\n", p}'
}

ready() {
  fail=0; ok() { echo "  ok   \$1"; }; ko() { echo "  FALLA \$1"; fail=1; }
  [ "\$(docker inspect -f '{{.State.Health.Status}}' "\$BOT" 2>/dev/null)" = healthy ] && ok "bot healthy" || ko "bot no healthy"
  [ "\$(docker inspect -f '{{.State.Health.Status}}' "\$ECOIN" 2>/dev/null)" = healthy ] && ok "ecoind healthy" || ko "ecoind no healthy"
  [ -n "\$BLOCKS" ] && ok "RPC responde (blocks=\$BLOCKS)" || ko "RPC no responde"
  if [ -n "\$BLOCKS" ] && [ -n "\$PEERH" ] && [ "\$BLOCKS" -ge "\$PEERH" ] 2>/dev/null; then ok "sincronizado (pares anuncian \$PEERH)"
  elif [ -n "\$BLOCKS" ] && [ -z "\$PEERH" ] && [ "\${CONNS:-0}" -gt 0 ] 2>/dev/null; then ok "sin altura de pares en el log reciente; \$CONNS conexiones (comprobar a mano si dudas)"
  else ko "no sincronizado: blocks=\${BLOCKS:-?} pares=\${PEERH:-?} conexiones=\${CONNS:-?}"; fi
  [ -n "\$ADDR" ] && ok "dirección en oasis/banking: \$ADDR" || ko "sin dirección en \$MAP"
  [ -n "\$ADDR" ] && rpc validateaddress "[\"\$ADDR\"]" | grep -q '"ismine" *: *true' && ok "la dirección es de esta cartera (ismine)" || ko "validateaddress no dice ismine:true"
  [ "\$(own wallet)" = 1 ] && ok "un único mensaje wallet propio" || ko "mensajes wallet propios = \$(own wallet) (esperado 1)"
  [ "\$BACKUP_OK" = 1 ] && ok "backup local de wallet.dat reciente" || ko "sin backup local reciente de wallet.dat (backup-ecoin.sh)"
  KEY="\${FEED#@}"; KEY="\${KEY%.ed25519}"
  last="\$(docker logs --tail 2000 "\$PUBC" 2>&1 | grep -a -F "\$KEY" | grep -a -o 'CONNECTED\|DISCONNECTED' | tail -1)"
  [ "\$last" = CONNECTED ] && ok "conectado al pub" || ko "el pub no lo ve conectado (último: \${last:-nada})"
  [ -f "\$CFG_ON" ] && grep -q '"pub": *true' "\$CFG_ON" && ok "\$CFG_ON presente (pub:true)" || ko "falta \$CFG_ON"
  [ "\$fail" = 0 ] && echo "LISTO para encender." || echo "NO listo."
  return \$fail
}

switch_to() { # switch_to <fichero de ssb-config>
  cp -p "\$ENV_FILE" "\$ENV_FILE.bak-hubwallet-\$(date -u +%Y%m%dT%H%M%SZ)"
  if grep -q '^OASIS_WALLET_BOT_SSB_CONFIG_FILE=' "\$ENV_FILE"; then
    sed -i "s|^OASIS_WALLET_BOT_SSB_CONFIG_FILE=.*|OASIS_WALLET_BOT_SSB_CONFIG_FILE=\$1|" "\$ENV_FILE"
  else
    printf '\nOASIS_WALLET_BOT_SSB_CONFIG_FILE=%s\n' "\$1" >> "\$ENV_FILE"
  fi
  \$C up -d --no-deps oasis-wallet-bot 2>&1 | tail -1
  n=0; until [ "\$(docker inspect -f '{{.State.Health.Status}}' "\$BOT" 2>/dev/null)" = healthy ] || [ \$n -ge 60 ]; do sleep 5; n=\$((n+1)); done
  PUBFLAG="\$(docker exec "\$BOT" sh -c 'grep -o "\"pub\": *[a-z]*" /home/oasis/.ssb/config' 2>/dev/null | sed 's/.*: *//')"
  MOUNTED="\$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/home/oasis/.ssb/config"}}{{.Source}}{{end}}{{end}}' "\$BOT" 2>/dev/null)"
  sleep 25   # el primer tick del motor corre a los 15 s del arranque del backend
  ENGINE_LOG="\$(docker logs "\$BOT" 2>&1 | grep -a -c 'PUB engine on')"
}

case "\$CMD" in
  status) status ;;
  ready)  ready ;;
  on)
    [ "\$YES" = 1 ] || { echo "on publica un pubAvailability (irreversible): repite con --yes tras el GO del custodio."; exit 64; }
    ready || { echo "ABORTADO: precondiciones."; exit 1; }
    switch_to "\$CFG_ON"; status
    [ "\$PUBFLAG" = true ] && [ "\$ENGINE_LOG" -ge 1 ] || { echo "DESVIACIÓN: pub=\$PUBFLAG, engine log=\$ENGINE_LOG. Considera: hub-wallet.sh pause"; exit 2; } ;;
  pause)
    switch_to "\$CFG_OFF"; status
    [ "\$PUBFLAG" = false ] && [ "\$ENGINE_LOG" = 0 ] || { echo "DESVIACIÓN: pub=\$PUBFLAG, engine log=\$ENGINE_LOG"; exit 2; } ;;
esac
REMOTE
