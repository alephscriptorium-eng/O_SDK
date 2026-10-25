# Ficha de instancia · Scriptorium (`pub.escrivivir.co`)

> **Qué es esto.** Los protocolos de o-sdk son genéricos; aquí están los **datos de un despliegue
> concreto**, el de la casa: la instancia de demostración que ejerce el método. Es registro vivo y
> ejemplo relleno. Quien monte otro pub no necesita nada de ella: rellena la
> [ficha vacía](./INSTANCIA-PLANTILLA.md) con sus valores y su lore.
>
> **Qué no va aquí.** Secretos (nada de `.env.prod`, credenciales RPC, invites, `secret`) ni datos que
> cambian solos (versión desplegada, memoria, disco): esos **se miden** con
> `devops/scripts/deploy-status.sh` y se registran en el journal (`deploy-log.sh`).

## 1. Identidad de la instancia

| Campo | Valor |
|---|---|
| Pub | `pub.escrivivir.co` (dominio del operador: `escrivivir.co`) |
| Host | VPS Gandi, Debian 13, 2 CPU · 4 GB (reducción a 3 GB / 1 CPU prevista por el custodio); swap 2 GB en `/swapfile` (disco raíz), `vm.swappiness` 10 (WP-O148, D-O41); definición en `devops/hosts/scriptorium/host.env` |
| Layout vivo | `/opt/oasis-scriptorium/OASIS_PUB` (pre-refactor, **sin git**). `host.env` lleva esa ruta (el layout medido): los scripts de `devops/` no piden ningún `export`. Migración al layout canónico: pendiente (`devops/MIGRATION-2026-07.md`) |
| Acceso | SSH con la clave `devops/.ssh/gandi_pub_ed25519` (carpeta fuera de git; nombre en `KEY_FILE` de `host.env`). Los scripts la toman solos |
| Nodos de Oasis | tres contenedores de la misma imagen en el host: `oasis-pub-scriptorium` (`server`), `oasis-pub-hub` (`backend`), `oasis-pub-wallet-bot` (`backend`); el bot 3 no corre en el host (deprecated, D-O36; §3). Versión y modo de cada uno: `deploy-status.sh`, bloque «Piezas vivas» |
| Datos | volumen `/srv/oasis` (un subdirectorio por servicio) |
| Edge | Caddy, 6 vhosts; solo `validate` + `reload` |
| Visor clearnet (`/c`) | tema `Dark-SNH`, idioma por defecto **`es`** (claves `themes.current` y `language` de `pub/config/hub/oasis-config.json`, D-O25). El visitante cambia de idioma con `?lang=` y de tema con `?theme=` (desde WP-O132: ambos viajan en la URL y se re-afirman por petición) |
| Ciclo de red | 6 (`src/configs/blockchain-cycle.json`); salto al 7 previsto: el historial actual es de pruebas |
| Feed del pub | se mide: `pub/scripts/whoami.sh` |

## 2. Pieles y lore

Una **piel** es una forma de organizar y mostrar lo que el pub sirve. La de la casa es **Scriptorium**:
un edificio de salas (Sala 04 = clearnet `/c`; hackería, parlamento, teatro «Arrakis»…) en
`pub/site/scriptorium/`. Los bots de soporte se organizan por piel. La familia de bots de la casa se
llama **Azofaifo**: es lore, va en la descripción, no en el nick.

Otro pub tendrá otras pieles y otra familia, o ninguna. El método no depende de ello.

## 3. Registro de bots de soporte

Convención: [`AGENTES.md` §5](../AGENTES.md) (D-O20). Alta y renombrado: `HUB-PROTOCOL.md` §11-§12.
El **cardinal** es único en la serie del pub y no se reutiliza. El **feed id** es la identidad; el
nombre puede cambiar.

