# WP-O145 · Cliente 1.2.2 → 1.3.0: la config viva pasa a `~/.ssb/oasis/oasis-config.json`

Rama `upgrade/oasis-1.3.0-cliente` desde `main` 04011c4d. 2026-10-15. Misma imagen que el pub (`src/` en 37e0fc93,
WP-O141): el cliente no necesita overlay nuevo; lo que cambia es **dónde cablea el entrypoint** y el drill del cliente.

## 1. Estado de partida

- Cliente real parado (`oasis-client` Exited, imagen `o-sdk-oasis-client:latest` = `a46b59ddc176`, 1.2.2; no existe la
  etiqueta `:1.2.2`). Feed real (medido con `count-feed-type.js` sobre el bind, cliente parado): `oasisVersion` 4
  (últimos seqs 45, 67, 88), `about` 4 (4, 76, 85), `karmaScore` 10 (89, 105, 109), `wallet` 1 (70).
- Bloqueo documentado en CLIENT-PROTOCOL §4 (WP-O135): desde Oasis 1.2.4 `config-manager.js` lee y escribe
  `~/.ssb/oasis/oasis-config.json` y de `src/configs/oasis-config.json` solo **copia una vez**. El entrypoint de WP-O103
  enlazaba `src/configs/oasis-config.json → /app/state/oasis-config.json`: en ≥ 1.2.4 ese enlace se leía una vez y la
  GUI escribía en otro sitio. El drill previo (1.2.5) lo mostró: `language` «es» en `.ssb/oasis` y «en» en `client-state`.
- `saveConfig` escribe con `rename` (`src/configs/config-manager.js:21-23`): ni symlink ni bind de fichero en el sitio
  nuevo; tiene que ser un fichero regular dentro del bind de `ssb-data`.

## 2. Diseño (aprobado por el custodio)

La config viva es `~/.ssb/oasis/oasis-config.json` (en el host `volumes-dev/ssb-data/oasis/oasis-config.json`).
`client-state/oasis-config.json` queda como **legado de solo lectura**: siembra la viva una vez y no se vuelve a tocar
(se retira en un WP posterior; el compose lo sigue bindeando).

| Commit | Pieza |
|---|---|
| 4f9d9ff6 | `docker-entrypoint.sh`: `OASIS_LIVE_CONFIG_FILE`; `persist_client_state` siembra (default + legado, gana el legado) o funde (default + viva, gana lo vivo); 600; repone el default en `src/configs` si quedó un enlace; corre en todos los modos (también `server`, para `sync-only.sh`); `OASIS_CONFIG_FILE` → la viva en los modos con backend; `wire_wallet_config`/`setup_oasis_config` sin cambios (escriben en `$OASIS_CONFIG_FILE`) |
| dbb38885 | `ecoin-verify.sh`: V4 lee la viva; V5 comprueba viva regular a 600, `src/configs` sin enlace, legado presente |
| 9f844b98 | CLIENT-PROTOCOL §4 (4.1 dónde vive, 4.2 receta, 4.3 delta declarado y cómo medirlo, 4.4 salto de motor ya pasado), §5, §6 (salvedad al volver por retag a ≤ 1.2.3), §8.3, §8.4, §8.8, §8.9 (D10-D14); textos de `setup.sh`, `ecoin-init.sh`, `guard-destroy.sh`, `sync-only.sh` |
| (este) | reporte, backlog, CHANGELOG |

HUB y bot no cambian: su bind `:ro` ya apunta al sitio nuevo. La afirmación «el backup de la GUI excluye la config»
está medida: `NOT_BACKED_UP` en `src/models/backup_model.js:27`.

## 3. Drill (identidad desechable, proyecto `o-sdk-drill`, 18:11-18:13Z)

`D="docker compose -p o-sdk-drill -f docker-compose.yml -f client/docker-compose.drill.yml --env-file client/.env.drill"`,
`OASIS_AI=none`. Imagen previa etiquetada `o-sdk-drill-oasis-client:pre-o145` (`26b4232a4e15`, 1.2.5); nueva `:o145` =
`:latest` (`1708636c5792`). Guion: `scratchpad/drill-145.sh`, salida `drill-145.log`.

