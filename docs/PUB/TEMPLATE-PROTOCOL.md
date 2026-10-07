# Protocolo de plantilla · del organigrama de un colectivo a la infraestructura de su pub

> **Estado · EN OBRAS 2026-10-07** (WP-O129, rama `dev/retro-exporter`). Hoy existe la vía **guion**
> (`pub/tools/template-seed.js --guion`); las vías **fría** (WP-O130) y **caliente** (WP-O131) tienen
> aquí su contrato y aún no su código. Demo: Acampada26S, `ARCHIVO/DISCO/retro-exporter/`.

Método para convertir lo que un colectivo ya tiene en papel (asambleas, nodos, comisiones, canales,
métodos de decisión) en objetos de Oasis 1.2.3 (tribus, salas, calendarios, listas, wikis, mapas,
convenciones de voto) y **activarlo en un pub** sin publicar nada que nadie haya pedido. Es genérico:
sirve a cualquier colectivo y a cualquier pub; la instancia que lo ejercita es Acampada26S
(`acampada26s.net`, Oasis 1.2.3 upstream).

> **Modelo mental.** Una *plantilla* no son datos de prueba ni un snapshot: es **estructura**. Se
> genera una vez a partir del organigrama, se revisa con el colectivo y se activa por una de tres
> vías. Lo que se activa en un pub vivo es **permanente** (`AGENTES.md` §3): por eso el guion humano
> es la vía por defecto, y las automáticas piden permiso por bloque y nunca publican con la identidad
> del pub.

## 0. Qué es una plantilla y qué no

| Es | No es |
|---|---|
| Un JSON (`pub/templates/<org>.json`, contrato en [`pub/templates/SCHEMA.md`](../../pub/templates/SCHEMA.md)) con tribus, salas, calendarios, eventos, listas, wikis, mapas y convenciones | Contenido de prueba (`test/seed.js` de upstream llena un directorio de mentira; esto llena uno de verdad con lo que el colectivo decidió) |
| Trazable: cada entrada lleva `origen` = `id` del organigrama | Un snapshot `.oasissn` (`HUB-PROTOCOL.md` §13): aquello replica mensajes ya publicados; esto los crea |
| Sin fechas absolutas (`offsetDays`) y **sin secretos** | Un `.ssb` para copiar (las identidades nacen en destino, ley 4) |

## 1. Entrada: el organigrama

Contrato mínimo del JSON de entrada (el de Acampada: `ARCHIVO/DISCO/retro-exporter/entrada/acampada26s_organigrama.json`):

- `organos[]` con `id`, `nombre`, `tipo` (`asamblea`, `grupo_de_asambleas`, `comision`, `base`, …), `funciones[]`,
  `periodicidad`/`hora`/`lugar` si se reúne, `miembros[]` (con `id`) si agrupa, `subgrupos` si tiene canales.
- `relaciones[]` con `origen`, `destino`, `direccion`, `sentido` (`ascendente`/`descendente`).
- `flujo_de_decision` (`ascendente[]`, `descendente[]`, `secuencia_diaria[]`).
- `metodos_y_conceptos[]` con `id` y `aplicado_en`.

Se transcribe de lo que el colectivo publica (imagen, texto); lo que no esté, no se inventa
(`<pendiente: …>`).

## 2. Mapeo: cinco reglas

| Regla | De → a | Modelo |
|---|---|---|
| R1 | órgano → **tribu** (pública si es abierta; privada y estricta si es de portavocías); agrupación → sub-tribus | `createTribe(..., parentTribeId)` |
| R2 | reunión periódica → **calendario** con intervalo + **sala** | `createCalendar`/`addDate`, `createRoom` |
| R3 | método de decisión → **convención** sobre un módulo (semáforo = `votes` con 3 opciones) | `createVote(q, deadline, options)` |
| R4 | canal externo (Telegram, lista) → **sub-tribu** o **lista de correo** | `createTribe(parent)`, `createList` |
| R5 | espacio externo (otros colectivos) → **federación de pubs** + tribu de enlace + lista cifrada | `follow`/`announce`, `createList({CLOSED})` |

