# =============================================================================
# ECOin P2P Cryptocurrency Wallet - Dockerfile
# =============================================================================
# Descripción: Instala ecoind (daemon) desde paquete .deb precompilado
# Basado en: https://ecoin.03c8.net / https://github.com/epsylon/ecoin
# =============================================================================

FROM debian:bookworm-slim

LABEL maintainer="alephscript"
LABEL description="ECOin P2P Cryptocurrency Wallet Daemon"
LABEL version="0.3"
LABEL org.opencontainers.image.source="https://github.com/epsylon/ecoin"

# =============================================================================
# STAGE 1: Runtime dependencies
# =============================================================================

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias mínimas para ecoind precompilado
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Runtime base
    ca-certificates \
    curl \
    procps \
    # Boost runtime (ecoin_amd64.deb enlaza contra 1.74 en Debian 12)
    libboost-chrono1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-program-options1.74.0 \
    libboost-system1.74.0 \
    libboost-thread1.74.0 \
    # OpenSSL runtime
    libssl-dev \
    libssl3 \
    # Berkeley DB runtime
    libdb5.3-dev \
    libdb5.3++-dev \
    libdb5.3++ \
    # Toolchain runtime
    libgcc-s1 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# STAGE 2: Install ECOin prebuilt package contents
# =============================================================================

# Copiar paquete .deb local al contexto de build
COPY ecoin_0.0.4-1_amd64.deb /tmp/ecoin_0.0.4-1_amd64.deb

RUN mkdir -p /tmp/ecoin-pkg /usr/share/ecoin/tools \
    && dpkg-deb -x /tmp/ecoin_0.0.4-1_amd64.deb /tmp/ecoin-pkg \
    && install -m 0755 /tmp/ecoin-pkg/usr/bin/ecoind /usr/local/bin/ecoind \
    && if [ -f /tmp/ecoin-pkg/usr/bin/ecoin-cpuminer ]; then install -m 0755 /tmp/ecoin-pkg/usr/bin/ecoin-cpuminer /usr/local/bin/ecoin-cpuminer; fi \
    && if [ -f /tmp/ecoin-pkg/usr/share/ecoin/tools/bootstrap.dat ]; then cp /tmp/ecoin-pkg/usr/share/ecoin/tools/bootstrap.dat /usr/share/ecoin/tools/bootstrap.dat; fi \
    && rm -rf /tmp/ecoin-pkg /tmp/ecoin_0.0.4-1_amd64.deb

# Verificar que el binario existe
RUN ecoind --version || echo "Prebuilt ecoind installed"

# =============================================================================
# STAGE 3: Setup runtime environment
# =============================================================================

# Crear usuario no-root para seguridad
RUN useradd -m -s /bin/bash -u 1000 ecoin

# Crear directorio de datos
RUN mkdir -p /home/ecoin/.ecoin \
    && chown -R ecoin:ecoin /home/ecoin

# Copiar configuración base
COPY --chown=ecoin:ecoin ecoin.conf /home/ecoin/.ecoin/ecoin.conf
RUN sed -i 's/\r$//' /home/ecoin/.ecoin/ecoin.conf

# Copiar bootstrap.dat si existe (acelera sync inicial)
# COPY --chown=ecoin:ecoin bootstrap.dat /home/ecoin/.ecoin/bootstrap.dat

# Copiar script de entrypoint
COPY --chown=ecoin:ecoin docker-entrypoint.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# =============================================================================
# STAGE 4: Runtime configuration
# =============================================================================

# Cambiar a usuario ecoin (no root)
USER ecoin
WORKDIR /home/ecoin

# Puertos:
# - 7474: JSON-RPC (comunicación con Oasis)
# - 12000: P2P ECOin network
EXPOSE 7474 12000

# Volumen para persistencia de datos
VOLUME ["/home/ecoin/.ecoin"]

# Health check - verifica que el daemon responde
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -sf --user "${RPC_USER:-ecoinrpc}:${RPC_PASS:-ecoinrpc}" \
        --data-binary '{"jsonrpc":"1.0","id":"health","method":"getinfo","params":[]}' \
        -H 'content-type: text/plain;' \
        http://127.0.0.1:7474/ || exit 1

# Entrypoint para configuración dinámica
ENTRYPOINT ["docker-entrypoint.sh"]

# Comando por defecto: ejecutar daemon en foreground
CMD ["ecoind", "-printtoconsole", "-logtimestamps"]
