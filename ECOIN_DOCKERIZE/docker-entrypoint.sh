#!/bin/bash
# =============================================================================
# ECOin Docker Entrypoint
# =============================================================================
# Configura el entorno antes de iniciar ecoind
# =============================================================================

set -e

ECOIN_DIR="/home/ecoin/.ecoin"
ECOIN_CONF="${ECOIN_DIR}/ecoin.conf"
PACKAGE_BOOTSTRAP="/usr/share/ecoin/tools/bootstrap.dat"

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
# Verificar configuración
# -----------------------------------------------------------------------------
if [ ! -f "${ECOIN_CONF}" ]; then
    echo "⚠️  ecoin.conf no encontrado, creando configuración por defecto..."
    cat > "${ECOIN_CONF}" << 'EOF'
rpcuser=ecoinrpc
rpcpassword=ecoinrpc
rpcport=7474
rpcallowip=127.0.0.1
rpcallowip=172.16.0.0/12
server=1
daemon=0
listen=1
noirc=1
addnode=46.163.118.220
addnode=82.223.99.61
addnode=ecoin0.vps.webdock.cloud
logtimestamps=1
EOF
fi

# -----------------------------------------------------------------------------
# Aplicar variables de entorno si existen
# -----------------------------------------------------------------------------
if [ -n "${RPC_USER}" ]; then
    echo "🔧 Configurando RPC_USER desde variable de entorno..."
    sed -i "s/^rpcuser=.*/rpcuser=${RPC_USER}/" "${ECOIN_CONF}"
fi

if [ -n "${RPC_PASS}" ]; then
    echo "🔧 Configurando RPC_PASS desde variable de entorno..."
    sed -i "s/^rpcpassword=.*/rpcpassword=${RPC_PASS}/" "${ECOIN_CONF}"
fi

if [ -n "${RPC_PORT}" ]; then
    echo "🔧 Configurando RPC_PORT desde variable de entorno..."
    sed -i "s/^rpcport=.*/rpcport=${RPC_PORT}/" "${ECOIN_CONF}"
fi

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
if [ -f "${ECOIN_DIR}/blkindex.dat" ]; then
    echo "⛓️  Blockchain data encontrada"
else
    echo "⛓️  Primera ejecución - sincronización inicial puede tardar"
    if [ ! -f "${ECOIN_DIR}/bootstrap.dat" ] && [ -f "${PACKAGE_BOOTSTRAP}" ]; then
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
echo "   • RPC User: $(grep -oP 'rpcuser=\K.*' ${ECOIN_CONF} || echo 'ecoinrpc')"
echo "   • Data Dir: ${ECOIN_DIR}"
echo ""

# -----------------------------------------------------------------------------
# Ejecutar comando
# -----------------------------------------------------------------------------
echo "🚀 Iniciando ECOin daemon..."
echo ""

exec "$@"
