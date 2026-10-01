# Reporte · WP-O113 · Upgrade de Oasis 1.1.4 → 1.1.10 en local, con el protocolo nuevo

- **Fecha**: 2026-10-01 · **Rama**: `upgrade/oasis-1.1.10` · **Asiento**: D-O25 (aplicación).
- **Resultado**: `src/` en 1.1.10 (upstream `f770dbb`) con los **5 guards**. Pub, HUB y bot de cartera
  suben en local desde estado 1.1.4 (motor de RBU encendido, época del mes abierta) y **cada uno
  publica un `oasisVersion` y nada más**. Visor con D-O25 aplicada, sitemap y RSS con `https`.
  Cliente del drill en 1.1.10: cartera, puente de loopback e IA en verde. **Listo para el host
  (WP-O114), que espera el GO del custodio.**
- Es la primera ejecución de `UPGRADE-PROTOCOL.md` tal como quedó en WP-O112. El protocolo paró
  donde tenía que parar (dos veces en U5, una en U4) y devolvió **once correcciones**, ya aplicadas.

## 1. Estado de partida

`upgrade-preflight.sh --from 1.1.4`: `OLD_REF=45a1cd4` · `NEW_REF=f770dbb` · «pub en modo server = 6
de los 15 ficheros que carga · backends y cliente = 73».
Host (`deploy-status.sh`, `upgrade-gates.sh --remote snapshot base-1.1.4`): tres nodos en 1.1.4,
`sequence` pub 15 · HUB 11 · bot 50, motor `pub=true`, épocas `2026-09,2026-10` (tabla completa en
el reporte de WP-O112).
Local (U0, `snapshot pre`): pub 5 · HUB 6 · bot 15, motor `pub=true`, mismas épocas.

## 2. Qué se entregó

| Pieza | Commit |
|---|---|
| Overlay limpio de `src/` a 1.1.10 | `cc21d0d` |
| Guards a mano: `/update` y aviso de ajustes (el 5.º guard no cambió: upstream no tocó el fichero) | `b6b1828` |
| nginx: D-O25 (sin `Accept-Language` ni `Cookie` hacia el HUB) y `location` de sitemap y RSS con `https` | `eb327df` |
| Config del HUB regenerada (sale `walletPub`, `language` fijada) | `b6458e6` |
| `inboxMutedBots` en HUB y bot + `pub/scripts/regen-node-configs.js` | `5ed82d2` |
| `client/scripts/test-ai-service.sh` para el contrato de IA de 1.1.10 | `40d15cb`, `a71ba6b` |
| Sala 04: sitemap, RSS y selector de idioma | `02ec7b2` |
| «Desconectar cartera» en AGENTES §3 y CLIENT §8.8 | `ea013cf` |
| ECOIN §3 pasos 7-9, §9 y §12.4; trampas de `/wallet` y de los cifrados; humo de la imagen | `e6b2b5d` |
| Correcciones a las herramientas | `94178e8`, `9010bbb`, `8a7e3fb` |

Invariante: `git diff oasis-upstream/main --stat -- src/` = 6 ficheros; `node --check` de
`backend.js`; `annex`: 28 `ok`, ninguna `!`.

## 3. Disposiciones del diff de comportamiento

`upgrade-behaviour-diff.sh 45a1cd4 f770dbb`: 192 líneas, 156 con signo. Todas dispuestas
(`--check` contra este fichero: 0 pendientes).

