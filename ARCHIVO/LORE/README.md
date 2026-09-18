# ARCHIVO/LORE — tu lore, dentro del repo y fuera de git

Un **lore** es la materia prima personal de una obra del Teatro: los exports de tus cuentas en
redes sociales y lo que se recupera alrededor de ellos (voces ajenas, páginas enlazadas). Vive
aquí para que el protocolo sea **autocontenido en o-sdk**: clonas el repo, dejas tu export en esta
carpeta y los mismos comandos que generan la obra de cualquier otro generan la tuya.

> **Todo lo que hay bajo esta carpeta, salvo este README y el `.gitignore`, está ignorado por git**
> (deny-by-default) y excluido de la imagen Docker (`.dockerignore`). Un export de cuenta contiene
> IPs, teléfono, tokens de dispositivo, bloqueos y mensajes: **nunca** uses `git add -f` aquí.
> `python pub/rrss-sidecar/twitter_x/sidecar.py check --obra <obra>` falla si algo se cuela.

## Los tres territorios

| Territorio | Ruta | Git | Qué es |
|---|---|---|---|
| Infra | `pub/rrss-sidecar/<fuente>/` | ✅ | el generador y sus protocolos |
| **Lore** | **`ARCHIVO/LORE/<fuente>/<obra>/`** | solo este esqueleto | tus exports + stores no regenerables |
| Visor | `volumes-dev/teatro/<obra>/` → `/srv/oasis/teatro/<obra>/` en el VPS | ❌ | el árbol estático generado (regenerable) |

`<fuente>` hoy es `twitter_x`. El destino es que las fuentes se normalicen al formato B.O.E.
(Arrakis) de Scriptorium; la costura está descrita en `pub/rrss-sidecar/CORPUS-SCHEMA.md`.

## Layout de una obra

```
ARCHIVO/LORE/twitter_x/<obra>/
  obra.json                 config de la obra; solo rutas RELATIVAS a esta carpeta (el lore es portable)
  exports/<AAAA-MM-DD>/     un export oficial descomprimido por generación (data/, assets/, Your archive.html)
  legacy/                   stores de un pipeline anterior, si los hubiera
  store/                    posts.json · generations.json · external_tweets.v2.json · external_worklist.json
                            links_store.json · links_browser_queue.json · links_blocked.json
  cache/voices/             respuestas crudas de las voces ajenas
  cache/links/              <hash>.md (markdown íntegro) y crudos de las páginas enlazadas
  cache/media_ext/          foto/póster de tuits de terceros
```

## Empezar con tu propio lore

1. Pide tu archivo en X (*Configuración → Tu cuenta → Descargar un archivo de tus datos*) y
   descomprímelo donde quieras.
2. Tráelo al repo (copia verificada; el origen no se toca):

   ```bash
   npm run teatro:lore:import -- --obra mi-obra --from "C:/Descargas/twitter-2026-06-30-…"
   npm run teatro:init        -- --obra mi-obra --title "Mi Obra"
   ```
3. Sigue `pub/rrss-sidecar/twitter_x/README.md` (ingest → voces → enlaces → build → deploy).

Cada export nuevo es una **generación**: impórtalo igual y vuelve a ejecutar `ingest`. El store es
aditivo; lo que borraste entre generaciones se conserva aquí como capa histórica y no se publica.

## Qué respaldar

- **Tus exports** (`exports/`): son tuyos y solo tuyos; guarda también los `.zip` originales fuera de
  esta máquina. El repo no hace copia de ellos.
- **Los stores** (`store/`) y `cache/links/`: no son regenerables — el contenido de terceros y los
  shares de agentes desaparecen con el tiempo. `devops/scripts/backup-teatro.sh` los empaqueta.
- El árbol del visor **no** hace falta respaldarlo: se regenera con `sidecar.py build`.
