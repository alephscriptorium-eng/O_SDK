# Protocolo para agentes · operar o-sdk de forma reproducible

> **Para quién.** Un agente —o una persona— que llega en frío y tiene que levantar, ampliar, subir de
> versión o recuperar un pub de Oasis con este repo. **Para qué.** Que dos operadores distintos, con
> el mismo repo y la misma intención, lleguen al mismo resultado sin depender de la memoria de nadie.
>
> **Método e instancia.** Todo lo de esta página es genérico. Los datos de un despliegue concreto
> (dominio, feeds, rutas, nombres) viven en su **ficha de instancia**; la de la casa es
> [`INSTANCIA-SCRIPTORIUM.md`](./PUB/INSTANCIA-SCRIPTORIUM.md) y sirve de plantilla para la tuya.
>
> **Criterio de aceptación de cualquier protocolo de este repo:** un agente sin contexto, al que solo
> se le da el repo y una intención, completa la tarea sin preguntar. Cada vez que tropieza, el defecto
> es del protocolo y se corrige aquí.

## 1. ¿Qué quieres hacer? → qué leer

| Intención | Protocolo | Antes, lee |
|---|---|---|
| Levantar un pub en un VPS | `pub/README.md` · `docs/PUB/deploy.md` (guía de upstream) | §2 y §3 de esta página |
| Subir Oasis de versión (con o sin piezas activas) | [`UPGRADE-PROTOCOL.md`](./PUB/UPGRADE-PROTOCOL.md) | HUB §5 y ECOIN §5 si están activos |
| Publicar en clearnet lo que los habitantes marcan (`/c`) | [`HUB-PROTOCOL.md`](./PUB/HUB-PROTOCOL.md) | — |
| Dar ECOin al pub: cartera, RBU | [`ECOIN-PROTOCOL.md`](./PUB/ECOIN-PROTOCOL.md) | HUB §3 (mismo bootstrap de bot) |
| Dar de alta o **renombrar un bot** de soporte | HUB-PROTOCOL [§11-§12](./PUB/HUB-PROTOCOL.md) | §5 de esta página (nombres) |
| App cliente: alta, importar identidad, cartera | [`CLIENT-PROTOCOL.md`](./CLIENT-PROTOCOL.md) | — |
| Acoger y desplegar una obra del Teatro | [`TEATRO-PROTOCOL.md`](./PUB/TEATRO-PROTOCOL.md) · [curaduría](./PUB/TEATRO-CURADURIA-PROTOCOL.md) · [sidecar RRSS](./PUB/RRSS-SIDECAR-PROTOCOL.md) | — |
| Algo se ha roto (disco, repo, identidad) | [`RECOVERY-PROTOCOL.md`](./PUB/RECOVERY-PROTOCOL.md) | **no toques nada antes de §0** |

Cómo se trabaja en el repo (ramas, commits, gates, reportes): `plan/PRACTICAS.md`. Por qué las cosas
son como son: `plan/DECISIONES.md`.

## 2. Reglas universales

1. **Preflight: mide el estado.** `devops/scripts/deploy-status.sh` contra el host antes de cualquier
   cambio. Compara con la ficha de instancia; si no cuadra, la ficha está vieja: corrígela primero.
2. **Parada dura.** Cada paso tiene una salida esperada. Si no aparece, paras, no avanzas y lo
   reportas con el comando y su salida. No hay «ya que estoy».
3. **Backup antes de escribir**, con sufijo `*.bak-<etiqueta>-<fecha>` junto al original.
4. **Un servicio cada vez:** `docker compose up -d --no-deps <servicio>`. Nunca un `up` global ni el
   `deploy.sh` en un host con piezas vivas. El pub no se reinicia si el cambio no es suyo.
5. **Binds de fichero: escribir in place** (`cat > fichero`), nunca reemplazar el inode (`mv`,
   `sed -i`, `scp` sobre el destino): el contenedor seguiría viendo el fichero antiguo.
