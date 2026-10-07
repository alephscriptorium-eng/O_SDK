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
| Host | VPS Debian, 4 GB; definición en `devops/hosts/scriptorium/host.env` |
| Layout vivo | `/opt/oasis-scriptorium/OASIS_PUB` (pre-refactor, **sin git**). `host.env` lleva esa ruta (el layout medido): los scripts de `devops/` no piden ningún `export`. Migración al layout canónico: pendiente (`devops/MIGRATION-2026-07.md`) |
| Acceso | SSH con la clave `devops/.ssh/gandi_pub_ed25519` (carpeta fuera de git; nombre en `KEY_FILE` de `host.env`). Los scripts la toman solos |
| Nodos de Oasis | tres contenedores de la misma imagen: `oasis-pub-scriptorium` (`server`), `oasis-pub-hub` (`backend`), `oasis-pub-wallet-bot` (`backend`). Versión y modo de cada uno: `deploy-status.sh`, bloque «Piezas vivas» |
| Datos | volumen `/srv/oasis` (un subdirectorio por servicio) |
| Edge | Caddy, 6 vhosts; solo `validate` + `reload` |
| Visor clearnet (`/c`) | tema `Dark-SNH`, idioma por defecto **`es`** (claves `themes.current` y `language` de `pub/config/hub/oasis-config.json`, D-O25). El visitante cambia de idioma con `?lang=` |
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

Dirección ECOin del bot 2 (pública, para la dote): `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc`.
Oasis **1.2.3** en pub, HUB y bot-2 desde el 2026-10-07 (WP-O128; antes 1.2.2, WP-O124, 2026-10-05). El pub
hace de centralita de Phone y Rooms, acotada (`phone` en su ssb-config: relé solo para feeds que sigue,
aforo de sala 12; `HUB-PROTOCOL.md` §14); HUB y bot-2, no. Nombre del pub (su `about`):
**`pub.escrivivir.co`**, publicado el 2026-10-05 (cuarto `about` del feed, solo `name`; la descripción
anterior se conserva). Nombre anterior: `PUB OASIS SCRIPTORIUM`. Motor de
base de datos **db2** desde el 2026-10-04 (1.2.1, WP-O123): los tres nodos migraron su log y no hay vuelta a una versión
anterior (`UPGRADE-PROTOCOL.md` §0.5). La versión viva se mide con `deploy-status.sh`. Motor de RBU: **encendido**
desde el 2026-09-19 17:09 UTC (WP-O107; `hub-wallet.sh status`): la casa sale en la lista de pubs de Banking,
sin fondos (✗, pool 0) hasta la dote. Época `2026-09` fijada con pool 0.

Al subir a 1.2.2 el bot 1 publicó además un `about` de visibilidad; en el ensayo local ese mensaje lleva solo
`visibilityPrefs` con `phone: "off"` (2026-10-05, WP-O124 §5.1); el del bot 2 sale cuando alguien
visite sus páginas. Al subir a 1.2.3 (2026-10-07) cada nodo publicó solo su `oasisVersion`; el `about` de
`clearnetSince` que 1.2.3 intenta publicar en cada arranque de un backend no público (bot-2) no salió, y puede
salir en cualquier reinicio: se declara `about=+0..1` (UPGRADE §0.4). Los tres nodos siguen sin salir por Tor
(`onion: []` en sus ssb-config; upstream lo abre por defecto desde 1.2.3; el custodio decidió el 2026-10-07 no
salir por Tor, HUB §5.2).

Nombres anteriores (siguen en el log de cada feed; D-O14): `azofaifo-scriptorium-skin-bot-1`,
`azofaifo-scriptorium-wallet-bot-2`.

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

## 5. Qué hay activo y con qué protocolo

| Pieza | Protocolo | Registro |
|---|---|---|
| Pub (solo sbot) | `UPGRADE-PROTOCOL.md` | journal `deploy-log.sh` |
| HUB clearnet `/c` | `HUB-PROTOCOL.md` | §10 |
| Centralita de Phone y Rooms (en el pub, acotada: aforo de sala 12) | `HUB-PROTOCOL.md` §14 · `CAPACIDAD.md` §4 | `plan/REPORTES/WP-O124-upgrade-oasis-1.2.2.md` §7 |
| Entrada de habitantes: la portada (`https://pub.escrivivir.co`) muestra un invite de 1000 usos, que sirve el panel (`/public/status`, `PUB_INVITE_USES`). Es público por diseño; no se copia aquí | `../AGENTES.md` §1 | [hoja del habitante](./INSTANCIA-SCRIPTORIUM-HABITANTE.md) |
| hub-wallet (ECOin) | `ECOIN-PROTOCOL.md` | §13 |
| Teatro · sidecar RRSS | `TEATRO-PROTOCOL.md` · `RRSS-SIDECAR-PROTOCOL.md` | en cada uno |
| Teatro P2P | `TEATRO-P2P-PROTOCOL.md` | §5 · *Aleph Cero* **congelada** el 2026-09-19; enlaces en `/teatro/aleph-cero/p2p/p2p.json`, anuncios de Oasis en `p2p/oasis.json` |

**Sitio del pub: qué páginas vivas no son las del repo** (medido el 2026-10-05, WP-O125). El repo
guarda la plantilla; en el host, estas llevan valores fusionados a mano y no se sustituyen enteras:

| Página | Qué lleva el vivo que el repo no |
|---|---|
| `site/scriptorium/index.html` | un valor real donde la plantilla dice «SOLICITAR», una orden `curl` completa y una ruta del layout del host en un diagrama |
| `site/admin/index.html` | la ruta del env local según el layout del host; finales de línea CRLF |

`site/hub/` (Sala 04) sí es idéntica a la del repo. Cómo se sube un cambio: `../AGENTES.md` §4.

Backups de cartera: `devops/backups/ecoin/` (no versionado). Particularidades del host que ya
costaron una parada: `HUB-PROTOCOL.md` §9 y `ECOIN-PROTOCOL.md` §11.
