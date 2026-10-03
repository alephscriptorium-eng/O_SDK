# =============================================================================
# OASIS Docker - Dockerfile Limpio Integrado
# Versión unificada que integra todos los scripts nativos
# =============================================================================

# Oasis >= 1.2 declara Node >= 22 (src/server/package.json).
FROM node:22-bookworm-slim

# Qué pila de IA lleva la imagen (Oasis >= 1.2 la separa del núcleo, en src/AI):
#   none  sin IA: pub, HUB y bots (por defecto)
#   nav   solo embeddings (navegación inteligente)
#   full  embeddings + asistente (node-llama-cpp): el cliente
ARG OASIS_AI=none

# Instalar dependencias del sistema necesarias para SSB y node-llama-cpp
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    unzip \
    git \
    cmake \
    build-essential \
    python3 \
    python3-pip \
    nano \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario oasis
RUN groupadd -r oasis && useradd -r -g oasis -m oasis

# Configurar directorio de trabajo
WORKDIR /app

# Copiar código fuente completo
COPY --chown=oasis:oasis . .

# Asegurar directorios de runtime y permisos antes de cambiar al usuario oasis.
# Sin `chown -R /app`: COPY ya deja el dueño, y recorrer src/base (19 000 ficheros) duplicaría la capa.
RUN mkdir -p /app/logs /app/src/AI/models \
    && chown oasis:oasis /app /app/logs /app/src/AI /app/src/AI/models \
    && dos2unix docker-entrypoint.sh \
    && chmod +x docker-entrypoint.sh

# Cambiar al usuario oasis ANTES de instalar dependencias
USER oasis

# 🎯 Variables de entorno para node-llama-cpp
ENV NODE_LLAMA_CPP_SKIP_DOWNLOAD=false \
    NODE_LLAMA_CPP_USE_PREBUILT_BINARIES=true \
    NODE_LLAMA_CPP_BUILD_FROM_SOURCE=false

# Núcleo: Oasis >= 1.2 no instala nada. Sus dependencias vienen en src/base/node_modules y
# src/server/node_modules es un enlace a ellas (el código las requiere por esa ruta). El enlace se
# crea aquí porque no viaja en el contexto de build (.dockerignore; en Windows git lo materializa
# como un fichero de texto). NUNCA `npm install` en src/server: escribiría a través del enlace.
WORKDIR /app/src/server
RUN rm -rf node_modules \
    && ln -s ../base/node_modules node_modules \
    && node -e "for (const m of ['ssb-db2', 'secret-stack', 'sodium-native', 'leveldown', 'sharp', 'koa', 'bipf']) require(m); console.log('nucleo vendorizado: carga en node ' + process.version)"

# Pila de IA, solo si se pide. `npm ci` con scripts: node-llama-cpp, onnxruntime-node y sharp bajan
# sus binarios de Linux en la instalación. Después, los parches de upstream (el de xenova vive ahí).
WORKDIR /app/src/AI
RUN case "$OASIS_AI" in \
      none) echo "imagen sin pila de IA (OASIS_AI=none)" ;; \
      nav)  npm ci --omit=optional --no-audit --no-fund && node /app/scripts/patch-node-modules.js ;; \
      full) npm ci --no-audit --no-fund && node /app/scripts/patch-node-modules.js ;; \
      *)    echo "OASIS_AI debe ser none, nav o full (es: $OASIS_AI)" >&2; exit 1 ;; \
    esac

WORKDIR /app/src/server

# Volver a root en runtime para poder ajustar permisos de volúmenes montados
USER root

# Exponer puertos
EXPOSE 8008 3000

# Punto de entrada integrado
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["full"]
