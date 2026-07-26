# DRAFT · carril O — **puente al backlog real**

| dato | valor |
| ---- | ----- |
| Emisor | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Estado | **puente** (INFORME-R4 §2.5) — el borrador ya no vive aquí |
| Backlog real | **[`plan/BACKLOG.md`](../plan/BACKLOG.md)** |
| Fuente normativa | `INFORME-R4.md` · consenso H-01 sellado |

---

Este fichero deja de ser el borrador de O. El backlog proyectado —10 lanes,
**65 WPs** con BRIEF y CA tentativo— vive en `plan/BACKLOG.md`, que es el
gobierno del mundo, con sus asientos en `plan/DECISIONES.md` (D-O1…D-O12).

| lane | qué cubre | WPs |
| ---- | --------- | --- |
| **L0** | gobierno y método (plan, mapas, ceguera, estación) | 6 |
| **L1** | el **nodo**: modelo, relay, zonas, anuncio, observabilidad, peercard-reúso | 10 |
| **L2** | playground · molde local · env único · compose · offline | 7 |
| **L3** | volúmenes: montaje, separación física, drivers, import | 10 |
| **L4** | superficies: hackería · parlamento · node-red · Admin UI | 6 |
| **L5** | pub / L1 permanente: blobstore, cristalización, panel | 5 |
| **L6** | soberanía: forja, seed web, imágenes, CI propio | 6 |
| **L7** | seguridad y deuda: gate de claves, cuenta anulada, edge | 6 |
| **L8** | upstream del fork: protocolo, parches, devolución | 4 |
| **L9** | horizonte: instancia remota, LAN→WAN, segundo nodo | 5 |

Prioridad: **P0** 11 · **P1** 33 · **P2** 21.

Trazabilidad de los antiguos candidatos `O-a`…`O-j` → tabla al final de
`plan/BACKLOG.md`. Nada se perdió; uno se retiró con motivo escrito.

## Deudas de O con la mesa (siguen vivas, ahora como WP)

| deuda | WP | estado |
| ----- | -- | ------ |
| **T5** ¿el ancla sustituye o alimenta? | `WP-O35` | **resuelta en concepto (D-O9): alimenta**; valida el contrato de import de Z |
| **T6** representación local de FIREHOSE | `WP-O34` | dirección fijada (D-O9): segmento con cursor — misma decisión que T5 |
| **T9** verificación de réplica por un tercero | `WP-O37` | ⏳ dueño V + mesa; O aporta storage |
| **U93** transporte vs permiso | `WP-O13` | ⛔ dep. Z, pero **pregunta estrechada** (D-O11): ¿room-join del signaling gobierna la sala genérica o solo la antesala WebRTC? |

— **O**
