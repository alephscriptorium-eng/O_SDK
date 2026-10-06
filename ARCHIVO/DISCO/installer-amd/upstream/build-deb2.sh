#!/bin/bash
# scripts/build-deb2.sh
# Genera Oasis .deb con Node.js embebido
# NO ejecuta install.sh, NO toca ~/.ssb

set -e

PKG_NAME="oasis"
ARCH=$(dpkg --print-architecture)
SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(node -p "require('${SRC_DIR}/src/server/package.json').version")"
BUILD_DIR="/tmp/oasis-deb-build"
DEB_ROOT="${BUILD_DIR}/${PKG_NAME}_${VERSION}_${ARCH}"
INSTALL_DIR="/opt/oasis"
NODE_VERSION="22.20.0"
NODE_TARBALL="node-v${NODE_VERSION}-linux-x64.tar.xz"
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TARBALL}"

if [ "$1" = "--arm64" ]; then
    ARCH="arm64"
    DEB_ROOT="${BUILD_DIR}/${PKG_NAME}_${VERSION}_${ARCH}"
    NODE_TARBALL="node-v${NODE_VERSION}-linux-arm64.tar.xz"
    NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TARBALL}"
fi

echo "=== Building Oasis ${VERSION} .deb (${ARCH}) ==="

# Descargar Node.js si no está en /tmp
if [ ! -f "/tmp/${NODE_TARBALL}" ]; then
    echo "Downloading Node.js ${NODE_VERSION}..."
    wget -q --show-progress "${NODE_URL}" -O "/tmp/${NODE_TARBALL}"
fi

rm -rf "${DEB_ROOT}"
mkdir -p "${DEB_ROOT}/DEBIAN"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/src/server"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/src/backend"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/src/views"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/src/models"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/src/client"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/src/configs"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/src/games"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/src/maps"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/scripts"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/docs"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}/node"
mkdir -p "${DEB_ROOT}/usr/bin"
mkdir -p "${DEB_ROOT}/usr/share/applications"
mkdir -p "${DEB_ROOT}/usr/share/doc/${PKG_NAME}"
mkdir -p "${DEB_ROOT}/lib/systemd/system"

echo "Copying application files..."

# ============================================
# NODE.JS EMBEBIDO
# ============================================
tar -xf "/tmp/${NODE_TARBALL}" -C "${DEB_ROOT}${INSTALL_DIR}/node" --strip-components=1
echo "  ✓ Node.js ${NODE_VERSION} embedded"

# ============================================
# BASE (node_modules pre-instalados)
# ============================================
if [ -d "${SRC_DIR}/src/base" ]; then
    cp -r "${SRC_DIR}/src/base" "${DEB_ROOT}${INSTALL_DIR}/src/"
    echo "  ✓ src/base (con node_modules)"
fi

# ============================================
# SERVER (respetando symlink node_modules)
# ============================================
cp "${SRC_DIR}/src/server/package.json" "${DEB_ROOT}${INSTALL_DIR}/src/server/"
cp "${SRC_DIR}/src/server/package-lock.json" "${DEB_ROOT}${INSTALL_DIR}/src/server/" 2>/dev/null || true
cp "${SRC_DIR}/src/server/"*.js "${DEB_ROOT}${INSTALL_DIR}/src/server/" 2>/dev/null || true
cp "${SRC_DIR}/src/server/nodemon.json" "${DEB_ROOT}${INSTALL_DIR}/src/server/" 2>/dev/null || true

if [ -L "${SRC_DIR}/src/server/node_modules" ]; then
    ln -sf "../base/node_modules" "${DEB_ROOT}${INSTALL_DIR}/src/server/node_modules"
    echo "  ✓ src/server/node_modules (symlink)"
fi

# ============================================
# PACKAGES INTERNOS
# ============================================
if [ -d "${SRC_DIR}/src/server/packages" ]; then
    cp -r "${SRC_DIR}/src/server/packages" "${DEB_ROOT}${INSTALL_DIR}/src/server/"
    find "${DEB_ROOT}${INSTALL_DIR}/src/server/packages" -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
fi

# ============================================
# BACKEND / VIEWS / MODELS / CLIENT
# ============================================
cp "${SRC_DIR}/src/backend/"*.js "${DEB_ROOT}${INSTALL_DIR}/src/backend/" 2>/dev/null || true
cp -r "${SRC_DIR}/src/views/"*.js "${DEB_ROOT}${INSTALL_DIR}/src/views/" 2>/dev/null || true
cp -r "${SRC_DIR}/src/models/"*.js "${DEB_ROOT}${INSTALL_DIR}/src/models/" 2>/dev/null || true
cp -r "${SRC_DIR}/src/client" "${DEB_ROOT}${INSTALL_DIR}/src/"
find "${DEB_ROOT}${INSTALL_DIR}/src/client" -name "*.py" -delete 2>/dev/null || true
find "${DEB_ROOT}${INSTALL_DIR}/src/client" -name ".ruff_cache" -type d -exec rm -rf {} + 2>/dev/null || true

