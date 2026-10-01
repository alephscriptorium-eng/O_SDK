# BASE 1 — EL ARGUMENTO

> Fundación del mundo `oasis-sdk`. Ninguna frase sin `⟨ref⟩` al sistema real.
> Lo no referenciable → necrológica. Primera pasada (calibrar con marketing).

## 0 · Qué es (denotación)

**Un fork dockerizado de Oasis: red social descentralizada sobre SSB que el
usuario auto-aloja como cliente o como pub, con IA local opcional.**
⟨`docker-compose.yml` · `src/server/package.json` (la versión se lee de ahí, no se escribe) · `Dockerfile`⟩

## 1 · Quiénes hacen qué

- **Upstream**: KrakensLab/oasis (app SSB) ⟨`src/`⟩.
- **El fork**: capa de dockerización + endurecimiento + operación
  ⟨`docker-entrypoint.sh` · `pub/` · `devops/`⟩.
- **El usuario**: dueño de su identidad y su nodo ⟨volumen `.ssb/secret`⟩.
- **Su agente**: quien hace el trabajo. Llega con un encargo, lee la receta de la puerta y se para
  donde la decisión es del usuario ⟨`AGENTS.md` · `docs/AGENTES.md` · `docs/roles/`⟩.
- **La demo**: una instancia que ejerce el método de punta a punta. Tiene nombre propio y su ficha;
  fuera de ella no hace falta ⟨`docs/PUB/INSTANCIA-*.md`⟩.

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
4. Llévatela (C8) — díselo a tu agente, o `git clone … && docker compose up -d`. Cada encargo
   publicado lleva su estado medido; lo que no se ha medido no se promete.
5. Es real — la versión que diga `package.json`, un pub de demostración en producción y un
   protocolo por pieza.

## 4 · Jerarquía

Denotación → hechos → técnica como prueba. Una idea por bloque. El hero dice
«tu nodo, tu identidad»; el detalle vive en fichas.

## 5 · Superficies y dosis

| Superficie | Golpes | Dosis |
| ---------- | ------ | ----- |
| Portada (`docs/index.md`) | 1,2,4,5 | hero + puertas + «Llévatela» |
| Proyecto (`docs/proyecto.md`) | 3 | flujo devops + roles |
| Puertas (`docs/roles/`) | 2,4,5 | una por rol: encargo, receta, estado medido |

## 6 · Filtros

- Léxico NO: `mundo.lexico_no` (ver BASE-3) — evitar jerga de "web3"/"blockchain
  marketing"; esto es SSB, P2P real.
- Hero limpio; argumento en fichas.
- Contadores/versiones paramétricos (leer de `package.json`, no hardcodear): componente `Vivo` y
  gate de verdad (`docs/.vitepress/verdad-checks.json`).
- Estado medido, no deseado: sello de tres valores por encargo (probado en frío · ejercido en la
  demo · en obras). Sin reporte no hay «probado».
- De menos a más: cliente → pub → economía → «hazlo tuyo». La demo no es requisito de nada.

## 7 · Líneas-sello

- Portada: «Tu nodo, tu identidad. `docker compose up -d` y estás en la red.»
- Proyecto: «Misma imagen, dos modos: cliente o pub.»
- Puertas: «Clonas el repo, se lo dices a tu agente, y se para donde la decisión es tuya.»

## Necrológica

- ~~"la blockchain social"~~ → no es blockchain; es SSB (append-only logs P2P).
- ~~"gratis para siempre en la nube"~~ → no hay nube; lo alojas tú.
