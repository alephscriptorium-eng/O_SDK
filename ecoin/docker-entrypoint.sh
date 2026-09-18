#!/bin/bash
# =============================================================================
# ECOin Docker Entrypoint
# =============================================================================
# Configura el entorno antes de iniciar ecoind
# =============================================================================

set -e

# Todo lo que cree este script (conf, wallet.dat vía ecoind) nace privado.
umask 077

ECOIN_DIR="/home/ecoin/.ecoin"
ECOIN_CONF="${ECOIN_DIR}/ecoin.conf"
PACKAGE_BOOTSTRAP="/usr/share/ecoin/tools/bootstrap.dat"
DEFAULT_CONF="/usr/share/ecoin/ecoin.conf.default"

echo "============================================="
echo "   ECOin Wallet Docker Container"
echo "   https://ecoin.03c8.net"
echo "============================================="
echo ""

# -----------------------------------------------------------------------------
# Verificar/crear directorio de datos
# -----------------------------------------------------------------------------
if [ ! -d "${ECOIN_DIR}" ]; then
    echo "📁 Creando directorio de datos..."
    mkdir -p "${ECOIN_DIR}"
fi

# -----------------------------------------------------------------------------
# Fail-closed de credenciales (WP-O102)
# -----------------------------------------------------------------------------
# Con ECOIN_REQUIRE_CREDS=1 el contenedor NO arranca si RPC_USER/RPC_PASS faltan
# o valen un valor conocido (el antiguo por defecto o los marcadores de la conf).
# Sin esa variable el comportamiento es el de siempre, pero se avisa por stderr.
is_weak_cred() {
    case "$1" in
        ""|ecoinrpc|CHANGE_ME_VIA_RPC_USER|CHANGE_ME_VIA_RPC_PASS) return 0 ;;
        *) return 1 ;;
    esac
}

if [ "${ECOIN_REQUIRE_CREDS:-0}" = "1" ]; then
    if is_weak_cred "${RPC_USER:-}" || is_weak_cred "${RPC_PASS:-}"; then
        echo "❌ ECOIN_REQUIRE_CREDS=1: RPC_USER y RPC_PASS son obligatorias y no pueden estar vacías" >&2
        echo "   ni valer 'ecoinrpc' (valor público por defecto). Genera cada una con:" >&2
        echo "   openssl rand -hex 32   — y pásalas por entorno (.env fuera de git). No se arranca ecoind." >&2
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# Verificar configuración
# -----------------------------------------------------------------------------
if [ ! -f "${ECOIN_CONF}" ]; then
    if [ -f "${DEFAULT_CONF}" ]; then
        echo "⚠️  ecoin.conf no encontrado, sembrando la configuración completa por defecto..."
        cp "${DEFAULT_CONF}" "${ECOIN_CONF}"
    else
        echo "⚠️  ecoin.conf no encontrado y falta ${DEFAULT_CONF}; creando configuración mínima..."
        cat > "${ECOIN_CONF}" << 'CONF'
rpcuser=CHANGE_ME_VIA_RPC_USER
rpcpassword=CHANGE_ME_VIA_RPC_PASS
rpcport=7474
rpcallowip=127.0.0.1
rpcallowip=172.16.*
rpcallowip=172.17.*
rpcallowip=172.18.*
rpcallowip=172.19.*
rpcallowip=172.20.*
rpcallowip=172.21.*
rpcallowip=172.22.*
rpcallowip=172.23.*
rpcallowip=172.24.*
rpcallowip=172.25.*
rpcallowip=172.26.*
rpcallowip=172.27.*
rpcallowip=172.28.*
rpcallowip=172.29.*
rpcallowip=172.30.*
rpcallowip=172.31.*
rpcallowip=192.168.*
server=1
daemon=0
listen=1
port=7408
noirc=1
addnode=46.163.118.220
addnode=82.223.99.61
addnode=ecoin0.vps.webdock.cloud
logtimestamps=1
CONF
    fi
fi

# La conf lleva la contraseña RPC: solo el dueño.
chmod 600 "${ECOIN_CONF}"

