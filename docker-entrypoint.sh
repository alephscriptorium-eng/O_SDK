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
# OJO: setup_ssb_config reasigna CONFIG_FILE (global) a ~/.ssb/config. Todo lo que
# toca oasis-config.json usa OASIS_CONFIG_FILE, que nadie reasigna.
OASIS_CONFIG_FILE="$CURRENT_DIR/src/configs/oasis-config.json"

if [ "$(id -u)" = "0" ] && [ "${OASIS_ENTRYPOINT_REEXEC:-0}" != "1" ]; then
    mkdir -p /home/oasis/.ssb "$MODEL_DIR" "$CURRENT_DIR/logs"
    chown oasis:oasis /home/oasis/.ssb "$MODEL_DIR" "$CURRENT_DIR/logs" 2>/dev/null || true
    chmod u+rwx /home/oasis/.ssb "$MODEL_DIR" "$CURRENT_DIR/logs" 2>/dev/null || true

    if [ -d /home/oasis/.ssb ]; then
        find /home/oasis/.ssb -mindepth 1 -maxdepth 1 ! -name config -exec chown -R oasis:oasis {} + 2>/dev/null || true
    fi

    # WP-O103: estado persistente del cliente (solo si OASIS_CLIENT_STATE_DIR está
    # definido y el modo no es server). Pub, HUB y wallet-bot no lo definen.
    if [ -n "${OASIS_CLIENT_STATE_DIR:-}" ] && [ "${1:-full}" != "server" ]; then
        mkdir -p "$OASIS_CLIENT_STATE_DIR" 2>/dev/null || true
        chown -R oasis:oasis "$OASIS_CLIENT_STATE_DIR" 2>/dev/null || true
        chmod u+rwx "$OASIS_CLIENT_STATE_DIR" 2>/dev/null || true
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
    
    # Patch 1: ssb-ref - Remover wrappers deprecados (parseAddress, parseInvite, etc.)
    SSB_REF_PATH="node_modules/ssb-ref/index.js"
    if [ -f "$SSB_REF_PATH" ]; then
        echo "  → Aplicando patch a ssb-ref..."
        node -e "
        const fs = require('fs');
        const p = '$SSB_REF_PATH';
        if (fs.existsSync(p)) {
            let d = fs.readFileSync(p, 'utf8');
            let changed = false;
            const rep = (re, s) => { const n = d.replace(re, s); if (n !== d) { d = n; changed = true; } };

            rep(/exports\.parseAddress\s*=\s*deprecate\(\s*['\"]\S*['\"],\s*parseAddress\s*\)/, 'exports.parseAddress = parseAddress');
            rep(/exports\.parseLegacyInvite\s*=\s*deprecate\(\s*['\"]\S*['\"],\s*parseLegacyInvite\s*\)/, 'exports.parseLegacyInvite = parseLegacyInvite');
            rep(/exports\.parseMultiServerInvite\s*=\s*deprecate\(\s*['\"]\S*['\"],\s*parseMultiServerInvite\s*\)/, 'exports.parseMultiServerInvite = parseMultiServerInvite');
            rep(/exports\.parseInvite\s*=\s*deprecate\(\s*['\"]\S*['\"]\s*,(\s*function\s*\(invite\)\s*\{[\s\S]*?\})\s*\)/, 'exports.parseInvite =\$1');
            rep(/exports\.toLegacyAddress\s*=\s*deprecate\(\s*['\"]\S*['\"],\s*toLegacyAddress\s*\)/, 'exports.toLegacyAddress = toLegacyAddress');

            if (changed) {
                fs.writeFileSync(p, d);
                console.log('    \u2713 ssb-ref patcheado exitosamente');
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
# WP-O103 · Estado persistente del cliente y cableado de la cartera ECOin
# -----------------------------------------------------------------------------
# Todo lo de este bloque está condicionado a OASIS_CLIENT_STATE_DIR definido y a
# un modo distinto de "server". Pub, HUB y wallet-bot no definen la variable (y
# montan oasis-config.json como bind :ro): para ellos nada de esto se ejecuta.
# =============================================================================

# Utilidades JS compartidas por los `node -e` de configuración. Va entre comillas
# simples de bash: el JS de este bloque NO puede contener comillas simples.
NODE_CFG_LIB='
const fs = require("fs");
const path = require("path");
const isObj = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
const readJson = (p) => JSON.parse(fs.readFileSync(p, "utf8"));
// Objetos: recursivo. Arrays y escalares: gana "over" (lo persistido).
const deepMerge = (base, over) => {
  if (!isObj(base) || !isObj(over)) return over === undefined ? base : over;
  const out = Object.assign({}, base);
  for (const k of Object.keys(over)) {
    if (k === "__proto__" || k === "constructor" || k === "prototype") continue;
    out[k] = Object.prototype.hasOwnProperty.call(base, k) ? deepMerge(base[k], over[k]) : over[k];
  }
  return out;
};
// Mismo formato que saveConfig de Oasis: 2 espacios, sin salto final.
const serialize = (obj) => JSON.stringify(obj, null, 2);
// Escritura atómica: temporal + rename en el directorio del fichero REAL (si el
// destino es un symlink se resuelve antes, así el symlink nunca se rompe). Si el
// rename no es posible (p. ej. fichero montado por bind) se escribe en el sitio.
// Lanza si el destino no es escribible: quien llama decide.
const writeJson = (target, obj) => {
  const data = serialize(obj);
  let real = target;
  try { real = fs.realpathSync(target); } catch (e) {}
  try { if (fs.readFileSync(real, "utf8") === data) return false; } catch (e) {}
  const tmp = path.join(path.dirname(real), "." + path.basename(real) + ".tmp-" + process.pid);
  try {
    fs.writeFileSync(tmp, data, { mode: 0o600 });
    fs.renameSync(tmp, real);
  } catch (e) {
    try { fs.unlinkSync(tmp); } catch (e2) {}
    fs.writeFileSync(real, data);
  }
  return true;
};
'

client_state_enabled() {
    [ -n "${OASIS_CLIENT_STATE_DIR:-}" ] && [ "$MODE" != "server" ]
}

# =============================================================================
# FUNCIÓN: Persistir el estado del cliente fuera de la capa efímera de la imagen
#   - oasis-config.json: default de la imagen + deep-merge de lo persistido
#     (gana lo persistido; las claves nuevas de upstream entran por el default),
#     escrito en $OASIS_CLIENT_STATE_DIR y enlazado desde src/configs.
#   - Estado bancario: desde Oasis 1.1.3 vive en ~/.ssb/oasis/banking (state-manager.js),
#     dentro del bind de ssb-data: ya persiste solo. NO se define OASIS_BANKING_DIR
#     (backend.js la ignora y banking_model.js no: habría dos mapas de direcciones) ni
#     se enlaza nada en src/configs (state-manager migraría el symlink). Si queda un
#     banking/ de 1.1.2 en el state dir, se copia UNA vez al sitio nuevo.
# Corre como usuario oasis (dueño de /app; el state dir lo prepara el bloque root).
# =============================================================================
persist_client_state() {
    local state_dir="$OASIS_CLIENT_STATE_DIR"
    unset OASIS_BANKING_DIR
    local state_cfg="$state_dir/oasis-config.json"
    local default_cfg="$CURRENT_DIR/src/configs/.oasis-config.image-default.json"
    local legacy_bank="$state_dir/banking"
    local new_bank="${SSB_PATH:-/home/oasis/.ssb}/oasis/banking"

    echo "Persistiendo estado del cliente en $state_dir ..."

    mkdir -p "$state_dir" 2>/dev/null || true
    if [ ! -d "$state_dir" ] || [ ! -w "$state_dir" ]; then
        echo "  ⚠ $state_dir no existe o no es escribible: el estado NO se persiste en este arranque"
        return 0
    fi

    # Contenedor nuevo: oasis-config.json es fichero regular = default de la imagen.
    # Se guarda una copia para poder rehacer el merge en reinicios del mismo contenedor.
    if [ -f "$OASIS_CONFIG_FILE" ] && [ ! -L "$OASIS_CONFIG_FILE" ]; then
        cp -f "$OASIS_CONFIG_FILE" "$default_cfg" 2>/dev/null || \
            echo "  ⚠ No se pudo guardar la copia del default de la imagen"
    fi

    if [ -f "$default_cfg" ]; then
        if CFG_DEFAULT="$default_cfg" CFG_STATE="$state_cfg" node -e "$NODE_CFG_LIB"'
            const def = readJson(process.env.CFG_DEFAULT);
            const state = process.env.CFG_STATE;
            let persisted = null;
            if (fs.existsSync(state)) {
              try {
                persisted = readJson(state);
                if (!isObj(persisted)) throw new Error("no es un objeto JSON");
              } catch (e) {
                const bad = state + ".corrupt-" + Date.now();
                fs.renameSync(state, bad);
                persisted = null;
                console.log("  ⚠ oasis-config.json persistido ilegible (" + e.message + "): apartado en " + bad);
              }
            }
            const merged = persisted ? deepMerge(def, persisted) : def;
            const wrote = writeJson(state, merged);
            console.log(persisted
              ? "  → oasis-config.json: default de la imagen + estado persistido" + (wrote ? "" : " (sin cambios)")
              : "  → oasis-config.json: sembrado desde el default de la imagen");
        '; then
            if [ "$(readlink "$OASIS_CONFIG_FILE" 2>/dev/null)" != "$state_cfg" ]; then
                ln -sfn "$state_cfg" "$OASIS_CONFIG_FILE" 2>/dev/null || \
                    echo "  ⚠ No se pudo enlazar $OASIS_CONFIG_FILE → $state_cfg (¿montado por bind?)"
            fi
            [ -L "$OASIS_CONFIG_FILE" ] && echo "    ✓ $OASIS_CONFIG_FILE → $state_cfg"
        else
            echo "  ⚠ Falló el merge de oasis-config.json: se mantiene la configuración actual"
        fi
    else
        echo "  ⚠ Sin default de la imagen para oasis-config.json: no se toca"
    fi

    # Estado bancario de un cliente 1.1.2 (state dir) → sitio de 1.1.4, una sola vez y sin pisar.
    if [ -s "$legacy_bank/wallet-addresses.json" ] && [ "$(tr -d ' 
' < "$legacy_bank/wallet-addresses.json")" != "{}" ]        && [ ! -e "$new_bank/wallet-addresses.json" ]; then
        mkdir -p "$new_bank" 2>/dev/null || true
        if cp -n "$legacy_bank"/*.json "$new_bank"/ 2>/dev/null; then
            echo "  → estado bancario de 1.1.2 copiado a $new_bank (el original se conserva en $legacy_bank)"
        else
            echo "  ⚠ No se pudo copiar $legacy_bank a $new_bank: NO abras /banking hasta resolverlo"
        fi
    fi
    [ -e "$new_bank/wallet-addresses.json" ] && echo "    ✓ mapa de direcciones: $new_bank/wallet-addresses.json"
    return 0
}

# =============================================================================
# FUNCIÓN: Cablear la cartera ECOin desde el entorno (el entorno manda)
#   ECOIN_RPC_URL definida (aunque vacía) → wallet.url/user/pass
#   OASIS_WALLET_FEE (opcional)           → wallet.fee
#   (el banco ya no se configura: desde 1.1.3 el cliente lo descubre por pubAvailability)
#   OASIS_WALLET_WIRING=manual            → no se toca nada
# Nunca imprime usuario ni contraseña.
# =============================================================================
wire_wallet_config() {
    echo "Cableando la cartera ECOin desde el entorno..."

    if [ "${OASIS_WALLET_WIRING:-}" = "manual" ]; then
        echo "  → OASIS_WALLET_WIRING=manual: no se toca wallet.* (manda /settings/wallet)"
        return 0
    fi
    if [ ! -f "$OASIS_CONFIG_FILE" ]; then
        echo "  ⚠ Archivo de configuración no encontrado: $OASIS_CONFIG_FILE"
        return 0
    fi

    OASIS_CFG="$OASIS_CONFIG_FILE" node -e "$NODE_CFG_LIB"'
        const env = process.env;
        const cfgPath = env.OASIS_CFG;
        let cfg;
        try {
          cfg = readJson(cfgPath);
          if (!isObj(cfg)) throw new Error("no es un objeto JSON");
        } catch (e) {
          console.log("  ⚠ No se pudo leer " + cfgPath + " (" + e.message + "): cartera sin cablear");
          process.exit(0);
        }
        if (!isObj(cfg.wallet)) cfg.wallet = {};
        if ("walletPub" in cfg) { delete cfg.walletPub; console.log("  → walletPub retirado (clave obsoleta desde Oasis 1.1.3)"); }

        const LOCAL_HOSTS = ["ecoin-wallet", "localhost", "127.0.0.1", "host.docker.internal"];
        const safeUrl = (u) => u.protocol + "//" + u.host + (u.pathname === "/" ? "" : u.pathname);

        if ("ECOIN_RPC_URL" in env) {
          const raw = String(env.ECOIN_RPC_URL).trim();
          let url = raw;
          let shown = "(vacía: cartera RPC desactivada, modo solo dirección)";
          if (raw) {
            let u = null;
            try { u = new URL(raw); } catch (e) {}
            if (!u || !/^https?:$/.test(u.protocol) || !u.hostname) {
              console.log("  ❌ ERROR: ECOIN_RPC_URL no es una URL http(s) válida → wallet.url = \"\"");
              url = "";
              shown = "(vacía: URL rechazada)";
            } else if (!LOCAL_HOSTS.includes(u.hostname.toLowerCase())) {
              if (env.ECOIN_RPC_ALLOW_REMOTE === "i-know") {
                console.log("  ⚠ AVISO: ecoind remoto (" + u.hostname + ") aceptado por ECOIN_RPC_ALLOW_REMOTE=i-know. El RPC viaja en HTTP plano.");
                shown = safeUrl(u);
              } else {
                console.log("  ❌ ERROR: ECOIN_RPC_URL apunta a un host remoto (" + u.hostname + "). El cliente solo habla con su propio ecoind");
                console.log("     (" + LOCAL_HOSTS.join(", ") + ") → wallet.url = \"\". Escape consciente: ECOIN_RPC_ALLOW_REMOTE=i-know");
                url = "";
                shown = "(vacía: URL remota rechazada)";
              }
            } else {
              shown = safeUrl(u);
            }
          }
          cfg.wallet.url = url;
          cfg.wallet.user = env.ECOIN_RPC_USER || "";
          cfg.wallet.pass = env.ECOIN_RPC_PASS || "";
          console.log("  → wallet.url: " + shown);
          console.log("  → user: " + (cfg.wallet.user ? "(configurado)" : "(vacío)"));
        } else {
          console.log("  → ECOIN_RPC_URL no definida: wallet.url/user/pass sin cambios");
        }

        const fee = String(env.OASIS_WALLET_FEE || "").trim();
        if (fee) {
          if (/^\d+(\.\d+)?$/.test(fee)) {
            cfg.wallet.fee = fee;
            console.log("  → wallet.fee: " + fee);
          } else {
            console.log("  ⚠ OASIS_WALLET_FEE no es un número: se ignora (wallet.fee sin cambios)");
          }
        }

        try {
          const wrote = writeJson(cfgPath, cfg);
          console.log(wrote ? "    ✓ configuración de cartera escrita" : "    ✓ configuración de cartera ya al día");
        } catch (e) {
          console.log("  ⚠ " + cfgPath + " no es escribible (" + e.code + "): cartera sin cablear");
        }
    ' || echo "  ⚠ Falló el cableado de la cartera (node): se continúa con la configuración actual"
    return 0
}

# =============================================================================
# FUNCIÓN: Configurar oasis según modelo IA (integración de oasis.sh)
# En node (no sed -i, que sustituiría un symlink por un fichero regular). Misma
# semántica: "off"→"on" si hay modelo, "on"→"off" si no lo hay; otro valor no se
# toca. Tolera un fichero no escribible (bind :ro) sin abortar el arranque.
# =============================================================================
setup_oasis_config() {
    echo "Configurando OASIS según disponibilidad del modelo IA..."

    if [ -f "$OASIS_CONFIG_FILE" ]; then
        local ai_target
        if [ -f "$MODEL_PATH" ] || [ -f "$LEGACY_MODEL_PATH" ]; then
            echo "  → Modelo IA encontrado, habilitando IA en configuración..."
            ai_target="on"
        else
            echo "  → Modelo IA no encontrado, deshabilitando IA en configuración..."
            ai_target="off"
        fi
        OASIS_CFG="$OASIS_CONFIG_FILE" AI_TARGET="$ai_target" node -e "$NODE_CFG_LIB"'
            const cfgPath = process.env.OASIS_CFG;
            const target = process.env.AI_TARGET;
            const from = target === "on" ? "off" : "on";
            try {
              const cfg = readJson(cfgPath);
              if (isObj(cfg) && isObj(cfg.modules) && cfg.modules.aiMod === from) {
                cfg.modules.aiMod = target;
                writeJson(cfgPath, cfg);
              }
              const now = isObj(cfg) && isObj(cfg.modules) ? cfg.modules.aiMod : undefined;
              const q = String.fromCharCode(39);
              console.log("    ✓ aiMod: " + q + now + q);
            } catch (e) {
              console.log("  ⚠ No se pudo ajustar aiMod en " + cfgPath + " (" + (e.code || e.message) + "): se deja como está");
            }
        ' || true
    else
        echo "  ⚠ Archivo de configuración no encontrado: $OASIS_CONFIG_FILE"
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
    )
    # Oasis 1.1.3+ muda gossip_unfollowed.json a oasis/peers/ (state-manager.js): vale en cualquiera de los dos sitios
    if [ ! -f "$SSB_PATH/gossip_unfollowed.json" ] && [ ! -f "$SSB_PATH/oasis/peers/gossip_unfollowed.json" ]; then
        required_files+=("$SSB_PATH/gossip_unfollowed.json")
    fi
    
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

# 4b. WP-O103: estado persistente del cliente y cableado de la cartera.
# Depende de OASIS_CLIENT_STATE_DIR y del modo, NO de OASIS_SKIP_AI_MODEL.
if client_state_enabled; then
    persist_client_state
    wire_wallet_config
fi

# 5. Configurar OASIS según modelo disponible
if [ "$SKIP_AI_MODEL" = "true" ] || [ "$MODE" = "server" ]; then
    echo "⏭ Saltando configuración IA del cliente para modo: $MODE"
else
    setup_oasis_config
fi

echo ""
echo "✅ OASIS configurado correctamente!"
echo ""

# Ensayo de configuración (tests/drill): termina aquí, sin arrancar SSB ni backend.
if [ "${OASIS_ENTRYPOINT_DRYRUN:-0}" = "1" ]; then
    echo "⏹ OASIS_ENTRYPOINT_DRYRUN=1: configuración aplicada; no se arranca Oasis."
    exit 0
fi

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