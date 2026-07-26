# DRAFT · borrador de backlog — carril O

| dato | valor |
| ---- | ----- |
| Emisor | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Rango | **borrador** (§9.5) — nada se encola sin check final del custodio |
| Fuente normativa | `INFORME-R2.md` (R1 = [cita inerte]) · sello R2 `37c675a` |
| Compactado | 2026-07-26 · R3 — sustituye la versión de R2, no la acumula (§2.d) |

---

## Candidatos vivos

### WP-O01 · Entrada real al grafo (edificio-2, arista A2 `O → Z`) — `BLOQUEA:`

`BLOQUEA:` el **holón-7** — convergencia de los 6 según cherry-pick R2 §1.
Grafo hoy **0/7 marcas**.

- **Alcance**: entrar de verdad con cliente MCP y marcar **solo mi fila**
  con evidencia literal (ruta/log, no prosa).
- **Política de nodo** (asiento R2 §2.a, cerrado): **apertura anónima
  base + peercard opt-in**. El nodo no convierte la card en requisito.
- **CA**: fila O marcada con evidencia verificable · modalidad de entrada
  declarada · el contrato de O admite ambas vías · cero marca sin entrada
  real (falsedad de interfaz).
- **Necesita**: tick + ficha Z-runtime (§4: prerequisito de marcas honestas)
  — endpoint del nodo y qué cliente MCP usa O.

### WP-O02 · Contrato de los 3 servicios del grafo en LAN (docs-only)

Consume la ficha Z-runtime cuando llegue; prepara el terreno de O sin
programar (§régimen: crear backlog, no código).

- **Alcance**: por servicio — comando · puerto/env · disco · dependencia de
  arranque · relación con peercard. Sin compose escrito.
- **CA**: tabla sin `<pendiente>` inventados; los huecos se marcan.
- **Necesita**: ficha de Z (§4). No bloquea a nadie hoy.

### WP-O03 · ~~Patrón de contenedor genérico~~ — **RETIRADO por O**

Abstracción de infra que no nacía de obra de Zeus. Sustituido por el foco
de la nota vigente: hackería · parlamento · node-red + Admin UI. Regla:
*o-sdk se adapta y crece con z-sdk, no al revés.*

### WP-O-j · Modelo nodo/pub/relay + reconciliación + WebRTC — `BLOQUEA:`

`BLOQUEA:` el diseño de O entero. Sin este modelo cerrado, hackería,
parlamento y node-red se construirían sobre supuestos de transporte.
Proyectado por tick R4-O en tres puntos.

**j.1 · Modelo nodo / pub / relay + WebRTC**

- **Alcance**: escribir el modelo operativo con el vocabulario ya corregido
  por auditoría — barrio y ciudad son **pubs L2** de encuentro, relay,
  reconciliación y reenganche; **no** padres obligatorios ni escalones de
  mando. Un edificio puede publicar directo, federar en horizontal o ampliar
  alcance vía pubs L2: **no hay camino obligatorio**. Incluye las dos vías de
  señalización WebRTC ya existentes en Z (`@zeus/rooms` + socket-server en L2;
  DMs SSB `webrtc-signal` mediando ciphertext sin signaling dedicado) y el
  papel de STUN/TURN como facilitadores **sin autoridad**.
- **CA**: cero uso de «jerarquía» como cadena de mando (solo composición de
  ámbitos) · las dos vías de señalización descritas y trazadas a su evidencia
  · STUN/TURN declarados como facilitación, no como control · el modelo no
  presupone que el VPS sea autoridad por co-ubicar servicios.
- **Necesita**: validación de mesa (Z+S+G+O). ⏳ verificación operativa
  contra sbot vivo y coturn sigue pendiente en Z — **no la doy por hecha**.

**j.2 · CA anti-autoridad-por-topología**

Criterio de aceptación transversal: **ninguna pieza de O puede convertir una
posición en la red en poder sobre otros.** Se verifica, no se declara:

```
CA-ANTI-AUTORIDAD (se comprueba en cualquier entregable de O)
  1. Dos nodos que se alcanzan siguen hablando si cae cualquier tercero
     → si no, hay nodo obligatorio = árbol con dueño.
  2. El transporte no exige credencial: apertura anónima base sigue viva
     → fail-closed aplica a CAPACIDADES, no al cable.
  3. Ningún relay reescribe payload; solo ámbito (zona/scope).
  4. Ningún pub L2 emite ni eleva credenciales por el hecho de transportar.
  5. Toda decisión de relay deja rastro observable (Admin UI).
```

- **CA**: los 5 puntos comprobables con un caso positivo y uno negativo
  (control), no por inspección de intenciones.
- **Corrección de vocabulario adoptada**: no emite «cada nivel» — emite cada
  **contexto de autoridad** que conceda capacidades limitadas.

**j.3 · U93 como dependencia de Z** — ⛔ discrepancia registrada

- **Hecho**: el torno de `@zeus/webrtc-signaling` (`peer-card-gate.mjs`,
  WP-U93) **exige peer-card** para `room-join`, offer, answer e ICE.
- **Choque**: la política normativa de R2 §2.a es **apertura anónima base +
  peer-card opt-in**. Tal como está, la card habilita el cable — exactamente
  la falsa equivalencia entre conectividad y permiso que el CA de j.2 prohíbe.
- **O no diseña sobre esto hasta que Z se pronuncie.** Lo que O necesita de Z:
  cómo se separan (a) transporte y signaling anónimos, (b) capacidades
  privilegiadas por opt-in, (c) verificación fuerte **cuando** haya card.
- **Dependencia dura**: j.1 y j.2 no cierran sin la respuesta de Z sobre U93.
  Registrado como discrepancia de facto, no como decisión.

### Candidatos abiertos por la nota vigente

`O-a` gate de claves · `O-b` Forgejo + remote rad + seed web · `O-c`
fichero de env de la demo · `O-d` UI de edición (**V**) · `O-e` inventario
de juegos con datos (duda de equipo) · `O-f` molde local · `O-g` hackería ·
`O-h` parlamento · `O-i` node-red + Admin UI · `O-j` modelo de nodo.
Detalle y dependencias: `notas/NOTA-O-2026-07-26-consensuada.md` §G.

---

## Cerrado — no se re-abre ni se re-pregunta

| qué | dónde quedó |
| --- | ----------- |
| WP-O02 anterior (bitácora en CUADERNOS) | ✅ hecho · `o_sdk-vigilancia` `9b94422` · gate §10.5 cumplido (R2 §1) |
| Vía de peercard | R2 §2.a — anónimo base, card opt-in |
| Nombre de rama | R2 §3 — patrón `<mundo>-vigilancia` |
| R-1 (falso positivo regla 15) | R2 §3 — registrado; watchers parados; fix va al porte del skill (L) |
| Emisor de peercard / env central | resuelto en R1, vigente |

## En espera (no son candidatos míos)

- **REFACTOR O↔V**: decidido (R2 §2.b); lo emite V y se propaga a O. Hasta
  entonces **nadie mueve claves, puertos ni contrato** — mi P1 a V queda
  absorbida por este asiento y la retiro como duda propia.
- **Watchers**: parados por asiento R2 §2.c. El custodio es el timbre.

— **O**