# -----------------------------------------------------------------------------
# Aplicar variables de entorno si existen
# -----------------------------------------------------------------------------
# set_conf clave valor — sustituye la línea `clave=` (tenga marcador o un valor
# previo) o la añade si no existe. El valor se escapa para sed (\, & y el
# delimitador |); las credenciales recomendadas son hex y no lo necesitan.
set_conf() {
    local key="$1" val="$2" esc
    esc="$(printf '%s' "${val}" | sed -e 's/[\\&|]/\\&/g')"
    if grep -q "^${key}=" "${ECOIN_CONF}"; then
        sed -i "s|^${key}=.*|${key}=${esc}|" "${ECOIN_CONF}"
    else
        printf '%s=%s\n' "${key}" "${val}" >> "${ECOIN_CONF}"
    fi
}

if [ -n "${RPC_USER}" ]; then
    echo "🔧 Configurando RPC_USER desde variable de entorno..."
    set_conf rpcuser "${RPC_USER}"
fi

if [ -n "${RPC_PASS}" ]; then
    echo "🔧 Configurando RPC_PASS desde variable de entorno..."
    set_conf rpcpassword "${RPC_PASS}"
fi

if [ -n "${RPC_PORT}" ]; then
    echo "🔧 Configurando RPC_PORT desde variable de entorno..."
    set_conf rpcport "${RPC_PORT}"
fi

chmod 600 "${ECOIN_CONF}"

# Aviso (no bloqueante sin ECOIN_REQUIRE_CREDS): credenciales efectivas conocidas.
EFF_USER="$(sed -n 's/^rpcuser=//p' "${ECOIN_CONF}" | tail -n 1)"
EFF_PASS="$(sed -n 's/^rpcpassword=//p' "${ECOIN_CONF}" | tail -n 1)"
if is_weak_cred "${EFF_USER}" || is_weak_cred "${EFF_PASS}"; then
    echo "⚠️  AVISO: el RPC de ecoind usa credenciales por defecto/públicas (ecoinrpc o marcador)." >&2
    echo "   Válido solo para desarrollo local sin puertos publicados. Define RPC_USER/RPC_PASS" >&2
    echo "   (openssl rand -hex 32) y ECOIN_REQUIRE_CREDS=1 para exigirlo." >&2
fi
unset EFF_PASS

# -----------------------------------------------------------------------------
# Verificar wallet.dat
# -----------------------------------------------------------------------------
if [ -f "${ECOIN_DIR}/wallet.dat" ]; then
    echo "💰 wallet.dat encontrado - usando wallet existente"
else
    echo "🆕 wallet.dat no existe - se creará automáticamente al iniciar"
fi

# -----------------------------------------------------------------------------
# Verificar blockchain data
# -----------------------------------------------------------------------------
# Esta build (v0.7.5.7) guarda la cadena en blk0001.dat + txleveldb/, NO en blkindex.dat, y
# tras importar bootstrap.dat lo renombra a bootstrap.dat.old. Mirar solo blkindex.dat hacía
# que se recopiara y reimportara en CADA arranque (~1600 líneas «already have block» en el log).
if [ -f "${ECOIN_DIR}/blkindex.dat" ] || [ -f "${ECOIN_DIR}/blk0001.dat" ] || [ -d "${ECOIN_DIR}/txleveldb" ]; then
    echo "⛓️  Blockchain data encontrada"
else
    echo "⛓️  Primera ejecución - sincronización inicial puede tardar"
    if [ ! -f "${ECOIN_DIR}/bootstrap.dat" ] && [ ! -f "${ECOIN_DIR}/bootstrap.dat.old" ] && [ -f "${PACKAGE_BOOTSTRAP}" ]; then
        echo "📦 Copiando bootstrap.dat incluido en el paquete ECOin..."
        cp "${PACKAGE_BOOTSTRAP}" "${ECOIN_DIR}/bootstrap.dat"
    fi
    if [ -f "${ECOIN_DIR}/bootstrap.dat" ]; then
        echo "📦 bootstrap.dat encontrado - acelerará sincronización"
    fi
fi

# -----------------------------------------------------------------------------
# Mostrar configuración
# -----------------------------------------------------------------------------
echo ""
echo "📋 Configuración actual:"
echo "   • RPC Port: $(grep -oP 'rpcport=\K.*' ${ECOIN_CONF} || echo '7474')"
# El usuario RPC es media credencial: no se imprime (los logs van al json de Docker).
echo "   • RPC User: (configurado; no se muestra)"
echo "   • Data Dir: ${ECOIN_DIR}"
echo ""

# -----------------------------------------------------------------------------
# Ejecutar comando
# -----------------------------------------------------------------------------
echo "🚀 Iniciando ECOin daemon..."
echo ""

exec "$@"