# ============================================
# CONFIGS
# ============================================
for f in oasis-config.json server-config.json snh-invite-code.json config-manager.js shared-state.js state-manager.js; do
    [ -f "${SRC_DIR}/src/configs/${f}" ] && cp "${SRC_DIR}/src/configs/${f}" "${DEB_ROOT}${INSTALL_DIR}/src/configs/"
done

# ============================================
# GAMES / MAPS
# ============================================
cp -r "${SRC_DIR}/src/games/." "${DEB_ROOT}${INSTALL_DIR}/src/games/" 2>/dev/null || true
cp -r "${SRC_DIR}/src/maps/." "${DEB_ROOT}${INSTALL_DIR}/src/maps/" 2>/dev/null || true

# ============================================
# SCRIPTS / DOCS / ROOT
# ============================================
cp -r "${SRC_DIR}/scripts" "${DEB_ROOT}${INSTALL_DIR}/"
if [ -d "${SRC_DIR}/docs/PUB" ]; then
    mkdir -p "${DEB_ROOT}${INSTALL_DIR}/docs/PUB"
    cp "${SRC_DIR}/docs/PUB/"* "${DEB_ROOT}${INSTALL_DIR}/docs/PUB/" 2>/dev/null || true
fi
cp "${SRC_DIR}/oasis.sh" "${DEB_ROOT}${INSTALL_DIR}/"
cp "${SRC_DIR}/LICENSE" "${DEB_ROOT}${INSTALL_DIR}/"
cp "${SRC_DIR}/README.md" "${DEB_ROOT}${INSTALL_DIR}/" 2>/dev/null || true

# ============================================
# DEBIAN/control (sin dependencia de nodejs)
# ============================================
cat > "${DEB_ROOT}/DEBIAN/control" << EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Architecture: ${ARCH}
Maintainer: SolarNET.HuB <solarnethub@riseup.net>
Depends: jq
Installed-Size: $(du -sk "${DEB_ROOT}${INSTALL_DIR}" | cut -f1)
Section: net
Priority: optional
Homepage: https://solarnethub.com
Description: Oasis P2P Social Network
 Oasis is a P2P encrypted social network built on Secure Scuttlebutt (SSB).
 Zero browser JavaScript — all rendering is server-side HTML+CSS.
 Includes embedded Node.js ${NODE_VERSION}.
 Part of the SolarNET.HuB ecosystem.
EOF

# ============================================
# DEBIAN/conffiles
# ============================================
cat > "${DEB_ROOT}/DEBIAN/conffiles" << 'CONFFILES'
/opt/oasis/src/configs/oasis-config.json
/opt/oasis/src/configs/server-config.json
/opt/oasis/src/configs/snh-invite-code.json
CONFFILES

# ============================================
# DEBIAN/postinst
# ============================================
cat > "${DEB_ROOT}/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e

INSTALL_DIR="/opt/oasis"
OASIS_HOME="/var/lib/oasis"
OASISRC="$OASIS_HOME/.oasisrc"

# Crear usuario oasis
if ! id -u oasis >/dev/null 2>&1; then
    useradd --system --home-dir "$OASIS_HOME" --create-home --shell /usr/sbin/nologin oasis
fi

# Permisos sobre la app
chown -R oasis:oasis "$INSTALL_DIR"

# Verificar symlink node_modules
if [ ! -e "${INSTALL_DIR}/src/server/node_modules" ]; then
    ln -s ../base/node_modules "${INSTALL_DIR}/src/server/node_modules"
    echo "Created node_modules symlink"
fi

# ============================================
# WIZARD
# ============================================
OASIS_PUB="no"
OASIS_DOMAIN=""

if [ -t 0 ]; then
    echo ""
    echo "========================================="
    echo "  Oasis - Setup"
    echo "========================================="
    echo ""
    printf "Is this a PUB (public server)? [y/N]: "
    read -r ANSWER

    case "$ANSWER" in
        [yY]|[yY][eE][sS])
            OASIS_PUB="yes"
            printf "Public domain (e.g. oasis.example.com): "
            read -r OASIS_DOMAIN
            OASIS_DOMAIN="${OASIS_DOMAIN:-localhost}"
            ;;
    esac
fi

# ============================================
# .oasisrc - SOLO CREAR SI NO EXISTE
# ============================================
if [ ! -f "$OASISRC" ]; then
    cat > "$OASISRC" << EOF
# Oasis configuration
# Edit this file and restart: sudo systemctl restart oasis

# ============================================
# BASIC SETTINGS
# ============================================
OASIS_PORT="3000"
OASIS_HOST="0.0.0.0"
OASIS_NO_OPEN="yes"
OASIS_DEBUG="no"

# ============================================
# MODE
# ============================================
# Set to "yes" for PUB (public server), "no" for client
OASIS_PUB="$OASIS_PUB"