Lo que SSB no modela y se deja explícito en la plantilla: **jerarquía** (no hay órganos «encima»;
hay autores y claves → `meta.autoria` es DECISIÓN del colectivo), **workflow** (ajuste local de cada
cliente, `src/models/workflows_model.js:111-118`; el pub no puede imponerlo → va al guion),
**recurrencia diaria** (solo semanal/mensual/anual → 7 fechas semanales), **roles sin voto** (todo
miembro vota en su tribu → las ratificaciones se votan fuera de la tribu de portavocías). Tabla
completa en el mapeo de la demo: `ARCHIVO/DISCO/retro-exporter/MAPEO.md` §2.

## 3. Plantilla

Formato y firma de modelo de cada campo: [`pub/templates/SCHEMA.md`](../../pub/templates/SCHEMA.md).
Dos reglas que no se negocian: **sin fechas absolutas** y **sin secretos** (ni `secret`, ni códigos de
invitación, ni carteras). Lo no decidido va como `<pendiente: …>` y la herramienta lo lista al final.

Validación: `node pub/tools/template-seed.js --template <json> --organigrama <entrada> --guion`
termina con exit 0 y todos los `origen` resueltos; cada firma citada en SCHEMA existe en
`src/models/*` de la versión declarada en `meta.version_oasis` (al subir de versión: `grep` antes).

## 4. Activación

### 4.1 Las tres vías

| Vía | Qué hace | Dónde | Reversible | Estado |
|---|---|---|---|---|
| **Guion** (`--guion`) | emite un markdown paso a paso: menú de la UI, campos, quién lo crea; incluye lo que no se automatiza (workflow por cliente, invite de asamblea, federación) | cualquier Node, sin SSB | no publica nada | **disponible** (WP-O129) |
| **Fría** (`--cold`) | siembra con el sbot embebido (`src/client/gui.js`, como `test/seed.js:17-22` de upstream) en un `ssb_path` aislado con la red pausada | contenedor (`src/server/node_modules` es un enlace que solo existe en la imagen) | sí: se borra el directorio | contrato aquí; código en WP-O130 |
| **Caliente** (`--hot`) | siembra desde una identidad **«secretaría»**: sbot propio (patrón bots de soporte, `HUB-PROTOCOL.md` §3 y §11) que redime un invite del pub y publica como ella; el seeder corre dentro por su socket | host del pub, contenedor o segundo sbot (`ssb_path=<dir> node src/server/SSB_server.js start` en una instalación upstream) | el feed de la secretaría se puede dejar de seguir o bloquear; lo publicado no desaparece | contrato aquí; código en WP-O131 |

**Descartado y por qué**: publicar desde una «identidad proxy» por el socket del pub. Los modelos
publican siempre como la identidad del sbot (`tribes_model.js:318`, `rooms_model.js:418`), el token de
las salas se firma con sus claves (`phone_module.js:1262`), `add` no está en el manifest top-level
(`ssb-db2/compat/db.js:11-15`) y `db.create({keys})` pasaría una clave privada por el socket (ley 4).
Publicar como el pub mismo también se descarta: todas las tribus serían del pub y sus claves quedarían
en un nodo que solo replica.

### 4.2 Qué vía en cada escenario

| Escenario | Vía | Permisos (cada uno expreso, cada vez) |
|---|---|---|
| Ensayo, formación de la mesa técnica, capturas para presentar | fría | ninguno |
| Pub nuevo, antes de `announce` | fría sobre el `ssb_path` definitivo con la red pausada; luego se anuncia | tribus, `about` |
| Pub vivo, autoría humana (hoy Acampada) | **guion** | los que ejerza cada persona desde su UI |
| Pub vivo, autoría delegable a un bot | caliente | `about` de la secretaría, invite redimida, cada bloque de tribus |

