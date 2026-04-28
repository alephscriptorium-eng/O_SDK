# ECOin Docker handoff report

Fecha: 2026-04-28  
Ámbito: integración técnica de `ecoin-wallet` en el stack Docker de `alephscript-network-sdk`

## Resumen ejecutivo

Se completó la habilitación operativa de `ECOin` en Docker dentro de este repositorio.

Resultado actual verificado:

- `ecoin-wallet` **construye correctamente**
- `ecoin-wallet` **arranca correctamente**
- el contenedor queda **healthy**
- el RPC responde vía `getinfo`
- Oasis dispone ahora de **scripts npm específicos** para operar ECOin
- Oasis puede usar **defaults de wallet basados en variables de entorno Docker** en vez de quedarse fijado a `localhost` con credenciales vacías

## Problema inicial detectado

La integración ECOin existente estaba definida en `docker-compose.yml`, pero no estaba realmente lista para usarse de extremo a extremo.

### Estado previo

1. El servicio `ecoin-wallet` estaba definido en Compose, pero no había scripts npm dedicados para operarlo.
2. La configuración persistida de Oasis seguía con:
   - `wallet.url = http://localhost:7474`
   - `wallet.user = ""`
   - `wallet.pass = ""`
3. El `Dockerfile` de ECOin intentaba compilar desde fuente.
4. El build fallaba en:
   - `./bootstrap.sh: not found`
   - dentro de `src/boost_1_68_0`

### Causa raíz del fallo de build desde fuente

Tras revisar la documentación incluida en `src/client/public/docs/ecoin.md` y la estructura real del repositorio upstream de ECOin, se confirmó lo siguiente:

- la guía oficial para construir `ecoind` **no incluye** un paso explícito de `bootstrap.sh` para Boost
- el `makefile.linux` referencia:
  - `BOOST_DIR := $(CURDIR)/src/boost_1_68_0`
  - `BOOST_INCLUDE_PATH := $(BOOST_DIR)/include`
  - `BOOST_LIB_PATH := $(BOOST_DIR)/lib`
- el árbol de `boost_1_68_0` no contenía el `bootstrap.sh` esperado en la ruta asumida por el `Dockerfile`

Conclusión: el `Dockerfile` heredado estaba imponiendo un paso de compilación de Boost no alineado con el estado real del repositorio upstream.

## Decisión técnica adoptada

Se cambió la estrategia de construcción de ECOin:

- **antes**: compilación desde fuente dentro de Docker
- **ahora**: instalación desde **paquete precompilado AMD64** provisto por ECOin

### Motivo de la decisión

La decisión está respaldada por tres hechos verificados:

1. El README oficial de ECOin publica paquetes `.deb` precompilados.
2. El entorno Docker del usuario corre sobre:
   - `linux/amd64`
3. El paquete local `ECOIN_DOCKERIZE/ecoin_0.0.4-1_amd64.deb` contiene:
   - `ecoind`
   - `ecoin-cpuminer`
   - `ecoin-qt`
   - `bootstrap.dat`

Esto evitó mantener una toolchain C++ frágil dentro del build y redujo drásticamente el riesgo de roturas por diferencias en Boost/toolchain.

## Cambios realizados

### 1. Scripts npm añadidos

Archivo modificado:

- `package.json`

Se añadieron scripts específicos para ECOin:

- `ecoin:build`
- `ecoin:up`
- `ecoin:start`
- `ecoin:stop`
- `ecoin:restart`
- `ecoin:logs`
- `ecoin:status`
- `ecoin:shell`
- `ecoin:info`
- `ecoin:balance`
- `ecoin:address`

### 2. Defaults de wallet para Docker en Oasis

Archivo modificado:

- `src/configs/config-manager.js`

Se añadió lógica para que la config de wallet:

- tome valores por defecto desde `ECOIN_RPC_URL`, `ECOIN_RPC_USER`, `ECOIN_RPC_PASS`, `ECOIN_RPC_FEE`
- reemplace automáticamente el fallback `http://localhost:7474` por `ECOIN_RPC_URL` cuando se ejecuta en Docker
- rellene `user/pass` si la config persistida está vacía

Objetivo:

- evitar que Oasis quede apuntando a `localhost` dentro del contenedor cuando el peer correcto es `http://ecoin-wallet:7474`

### 3. Migración del Dockerfile de ECOin a prebuilt `.deb`

Archivo modificado:

- `ECOIN_DOCKERIZE/Dockerfile`

Cambios clave:

- se eliminó la compilación desde fuente
- se eliminó la dependencia del paso roto de Boost
- se pasó a:
  - copiar `ecoin_0.0.4-1_amd64.deb`
  - extraerlo con `dpkg-deb -x`
  - instalar `ecoind` en `/usr/local/bin/ecoind`
  - instalar opcionalmente `ecoin-cpuminer`
  - copiar `bootstrap.dat` a `/usr/share/ecoin/tools/bootstrap.dat`
- se añadieron librerías runtime necesarias para el binario precompilado, incluyendo Boost 1.74 de Debian 12

### 4. Bootstrap automático en primer arranque

Archivo modificado:

- `ECOIN_DOCKERIZE/docker-entrypoint.sh`

Se añadió lógica para:

- detectar primera ejecución
- copiar `bootstrap.dat` desde el paquete si el volumen aún no lo contiene

Objetivo:

