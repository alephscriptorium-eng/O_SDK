#!/usr/bin/env bash
# identity-lock.sh — cerrojo de «identidad mudada» del cliente (CLIENT-PROTOCOL §7, D-O39).
#
# Si en el directorio de datos del cliente existe el fichero IDENTIDAD-MUDADA, la identidad de ese
# `secret` vive ahora en otro sitio: arrancar este cliente (o importarle otra identidad encima, o
# subirlo de versión) sería tener dos instancias vivas de la misma identidad, y eso bifurca el feed
# (AGENTES §3, RECOVERY §4). Los scripts del cliente lo comprueban antes de hacer nada; el bloqueo del
# `docker compose up` lo pone el override local descrito en el protocolo. El cerrojo se retira
# borrando el fichero, y solo cuando la mudanza esté resuelta (una sola instancia).
#
# Uso (desde un script, con el cwd en la raíz del repo):
#   . "$(dirname "${BASH_SOURCE[0]}")/lib/identity-lock.sh"; client_identity_lock_check [<dir de datos>]
# El directorio por defecto es volumes-dev/ssb-data (o $OASIS_CLIENT_DATA_DIR). Sale con código 78 si está bloqueado.
# Se puede saltar SOLO a sabiendas con OASIS_IDENTITY_LOCK_OVERRIDE=1 (queda en el log del script).

client_identity_lock_check() {
  local d="${1:-${OASIS_CLIENT_DATA_DIR:-volumes-dev/ssb-data}}"
  local f="$d/IDENTIDAD-MUDADA"
  [ -f "$f" ] || return 0
  if [ "${OASIS_IDENTITY_LOCK_OVERRIDE:-}" = "1" ]; then
    echo "AVISO: cerrojo de identidad mudada ($f) SALTADO por OASIS_IDENTITY_LOCK_OVERRIDE=1" >&2
    return 0
  fi
  {
    echo "BLOQUEADO: la identidad de este cliente se ha mudado (D-O39). No se arranca, no se importa, no se sube."
    echo "Cerrojo: $f"
    echo "------------------------------------------------------------------"
    cat "$f"
    echo "------------------------------------------------------------------"
    echo "Cómo se resuelve: docs/CLIENT-PROTOCOL.md §7 (una sola instancia viva; después se retira el fichero)."
  } >&2
  exit 78
}