| # | Nombre | Tipo · piel | Qué sirve | Contenedor · estado | Feed id | Alta |
|---|---|---|---|---|---|---|
| 1 | `clearnet.escrivivir.co` | clearnet · scriptorium | HUB web de solo lectura `/c` (Sala 04) | `oasis-pub-hub` · `/srv/oasis/oasis-hub` | `@KM+ZBipR18VSyjNTFjAOnsmz6EiobGYHb3ZCZ4ZxQYI=.ed25519` | 2026-09-13 (WP-O46) |
| 2 | `ecoin.escrivivir.co` | ecoin (cartera) · scriptorium | hub-wallet: cartera ECOin del pub, custodia la dote y reparte la RBU; **sin ruta pública** | `oasis-pub-wallet-bot` + `oasis-pub-ecoin` · `/srv/oasis/oasis-wallet-bot`, `/srv/oasis/ecoin` | `@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519` | 2026-09-18 (WP-O102) |
| 3 | `retro.escrivivir.co` | retro (secretaría de plantillas) · scriptorium | activaba plantillas de organización (`TEMPLATE-PROTOCOL.md` §4.5): tribus, salas, calendarios, listas, wikis, mapas, bloque a bloque y con permiso; custodia las claves de las tribus que creó; **modo `server`, sin ruta pública**. Avatar: logo «Scriptorium Skins» 512×512 (blob `&q4Mkl/fcUGNELIrsmVyMBBdZsCXxyh5LmGN/XovlHDg=.sha256`) | **deprecated** (D-O36, 2026-10-12); identidad conservada y apagada en `volumes-real/oasis-retro-bot/` de la máquina operadora (contenedor local `oasis-pub-retro-bot`, parado); no corre en el host (estuvo en `/srv/oasis/oasis-retro-bot` del 2026-10-08 al 2026-10-10, D-O33). No se arranca, no se recrea, no se sube de versión, no siembra; la identidad no se borra | `@fJG3E7UKNlYVh0Aoc89LKPAAQsKNfy4iMaJtdVH0I8I=.ed25519` | 2026-10-08 (WP-O131) |

Dirección ECOin del bot 2 (pública, para la dote): `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc`.
Última subida registrada en el journal: Oasis 1.3.8 en pub, HUB y bot 2, 2026-10-25 (WP-O147). El estado
presente se mide: `deploy-status.sh`. En esa subida el pub y el HUB publicaron solo su `oasisVersion`; el bot 2,
`oasisVersion` y un `karmaScore`. Desde 1.3.8 los tres nodos llevan el guardián de feeds de upstream (`feed_guard.js`): tras
cada recreación se mide con `devops/scripts/feed-guard-status.js` (`lastRepair: null`). Lo que publicó cada nodo en los ciclos anteriores: `UPGRADE-PROTOCOL.md` §7 y sus
reportes.
Desde 1.2.6 HUB y bots publican solos su `karmaScore` cuando cambia, como mucho uno al día (aceptado por el
custodio, UPGRADE §3.4). El pub hace de centralita de Phone y Rooms, acotada (`phone` en su ssb-config: relé
solo para feeds que sigue, aforo de sala 12; `HUB-PROTOCOL.md` §14); HUB y bot 2, no. Los tres nodos no salen
por Tor (`onion: []` en sus ssb-config; upstream lo abre por defecto desde 1.2.3; decisión del custodio del
2026-10-07, HUB §5.2). Nombre del pub (su `about`): **`pub.escrivivir.co`**, publicado el 2026-10-05 (cuarto
`about` del feed, solo `name`; la descripción anterior se conserva). Nombre anterior: `PUB OASIS SCRIPTORIUM`.
Motor de base de datos **db2** desde el 2026-10-04 (1.2.1, WP-O123): los tres nodos migraron su log y no hay
vuelta a una versión anterior (`UPGRADE-PROTOCOL.md` §0.5). Motor de RBU: **encendido** desde el 2026-09-19
17:09 UTC (WP-O107; `hub-wallet.sh status`): la casa sale en la lista de pubs de Banking, sin fondos (✗, pool 0)
hasta la dote. Época `2026-09` fijada con pool 0.

Nombres anteriores (siguen en el log de cada feed; D-O14): `azofaifo-scriptorium-skin-bot-1`,
`azofaifo-scriptorium-wallet-bot-2`. El bot 3 nació ya con su nombre definitivo.

