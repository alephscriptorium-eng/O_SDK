#!/bin/bash
# scripts/build-deb2.sh
# Genera Oasis .deb con Node.js embebido
# NO ejecuta install.sh, NO toca ~/.ssb
#
# Propuesta installer-amd (2026-10-06) sobre el script original. Cambios, marcados con [Fn]:
#   [F1][F4] .oasisrc solo KEY="VALUE"; lo lee /opt/oasis/oasis-run, que es lo que arranca el servicio
#   [F2]     dpkg-deb -Zxz (zstd no se instala en Debian 11 / Ubuntu <= 21.04)
#   [F3]     /usr/bin/oasis hace cd /opt/oasis antes de lanzar oasis.sh
#   [F6]     el asistente admite OASIS_PUB / OASIS_DOMAIN por entorno cuando no hay tty, y no pregunta en upgrades
#   [F7]     Depends con libc6/libstdc++6/libgcc-s1, Recommends xdg-utils, DEBIAN/md5sums
#   [F9]     /opt/oasis es de root; el usuario de servicio solo escribe en src/configs y src/server
#   [F10]    poda de node/ (include, npm, corepack, share) y Version con revisión Debian (1.2.2-1)
#   [F13]    con PUB=yes en la primera instalación se copia docs/PUB/server-config.json.example (pub: true)

set -e

PKG_NAME="oasis"
ARCH=$(dpkg --print-architecture)
SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(node -p "require('${SRC_DIR}/src/server/package.json').version")"
DEB_REVISION="${DEB_REVISION:-1}"                      # [F10]
PKG_VERSION="${VERSION}-${DEB_REVISION}"               # [F10]
BUILD_DIR="/tmp/oasis-deb-build"
DEB_ROOT="${BUILD_DIR}/${PKG_NAME}_${PKG_VERSION}_${ARCH}"
INSTALL_DIR="/opt/oasis"
NODE_VERSION="22.20.0"
NODE_TARBALL="node-v${NODE_VERSION}-linux-x64.tar.xz"
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TARBALL}"

if [ "$1" = "--arm64" ]; then
    ARCH="arm64"
    DEB_ROOT="${BUILD_DIR}/${PKG_NAME}_${PKG_VERSION}_${ARCH}"
    NODE_TARBALL="node-v${NODE_VERSION}-linux-arm64.tar.xz"
    NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TARBALL}"
fi

echo "=== Building Oasis ${PKG_VERSION} .deb (${ARCH}) ==="

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
# [F10] en producción solo hace falta el binario y su lib: fuera cabeceras, npm, corepack y docs
rm -rf "${DEB_ROOT}${INSTALL_DIR}/node/include" \
       "${DEB_ROOT}${INSTALL_DIR}/node/share" \
       "${DEB_ROOT}${INSTALL_DIR}/node/lib/node_modules/npm" \
       "${DEB_ROOT}${INSTALL_DIR}/node/lib/node_modules/corepack" \
       "${DEB_ROOT}${INSTALL_DIR}/node/bin/npm" \
       "${DEB_ROOT}${INSTALL_DIR}/node/bin/npx" \
       "${DEB_ROOT}${INSTALL_DIR}/node/bin/corepack" \
       "${DEB_ROOT}${INSTALL_DIR}/node/CHANGELOG.md"
echo "  ✓ Node.js ${NODE_VERSION} embedded (runtime only)"

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
# SERVICE RUNNER  [F1][F4]
# Lee /var/lib/oasis/.oasisrc (solo KEY="VALUE") y arranca oasis.sh con las flags que ya acepta.
# Es lo que ejecuta la unidad systemd; oasis.sh queda intacto.
# ============================================
cat > "${DEB_ROOT}${INSTALL_DIR}/oasis-run" << 'RUNNER'
#!/bin/sh
# Oasis service runner: reads /var/lib/oasis/.oasisrc and starts oasis.sh accordingly.
OASIS_HOME="${OASIS_HOME:-/var/lib/oasis}"
RC="$OASIS_HOME/.oasisrc"
[ -f "$RC" ] && . "$RC"

MODE="gui"
[ "${OASIS_PUB:-no}" = "yes" ] && MODE="server"

# A flag given twice becomes an array for the backend and the listener crashes
# ("hostname must be of type string"). oasis.sh server already passes
# --public --no-open --host=0.0.0.0, so in that mode only add what it does not set.
ARGS="--port=${OASIS_PORT:-3000}"
if [ "$MODE" = "server" ]; then
    [ -n "${OASIS_DOMAIN:-}" ] && ARGS="$ARGS --allow-host=$OASIS_DOMAIN"
else
    ARGS="$ARGS --host=${OASIS_HOST:-127.0.0.1}"
    [ "${OASIS_NO_OPEN:-yes}" = "yes" ] && ARGS="$ARGS --no-open"
fi
[ "${OASIS_DEBUG:-no}" = "yes" ] && ARGS="$ARGS --debug"

export HOME="$OASIS_HOME"
export PATH="/opt/oasis/node/bin:$PATH"
cd /opt/oasis || exit 1
exec /bin/sh /opt/oasis/oasis.sh "$MODE" $ARGS
RUNNER
chmod 755 "${DEB_ROOT}${INSTALL_DIR}/oasis-run"

# ============================================
# DEBIAN/control (sin dependencia de nodejs)
# [F7] el Node embebido y sharp piden glibc >= 2.28 y libstdc++; xdg-utils solo para abrir el navegador
# ============================================
cat > "${DEB_ROOT}/DEBIAN/control" << EOF
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Architecture: ${ARCH}
Maintainer: SolarNET.HuB <solarnethub@riseup.net>
Depends: jq, libc6 (>= 2.28), libstdc++6, libgcc-s1
Recommends: xdg-utils
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
chown oasis:oasis "$OASIS_HOME"
chmod 750 "$OASIS_HOME"

