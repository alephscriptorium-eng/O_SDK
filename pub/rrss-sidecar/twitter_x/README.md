# twitter_x — tu export de X como obra del Teatro

Guía para **cualquier usuario** de o-sdk. Necesitas: este repo, Python ≥ 3.10 (solo biblioteca
estándar) y tu archivo de X. Para publicar en un VPS, además, el stack del pub (`pub/`) y WSL o
Linux con `rsync`. Los comandos se dan con `npm run …`; equivalen a
`python pub/rrss-sidecar/twitter_x/sidecar.py <subcomando>`.

> Tu lore vive en `ARCHIVO/LORE/twitter_x/<obra>/` (ignorado por git). Lee antes
> `ARCHIVO/LORE/README.md`: ahí hay datos personales que **no** deben salir de esa carpeta.

## 1. Trae tu export

```bash
npm run teatro:lore:import -- --obra mi-obra --from "C:/Descargas/twitter-AAAA-MM-DD-…"   # descomprimido
npm run teatro:init        -- --obra mi-obra --title "Mi Obra"
```

`lore-import` lee la fecha de `data/manifest.js`, copia a `exports/<fecha>/` y verifica recuento,
bytes y sha256. `init` escribe `obra.json` (cuenta, handle, título, base `/teatro/mi-obra`) desde el
manifest. Edita `obra.json` para declarar tus dominios en `own_hosts`, el sello (`stamp`) o el
lema (`tagline`). Plantilla: `obra.example.json`.

Cada export posterior es una **generación** nueva: repite `lore-import` y continúa desde el paso 2.

## 2. Ingesta (store aditivo)

```bash
npm run teatro:ingest -- --obra mi-obra
```

Une todas las generaciones por id. Lo que borraste entre exports queda en `store/posts.json` con
`deleted: true` y **no se publica** (`publish.deleted_posts: "hidden"`). Soporta archivos partidos
(`tweets-part1.js`…).

## 3. Protocolo (a) — voces ajenas a uno y dos niveles

El export trunca los RT y no trae ni el padre de una réplica ni el tuit citado (la cita es solo una
URL). Se recuperan de fuera, sin autenticación:

```bash
npm run teatro:fetch:voices -- --obra mi-obra             # solo planifica: cuántas faltan
npm run teatro:fetch:voices -- --obra mi-obra --run       # nivel 1; el nivel 2 llega embebido
npm run teatro:fetch:voices -- --obra mi-obra --media     # foto/póster de terceros (≤600 KB) en local
```

- Nivel 1: original de cada RT, padre de cada réplica a terceros, cada tuit citado.
- Nivel 2: el padre y el citado **de** esa voz; vienen en la misma respuesta, sin peticiones extra.
- Fuente `cdn.syndication.twimg.com/tweet-result`; segunda opinión `api.fxtwitter.com`. Ninguna está
  documentada oficialmente: el crudo se cachea en `cache/voices/` y el proceso es reanudable.
- Lo no recuperable queda `unavailable`. **Nunca se inventa texto.** `--retry-unavailable` reintenta.
- `--migrate` importa un store antiguo dejado en `legacy/` sin perder ningún texto.

## 4. Protocolo (b) — cada enlace externo a Markdown

```bash
npm run teatro:fetch:links -- --obra mi-obra              # clasifica por familia
npm run teatro:fetch:links -- --obra mi-obra --run        # descarga; --family agent limita la tanda
```

| Familia | Cómo |
|---|---|
| `agent:chatgpt` | JSON público del share → secciones `## Usuario` / `## Asistente` |
| `agent:deepseek` | vía el proxy de lectura `r.jina.ai` (un tercero ve la URL, que ya es pública) |
| `agent:grok`, `agent:claude`, `agent:perplexity`, `agent:gemini` | **cola de navegador** (abajo) |
| `github:*` | API de GitHub y `raw.githubusercontent.com` (`GITHUB_TOKEN` o `gh auth token` evita el límite de 60/h) |
| `video:*` | solo metadatos y subtítulos si existen; no se descarga vídeo |
| `own`, `generic` | HTML → Markdown con `lib/html2md.py` (stdlib) |

Se publica el **Markdown íntegro** de cada página en `corpus/links/` y en la puerta «Enlaces» del
visor. Es una decisión editorial de cada obra: si no quieres republicar páginas de terceros, no
ejecutes las familias `generic`/`video`.

### Tanda de navegador

Algunas páginas solo se renderizan en un navegador real. Quedan en `store/links_browser_queue.json` y
las procesa un agente con la extensión **Claude in Chrome** sobre tu sesión:

```bash
python pub/rrss-sidecar/twitter_x/sidecar.py browser-next --obra mi-obra     # → {hash, url, family}
#   el agente abre la URL, espera el render y extrae el texto de la conversación SIN resumir
python pub/rrss-sidecar/twitter_x/sidecar.py browser-save --obra mi-obra --hash <h> --title "…" --md-file conv.md
```

