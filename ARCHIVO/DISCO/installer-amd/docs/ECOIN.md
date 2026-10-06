# ECOin y el instalador: cómo encajaría

Pregunta de partida: *¿el instalador podría dar las claves de ECOin y configurar el pub?* Respuesta
corta: **las claves no, la configuración sí, y el pub solo hasta la puerta del motor**. Es un diseño,
no un ensayo: nada de esto se ha probado en el banco (ver «Qué quedaría por ensayar»).

## Lo que hay hoy en el paquete

El `.deb` 1.2.2 no toca ECOin. `src/configs/oasis-config.json` viaja con
`"wallet": { "url": "http://localhost:7474", "user": "", "pass": "", "fee": "5" }` y
`walletMod: "on"`. Oasis lee ese bloque, y solo ese bloque, para hablar con `ecoind` por JSON-RPC
(`getbalance`, `getnewaddress`, `listtransactions`, `sendtoaddress`…). Las credenciales se rellenan
desde Settings → Wallet, que solo admite peticiones desde loopback. Un PUB además enciende por sí
solo el motor de renta básica (RBU/UBI) cuando se dan dos condiciones a la vez: `server-config.json`
con `"pub": true` y un RPC de ECOin que responde en `wallet.url` (`docs/PUB/deploy.md` §19 del
propio paquete: *«There is no switch»*).

## Qué puede y qué no puede hacer un paquete

| | Por qué |
|---|---|
| **No** incluir `wallet.dat` ni credenciales RPC | Son material de claves. Un paquete es público, se copia y se cachea; una cartera que viaja dentro ya no es de nadie. Además, dos instalaciones compartirían la misma cartera. |
| **No** abrir la GUI con la cartera cableada en el `postinst` | Desde Oasis 1.1.4, abrir la GUI con `wallet.*` relleno publica un mensaje `wallet` en el feed. Es irreversible (SSB no borra). Eso lo decide el habitante, no el instalador. |
| **No** encender el motor de RBU del pub | Publicar `pubAvailability` y abrir la época del mes es irreversible y compromete fondos. Pide una decisión explícita del operador con la cartera ya respaldada. |
| **Sí** generar las credenciales RPC en el destino | Es lo que hace cualquier cliente de ECOin: `openssl rand -hex` en el `postinst`, a `0600`, nunca por la línea de comandos ni en logs. |
| **Sí** escribirlas en `ecoin.conf` y en `wallet.*` | Las dos puntas se ponen de acuerdo sin que el usuario copie nada a mano. |
| **Sí** dejar `ecoind` como servicio aparte, parado o arrancado | `ecoind` crea `wallet.dat` en su primer arranque. Eso ya es «nacer en el destino». |

## Forma propuesta

Dos paquetes, no uno:

1. **`ecoin`** (`ecoin_0.0.4-1_amd64.deb` existe upstream en
   `github.com/epsylon/ecoin/releases`; depende de Boost 1.74, libssl3 y libdb5.3++, que Debian 12 trae).
   Debería aportar: usuario de sistema `ecoin`, `ecoind` y `ecoin-cpuminer` en `/usr/bin`, datadir
   `/var/lib/ecoin/.ecoin` a `0700`, una unidad `ecoin.service` y un `ecoin.conf` plantilla con
   `rpcport=7474`, `port=7408`, `rpcallowip=127.0.0.1` y **sin** credenciales. Su `postinst` genera
   `rpcuser`/`rpcpassword` si no existen y los escribe a `0600`.
2. **`oasis`** con `Suggests: ecoin` (no `Depends`: un cliente puede vivir solo con la dirección de
   otro) y un subcomando `oasis ecoin-init` (o un paso opcional del asistente: *«Connect a local
   ECOin wallet? [y/N]»*) que:
   - comprueba que `ecoin` está instalado y que `/var/lib/ecoin/.ecoin/ecoin.conf` tiene credenciales;
   - las lee como root y las escribe en `wallet.{url,user,pass}` de **la copia de configuración del
     usuario de servicio**, no en el conffile de `/opt/oasis` (ver abajo);
   - añade el usuario `oasis` al grupo `ecoin` si hace falta para leer el conf, o, mejor, copia los
     dos valores y no da acceso al fichero;
   - **no** arranca la GUI y termina con el aviso: *make a backup of `/var/lib/ecoin/.ecoin/wallet.dat`
     before opening Oasis; opening it publishes your wallet address*.

Orden que el aviso debe fijar, porque el software no lo impone: **cartera → backup → publicar**.

### El sitio de la configuración mutable

Hoy `wallet.*` vive en `/opt/oasis/src/configs/oasis-config.json`, un conffile que la propia app
reescribe en cada arranque (F5). Poner ahí credenciales tiene dos problemas: cada upgrade pregunta
por el conffile, y las credenciales quedan bajo `/opt`, legibles por quien lea el paquete instalado.
Lo limpio es que la app acepte un directorio de configuración del usuario (`~/.config/oasis` o
`OASIS_STATE_DIR`, que ya existe para el estado) y que el paquete deje en `/opt/oasis` solo los
valores por defecto. Es un cambio de aplicación, no del script de empaquetado; hasta entonces, el
`postinst` puede escribir `wallet.*` en el conffile y asumir la pregunta en los upgrades.

## El pub

Para un PUB el instalador puede dejar todo preparado y **parar justo antes del motor**:

- `server-config.json` con `pub: true` (lo hace la propuesta de `packaging/` con PUB=yes);
- `ecoind` instalado, con RPC solo en loopback y la cartera recién creada;
- `wallet.*` **vacío** hasta que el operador lo decida: con `pub: true` y `wallet.url` relleno,
  Oasis arranca el motor al primer tick, anuncia `pubAvailability` y empieza a pagar con lo que haya
  en la cartera. Por eso un pub recién instalado no debe tener las dos cosas a la vez.

Encender el motor es entonces un acto explícito del operador, después de fondear la cartera y de
guardar `wallet.dat` fuera de la máquina: rellenar `wallet.*` y reiniciar el servicio. El paquete
puede ofrecer `oasis ubi-on` que haga exactamente eso y pida confirmación escrita.

## Qué quedaría por ensayar

- Instalar `ecoin_0.0.4-1_amd64.deb` en el banco (`oasis-deb-plain`) y ver qué hace su `postinst`
  real (no se ha mirado).
- `ecoind` sin red: si `getinfo` responde por RPC antes de sincronizar, bastaría para probar el
  cableado `wallet.*` → `GET /wallet` con identidad desechable y `--network none`.
- El subcomando `oasis ecoin-init` como parte de `packaging/`.