6. **Edge (Caddy): validar y `reload`**, nunca `restart`; después, salud de todos los vhosts ajenos.
7. **Secretos.** Se generan en el destino; `.env.prod` solo existe allí. No se imprimen, no se
   copian a reportes, no se pasan por línea de comandos (quedan en `ps` y en el historial).
8. **Evidencia.** Reporte en `plan/REPORTES/` con comando + salida. Lo que no mediste, no lo afirmes.
9. **Gates locales antes del VPS.** Todo cambio se ensaya en Docker local; la identidad de prueba es
   desechable. La identidad real de nadie se usa para ensayar.

## 3. Acciones irreversibles y su puerta

Un feed SSB es append-only y se replica: lo publicado no se retira. Estas acciones exigen **permiso
expreso del custodio en el momento**, aunque el plan general ya esté aprobado.

| Acción | Por qué no tiene vuelta | Puerta |
|---|---|---|
| Publicar `about` (nombre, descripción, imagen) | queda en el log; el último gana, los anteriores siguen ahí | texto literal aprobado; ventana no pública (HUB §12) |
| Publicar `wallet` (dirección ECOin) | el alta **no es idempotente**: cada POST es otro mensaje | contar antes (`0` mensajes `wallet`), publicar **una** vez, contar después |
| `contact` (seguir, bloquear), invites redimidos | cambian la replicación de terceros | lista cerrada aprobada |
| `pubAvailability`, `ubiAllocation`, pagos de RBU | anuncian el pub como banco y mueven ECO reales | ECOIN §9; saldo, backup y elegibilidad comprobados |
| Borrar o pisar `wallet.dat` o `secret` | son las claves: sin copia, el dinero o la identidad se pierden | **nunca**; se aparta con sufijo, no se borra |
| Arrancar un nodo con el `secret` y un log más corto que el de la red | bifurca el feed | RECOVERY §4 |
| `docker compose down -v`, borrar volúmenes | se lleva estado no derivable | `client/scripts/guard-destroy.sh`; backup < 24 h |
| Reload del edge | tumba todos los vhosts si la config es inválida | `validate` antes |

**Subagentes.** El clasificador de permisos de una sesión puede denegar a un subagente una
publicación aunque el plan la autorice. El subagente **para y lo dice**; no busca otra vía. La ejecuta
el agente principal tras volver a verificar la precondición (registro: ECOIN §13).

## 4. Trampas conocidas

Todas costaron una parada. Síntoma → causa → dónde está el detalle.

| Síntoma | Causa y salida | Detalle |
|---|---|---|
| `ecoind` responde 403 a todo el RPC | `rpcallowip` no entiende CIDR: usar comodines (`172.16.*` … `172.31.*`) | ECOIN §14 |
| El invite no conecta desde otro contenedor | el invite lleva el host público; reescribirlo a la IP del bridge del pub | HUB §3 · ECOIN §3 |
| Tras el invite el bot conecta a una dirección muerta | `conn.json` guarda la entrada con semilla; normalizar con `pub/tools/hub-conn-fix.js` y reiniciar | HUB §2 |
| El invite responde `alreadyFederated` | `seeds` en el `ssb-config`, o clave vieja en `gossip.json` | HUB §5, §10 |
| Aparecen dos mensajes `wallet` | `POST /banking/addresses` no es idempotente | ECOIN §3 · CLIENT §8.1 |
| Un backup de cartera no contiene la dirección publicada | el backup se hizo **antes** de generar la dirección | ECOIN §8 |
| Un contador sobre `log.offset` no se mueve | `grep -c` en binario cuenta líneas: `grep -a -o … \| wc -l` | RECOVERY §0 |
| En Git Bash un path `/c/…` o `/app/…` llega destrozado | conversión de rutas de MSYS: `MSYS_NO_PATHCONV=1`; y con él, `git -C /c/…` falla: `cd` + ruta relativa, `cygpath -m` para node | ECOIN §14 · CLIENT §8 |
| `MODULE_NOT_FOUND` al llamar a `ssb-admin.js` | la ruta dentro de la imagen viva depende del layout del host | HUB §9 |
| Un POST desde el loopback da 403 o 400 | `Host` y el host del `Referer` deben ser idénticos (mismo host:puerto) | ECOIN §3, §14 |
| «¿Está sincronizado `ecoind`?» da alturas absurdas | la altura de los pares sale de `receive version message … blocks=N`, no de `height=` | ECOIN §3 |
| `bootstrap.dat` se reimporta en cada arranque | comprobar `blk0001.dat`/`txleveldb`/`bootstrap.dat.old`, no `blkindex.dat` | ECOIN §14 |
| Tras un upgrade reaparece estado viejo o ficheros fantasma | el overlay se hizo sin `git rm -r src`: los ficheros que upstream borró siguen ahí | UPGRADE §2 |
| Desde Oasis 1.1.3: una segunda dirección ECOin, o el mapa de direcciones «vacío» | el estado vive en `~/.ssb/oasis/**`; `OASIS_BANKING_DIR` solo lo honra medio código | ECOIN §5 · UPGRADE §2 |
| El backend arranca sin sbot embebido | `OASIS_TEST` definido en el entorno (desde 1.1.3) | UPGRADE §1 |
| El nombre nuevo de un feed no aparece | `nameCache` es memoria del proceso: reiniciar el nodo que lo muestra | HUB §12 |
| El build del portal rompe | tokens entre ángulos fuera de código (Vue los lee como etiquetas) o enlaces muertos (`ignoreDeadLinks: false`) | `docs/proyecto.md` |

