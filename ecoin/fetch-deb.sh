#!/usr/bin/env bash
# =============================================================================
# fetch-deb.sh — descarga verificada del paquete ECOin (WP-O102)
# =============================================================================
# El .deb NO se versiona (gitignored). Este script lo trae de la URL declarada en
# ecoin_0.0.4-1_amd64.deb.txt y lo contrasta con el hash versionado en
# ecoin_0.0.4-1_amd64.deb.sha256. Idempotente: si el fichero ya existe y el hash
# casa, no descarga. Si el hash falla, borra el fichero y sale 1.
# Funciona en Git Bash (Windows) y en Linux.
#
# Uso:  bash ecoin/fetch-deb.sh
# =============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEB="ecoin_0.0.4-1_amd64.deb"
URL_FILE="${DEB}.txt"
SUM_FILE="${DEB}.sha256"

cd "${HERE}"

for f in "${URL_FILE}" "${SUM_FILE}"; do
    if [ ! -f "${f}" ]; then
        echo "fetch-deb: falta ${HERE}/${f}" >&2
        exit 1
    fi
done

for bin in curl sha256sum; do
    if ! command -v "${bin}" >/dev/null 2>&1; then
        echo "fetch-deb: falta la herramienta '${bin}'" >&2
        exit 1
    fi
done

# El .sha256 puede llegar con CRLF en un checkout de Windows: se verifica contra
# una copia normalizada por stdin (sha256sum -c no tolera el \r en el nombre).
check_hash() {
    tr -d '\r' < "${SUM_FILE}" | sha256sum -c - >/dev/null 2>&1
}

if [ -f "${DEB}" ]; then
    if check_hash; then
        echo "fetch-deb: ${DEB} ya está y el hash casa; no se descarga."
        exit 0
    fi
    echo "fetch-deb: ${DEB} existe pero el hash NO casa; se borra y se vuelve a descargar." >&2
    rm -f "${DEB}"
fi

URL="$(tr -d '\r\n[:space:]' < "${URL_FILE}")"
case "${URL}" in
    https://*) ;;
    *)
        echo "fetch-deb: URL no válida en ${URL_FILE} (se exige https://): '${URL}'" >&2
        exit 1
        ;;
esac

echo "fetch-deb: descargando ${URL}"
TMP="${DEB}.part"
rm -f "${TMP}"
if ! curl -fL --retry 3 --connect-timeout 20 -o "${TMP}" "${URL}"; then
    rm -f "${TMP}"
    echo "fetch-deb: la descarga ha fallado." >&2
    exit 1
fi
mv -f "${TMP}" "${DEB}"

if check_hash; then
    echo "fetch-deb: ${DEB} descargado y verificado (sha256 OK)."
    exit 0
fi

echo "fetch-deb: el hash de lo descargado NO casa con ${SUM_FILE}; se borra el fichero." >&2
rm -f "${DEB}"
exit 1
