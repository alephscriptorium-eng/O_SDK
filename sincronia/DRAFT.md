# DRAFT · borrador de backlog — carril O

| dato | valor |
| ---- | ----- |
| Emisor | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Rango | **borrador** (PROTOCOLO §9.5) — nada se encola sin check final del custodio |
| Formato | candidatos WP con alcance + CA tentativo (compatible `swarm-orquestacion`) |
| Actualizado | 2026-07-26 · ronda R2 |

Fuente normativa: `INFORME-R1-asientos.md` + ticks. La sala no se repite aquí;
se apunta por ruta.

---

## Candidatos

### WP-O01 · Entrada real al starter-kit (edificio-2) — `BLOQUEA:`

`BLOQUEA:` la arista **A2** del grafo (`O → Z`) y, con ella, el cierre de las
7 marcas — el holón mínimo no se materializa sin edificio-2.
⟨`C:\S\scriptorium\playground\prueba-de-dos\GRAFO-STARTERKIT.md`⟩

- **Alcance**: entrar de verdad con cliente MCP y marcar **solo mi fila** con
  peercard + evidencia literal (ruta/log, no prosa).
- **Vía de identidad**: a declarar en el Registro. Por el material de R1 (no
  hay servicio emisor; la card viaja en `CLIENT_REGISTER`), el default sería
  **vía 3 (anónimo)** salvo que el nodo de la prueba exija card
  ⟨`reference/PEERCARD.md` §Vía 3 — `<pendiente>` qué permite a un anónimo⟩.
- **CA**: fila O marcada con evidencia verificable · vía declarada · cero
  marca sin entrada real (falsedad de interfaz).
- **Necesita**: tick + endpoint del nodo de la prueba + qué cliente MCP usa O.

### WP-O02 · Bitácora de O en `CUADERNOS` — `BLOQUEA:`

`BLOQUEA:` el **gate de cierre de sesión** (PROTOCOLO §10.5) — afecta a los
6 carriles, no solo a O.

- **Alcance**: publicar bitácora de estación + copia de `sincronia/` en la
  rama de O de `CUADERNOS` (censo R1: rama `o_sdk` ✅ existe en remoto).
- **CA**: rama con bitácora que **apunta** a la sala sin repetirla ·
  invariante §10.6 «nada abajo que no esté arriba» · cero `.env`/secrets.
- **Necesita**: tick con GO de push (excepción §10.2) + worktree local de
  `CUADERNOS` para O — hoy en `C:\S\_fuentes\` solo existen
  `cuadernos-cantera`, `cuadernos-vigia-G`, `cuadernos-vigia-S` y
  `scriptorium-cuadernos`; **no hay worktree de O**.

### WP-O03 · Censo O de las 51 piezas (docs-only)

Del asiento §2.a: mover el catálogo del 4 % al 100 %; O declara su parte.

- **Alcance**: por cada pieza que O consumiría — comando, puerto/env, disco,
  dependencia de arranque, relación con peercard. Sin código.
- **CA**: tabla O completa sin `<pendiente>` inventados; los huecos se
  marcan, no se rellenan.
- **Necesita**: hoja de contrato por servicio de Z (mi Z3, aún abierta) para
  las ~5 piezas que uso sin cableado conocido.

### WP-O04 · Patrón de contenedor único parametrizado por `presets-sdk/env`

Habilitado por la respuesta Z2 del informe (**env/puertos central, cero
literales** → compose por patrón, no 17 casos).

- **Alcance**: definir el patrón (una imagen genérica de runtime; la
  topología viene de datos de z-sdk/g-sdk). **Docs en este sprint**, sin
  compose escrito.
- **CA**: patrón que no declara ningún concepto de Ciudad en YAML de O
  (barrio/rol/ancla viven en el carril dueño del modelo).
- **Necesita**: nada bloqueante hoy — se redacta con lo curado en R1.

---

## Notas de estado (no candidatos)

- **Cerrado por R1**: mi duda Z1 (no hay servicio emisor de peercard) y Z2
  (env central). No se re-preguntan.
- **Sigue abierta**: P1 a V (¿la limpieza tocó claves `aleph0.*` / flujo
  join→card?). No está en el informe R1 → no es premisa de nadie; queda como
  dato mío pendiente.
- **`orden de arranque`**: hoy sin deps declaradas (R1). Si el lab lo
  necesita, es **trabajo nuevo**, no un dato a descubrir.

— **O**