| Qué | Disposición | Por qué | IDs |
|---|---|---|---|
| Versión y dependencias | **no-afecta** | Solo cambia `version` en `package.json`; las dependencias son idénticas, así que los parches de `node_modules` del entrypoint encuentran sus cadenas (confirmado en el log de arranque, U3). | `aba81af3` `8127fa58` `212d4d4d` |
| Banner del sbot | **no-afecta** | `ssb_metadata.js` solo cambia de dónde lee la dirección ECOin que imprime al arrancar (de `state-manager`, y solo si hay credenciales). `OASIS_BANKING_DIR` gana un uso ahí; ningún compose la define. | `f870255c` `13dee177` |
| Estado: ficheros nuevos | **documentado** | UPGRADE §6 y ECOIN §5.2: la mudanza de estado no vuelve con un rollback de imagen (tgz de `ssb-data/oasis/` antes). Lo nuevo —vectores de IA, histórico de fondos, flags de bandeja— no existe en ubicaciones viejas, así que `migrateAll` no mueve nada. El pub carga `state-manager.js` solo para resolver rutas. | `bd892fc9` `8ee487bf` `88913a42` `8241a28a` `6f4e4175` `dbcad4d4` |
| Lo que carga el pub en modo server | **gate U3** | `banking_model.js` (el sbot llama a `ensureSelfAddressPublished` a los 5 s; función idéntica a 1.1.4, inerte sin cartera alcanzable), `typed_log.js` (marca de «listado truncado» por petición) y `shared-state.js` (contadores de bandeja). Lo decide la medida: el pub recreado en 1.1.10 publica `oasisVersion` y nada más. | `5c0837d4` `9f6ad872` `ad3e9c63` |
| IA: servicio, modelo y variables | **gate cliente** | Solo afecta al cliente: HUB y bot llevan `aiMod: off` y el pub `OASIS_SKIP_AI_MODEL`. Servicio con token por sesión y puerto variable → `client/scripts/test-ai-service.sh` reescrito (`40d15cb`). `install.sh` de upstream delata que el modelo cambia bajo el mismo nombre (Qwen2.5-3B, 2,1 GB) y que hay un modelo de embeddings: ver hallazgos. `OASIS_TEST` gana un uso en `ai_client.js`; ningún compose la define. `/ai/export` y sus cabeceras son una descarga desde la GUI. | `9d8eb69e` `a1a4e357` `71777e25` `b7a43fb9` `5416bc57` `8f388e15` `b0ec941d` `8b2a06c8` `2155533d` `b0f33449` `9e01b0a2` `4f5e6c55` `bbcdd295` `1ad81a4d` `d8c0ca01` `7446adf0` `53e8434e` `0b15e9b4` `65c44fee` |
| Idioma del visor por cabecera del visitante | **adaptado** | D-O25, `eb327df` (nginx no reenvía `Accept-Language` ni `Cookie`) y `b6458e6`/`5ed82d2` (`language` fijada en la config del HUB). Gate U4: mismo `/c` con tres `Accept-Language` y con cookies; `?lang=` elige; sin cruce en concurrencia. Dos traducciones nuevas (ca, gl) solo alargan el selector. | `2a1d7f97` `1536607d` `ac296037` `4a5cf563` `ab9dbff6` `c9cfdefc` `52881176` |
| Sitemap y RSS del visor | **adaptado** | `eb327df` (`location` propia con `sub_filter` a https) y `02ec7b2` (Sala 04). Gate U4. | `25c9cb1d` `d8e96ec4` |
| Guardas de petición y CSP | **gate U4 + drill del cliente** | `request_guards.js` saca de `middleware.js` la comprobación de host/Referer y la CSP (`buildCsp(isClearnet)`). U4 comprueba que el visor sirve y que hay una sola CSP; el POST por el puente de loopback se comprueba en el drill del cliente (CLIENT §8.10). | `efb1d5c3` `dbd00b69` `6902da1b` `257d96a9` `f79b535d` |
| «Desconectar cartera» | **documentado** | `ea013cf`: fila en AGENTES §3 y aviso en CLIENT §8.8. Publica un `wallet` vacío que anula la dirección. En HUB y bot el modo público bloquea todo POST. | `4fe429f7` `def12f57` `61da79c6` `73ff6676` |
| La GUI publica la dirección si está en local y no en el feed | **gate U5 y U6** | Rama nueva de `refreshWalletReady` (`setUserAddress(me, addr, true)`). U5: en el bot, con la dirección ya publicada, `GET /banking` y `/wallet` no mueven `wallet`. U6: bootstrap de un bot nuevo; ECOIN §3 pasos 7-8 se reescriben con lo medido. | `b8e640d7` |
| Avisos automáticos del backend (notifyBot) | **adaptado** | `5ed82d2`. `notifyBot` sustituye a `pmModel.sendMessage` en todos los avisos: mismos destinatarios, más deduplicación y respeto a `inboxMutedBots`. Los que se dirigen a uno mismo (político, empleo, banca, recordatorios) salían cifrados sin que nadie los pidiera: en HUB y bot van silenciados. Los tres avisos nuevos (podcast, blog, ruta de logística) y los demás los dispara una acción de usuario en la GUI. Gate U3: `(cifrado)` = 0. | `3fba76df` `affd35e3` `81d2bdee` `e2912420` `dd28b8a7` `3a2d05b0` `da347d9a` `feb5cfca` `e7fb08a5` `1f80c563` `b0d17afa` `419af3a3` `d7bcb7f0` `3e8cf411` `b8933d96` `c1161349` `eb08ebd7` `b032f87d` `e7ba5967` `a44143fe` `4b28554e` `045e692e` `977aa54a` `edb749be` `f419f325` `224a30a2` `12502a26` `920f4e2f` `ccd1f460` `002d276e` `11ba1c23` `f2e9f7e8` `1c27466d` `89b733aa` `7456f0ed` `88057301` `2ea3d487` `2504b914` `0915e8f2` `d2fe485d` `a4ffdc94` `d9f02ff2` `5ba2eb0c` `e3073ad0` `3f6cb8a0` `cc37bdba` `5b92e6ea` `3638dd95` `963d4168` `9b778081` `e96ab945` `17cc00c4` `240d1559` `c43aeb2f` `aabd923b` `e04ba125` `400fd189` `0406c2f4` `d1cb07c2` `d962539c` `302bf085` `09bb1600` `49ddce75` `7889d394` `b0f5f594` `7fb603b7` `35874e92` `75b06f29` `abd4bd4a` `1d7a77e7` |
| Bandeja, menciones y vista previa de blog | **no-afecta** | Acciones de usuario en la GUI: marcar leído o archivar escribe flags locales; `/inbox/delete-many` y `/blogs/preview` las pulsa una persona. En HUB y bot el modo público bloquea todo POST. `/settings/inbox-bots` escribe `inboxMutedBots`, que en los nodos de soporte se fija por config (`5ed82d2`). | `66f4ad00` `e8f57c45` `0edf61b2` `f47bdcdf` `f123ede8` `f673af0e` `81a08446` `c7531203` `94c9a813` `8c38d424` `f2b2462e` |
| PM de bienvenida tras fijar el idioma | **gate U3** | Un `setTimeout(welcomePmTick, 0)` más, al fijarse el idioma en la primera petición. El PM solo sale si falta el flag de primer contacto: `snapshot` lo avisa (`94178e8`) y en HUB y bot el flag está presente. | `75c167ba` |
| Variables de entorno de presentación y traza | **no-afecta** | `OASIS_MOBILE` (tema móvil) y `OASIS_DEBUG` (más traza) ganan usos; ningún compose las define. | `a1e497a4` `de57c9fd` |
| Defaults de configuración | **no-afecta** | En `oasis-config.json` solo cambia el salto de línea final. Las copias de HUB y bot se regeneran igualmente (`regen-node-configs.js`). | `0d42df26` `2491ca0e` |
| Suite de tests de upstream | **no-afecta** | Upstream amplía `test/` (clearnet, banking, request-guards). El fork no la importa; queda como candidata a gate (seguimiento). | `253e341f` `597d595e` `6e190918` `eb0d23c5` `57190f53` `dcf51c20` `bdadcc72` `8a63bdf4` `2d02a331` `aedb6787` `4e783380` `ee7baa31` `807d2a51` `d6e17003` `6b44ae2e` `88e2b2f3` |