## 5. Nombres de los bots de soporte

Un pub delega funciones en **bots**: cuentas SSB propias, una por servicio, cada una en su contenedor
(HUB §11). Su nombre aparece en menciones, listas, actividad y —si reparte RBU— en la **tarjeta de
pub de Banking**, junto a los de otros pubs. La regla:

1. **El nick dice qué es y de quién, y nada más.** Quien lo ve debe poder trazar la cadena
   *tipo de bot → piel que lo organiza → pub que lo crea*. El nick lleva los extremos (tipo y pub); la
   cadena completa va en la **descripción**.
2. **Forma libre, se prefiere corta.** No hay gramática obligatoria: cada pub elige la suya y la
   mantiene. Recomendación: jerarquía tipo DNS, **`<tipo>.<dominio del pub>`**, porque se lee sola, no
   colisiona entre pubs y, si el operador quiere, puede hacerse resoluble.
3. **Máximos medidos** (Oasis 1.1.4; Oasis no valida ni recorta el nombre):
   - Tarjeta de pub en Banking: rejilla de 3 columnas (1 bajo 900 px); la cabecera es un flex con
     *wrap* y **sin elipsis**: un nombre largo parte línea o empuja el botón de donar. Caben
     **≈20-22 caracteres** en una línea junto al botón.
   - En campos de tarjeta y pies (`.card-field`, `.card-footer`) el enlace de usuario se recorta con
     elipsis a 220 px (≈28-30 caracteres).
   - **Sin `about` publicado se muestra el feed id entero** (53 caracteres): un bot sin nombre es lo
     peor que puede salir en una lista.
   - Caracteres: letras, cifras, punto y guion. Los puntos son seguros: las menciones viajan por feed
     id. Sin espacios, sin ángulos (se eliminan al sanear).
4. **Descripción: plantilla.** Tipo y cardinal en la serie del pub · piel que lo organiza · pub que
   responde por él · qué sirve · qué firma · qué **no** hace. Menos de 6 KB (el formulario no comprueba
   el límite de mensaje SSB: si te pasas, 500).
5. **Cambiar el nombre** es publicar otro `about`: irreversible (§3) y con procedimiento propio, HUB §12.
   El feed id no cambia nunca; lo que identifica al bot es el id, el nombre es cortesía.

Ejemplo (instancia Scriptorium): `clearnet.escrivivir.co` y `ecoin.escrivivir.co`. Sus descripciones
literales, en la ficha de instancia.
