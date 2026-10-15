# WP-O144 · Restos del host tras WP-O143 (y un byte invisible en el entrypoint)

Rama `wp/O144-restos-host` desde `main` eb72c330. 2026-10-15. Sin cambio de versión (1.3.0). Sin rebuild: la imagen
`8639c5f9…` que corre lleva la variante del entrypoint con el `\r` literal, funcionalmente idéntica; el próximo ciclo
la reconstruye.

## 1. Estado de partida

`deploy-status` tras WP-O143: pub en «IMAGEN VIEJA» (corría `e561a64f…`, `latest` = `8639c5f9…`); `tools/ssb-admin.js`
del host «DISTINTO y fuera de la historia» (contenido igual al repo salvo fines de línea: el blob raw `9d0d3472…`;
la copia traída por `ssh` sí daba un blob histórico, lo que engañó a mi primera precondición y el guion paró, bien);
`docker-entrypoint.sh` con un `\r` literal dentro de las comillas de un `tr -d` (l.393-394), que una tubería que filtre
CR convierte en un no-op (WP-O143 §5).

## 2. Entregado

| Commit | Pieza |
|---|---|
| dfc86d28 | `fix(entrypoint)`: `tr -d ' \n\r'` con escapes; 0 CR en el fichero (medido: `{ }⏎␍` → `{}`) |
| (este) | reporte, backlog, CHANGELOG |

## 3. Host (17:37-17:45Z)

| Paso | Hecho |
|---|---|
| foto | `snapshot pre144` |
| a | `tools/ssb-admin.js`: precondición «contenido sin CR = HEAD sin CR» ✓ → `.bak-o144-2026-10-15` → blob de HEAD tal cual → sha = HEAD ✓ |
| b | `docker-entrypoint.sh`: vivo = blob de O143 (`9a13be08…`) ✓ → `.bak` → blob de HEAD (`73f7a1da…`), CR 0, ejecutable ✓ |
| c | `up -d --no-deps --no-build oasis-pub` → `healthy` a los 4 s, imagen `8639c5f9…`, `Version: 1.3.0`, tres parches |
| check | `check pre144 --wait --expect 0` → **`GATE OK` (316 s)**: Δ0 en los tres; `hub connected(out)`, `bot connected(in)`. Tras recrear el pub, el enlace con el bot lo abrió **el pub** (`in` visto desde el bot) aunque su libreta tiene al bot sin `autoconnect`: `ssb-conn` también marca a pares conocidos al arrancar por otras vías (gossip, `conn.json` con `type: pub`). Observación, no desviación: `pub_link` mide por clave y el enlace existe |
| cierre | `deploy-status`: los tres nodos «imagen al día»; LINK `connected` ×2; deriva solo `.dockerignore` (esperada, E0); VERDE; `capacity` 0 |

Delta: ninguno. Nada publicado.

## 4. Correcciones al protocolo

- Precondición de convergencia de un fichero que el host guarda con otro fin de línea: comparar **contenido sin CR**
  frente a HEAD sin CR, no el sha raw ni el sha de la copia traída por `ssh` (que normaliza). UPGRADE §4 paso 1 ya
  dice «sha del vivo = blob del repo»; se añade la variante «o igual salvo fines de línea → se escribe el blob de HEAD».

## 5. Seguimiento

- Quién abre el enlace pub↔bot tras recrear el pub (el bot lo ve `in`): leer `[pub-link]` del bot y la libreta del pub
  cuando se mire WP-O143 pasado un día.
- `.dockerignore` del host: deriva esperada hasta E0.