# Only used if OASIS_PUB="yes"
OASIS_DOMAIN="$OASIS_DOMAIN"

# ============================================
# ARGUMENT BUILDER (no editar debajo)
# ============================================
if [ "\$OASIS_PUB" = "yes" ]; then
    OASIS_MODE="server"
    OASIS_ARGS="--public --allow-host=\$OASIS_DOMAIN"
else
    OASIS_MODE="gui"
    OASIS_ARGS=""
fi

OASIS_ARGS="--host=\$OASIS_HOST --port=\$OASIS_PORT \$OASIS_ARGS"
[ "\$OASIS_NO_OPEN" = "yes" ] && OASIS_ARGS="\$OASIS_ARGS --no-open"
[ "\$OASIS_DEBUG" = "yes" ]   && OASIS_ARGS="\$OASIS_ARGS --debug"
EOF
    chown oasis:oasis "$OASISRC"
    chmod 600 "$OASISRC"
    echo "Created $OASISRC"
else
    echo "$OASISRC already exists, preserving."
fi

systemctl daemon-reload 2>/dev/null || true

echo ""
echo "========================================="
echo "  Oasis ${VERSION} installed"
echo "========================================="
echo ""
echo "Mode:   $([ "$OASIS_PUB" = "yes" ] && echo "PUB ($OASIS_DOMAIN)" || echo "Client")"
echo "Config: $OASISRC"
echo ""
echo "Start:  sudo systemctl enable --now oasis"
echo "Logs:   journalctl -u oasis -f"
echo ""
echo "Open:   http://localhost:3000"
echo "========================================="
POSTINST
chmod 755 "${DEB_ROOT}/DEBIAN/postinst"

# ============================================
# DEBIAN/prerm
# ============================================
cat > "${DEB_ROOT}/DEBIAN/prerm" << 'PRERM'
#!/bin/bash
set -e
systemctl stop oasis 2>/dev/null || true
systemctl disable oasis 2>/dev/null || true
PRERM
chmod 755 "${DEB_ROOT}/DEBIAN/prerm"

# ============================================
# DEBIAN/postrm
# ============================================
cat > "${DEB_ROOT}/DEBIAN/postrm" << 'POSTRM'
#!/bin/bash
set -e
if [ "$1" = "purge" ]; then
    rm -rf /opt/oasis
    userdel oasis 2>/dev/null || true
    # /var/lib/oasis NO se toca (contiene .ssb con la identidad del usuario)
fi
systemctl daemon-reload 2>/dev/null || true
POSTRM
chmod 755 "${DEB_ROOT}/DEBIAN/postrm"

# ============================================
# SYSTEMD SERVICE (con PATH al Node embebido)
# ============================================
cat > "${DEB_ROOT}/lib/systemd/system/oasis.service" << EOF
[Unit]
Description=Oasis P2P Social Network
After=network.target

[Service]
Type=simple
User=oasis
Group=oasis
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=${INSTALL_DIR}/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/bin/sh ${INSTALL_DIR}/oasis.sh
Restart=on-failure
RestartSec=10
Environment=HOME=/var/lib/oasis
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# ============================================
# CLI LAUNCHER (también con PATH)
# ============================================
cat > "${DEB_ROOT}/usr/bin/oasis" << 'LAUNCHER'
#!/bin/sh
export PATH="/opt/oasis/node/bin:$PATH"
exec /bin/sh /opt/oasis/oasis.sh "$@"
LAUNCHER
chmod 755 "${DEB_ROOT}/usr/bin/oasis"

# ============================================
# DESKTOP ENTRY
# ============================================
cat > "${DEB_ROOT}/usr/share/applications/oasis.desktop" << EOF
[Desktop Entry]
Name=Oasis
GenericName=P2P Social Network
Exec=xdg-open http://localhost:3000
Icon=applications-internet
Terminal=false
Type=Application
Categories=Network;Chat;InstantMessaging;
EOF

# ============================================
# COPYRIGHT
# ============================================
cat > "${DEB_ROOT}/usr/share/doc/${PKG_NAME}/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Oasis
Source: https://code.03c8.net/KrakensLab/snh-oasis

Files: *
Copyright: 2022-2026 SolarNET.HuB / psy <epsylon@riseup.net>
License: AGPL-3.0

Files: opt/oasis/node/*
Copyright: Node.js contributors
License: MIT
EOF

# ============================================
# BUILD
# ============================================
echo "Building .deb package..."
DEB_FILE="${BUILD_DIR}/${PKG_NAME}_${VERSION}_${ARCH}.deb"
dpkg-deb --build --root-owner-group "${DEB_ROOT}" "${DEB_FILE}"

echo ""
echo "=== Package built: ${DEB_FILE} ==="
echo "Size: $(du -h "${DEB_FILE}" | cut -f1)"
echo ""
echo "Install: sudo dpkg -i ${DEB_FILE}"
echo "         sudo apt-get install -f"