## 4. Qué viaja al host (WP-O114)

| Qué | Destino en el host | Cómo | Cuándo |
|---|---|---|---|
| `src/` (de `main`) | `src` en la raíz del repo del host | `git archive` → `src.new` → `mv` (UPGRADE §4) | paso 4 |
| `pub/config/hub/nginx.conf.template` | `config/hub/` | in place + `nginx -t` + **recrear** `hub-cache` | paso 5 (inocuo en 1.1.4: medido) |
| `pub/config/hub/oasis-config.json` | `config/hub/` | in place + recrear el HUB | paso 8 |
| `pub/config/wallet-bot/oasis-config.json.tpl` **y** `pub/scripts/render-wallet-bot-config.sh` | `config/wallet-bot/`, `scripts/` | los dos juntos (el host tiene versiones de antes de `27a1689`, con `walletPub`), re-render con `.env.prod`, recrear el bot | paso 9 |
| `pub/site/hub/index.html` (Sala 04) | sitio | `deploy-site.sh`, fusionando los valores vivos | tras el paso 8 |
| `.dockerignore` del host | raíz del repo del host | solo si el paso 0 confirma que deja entrar `src.old*` o `.env.prod` en la imagen | antes del build |

**No viaja**: `docker-compose.pub.yml` (el del host está editado a mano y no cambia en este ciclo),
`Caddyfile` (igual que `HEAD`), `Dockerfile` y `docker-entrypoint.sh` (el host conserva los suyos;
por eso el humo de la imagen se hace allí).

**Para decidir en el GO**: el idioma por defecto del visor (`language`, hoy `en`; propuesta `es`).

## 5. Gates locales

Identidades desechables; stack `pub/docker-compose.pub.yml` + `pub/.env.local`; el stack local no
tiene pares fuera de la máquina (el log del pub solo muestra a su HUB y a su bot).

