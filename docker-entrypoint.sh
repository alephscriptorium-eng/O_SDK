#!/bin/bash
set -e

# =============================================================================
# OASIS Docker Entrypoint - Versión Limpia Integrada
# Integra toda la lógica de los scripts nativos: oasis.sh, install.sh, 
# patch-node-modules.js y generate_shs.js
# =============================================================================

CURRENT_DIR="/app"
MODEL_DIR="$CURRENT_DIR/src/AI/models"
MODEL_FILE="oasis-42-1-chat.Q4_K_M.gguf"
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"
LEGACY_MODEL_PATH="$CURRENT_DIR/src/AI/$MODEL_FILE"
CONFIG_FILE="$CURRENT_DIR/src/configs/oasis-config.json"

if [ "$(id -u)" = "0" ] && [ "${OASIS_ENTRYPOINT_REEXEC:-0}" != "1" ]; then
    mkdir -p /home/oasis/.ssb "$MODEL_DIR" "$CURRENT_DIR/logs"
    chown oasis:oasis /home/oasis/.ssb "$MODEL_DIR" "$CURRENT_DIR/logs" 2>/dev/null || true
    chmod u+rwx /home/oasis/.ssb "$MODEL_DIR" "$CURRENT_DIR/logs" 2>/dev/null || true

    if [ -d /home/oasis/.ssb ]; then
        find /home/oasis/.ssb -mindepth 1 -maxdepth 1 ! -name config -exec chown -R oasis:oasis {} + 2>/dev/null || true
    fi

    REEXEC_ARGS=$(printf '%q ' "$@")
    exec su -m -s /bin/bash oasis -c "OASIS_ENTRYPOINT_REEXEC=1 $CURRENT_DIR/docker-entrypoint.sh ${REEXEC_ARGS}"
fi

# Configurar directorios necesarios
mkdir -p "$MODEL_DIR"
mkdir -p "$CURRENT_DIR/logs"

# =============================================================================
# FUNCIÓN: Generar clave SHS (integración de generate_shs.js)
# =============================================================================
generate_shs_key() {
    node -e "
    const crypto = require('crypto');
    const cap = crypto.randomBytes(32).toString('base64');
    console.log(cap);
    "
}

# =============================================================================
# FUNCIÓN: Configurar SSB con clave SHS dinámica
# =============================================================================
setup_ssb_config() {
    CONFIG_FILE="/home/oasis/.ssb/config"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Creando configuración SSB inicial..."
        SHS_CAP=$(generate_shs_key)
        
        cat > "$CONFIG_FILE" << EOF
{
  "logging": {
    "level": "info"
  },
  "caps": {
    "shs": "$SHS_CAP"
  },
  "connections": {
    "incoming": {
      "net": [
        {
          "port": 8008,
          "host": "0.0.0.0",
          "scope": "public",
          "transform": "shs"
        }
      ],
      "unix": []
    }
  },
  "blobs": {
    "max": 52428800
  },
  "path": "/home/oasis/.ssb"
}
EOF
        echo "Configuración SSB creada con nueva clave SHS"
    else
        echo "Configuración SSB ya existe"
    fi
}