## 4. `about` literal de cada bot

Lo que se publica se transcribe aquí **tal cual**, con fecha. Estado: *propuesto* hasta que el reporte
del WP que lo publica diga lo contrario. En el feed la descripción va en **una sola línea**.

**Bot 1** — **publicado 2026-09-19** (WP-O106; segundo `about` del feed):

```
name:        clearnet.escrivivir.co
description: Bot de soporte nº 1 de pub.escrivivir.co · tipo clearnet · piel Scriptorium (Sala 04) ·
             familia Azofaifo. Sirve en https://pub.escrivivir.co/c la vista web de solo lectura de
             lo que cada habitante marcó como clearnet. No publica por nadie ni escribe en el pub:
             replica y muestra. Responde por él el pub escrivivir.co.
             Antes: azofaifo-scriptorium-skin-bot-1.
```

**Bot 2** — **publicado 2026-09-19** (WP-O106; segundo `about` del feed) con `vis_wallet=on` (HUB-PROTOCOL §12 paso 3):

```
name:        ecoin.escrivivir.co
description: Bot de soporte nº 2 de pub.escrivivir.co · tipo ecoin (cartera) · piel Scriptorium ·
             familia Azofaifo. Es la cartera ECOin del pub: custodia la dote y, cuando el motor está
             encendido, firma y paga la RBU. No tiene web pública ni publica por nadie. Responde por
             él el pub escrivivir.co. Antes: azofaifo-scriptorium-wallet-bot-2.
```

**Bot 3** — **publicado 2026-10-08** (WP-O131; primer `about` del feed, seq 3, clave `%lrtuvolSEp80ksfp9rwXRk4zKxuSTPAm5Yuvxz71FUo=.sha256`), con imagen (`&q4Mkl/fcUGNELIrsmVyMBBdZsCXxyh5LmGN/XovlHDg=.sha256`), por `ssb-admin.js publish-about --image` (HUB §12). Sin nombres anteriores:

```
name:        retro.escrivivir.co
description: Bot de soporte nº 3 de pub.escrivivir.co · tipo retro (secretaría de plantillas) · piel
             Scriptorium · familia Azofaifo. Activa en el pub las plantillas de organización (tribus,
             salas, calendarios, listas, wikis, mapas) que un colectivo aprueba, bloque a bloque y con
             permiso expreso. Custodia las claves de las tribus que crea. No tiene web pública ni
             publica por nadie. Responde por él el pub escrivivir.co.
image:       ARCHIVO/DISCO/scriptorium-exported/assets/avatar-retro-512.png
```

## 5. Qué hay activo y con qué protocolo