| Gate | Comando | Salida |
|---|---|---|
| U0 | `hub-wallet.sh --local on --yes` sobre 1.1.4 · `backup pre1110` · `snapshot pre` | tres nodos `v1.1.4` healthy; `seq` = registros = `sbot` (5, 6, 15); motor `pub=true`; épocas `2026-09,2026-10` |
| U1 | invariantes de §2 · `annex` · `--check` | 6 ficheros · 28 `ok`, 0 `!` · 0 IDs sin disponer |
| U2 | `docker tag …:latest …:1.1.4-local` · `compose build oasis-pub` · humo | build limpio; `1.1.10`; `server` y `backend` arrancan sin red; 3 parches «patcheado exitosamente»; `GET /c → 200` |
| U3 | `up pub` · `up hub` · bot con `pause` → `on --yes` · `check pre --expect "pub:oasisVersion=+1 hub:oasisVersion=+1 bot:oasisVersion=+1,pubAvailability=+0..1"` | `pub v1.1.4 → v1.1.10 · Δseq=1 · oasisVersion+1 → ok` · HUB igual · bot igual (con `pubAvailability` +0) · `GATE OK` |
| U4 | plantilla nueva con el HUB aún en 1.1.4: `hub` · ya en 1.1.10: `prune-cache` · `hub --strict` | en 1.1.4: `GATE OK (con avisos)` · en 1.1.10: `/c → 200` · `MISS → HIT` · una CSP · idioma por defecto «en» con `Accept-Language` de/es/fr y con cookies · `?lang=` elige · sin cruce en 16 peticiones concurrentes · sitemap y RSS 200 con `https` · `GATE OK` |
| U5 | `snapshot u5` · `worst` · `check u5 --expect "bot:karmaScore=+0..1"` | `bot v1.1.10 · Δseq=0 · sin publicaciones → ok` (en 1.1.4 el mismo `GET /banking` publicó un cifrado) |
| U6 · bootstrap | backend efímero con cartera e identidad nueva · `GET /banking` dos veces | `wallet` 0 → **1** tras el primer GET; sigue en 1 tras el segundo |
| U6 · cliente | drill `o-sdk-drill` en 1.1.10 · `ecoin-verify` · GUI y POST por el puente · `test-ai-service.sh` | 14 PASS, 0 FAIL · `GET /banking → 200`, `wallet` 0 → 1 y sigue en 1 · `POST` con Referer → 302, sin Referer → 400 · IA: sin token 403, `ready`, contexto 4096, `POST /ai → 200` (con el modelo antiguo) |
| U6 · invite | — | no se repite: `ssb-*` sin cambios (`deps` solo trae `version`) |
| U7 | parar · `restore pre1110 --yes` · re-render · U3 otra vez | mismo delta las tres veces que se repitió |

## 6. Delta de publicación medido

| Nodo | Recrear en la misma versión (1.1.4) | Subir a 1.1.10 | Peor caso en 1.1.10 |
|---|---|---|---|
| pub | 0 | `oasisVersion` +1 | — |
| HUB | 0 al medir; **`(cifrado)` +1 un minuto después** (aviso `LARP_RULING`) | `oasisVersion` +1, sin cifrados | — |
| bot | 0 | `oasisVersion` +1; `pubAvailability` +0; `ubiAllocation` 0 | 0 (`/banking`, `/transfers`, `/shops`, `/market`, `/school`) |

En el host se espera lo mismo: `pub:oasisVersion=+1 hub:oasisVersion=+1
bot:oasisVersion=+1,pubAvailability=+0..1`. La época 2026-10 ya está abierta allí.

## 7. Hallazgos

1. **Qué eran los cifrados propios** de HUB (4), bot (1) y pub (1). El backend trae avisos
   automáticos (el «bot político», empleo, banca, recordatorios) que corren en el middleware con
   cualquier petición —también la del healthcheck— y se envían a sí mismos un PM cifrado.
   Reproducido y descifrado en local: `subject: LARP_RULING`, «Now ACADEMIA rules during this
   cycle…». Desde 1.1.10 `notifyBot` respeta `inboxMutedBots`: silenciados en los nodos de soporte,
   el invariante «ningún cifrado» de HUB §1 vuelve a ser alcanzable. **Es una decisión tomada en la
   ejecución**, reversible quitando la clave; sin ella el gate de publicación no es determinista.
2. **`GET /wallet` en un bot con el motor encendido republica la dirección.** Compara la dirección
   «actual» de la cartera con la del mapa local; cada `pubAvailability` pide una nueva, así que
   difieren y publica otro `wallet`. Lo paró el gate U5 en 1.1.10; repetido sobre 1.1.4, **hace lo
   mismo**: no es una regresión, es una trampa que nadie conocía. En el host nadie abre esa
   página (el bot no tiene ruta pública), pero un operador sí podría. AGENTES §4, ECOIN §9.
