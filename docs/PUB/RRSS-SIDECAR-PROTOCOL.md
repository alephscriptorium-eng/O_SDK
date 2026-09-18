# Protocolo del sidecar de RRSS (de un export de x.com a una obra del Teatro)

> **Este repo es el sitio del sidecar** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). Código en `pub/rrss-sidecar/`, lore en
> `ARCHIVO/LORE/`, salida en `volumes-dev/teatro/`. Publicación: [`TEATRO-PROTOCOL.md`](./TEATRO-PROTOCOL.md).

> **Estado · ACTIVO 2026-09-18** (WP-O99, asiento D-O16). Única fuente: `twitter_x`. Primera obra:
> «Aleph Cero» (3 generaciones de export, 1940 posts visibles). Guía de usuario paso a paso:
> `pub/rrss-sidecar/twitter_x/README.md`. Contrato del corpus: `pub/rrss-sidecar/CORPUS-SCHEMA.md`.

Checklist operativo para **construir o actualizar una obra** desde el archivo de una cuenta de X,
**recuperar las voces ajenas** que el archivo no trae y **traer a Markdown las páginas enlazadas**.

> **Modelo mental.** Tres territorios, una sola casa. **Infra** en git (`pub/rrss-sidecar/<fuente>/`);
> **lore** dentro del repo pero fuera de git (`ARCHIVO/LORE/<fuente>/<obra>/`: exports del usuario
> y stores no regenerables); **visor** generado (`volumes-dev/teatro/<obra>/`). El protocolo es
> **autocontenido**: ningún comando apunta fuera de o-sdk, y la obra del custodio es un caso
> contingente. La costura `fuente → corpus normalizado → visor` deja sitio a un adaptador
> **B.O.E. (Arrakis)** cuando los orígenes se parseen a ese formato.

## 0. Estado

```bash
ls ARCHIVO/LORE/twitter_x/                              # obras con lore en esta máquina
cat ARCHIVO/LORE/twitter_x/<obra>/store/generations.json # generaciones integradas
npm run teatro:fetch:voices -- --obra <obra>             # worklist de voces y cuántas faltan (no descarga)
npm run teatro:fetch:links  -- --obra <obra>             # enlaces por familia y estado (no descarga)
git ls-files ARCHIVO/LORE                                # debe ser SOLO README.md y .gitignore
```

## 1. Generación nueva (un export nuevo)

```bash
npm run teatro:lore:import -- --obra <obra> --from "<dir del export descomprimido>"
npm run teatro:ingest      -- --obra <obra>
```

Copia verificada (recuento, bytes, sha256); el origen no se toca. El store es **aditivo**: los posts
borrados entre generaciones quedan en `store/posts.json` (`deleted: true`) y no se publican.

## 2. Protocolo (a) — voces ajenas a uno y dos niveles

```bash
npm run teatro:fetch:voices -- --obra <obra> --run      # + --migrate la primera vez si hay legacy/
npm run teatro:fetch:voices -- --obra <obra> --media
```

| Rama | De dónde sale | Nivel |
|---|---|---|
| `retweets` | el RT (el archivo lo trunca) → su original | 1 |
| `parents` | `in_reply_to_status_id` de una réplica a terceros | 1 |
| `quotes` | URL de status en `entities.urls` (el archivo **no** trae `quoted_status`) | 1 |
| — | `parent` y `quoted_tweet` embebidos en la respuesta de una voz de nivel 1 | 2 |

Medido en «Aleph Cero» (2026-09-18): 662 ids de nivel 1 → 635 `ok`, 18 `unavailable`, 0 `error`;
230 nodos de nivel 2 sin una sola petición extra; 653 peticiones en ~10 min. Endpoints sin
documentar (`tweet-result`, fallback `fxtwitter`): crudo en `cache/voices/`, reanudable, y cuanto
antes se lance menos se pierde (los tuits se borran).

## 3. Protocolo (b) — enlaces externos a Markdown

```bash
npm run teatro:fetch:links -- --obra <obra> --run                 # todo lo que no exige navegador
npm run teatro:fetch:links -- --obra <obra> --run --family agent  # solo conversaciones con agentes
```

Familias y método: `pub/rrss-sidecar/twitter_x/README.md` §4. Se publica el **Markdown íntegro**
(decisión D-O16). `chatgpt.com` responde 403 de forma intermitente (anti-bot, no «privado»): el
fetcher reintenta y, si persiste, manda la URL a la cola de navegador.

### 3.1 Tanda de navegador (agente + Claude in Chrome)

Para `agent:grok`, `agent:claude`, `agent:perplexity`, `agent:gemini` y lo que un fetcher marque como
SPA. Sesión interactiva, con el Chrome del usuario abierto:

1. `python pub/rrss-sidecar/twitter_x/sidecar.py browser-next --obra <obra>` → `{hash, url, family}`.
2. Abrir la URL, esperar el render, extraer el **texto completo** de la conversación (sin resumir,
   conservando turnos y bloques de código) a un `.md` temporal fuera del repo.
3. `… browser-save --obra <obra> --hash <h> --title "<título>" --md-file <fichero>`.
4. Si la página pide login o dice que no existe: `… browser-block --obra <obra> --hash <h> --evidence "<qué se ve>"` → §3.2.

### 3.2 REGLA PARAR

Un share de agente que no es accesible **no se salta en silencio**. Queda en
`store/links_blocked.json`, la tanda sale con código **3**, `build` se niega a continuar y **se pide
al usuario que lo haga público**; después `fetch-links --run --retry`. Solo el custodio puede
dispensar una entrada (`waived_by`, `waived_at`, `reason`), y entonces se publica como «enlace no
recuperable», sin texto. Las páginas genéricas o de vídeo caídas no paran la tanda: quedan `gone`.

## 4. Build, comprobación y publicación

```bash
npm run teatro:build -- --obra <obra>
npm run teatro:check -- --obra <obra>
npm run pub:local:up          # http://localhost:8088/teatro/<obra>/
```

Después, `TEATRO-PROTOCOL.md` §2-§5 (catálogo, deploy, verificación, backup).

## 5. Hostil-omite (lo que no se puede saltar)

- El **parche multi-vídeo** del visor es declarativo (`patches/viewer-multivideo.json`) y solo se
  aplica si el sha256 del bundle stock coincide: si X cambia el bundle, el build avisa.
- La **migración del store antiguo** conserva todo texto ya recuperado aunque hoy no esté disponible.
- `git ls-files ARCHIVO/LORE` = 2 ficheros; `.dockerignore` excluye `ARCHIVO/LORE` y `pub/rrss-sidecar`.
- Ningún proceso escribe en el directorio de origen de un export.
- `data/ip-audit.js` → 404 en producción (guardas + bloque `@teatro` de Caddy).

## 6. Pendiente anotado

**Reorganización semántica de «Aleph Cero».** Este protocolo deja reunidos los datos (posts, voces a
dos niveles, conversaciones y páginas enlazadas). La nueva visión de la obra se decide **en modo
plan**, leyendo el feed hacia atrás desde el tramo final para construir el concepto de obra.
