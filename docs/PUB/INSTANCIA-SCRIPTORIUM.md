# Ficha de instancia · Scriptorium (`pub.escrivivir.co`)

> **Qué es esto.** Los protocolos de o-sdk son genéricos; aquí están los **datos de un despliegue
> concreto**, el de la casa. Es a la vez registro vivo y **plantilla**: quien monte otro pub copia
> este fichero como `INSTANCIA-<la-suya>.md`, conserva los epígrafes y pone sus valores y su lore.
>
> **Qué no va aquí.** Secretos (nada de `.env.prod`, credenciales RPC, invites, `secret`) ni datos que
> cambian solos (versión desplegada, memoria, disco): esos **se miden** con
> `devops/scripts/deploy-status.sh` y se registran en el journal (`deploy-log.sh`).

## 1. Identidad de la instancia

| Campo | Valor |
|---|---|
| Pub | `pub.escrivivir.co` (dominio del operador: `escrivivir.co`) |
| Host | VPS Debian, 4 GB; definición en `devops/hosts/scriptorium/host.env` |
| Layout vivo | `/opt/oasis-scriptorium/OASIS_PUB` (pre-refactor, **sin git**): exportar `REMOTE_REPO_DIR` con esa ruta antes de los scripts de `devops/` |
| Datos | volumen `/srv/oasis` (un subdirectorio por servicio) |
| Edge | Caddy, 6 vhosts; solo `validate` + `reload` |
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
Motor de RBU: **apagado** (rediseño del interruptor para Oasis 1.1.4 en WP-O107).

Nombres anteriores (siguen en el log de cada feed; D-O14): `azofaifo-scriptorium-skin-bot-1`,
`azofaifo-scriptorium-wallet-bot-2`.

## 4. `about` literal de cada bot

Lo que se publica se transcribe aquí **tal cual**, con fecha. Estado: *propuesto* hasta que el reporte
del WP que lo publica diga lo contrario.

**Bot 1** — propuesto 2026-09-19 (WP-O106):

```
name:        clearnet.escrivivir.co
description: Bot de soporte nº 1 de pub.escrivivir.co · tipo clearnet · piel Scriptorium (Sala 04) ·
             familia Azofaifo. Sirve en https://pub.escrivivir.co/c la vista web de solo lectura de
             lo que cada habitante marcó como clearnet. No publica por nadie ni escribe en el pub:
             replica y muestra. Responde por él el pub escrivivir.co.
             Antes: azofaifo-scriptorium-skin-bot-1.
```

**Bot 2** — propuesto 2026-09-19 (WP-O106):

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
| hub-wallet (ECOin) | `ECOIN-PROTOCOL.md` | §13 |
| Teatro · sidecar RRSS | `TEATRO-PROTOCOL.md` · `RRSS-SIDECAR-PROTOCOL.md` | en cada uno |

Backups de cartera: `devops/backups/ecoin/` (no versionado). Particularidades del host que ya
costaron una parada: `HUB-PROTOCOL.md` §9 y `ECOIN-PROTOCOL.md` §11.