# [F9] La app es de root. El usuario de servicio solo escribe donde la app escribe:
#      src/configs (oasis.sh edita oasis-config.json) y src/server (.update_required)
chown -R oasis:oasis "${INSTALL_DIR}/src/configs" "${INSTALL_DIR}/src/server"

# Verificar symlink node_modules
if [ ! -e "${INSTALL_DIR}/src/server/node_modules" ]; then
    ln -s ../base/node_modules "${INSTALL_DIR}/src/server/node_modules"
    echo "Created node_modules symlink"
fi

# ============================================
# WIZARD  [F6] solo en la primera instalación; con tty pregunta, sin tty lee el entorno
# ============================================
OASIS_PUB="${OASIS_PUB:-}"
OASIS_DOMAIN="${OASIS_DOMAIN:-}"

if [ ! -f "$OASISRC" ]; then
    if [ -z "$OASIS_PUB" ] && [ -t 0 ]; then
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
                ;;
        esac
    fi
    case "$OASIS_PUB" in
        [yY]|[yY][eE][sS]) OASIS_PUB="yes"; OASIS_DOMAIN="${OASIS_DOMAIN:-localhost}" ;;
        *)                 OASIS_PUB="no";  OASIS_DOMAIN="" ;;
    esac

    # [F13] Un PUB necesita la forma de PUB en server-config.json (pub: true). Solo en la primera
    #       instalación: después es un conffile que dpkg respeta.
    if [ "$OASIS_PUB" = "yes" ] && [ -z "$2" ] && [ -f "${INSTALL_DIR}/docs/PUB/server-config.json.example" ]; then
        cp "${INSTALL_DIR}/docs/PUB/server-config.json.example" "${INSTALL_DIR}/src/configs/server-config.json"
        chown oasis:oasis "${INSTALL_DIR}/src/configs/server-config.json"
        echo "server-config.json: PUB profile (pub: true)"
    fi

    # Un cliente escucha solo en loopback; la GUI no tiene autenticación. Un PUB escucha en todas.
    if [ "$OASIS_PUB" = "yes" ]; then OASIS_HOST="0.0.0.0"; else OASIS_HOST="127.0.0.1"; fi

    # [F1] Solo KEY="VALUE": lo lee /opt/oasis/oasis-run. Nada de lógica aquí.
    cat > "$OASISRC" << EOF
# Oasis configuration — read by /opt/oasis/oasis-run (systemd service).
# Edit this file and restart: sudo systemctl restart oasis
# Only KEY="VALUE" lines; no shell logic.

# "yes" for a PUB (public server), "no" for a client
OASIS_PUB="$OASIS_PUB"

# Only used if OASIS_PUB="yes": public hostname behind the reverse proxy
OASIS_DOMAIN="$OASIS_DOMAIN"

# Interface of the web UI for a client (127.0.0.1 keeps it private). A PUB always listens on 0.0.0.0.
OASIS_HOST="$OASIS_HOST"
OASIS_PORT="3000"

# "yes": never try to open a browser (a service has none)
OASIS_NO_OPEN="yes"
# "yes": verbose logging
OASIS_DEBUG="no"
EOF
    chown oasis:oasis "$OASISRC"
    chmod 600 "$OASISRC"
    echo "Created $OASISRC"
else
    echo "$OASISRC already exists, preserving."
    OASIS_PUB="$(sed -n 's/^OASIS_PUB="\(.*\)"/\1/p' "$OASISRC" | head -1)"
    OASIS_DOMAIN="$(sed -n 's/^OASIS_DOMAIN="\(.*\)"/\1/p' "$OASISRC" | head -1)"
fi

systemctl daemon-reload 2>/dev/null || true

echo ""
echo "========================================="
echo "  Oasis installed"
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
# SYSTEMD SERVICE  [F1][F4] arranca el runner, que aplica .oasisrc
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
Environment=HOME=/var/lib/oasis
Environment=NODE_ENV=production
ExecStart=${INSTALL_DIR}/oasis-run
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# ============================================
# CLI LAUNCHER  [F3] oasis.sh usa \$(pwd): hay que entrar en /opt/oasis
# ============================================
cat > "${DEB_ROOT}/usr/bin/oasis" << 'LAUNCHER'
#!/bin/sh
export PATH="/opt/oasis/node/bin:$PATH"
cd /opt/oasis || exit 1
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
# DEBIAN/md5sums  [F7] para que dpkg -V pueda verificar la instalación
# ============================================
(cd "${DEB_ROOT}" && find . -type f ! -path './DEBIAN/*' -exec md5sum {} + | sed 's| \./| |' > DEBIAN/md5sums)
chmod 644 "${DEB_ROOT}/DEBIAN/md5sums"

# ============================================
# BUILD  [F2] xz: lo leen todos los dpkg; zstd solo desde dpkg 1.21.18 (Debian 12)
# ============================================
echo "Building .deb package..."
DEB_FILE="${BUILD_DIR}/${PKG_NAME}_${PKG_VERSION}_${ARCH}.deb"
dpkg-deb -Zxz --build --root-owner-group "${DEB_ROOT}" "${DEB_FILE}"

echo ""
echo "=== Package built: ${DEB_FILE} ==="
echo "Size: $(du -h "${DEB_FILE}" | cut -f1)"
echo ""
echo "Install: sudo dpkg -i ${DEB_FILE}"
echo "         sudo apt-get install -f"