- acelerar la sincronización inicial sin depender de descarga adicional en runtime

### 5. Normalización de finales de línea para Debian

Archivo modificado:

- `ECOIN_DOCKERIZE/Dockerfile`

Se añadió:

- `sed -i 's/\r$//' /home/ecoin/.ecoin/ecoin.conf`
- `sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh`

Motivo:

- el contenedor arrancaba en bucle con:
  - `exec /usr/local/bin/docker-entrypoint.sh: no such file or directory`
- la causa real era formato `CRLF` en archivos de texto copiados al contenedor Linux

### 6. Corrección de scripts RPC helper

Archivo modificado:

- `package.json`

Los helpers iniciales de RPC fallaban porque:

- `ecoind getinfo` no esperaba a que el RPC estuviera listo
- los wrappers con `sh -lc` daban problemas de quoting en Windows/Git Bash

Se simplificaron a invocaciones directas con:

- `-rpcwait`
- `-rpcconnect=127.0.0.1`
- credenciales explícitas

## Ficheros tocados

### Modificados

- `package.json`
- `src/configs/config-manager.js`
- `ECOIN_DOCKERIZE/Dockerfile`
- `ECOIN_DOCKERIZE/docker-entrypoint.sh`

### Añadido al flujo de build

- `ECOIN_DOCKERIZE/ecoin_0.0.4-1_amd64.deb`

Nota: este archivo fue aportado localmente y quedó integrado como artefacto de build para la imagen ECOin.

## Verificaciones realizadas

### Build de la imagen

Verificado:

- `npm run ecoin:build`

Resultado:

- imagen `alephscript-network-sdk-ecoin-wallet` construida con éxito

### Arranque del servicio

Verificado:

- `npm run ecoin:up`
- `npm run ecoin:status`

Resultado observado:

- `ecoin-wallet` en estado `Up ... (healthy)`
- puertos expuestos:
  - `7474` RPC
  - `12000` P2P publicado por Compose
  - `7408` P2P real de ECOin se observa en logs como puerto bind interno del daemon

### Respuesta RPC

Verificado:

- `npm run ecoin:info`

Resultado observado al cierre de esta sesión:

- versión: `v0.7.5.7-ga-beta`
- `blocks`: `8357`
- `connections`: `10`
- `errors`: `""`

### Logs de daemon

Se verificó en logs que:

- el daemon abre el directorio `/home/ecoin/.ecoin`
- el índice blockchain carga correctamente
- se detecta el bloque génesis ECOin
- la wallet se crea correctamente en primera ejecución

## Estado actual

Estado funcional al final de la intervención:

- `ecoin-wallet` está **operativo**
- el build Docker ya **no depende** de compilar Boost/C++ en la imagen
- los scripts npm de administración ECOin están listos
- la integración de defaults de wallet en Oasis ya está implementada

## Riesgos y observaciones para validación

### 1. El `.deb` es un artefacto binario versionado

Esto mejora mucho la estabilidad del build, pero implica:

- revisar política del repo respecto a binarios versionados
- confirmar si el binario debe mantenerse en Git o descargarse desde release en CI

### 2. Dependencias del paquete

El `.deb` oficial incluye también `ecoin-qt`, pero en la imagen solo se está aprovechando:

- `ecoind`
- opcionalmente `ecoin-cpuminer`
- `bootstrap.dat`

No se instalaron dependencias Qt porque no son necesarias para el daemon en servidor.

### 3. Configuración de wallet en Oasis

La lógica actual ya mejora mucho el caso Docker, pero conviene que el agente validador confirme si desea además:

- persistir explícitamente `http://ecoin-wallet:7474` en `src/configs/oasis-config.json`
- o mantener el enfoque actual basado en defaults por entorno

### 4. Puerto P2P

En logs el daemon enlaza en `7408`, mientras que el `docker-compose.yml` expone `12000:12000` para ECOin.

Esto **no se corrigió en esta intervención** porque el servicio ya sincroniza y tiene conexiones, pero conviene revisar si:

- ECOin realmente necesita publicar `7408`
- o si hay una reconfiguración explícita en `ecoin.conf` que justifique `12000`

Este punto merece validación específica antes de cerrar la integración como definitiva.

## Recomendaciones para el siguiente agente

### Validación mínima recomendada

1. revisar si el puerto P2P expuesto en `docker-compose.yml` debe pasar a `7408:7408`
2. verificar desde Oasis UI si la sección Wallet ya opera correctamente con la config efectiva
3. comprobar si `banking`/`wallet` en Oasis leen bien `http://ecoin-wallet:7474`
4. decidir si el `.deb` debe permanecer versionado en repo o sustituirse por descarga reproducible en build

### Posibles mejoras posteriores

- añadir script `ecoin:logs:tail` o `ecoin:peers`
- añadir `depends_on` opcional desde `oasis-dev` hacia `ecoin-wallet`
- persistir configuración wallet más explícita para entornos Docker
- documentar el flujo completo en README o en `SESION-BACKLOG-EXPANSION.md`

## Criterio de cierre de esta intervención

Esta tarea puede considerarse técnicamente resuelta en lo siguiente:

- ECOin ya no está en estado "infra definida pero no arrancable"
- ECOin ahora está **construido, arrancado, healthy y respondiendo por RPC**
- el repositorio dispone de artefactos y scripts suficientes para que otro agente continúe validación e integración con Oasis