# =============================================================================
# FUNCIÓN: Aplicar parches de node_modules (integración de patch-node-modules.js)
# =============================================================================
apply_node_patches() {
    echo "Aplicando parches críticos a node_modules..."
    cd "$CURRENT_DIR/src/server"
    
    # Patch 1: ssb-ref - Remover uso deprecado de parseAddress
    SSB_REF_PATH="node_modules/ssb-ref/index.js"
    if [ -f "$SSB_REF_PATH" ]; then
        echo "  → Aplicando patch a ssb-ref..."
        node -e "
        const fs = require('fs');
        const path = '$SSB_REF_PATH';
        if (fs.existsSync(path)) {
            const data = fs.readFileSync(path, 'utf8');
            const patched = data.replace(
                /exports\.parseAddress\s*=\s*deprecate\([^)]*\)/,
                'exports.parseAddress = parseAddress'
            );
            if (patched !== data) {
                fs.writeFileSync(path, patched);
                console.log('    ✓ ssb-ref patcheado exitosamente');
            } else {
                console.log('    - ssb-ref no necesita patch');
            }
        }
        "
    fi
    
    # Patch 2: ssb-blobs - Arreglar manejo de wantCallbacks
    SSB_BLOBS_PATH="node_modules/ssb-blobs/inject.js"
    if [ -f "$SSB_BLOBS_PATH" ]; then
        echo "  → Aplicando patch a ssb-blobs..."
        node -e "
        const fs = require('fs');
        const path = '$SSB_BLOBS_PATH';
        if (fs.existsSync(path)) {
            let data = fs.readFileSync(path, 'utf8');
            const marker = 'want: function (id, cb)';
            const startIndex = data.indexOf(marker);
            if (startIndex !== -1) {
                const endIndex = data.indexOf('},', startIndex);
                if (endIndex !== -1) {
                    const before = data.slice(0, startIndex);
                    const after = data.slice(endIndex + 2);
                    const replacement = \`
  want: function (id, cb) {
    id = toBlobId(id);
    if (!isBlobId(id)) return cb(new Error('invalid id:' + id));

    if (blobStore.isEmptyHash(id)) return cb(null, true);

    if (wantCallbacks[id]) {
      if (!Array.isArray(wantCallbacks[id])) wantCallbacks[id] = [];
      wantCallbacks[id].push(cb);
    } else {
      wantCallbacks[id] = [cb];
      blobStore.size(id, function (err, size) {
        if (err) return cb(err);
        if (size != null) {
          while (wantCallbacks[id].length) {
            const fn = wantCallbacks[id].shift();
            if (typeof fn === 'function') fn(null, true);
          }
          delete wantCallbacks[id];
        }
      });
    }

    const peerId = findPeerWithBlob(id);
    if (peerId) get(peerId, id);

    if (wantCallbacks[id]) registerWant(id);
  },\`;
                    const finalData = before + replacement + after;
                    fs.writeFileSync(path, finalData);
                    console.log('    ✓ ssb-blobs patcheado exitosamente');
                } else {
                    console.log('    - ssb-blobs: no se encontró el final de la función want');
                }
            } else {
                console.log('    - ssb-blobs: no se encontró la función want');
            }
        }
        "
    fi
    
    # Patch 3: multiserver unix-socket - Evitar error ENOENT en chmod socket
    UNIX_SOCKET_PATH="node_modules/multiserver/plugins/unix-socket.js"
    if [ -f "$UNIX_SOCKET_PATH" ]; then
        echo "  → Aplicando patch a multiserver unix-socket..."
        node -e "
        const fs = require('fs');
        const path = '$UNIX_SOCKET_PATH';
        if (fs.existsSync(path)) {
            let data = fs.readFileSync(path, 'utf8');
            
            // Buscar la línea problemática fs.chmodSync
            const originalChmod = 'fs.chmodSync(socket, mode)';
            const patchedChmod = 'try { fs.chmodSync(socket, mode); } catch(e) { if (e.code !== \"ENOENT\") throw e; }';
            
            if (data.includes(originalChmod)) {
                data = data.replace(originalChmod, patchedChmod);
                fs.writeFileSync(path, data);
                console.log('    ✓ multiserver unix-socket patcheado exitosamente');
            } else {
                console.log('    - multiserver unix-socket: no necesita patch (patrón no encontrado)');
            }
        }
        "
    fi
    
    echo "Parches aplicados."
}

# =============================================================================
# FUNCIÓN: Descargar modelo IA (integración de install.sh)
# =============================================================================
download_ai_model() {
    MODEL_TAR="$MODEL_FILE.tar.gz"
    MODEL_URL="https://solarnethub.com/code/models/$MODEL_TAR"

    if [ ! -f "$MODEL_PATH" ]; then
        echo "=============================="
        echo "|| Descargando modelo IA... ||"
        echo "=============================="
        echo "Tamaño: 3.8 GiB (4.081.004.224 bytes)"
        echo "URL: $MODEL_URL"
        echo ""
        
        curl -L -o "$MODEL_DIR/$MODEL_TAR" "$MODEL_URL" || {
            echo "❌ Error descargando modelo IA. Continuando sin modelo..."
            return 1
        }
        
        echo ""
        echo "Extrayendo package: $MODEL_TAR..."
        echo ""
        tar -xzf "$MODEL_DIR/$MODEL_TAR" -C "$MODEL_DIR" --no-same-owner --no-same-permissions 2>/dev/null || {
            echo "Error extrayendo con permisos. Intentando extracción simple..."
            tar -xzf "$MODEL_DIR/$MODEL_TAR" -C "$MODEL_DIR" 2>/dev/null || {
                echo "❌ Error extrayendo modelo. Eliminando archivo corrupto..."
                rm -f "$MODEL_DIR/$MODEL_TAR"
                return 1
            }
        }
        
        rm -f "$MODEL_DIR/$MODEL_TAR"
        echo "✅ Modelo IA descargado y extraído correctamente"
    else
        echo "✅ Modelo IA ya existe: $MODEL_PATH"
    fi
}

link_ai_model() {
    if [ -f "$MODEL_PATH" ]; then
        ln -sf "$MODEL_PATH" "$LEGACY_MODEL_PATH"
        echo "✅ Modelo IA enlazado para compatibilidad: $LEGACY_MODEL_PATH"
    elif [ -L "$LEGACY_MODEL_PATH" ]; then
        rm -f "$LEGACY_MODEL_PATH"
    fi
}

# =============================================================================
# FUNCIÓN: Configurar oasis según modelo IA (integración de oasis.sh)
# =============================================================================
setup_oasis_config() {
    echo "Configurando OASIS según disponibilidad del modelo IA..."
    
    if [ -f "$CONFIG_FILE" ]; then
        if [ -f "$MODEL_PATH" ] || [ -f "$LEGACY_MODEL_PATH" ]; then
            echo "  → Modelo IA encontrado, habilitando IA en configuración..."
            sed -i.bak 's/"aiMod": *"off"/"aiMod": "on"/' "$CONFIG_FILE" 2>/dev/null || true
            echo "    ✓ aiMod: 'on'"
        else
            echo "  → Modelo IA no encontrado, deshabilitando IA en configuración..."
            sed -i.bak 's/"aiMod": *"on"/"aiMod": "off"/' "$CONFIG_FILE" 2>/dev/null || true
            echo "    ✓ aiMod: 'off'"
        fi
        rm -f "$CONFIG_FILE.bak" 2>/dev/null || true
    else
        echo "  ⚠ Archivo de configuración no encontrado: $CONFIG_FILE"
    fi
}

# =============================================================================
# FUNCIÓN: Instalar dependencias críticas de runtime
# =============================================================================
install_runtime_deps() {
    echo "Verificando dependencias críticas..."
    cd "$CURRENT_DIR/src/server"
    
    # Instalar dependencias faltantes sin usar npm install completo
    MISSING_DEPS=""
    [ ! -d "node_modules/module-alias" ] && MISSING_DEPS="$MISSING_DEPS module-alias"
    [ ! -d "node_modules/env-paths" ] && MISSING_DEPS="$MISSING_DEPS env-paths"
    
    if [ -n "$MISSING_DEPS" ]; then
        echo "Instalando dependencias faltantes:$MISSING_DEPS"
        npm install --no-save --no-bin-links --prefer-offline $MISSING_DEPS 2>/dev/null || \
        echo "⚠ Advertencia: Algunas dependencias no se pudieron instalar"
    fi
    
    # Intentar instalar node-llama-cpp solo si el modelo existe
    if [ -f "$MODEL_PATH" ] && [ ! -d "node_modules/node-llama-cpp" ]; then
        echo "Instalando node-llama-cpp para soporte de IA..."
        npm install --no-save --no-bin-links --prefer-offline node-llama-cpp@latest 2>/dev/null || \
        echo "⚠ node-llama-cpp no se pudo instalar, la IA podría no funcionar"
    fi
}

# =============================================================================
# FUNCIÓN: Verificar y recuperar base de datos SSB
# =============================================================================
check_and_recover_ssb() {
    echo "🔍 Verificando integridad de la base de datos SSB..."
    
    SSB_PATH="/home/oasis/.ssb"
    RECOVERY_NEEDED=false
    
    # Lista de directorios LevelDB críticos para verificar
    local leveldb_dirs=(
        "$SSB_PATH/db"
        "$SSB_PATH/blobs_push"
        "$SSB_PATH/flume"
        "$SSB_PATH/flume/search"
    )
    
    # Función auxiliar para verificar integridad de LevelDB
    check_leveldb_integrity() {
        local db_path="$1"
        local db_name="$2"
        
        if [ -d "$db_path" ]; then
            # Verificar si existe archivo CURRENT
            if [ -f "$db_path/CURRENT" ]; then
                # Verificar si el archivo CURRENT termina con newline
                if [ -n "$(tail -c1 "$db_path/CURRENT" 2>/dev/null)" ]; then
                    echo "  ⚠ $db_name: CURRENT no termina con newline - corrigiendo..."
                    echo "" >> "$db_path/CURRENT"
                fi
                
                # Verificar si el archivo MANIFEST referenciado existe
                local manifest_file=$(cat "$db_path/CURRENT" 2>/dev/null | head -1)
                if [ -n "$manifest_file" ] && [ ! -f "$db_path/$manifest_file" ]; then
                    echo "  ❌ $db_name: Archivo MANIFEST $manifest_file no encontrado"
                    return 1
                fi
            fi
            
            # Verificar archivos .ldb corruptos o incompletos
            local ldb_files=$(find "$db_path" -name "*.ldb" -size 0 2>/dev/null || true)
            if [ -n "$ldb_files" ]; then
                echo "  ❌ $db_name: Archivos .ldb corruptos encontrados"
                return 1
            fi
        fi
        
        return 0
    }
    
    # Verificar cada directorio LevelDB
    for db_dir in "${leveldb_dirs[@]}"; do
        db_name=$(basename "$db_dir")
        if [ "$db_name" = "flume" ] && [ "$db_dir" != "$SSB_PATH/flume/search" ]; then
            db_name="flume-main"
        elif [ "$(dirname "$db_dir")" = "$SSB_PATH/flume" ]; then
            db_name="flume-search"
        fi
        
        if ! check_leveldb_integrity "$db_dir" "$db_name"; then
            echo "  🔧 Marcando $db_name para recuperación..."
            RECOVERY_NEEDED=true
        else
            echo "  ✅ $db_name: Base de datos íntegra"
        fi
    done
    
    # Verificar directorios básicos
    local required_dirs=(
        "$SSB_PATH"
        "$SSB_PATH/blobs"
        "$SSB_PATH/blobs_push"
        "$SSB_PATH/db"
        "$SSB_PATH/flume"
        "$SSB_PATH/node_modules"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            echo "  📁 Directorio faltante: $dir"
            RECOVERY_NEEDED=true
        fi
    done
    
    # Verificar archivos JSON básicos
    local required_files=(
        "$SSB_PATH/conn.json"
        "$SSB_PATH/gossip.json"
        "$SSB_PATH/gossip_unfollowed.json"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "  📄 Archivo faltante: $file"
            RECOVERY_NEEDED=true
        fi
    done
    
    # Verificar y manejar socket Unix
    if [ -S "$SSB_PATH/socket" ]; then
        # Si existe pero no es accesible, marcarlo para limpieza
        if ! [ -r "$SSB_PATH/socket" ] || ! [ -w "$SSB_PATH/socket" ]; then
            echo "  ⚠ Socket Unix inaccesible - marcado para limpieza"
            RECOVERY_NEEDED=true
        fi
    fi
    
    # Ejecutar recuperación si es necesaria
    if [ "$RECOVERY_NEEDED" = true ]; then
        echo "✅ Base de datos SSB no inicializada!"
    else
        echo "✅ Base de datos SSB verificada - no se requiere recuperación"
        
        # Aún así, limpiar sockets problemáticos
        if [ -S "$SSB_PATH/socket" ] && ! [ -r "$SSB_PATH/socket" ]; then
            echo "🧹 Limpiando socket Unix inaccesible..."
            rm -f "$SSB_PATH/socket"
        fi
    fi
}

# =============================================================================
# EJECUTAR SECUENCIA DE CONFIGURACIÓN INTEGRADA
# =============================================================================
echo "==============================="
echo "|| OASIS Dockerized AS v1.0 ||"
echo "==============================="

MODE="${1:-full}"
SKIP_AI_MODEL="${OASIS_SKIP_AI_MODEL:-false}"

# Configurar permisos (intentar sin fallar) - saltar si ya somos usuario oasis
echo "📋 Verificando estructura de directorios..."
ls -la /home/oasis/
echo ""
echo "📋 Verificando directorio SSB:"
ls -la /home/oasis/.ssb/ 2>/dev/null || echo "⚠ Directorio SSB no existe aún"
echo ""
echo "📋 Verificando modelo AI:"
ls -la "$MODEL_DIR/" 2>/dev/null || echo "⚠ Directorio de modelos no existe aún" 
echo ""
echo "📋 Verificando permisos de usuario actual:"
whoami
id
echo ""

# Como se ejecuta como usuario oasis, estos no son necesarios
echo "⚠ Ejecutando como usuario oasis - saltando cambios de permisos"

# Verificar que el modelo existe antes de continuar
echo "🔍 Verificando modelo AI como usuario oasis..."
if [ -f "$MODEL_PATH" ]; then
    echo "✅ Modelo accesible en $MODEL_DIR/"
else
    echo "❌ Modelo no encontrado en $MODEL_DIR/"
fi

# 1. Verificar e inicializar estructura SSB (con recuperación si es necesario)
# check_and_recover_ssb

# 2. Configurar SSB
setup_ssb_config

# 3. Descargar modelo IA si es necesario
if [ "$SKIP_AI_MODEL" = "true" ] || [ "$MODE" = "server" ]; then
    echo "⏭ Saltando descarga de modelo IA para modo: $MODE"
else
    download_ai_model
fi

# 3b. Enlazar modelo IA al path esperado por Oasis AI sin volver a descargarlo
if [ "$SKIP_AI_MODEL" = "true" ] || [ "$MODE" = "server" ]; then
    echo "⏭ Saltando enlace de modelo IA para modo: $MODE"
else
    link_ai_model
fi

# 3. Instalar dependencias críticas
install_runtime_deps

# 4. Aplicar parches críticos
apply_node_patches

# 5. Configurar OASIS según modelo disponible
if [ "$SKIP_AI_MODEL" = "true" ] || [ "$MODE" = "server" ]; then
    echo "⏭ Saltando configuración IA del cliente para modo: $MODE"
else
    setup_oasis_config
fi

echo ""
echo "✅ OASIS configurado correctamente!"
echo ""

# =============================================================================
# LÓGICA DE EJECUCIÓN (integración de oasis.sh)
# =============================================================================

# Configurar variables de entorno finales para evitar conflictos de paths
export HOME=/home/oasis
export SSB_PATH=/home/oasis/.ssb
echo "🏠 HOME establecido como: $HOME"
echo "🔑 SSB_PATH establecido como: $SSB_PATH"

# Asegurar que no hay conflictos de rutas SSB
if [ -d "/root/.ssb" ]; then
    echo "⚠ Detectado directorio /root/.ssb - relocalizando a /home/oasis/.ssb"
    cp -r /root/.ssb/* /home/oasis/.ssb/ 2>/dev/null || true
    rm -rf /root/.ssb 2>/dev/null || true
fi

case "$MODE" in
    "server")
        echo "🚀 Iniciando solo servidor SSB..."
        cd "$CURRENT_DIR/src/server"
        exec node SSB_server.js start
        ;;
    "client"|"backend")
        echo "🚀 Iniciando solo cliente web..."
        cd "$CURRENT_DIR/src/backend"
        exec node backend.js --host 0.0.0.0
        ;;
    "full"|*)
        echo "🚀 Iniciando servidor completo (SSB + Cliente + AI)..."
        
        # Iniciar servicio AI standalone en background si el modelo existe
        # if [ -f "$MODEL_PATH" ]; then
        #    echo "🤖 Iniciando servicio AI Standalone en puerto 4001..."
        #     cd "$CURRENT_DIR/src/AI"
        #     node ai_service_standalone.mjs &
        #     AI_PID=$!
        #     echo "   → AI Standalone PID: $AI_PID"
        #     sleep 2  # Dar tiempo para que arranque
        # else
        #     echo "⚠ Modelo AI no encontrado - servicio AI deshabilitado"
        # fi
        
        # Iniciar backend.js que incluye tanto SSB como cliente web
        cd "$CURRENT_DIR/src/backend"
        exec node backend.js --host 0.0.0.0
        ;;
esac