### Enlaces que no se descargan, metadatos y URL pública

- **`link_only_hosts`** en `obra.json` (coincidencia exacta de host, p. ej. `["miblog.example"]`): esos
  enlaces **se quedan como enlace**, nunca se descargan ni se reintentan. Útil para tu propio blog si
  prefieres que la obra apunte a él. Lo ya recuperado (`ok`) no se toca.
- `sidecar.py link-mark --obra <obra> --hash <h> --status gone|link_only|pending --note "…"`: marcado
  manual de un enlace **no-agente** (página que ya no existe, sitio caído).
- `sidecar.py link-mark … --status link_only --waived-by <custodio>`: única vía para dejar como enlace un
  share de **agente** sin rescatarlo: es una dispensa expresa del custodio y queda anotada (`waived_by`).
- `sidecar.py browser-save … --meta`: para páginas de vídeo de las que solo se guardan metadatos
  (título, descripción). Nunca para `agent:*`.
- `sidecar.py link-public-url --obra <obra> --hash <h> --url <nueva>`: si republicas un share con otra
  URL (p. ej. un artifact), se anota junto a la original y el visor enlaza ambas.

### REGLA PARAR

Las conversaciones con agentes se compartieron como públicas. Si una responde con login,
«private», «not found» o vacío, **no se salta**: se anota en `store/links_blocked.json`, la tanda
termina con código **3** y `build` se niega a continuar. Hazla pública y relanza con `--retry`. La
única excepción es una dispensa escrita a mano (`waived_by`, `waived_at`, `reason`) en ese fichero.

## 5. Build y comprobación

```bash
npm run teatro:build -- --obra mi-obra      # corpus + sitio + visor + guardas → volumes-dev/teatro/mi-obra/
npm run teatro:check -- --obra mi-obra
npm run pub:local:up                        # previsualiza en http://localhost:8088/teatro/mi-obra/
```

Invariantes (`lib/guards.py`): solo la whitelist de `data/`; ningún `.js` salvo el visor; ningún
`<script>` salvo en `navegador.html` (**excepción declarada**: es el visor oficial de X, limpiado y
sin CDNs; desactívalo con `publish.viewer: false`); ningún recurso externo cargado; ningún nombre de
fichero sensible; ni tu email ni tu teléfono en ninguna página.

## 6. La puerta semántica (opcional, curada por ti)

Todo lo anterior es mecánico. Si quieres que la obra se explique —qué ideas sostiene, dónde nace cada
una, qué posts las cuentan mejor— añade la **capa curada** en tu lore:

```bash
npm run teatro:editorial:init  -- --obra mi-obra     # esqueleto en ARCHIVO/LORE/…/mi-obra/editorial/
npm run teatro:editorial:check -- --obra mi-obra -v  # ids, ficheros, citas literales, cobertura
npm run teatro:editorial:delta -- --obra mi-obra     # tras un export nuevo: qué falta por curar
```

Genera las puertas «El sistema» (territorios → constructos) y «El cantar» (una obra derivada: disco,
serie de vídeos…), una portada SVG y chips «curado en» en cada post. Curado y mecánico nunca se
mezclan, y una cita que no sea literal detiene el build. Guía completa:
`docs/PUB/TEATRO-CURADURIA-PROTOCOL.md`.

## 7. Publicar

`docs/PUB/TEATRO-PROTOCOL.md`: alta en el catálogo y `TEATRO_OBRA=mi-obra npm run devops:teatro:deploy`.
La descarga destacada es el **zip con todo**; el zip ligero y `MANIFEST.sha256` son para inspección.

## Piezas

| Fichero | Papel |
|---|---|
| `sidecar.py` | CLI |
| `lib/obra.py` | `obra.json`, rutas del lore, manifest |
| `lib/ytd.py`, `lib/normalize.py` | **lo único que conoce el formato de X** (costura B.O.E.: `../CORPUS-SCHEMA.md`) |
| `lib/store.py` | store aditivo multi-generación |
| `lib/voices.py`, `lib/links.py`, `lib/html2md.py` | protocolos (a) y (b) |
| `lib/editorial.py`, `editorial.example/` | capa curada: puerta semántica declarada en el lore |
| `lib/guards.py` | invariantes de publicación |
| `tools/build_corpus.py`, `tools/build_site.py`, `tools/build_viewer.py` | generadores |
| `patches/*.json` | parches declarativos del visor (se aplican solo si el sha256 del bundle coincide) |
| `templates/obra.css`, `AGENTS.md` | piel y protocolo para agentes (plantilla por obra) |
| `tests/` | `npm run teatro:test` sobre un export sintético |