### 4.3 Contrato de la herramienta

```
node pub/tools/template-seed.js --template <json> (--guion | --cold | --hot | --verify)
     [--organigrama <json>] [--out <md>] [--yes <bloque>]... [--ledger <dir>]
```

- **Dry-run por defecto** en `--cold` y `--hot`: lista las llamadas y el número de mensajes previstos
  por bloque; solo publica el bloque que lleve su `--yes`. Bloques, en este orden: `tribes` →
  `subtribes` → `invites` → `rooms` → `calendars` → `events` → `mailing` → `wiki` → `maps`.
  `votes`, `emergencies`, `courts` y `federation` son convenciones: solo guion.
- **Gates**: `--cold` para si `ssb_path` es `~/.ssb` o `OASIS_NETWORK_PAUSED` ≠ `1`; `--hot` para si
  `whoami` = id del pub (de la ficha de instancia) — nunca con la identidad del pub.
- **Evidencia**: antes y después de cada bloque, `createUserStream({id, reverse:true, limit:1}).value.sequence`
  y recuento por tipo (`messagesByType` filtrado por autor); la salida es JSON y va al reporte del WP.
- **Ledger** `<keysDir>/plantilla-<id>.json` (entidad → clave de mensaje): reejecutar salta lo hecho;
  las wikis ya son idempotentes por slug (`wiki_model.js:298-300`).
- **Trampas conocidas**: el stream vivo de tribus obliga a `process.exit`; salas sin pub conectado quedan
  sin centralita (`rooms_model.js:339-345`); `parliament` exige legislatura activa; eventos y
  calendarios exigen fecha futura; votaciones ≥ 7 días.
- **Secretaría** (`--hot`): servicio clon de `oasis-wallet-bot` (`pub/docker-compose.pub.yml`) con
  `command: ["server"]` (sin HTTP: no publica avisos solos), `pub: false`, volumen propio; fila en la
  ficha de instancia (§3-§4 de `INSTANCIA-PLANTILLA.md`), `about` aprobado literal (HUB §12). Las
  claves de tribu quedan en su keyring: quién lo custodia es DECISIÓN del colectivo.

## 5. Verificación tras activar

- Recuento por tipo en el visor público: `/c/sitemap.xml` y `/c/rss/<módulo>` (tribus públicas,
  calendarios, salas, mapas y eventos marcados `clearnetPublic` aparecen; las tribus privadas no).
- `./oasis.sh status` (pares) y, si hubo secretaría, su `sequence` subiendo en el pub
  (`pub/tools/ssb-probe.js`).
- Las tribus con invitación abierta muestran código y QR en su tarjeta; **el código no se copia a
  ningún documento**.
- El feed del pub no ha cambiado: mismo `sequence` antes y después (si cambió, parada dura).

## 6. Lo irreversible y lo que la plantilla nunca lleva

Tabla completa en [`AGENTES.md` §3](../AGENTES.md). Para este protocolo: cada tribu, sub-tribu, sala,
calendario, lista, wiki y mapa es un mensaje permanente; cada invitación abierta también; `about`,
`contact` (follow entre pubs) e invite redimida piden PERMISO cada vez. La plantilla nunca contiene
`secret`, códigos de invitación con semilla, direcciones de cartera ni datos de otra instancia.

## 7. Addenda-roadmap

Módulos fuera del workflow elegido que resolverían algo del organigrama: `addenda[]` en la plantilla,
§3 del mapeo de la demo. Encenderlos es un clic por cliente (Settings → Modules); el protocolo no los
activa, los señala.

## 8. Registro

| Fecha | Qué | Dónde |
|---|---|---|
| 2026-10-07 | Primera plantilla (Acampada26S), guion generado, vías fría y caliente con contrato | WP-O129, `ARCHIVO/DISCO/retro-exporter/` |
