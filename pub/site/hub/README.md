# Sala 04 · HUB clearnet — puerta estática

> Segmento público del OASIS PUB: `/hub/`. Estética del PUB (`/assets/fanzine.css`), HTML plano, cero JavaScript.

## Qué es

La sala **no contiene el HUB, lo frontea**: explica qué es `/c` (lectura pública de lo que cada
habitante marcó como Clearnet), quién lo sirve y cómo entrar o aparecer, y abre la puerta con un
`door-link` a `/c`. La vista real (`/c`, `/c/inhabitant/<feedId>`, `/c/<tipo>/<id>`, `/c/blob/<id>`)
la genera el visor de Oasis, no este directorio.

Invariantes de la puerta:

- Solo GET; nada de formularios ni scripts. `grep -c "<script" index.html` → 0.
- Sin recursos externos: solo `/assets/fanzine.css` y `/ico.png` (ambos de la landing).
- No promete nada sin opt-in: quien no activó Clearnet aparece como «not accessible».
- No expone `/qr/*` ni lo anuncia (codifica `localhost:3000`; queda fuera del proxy).
- La cuenta de soporte se nombra (`azofaifo-scriptorium-skin-bot-1`); su feed id se rellena tras el alta.

## De qué depende (operativa)

| Pieza | Dónde | Qué hace |
|---|---|---|
| `oasis-hub` | `pub/docker-compose.pub.yml` | nodo de soporte: `backend.js --public` con sbot embebido, identidad propia, hops 2 |
| `hub-cache` | `pub/docker-compose.pub.yml` + `pub/config/hub/nginx.conf.template` | caché HTTP en disco delante del HUB (`max_size`, caché negativa, POST → 405) |
| bloque `@hub` | `pub/caddy/Caddyfile` (vhost del pub) | enruta `/c`, `/c/*`, `/clearnet` y `/assets/{styles,themes,images}/*` a `hub-cache:80`; el resto del vhost es esta landing |

Si `hub-cache` cae, `/c` devuelve 502 pero `/hub/` y el resto de la landing siguen. Si el pub cae,
`/c` sigue sirviendo réplica y caché (STALE). El pub no sirve web ni se reinicia por esta sala.

## Dónde está el protocolo

- `docs/PUB/HUB-PROTOCOL.md` — piezas, activación, verificación, disco, memoria, upgrades, rollback, serie de bots (§11).
- `docs/PUB/clearnet.md` — guía upstream del HUB (rutas y opt-in del habitante).
- Plan de origen: `ARCHIVO/DISCO/oasis-clearweb/v2.md` §7 (histórico, no se edita).

## Enlaces desde otras páginas

- Vestíbulo `pub/site/scriptorium/index.html`: tarjeta «Sala 04 · HUB», nav-top, mapa de acceso, tabla «Si vienes a…», keywords.
- Landing `pub/site/index.html`: línea en «Accesos».

Se despliega con el resto del site (`deploy-site.sh`); en el VPS, `site/scriptorium/index.html` lleva
dos valores vivos que se re-aplican tras cada subida (ver `v2.md` «Secuencia de deploy» paso 5).