| Gate | Comando | Salida |
|---|---|---|
| D0 | `$D stop`; apartar la viva del drill para forzar la siembra | `apartada: …/oasis-config.json.bak-pre-o145 ("language": "es")` · `legado: "language": "en" · sha e4a849f1962c` |
| D1 build + up | `$D build && $D up -d` | `healthy a los 6 s`; log: `Persistiendo estado del cliente (config viva: /home/oasis/.ssb/oasis/oasis-config.json; legado: /app/state)` → `config viva SEMBRADA desde el default de la imagen + el legado de /app/state/oasis-config.json (el legado no se vuelve a tocar)` → `wallet.url: http://ecoin-wallet:7474`; `[Version: 1.3.0]` |
| D10 siembra | host: `language` y sha de viva y legado; dentro: `stat`, `test -L src/configs/oasis-config.json` | `viva … "language": "en" · sha 0e1bca4d69c5 · legado intacto: e4a849f1962c`; `dentro: viva 600 src/configs regular` |
| D13 / D3 | `client:ecoin:verify` (drill) | **16 PASS · 0 FAIL · 0 SKIP**; V5: `config viva … (600, dentro del bind de ssb-data)`, `src/configs/oasis-config.json es el default de la imagen`, `legado … presente (solo lectura; sembró la config viva)` |
| D11 | escribir `language=fr` en la viva (como la GUI) → `$D up -d --force-recreate oasis-client` | `tras recreate: "language": "fr"`; log `config viva: default de la imagen + lo vivo (gana lo vivo) (sin cambios)` |
| D12 | `OASIS_WALLET_FEE=0.0002` en `.env.drill` → recreate | `viva wallet.fee: "fee": "0.0002" · language sigue: "fr"`; `.env.drill` restaurado después |
| D14 | `ls -a volumes-dev/drill/ssb-data/oasis/` | `tmp-: 0` |
| D6 rollback | retag `pre-o145` → `$D up -d` → retag `o145` → `$D up -d` | 1.2.5: `✓ /app/src/configs/oasis-config.json → /app/state/oasis-config.json`, `[Version: 1.2.5]`, la viva intacta (`"language": "fr"`); vuelta a 1.3.0: `config viva: default de la imagen + lo vivo`, `language fr` |

Drill parado al final (`$D --profile ecoin stop`: `oasis-client-drill` y `ecoin-wallet-drill` Stopped).

## 4. Delta de publicación (drill, feed `@Br/nQykb…`, `count-feed-type.js` sobre el bind)

Antes: `oasisVersion` seqs [5, 12], `about` [1], `karmaScore` [2], `wallet` 0. Después de D1-D6 (cinco arranques:
1.3.0 ×3, 1.2.5, 1.3.0): `oasisVersion` [5, 12, **15, 16**], `about` [1, **13**], `karmaScore` [2, **14**], `wallet` 0,
`pubAvailability` 0. Es decir `about+1` (`clearnetSince`, a los 3 s del primer arranque en 1.3.0), `karmaScore+1`,
`oasisVersion+2` por el cambio de versión ida y vuelta (la última subida duró segundos antes del `stop`: un tercero puede
quedar pendiente; en el cliente real no hay rollback previsto). Ningún otro tipo.

**Delta declarado para el cliente real** (CLIENT-PROTOCOL §4.3): `oasisVersion=+1`, `about=+1`, `karmaScore=+0..1`,
`wallet=0`, `pub-invites=0`.

## 5. Correcciones al protocolo

- CLIENT-PROTOCOL §4 pasa de aviso de bloqueo a receta: retag **antes** del build (hoy no existe `:1.2.2`), copia en
  frío con el cliente parado, delta declarado y medido con `count-feed-type.js` antes (bind) y después (contenedor).
- §6: al volver por retag de ≥ 1.2.4 a ≤ 1.2.3 la imagen vieja lee el legado; lo guardado bajo la nueva no se ve hasta
  volver a subir; la viva no se toca.
- `sync-only.sh` (modo `server`) también siembra/funde la viva: así Oasis no deja su default interno la primera vez.
- Secreto nuevo en el bind: la viva lleva `wallet.user/pass` (600) y **viaja con cualquier copia de `ssb-data`**.

## 6. Pendiente: cliente real (con GO del custodio)

1. `docker tag o-sdk-oasis-client:latest o-sdk-oasis-client:1.2.2`.
2. Copia en frío (cliente parado) de `volumes-dev/ssb-data` y `volumes-dev/client-state` a `devops/backups/client/<ts>/`
   (ignorado por git; material de claves: a cifrado).
3. `npm run build && docker compose up -d oasis-client` → log «SEMBRADA … + el legado» → healthy.
4. `count-feed-type.js` dentro del contenedor y `client:inspect-log`: delta = el declarado; `client:ecoin:verify`;
   healthcheck §5; `devops:pub-feed-seq`.