3. **En 1.1.10 el primer `GET /banking` de un nodo con cartera publica la dirección.** `ECOIN §3`
   decía «no la publica» y mandaba un `POST` después: en 1.1.10 serían dos mensajes. Reescrito
   como «contar → actuar solo si 0».
4. **El modelo de IA cambia bajo el mismo nombre de fichero.** Upstream pasa de Llama-2 7B (3,8 GB)
   a Qwen2.5-3B (2,1 GB, 29 idiomas) conservando `oasis-42-1-chat.Q4_K_M.gguf`, y añade un modelo
   de embeddings (`src/AI/embeddings/onnx/`, ~60 MB) para la búsqueda semántica. Lo delató
   `install.sh` en la sección `outside`. Medido: el servicio de 1.1.10 **funciona con el modelo
   antiguo**, y sin embeddings la búsqueda semántica se desactiva sola (`embedder.js`). El cliente
   real puede subir sin descargar nada; cambiar de modelo es una mejora aparte.
5. **El entrypoint solo enlaza el modelo si no se salta la IA**: con `OASIS_SKIP_AI_MODEL=true` no
   crea `src/AI/<fichero>` y el servicio dice `model_missing` aunque el modelo esté en
   `src/AI/models/`. 1.1.10 admite `OASIS_AI_MODEL` con la ruta: candidato a sustituir el enlace.
6. **`hub-wallet.sh ready` da por bueno un backup local de la cartera del drill** para encender el
   motor del host: solo mira que la carpeta más reciente de `devops/backups/ecoin/` tenga menos de
   24 h. En WP-O114 el backup del host se hace explícitamente antes (paso 1).
7. **El host tiene versiones viejas de la plantilla del bot y de su script de render** (anteriores a
   `27a1689`): viajan los dos juntos.
8. **Sugerencias para upstream**: falta `Vary: Accept-Language` en `/c`; el idioma es una variable
   global del proceso (no se observó cruce en 16 peticiones concurrentes, pero el diseño lo
   permite); `GET /wallet` republica la dirección; los avisos a uno mismo en un nodo `--public`.

## 8. Correcciones al protocolo que devolvió la ejecución

1. El preflight avisaba «árbol no limpio» por un fichero sin seguimiento (`94178e8`).
2. La foto no decía el modo de cada nodo ni avisaba de un flag de primer contacto ausente (`94178e8`).
3. El gate del visor no comprobaba la CSP ni podía probar el `https` del sitemap en local (`94178e8`).
4. **El gate medía demasiado pronto.** La prueba «misma imagen → delta 0» de WP-O112 fue verde y el
   HUB publicó un cifrado 60 s después. `up` espera 90 s con una petición en medio; en el host, el
   `check` que cuenta es el de al menos 5 minutos después (`9010bbb`).
5. **El diff no veía las rutas con comillas simples**: 15 rutas nuevas, no 4 (`8a7e3fb`).
6. Las copias de config se regeneran con un script, no a mano (`5ed82d2`).
7. `(cifrado)` entra en el delta declarado como «debe ser 0» (`9010bbb`).
8. Caché negativa: `prune-cache` **antes** del gate estricto del visor (`e6b2b5d`).
9. `restore` repone también la config renderizada vieja del bot: re-render tras restaurar (`e6b2b5d`).
10. `/wallet` sale del peor caso por defecto, con el motivo escrito en el script (`e6b2b5d`).
11. El humo de la imagen tiene ya su comando literal (`e6b2b5d`).

## 9. No medido / pendiente

- **El host**: todo WP-O114. Incluye la hipótesis de `.env.prod` y `src.old` dentro de la imagen.
- **El cliente real** (identidad del custodio): solo se ha ensayado el drill.
- **El modelo de IA nuevo y los embeddings**: no se han descargado ni probado.
- **La GPU**: `ai_service.mjs` de 1.1.10 carga con `gpu: false`; el compose del cliente reserva una
  GPU que ya no se usa. Sin tocar.
- **Cruce de idiomas**: 16 peticiones concurrentes sin cruce no prueban que no pueda ocurrir.
- La suite `test/` de upstream como gate.

## 10. Seguimiento

- **WP-O114**: aplicación en el host con GO en cada puerta (UPGRADE §4).
- Estado local al cerrar: stack del pub en 1.1.10 con el motor encendido (`pub/.env.local` apunta a
  `ssb-config.engine-on`, como el host); copia de la línea base en `volumes-dev/.gates/pre1110`;
  imagen de rollback `oasis-pub-scriptorium:1.1.4-local`.