| Pieza | Protocolo | Registro |
|---|---|---|
| Pub (solo sbot) | `UPGRADE-PROTOCOL.md` | journal `deploy-log.sh` |
| HUB clearnet `/c` | `HUB-PROTOCOL.md` | §10 |
| Centralita de Phone y Rooms (en el pub, acotada: aforo de sala 12) | `HUB-PROTOCOL.md` §14 · `CAPACIDAD.md` §4 | `plan/REPORTES/WP-O124-upgrade-oasis-1.2.2.md` §7 |
| Entrada de habitantes: la portada (`https://pub.escrivivir.co`) muestra un invite de 1000 usos, que sirve el panel (`/public/status`, `PUB_INVITE_USES`). Es público por diseño; no se copia aquí | puerta [Habitante](../roles/habitante.md), nota «para quien opera» | [hoja del habitante](./INSTANCIA-SCRIPTORIUM-HABITANTE.md) |
| hub-wallet (ECOin) | `ECOIN-PROTOCOL.md` | §13 |
| Enlace de los nodos de soporte con el pub (HUB y bot de cartera): keepalive del entrypoint con las variables `OASIS_PUB_LINK_*` **por defecto** (`OASIS_PUB_LINK_HOST=oasis-pub`, 60 s / 30 s; `.env.prod` sin tocar) + libreta del pub; `conn.populatePubs: false` en sus `ssb-config`. Se mide, no se supone: `hub-wallet.sh status` (línea `pares:`), `deploy-status.sh` (líneas `LINK`), foto de `upgrade-gates.sh --remote snapshot` (`pub_link=connected` en HUB y bot) | `HUB-PROTOCOL.md` §2 · `UPGRADE-PROTOCOL.md` §3.4, §6 · D-O38 | `plan/REPORTES/WP-O143-enlace-pub.md` |
| Plantillas de organización — **inactivo** (bot 3: deprecated, D-O36); queda el método. Historia: Campamento **sembrada el 2026-10-08 y deshecha el 2026-10-10**. La siembra fue 25 tribus, 7 salas, 7 calendarios, 7 eventos, 4 listas, 5 wikis, 2 mapas, 14 `clearnetItem` (feed del bot en 148); el deshacer, 115 retiradas en 11 bloques (`vps/tombstone-o135.jsonl`; feed en 266; dos listas CLOSED privadas quedan) | `TEMPLATE-PROTOCOL.md` | §8 · `ARCHIVO/DISCO/scriptorium-exported/` (ledger del VPS en `vps/`) · guía de reparto en la Sala 02 (`site/parlament/campamento/`, generada con los enlaces reales) · **mapa de entrada** publicado por el bot 3 el 2026-10-08 como entrada de Blog, `%PbJ+F75RZoHpKWBIrmLtWVT+VV5mlRu+gY50J7tj1zk=.sha256` (seq 149; su `clearnetItem` seq 150), generado por `mensaje-entrada.mjs`, visible en `/c/blog` |
| Cliente real de la máquina operadora (feed del custodio, `volumes-dev/ssb-data`) — **cerrado desde 2026-10-18 (D-O39)**: la identidad se mudó (destino: «pendiente»); queda en Oasis 1.3.0 (WP-O145) y no se arranca ni se sube. Cerrojo: `IDENTIDAD-MUDADA` en el bind, `identity-lock.sh` en los scripts, override local de Compose | `CLIENT-PROTOCOL.md` §7.1 | `plan/REPORTES/WP-O146-upgrade-oasis-1.3.2.md` |
| Teatro · sidecar RRSS | `TEATRO-PROTOCOL.md` · `RRSS-SIDECAR-PROTOCOL.md` | en cada uno |
| Teatro P2P | `TEATRO-P2P-PROTOCOL.md` | §5 · *Aleph Cero* **congelada** el 2026-09-19; enlaces en `/teatro/aleph-cero/p2p/p2p.json`, anuncios de Oasis en `p2p/oasis.json` |

**Sitio del pub: qué páginas vivas no son las del repo** (medido el 2026-10-05, WP-O125). El repo
guarda la plantilla; en el host, estas llevan valores fusionados a mano y no se sustituyen enteras:

| Página | Qué lleva el vivo que el repo no |
|---|---|
| `site/scriptorium/index.html` | un valor real donde la plantilla dice «SOLICITAR», una orden `curl` completa y una ruta del layout del host en un diagrama |
| `site/admin/index.html` | la ruta del env local según el layout del host; finales de línea CRLF |
| `site/parlament/index.html` | finales de línea CRLF (el repo lleva LF); el 2026-10-08 se insertó **solo** la línea del enlace a `campamento/` sobre el vivo, con backup `.bak-retro-*` |

`site/hub/` (Sala 04) sí es idéntica a la del repo. Cómo se sube un cambio: `../AGENTES.md` §4.

Backups de cartera: `devops/backups/ecoin/` (no versionado). Copias de estado de los nodos (`/srv/oasis/*.bak-*.tgz`, `*.cold-*.tgz`): en el host solo la última por nodo; las descargadas viven en `devops/backups/srv-oasis/<ts>/` (no versionado) y en el almacenamiento seguro del custodio (WP-O133). Contienen `secret`: nunca a git ni a un reporte. Particularidades del host que ya
costaron una parada: `HUB-PROTOCOL.md` §9 y `ECOIN-PROTOCOL.md` §11.
