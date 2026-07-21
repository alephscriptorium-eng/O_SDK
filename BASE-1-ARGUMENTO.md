# BASE 1 — EL ARGUMENTO

> Fundación del mundo `oasis-sdk`. Ninguna frase sin `⟨ref⟩` al sistema real.
> Lo no referenciable → necrológica. Primera pasada (calibrar con marketing).

## 0 · Qué es (denotación)

**Un fork dockerizado de Oasis: red social descentralizada sobre SSB que el
usuario auto-aloja como cliente o como pub, con IA local opcional.**
⟨`docker-compose.yml` · `src/server/package.json` (0.8.8) · `Dockerfile`⟩

## 1 · Quiénes hacen qué

- **Upstream**: KrakensLab/oasis (app SSB) ⟨`src/`⟩.
- **El fork**: capa de dockerización + endurecimiento + operación
  ⟨`docker-entrypoint.sh` · `OASIS_PUB/` · `GANDI_DEVOPS_FOLDER/`⟩.
- **El usuario**: dueño de su identidad y su nodo ⟨volumen `.ssb/secret`⟩.

## 2 · A quién

| Círculo | Qué debe quedarle claro | Ancla |
| ------- | ----------------------- | ----- |
| Lectura cruzada | «es tuyo, corre en tu máquina» | §0–§1 |
| Comunidades | usable hoy: `up -d` y entras | portada + quickstart |
| Técnicos | afirmaciones comprobables | compose + entrypoint + protocolos |

## 3 · Cinco golpes

1. Qué es — red social P2P que corres tú, sobre SSB.
2. Quiénes — fork dockerizado de Oasis; identidad soberana.
3. Piezas — cliente web, pub de federación, IA local, mismo contenedor.
4. Llévatela (C8) — `git clone … && docker compose up -d`.
5. Es real — versión 0.8.8 corriendo; protocolos de upgrade y recuperación.

## 4 · Jerarquía

Denotación → hechos → técnica como prueba. Una idea por bloque. El hero dice
«tu nodo, tu identidad»; el detalle vive en fichas.

## 5 · Superficies y dosis

| Superficie | Golpes | Dosis |
| ---------- | ------ | ----- |
| Portada (`docs/index.md`) | 1,2,4,5 | hero + quickstart |
| Proyecto (`docs/proyecto.md`) | 3 | flujo devops + roles |

## 6 · Filtros

- Léxico NO: `mundo.lexico_no` (ver BASE-3) — evitar jerga de "web3"/"blockchain
  marketing"; esto es SSB, P2P real.
- Hero limpio; argumento en fichas.
- Contadores/versiones paramétricos (leer de `package.json`, no hardcodear).

## 7 · Líneas-sello

- Portada: «Tu nodo, tu identidad. `docker compose up -d` y estás en la red.»
- Proyecto: «Misma imagen, dos modos: cliente o pub.»

## Necrológica

- ~~"la blockchain social"~~ → no es blockchain; es SSB (append-only logs P2P).
- ~~"gratis para siempre en la nube"~~ → no hay nube; lo alojas tú.
