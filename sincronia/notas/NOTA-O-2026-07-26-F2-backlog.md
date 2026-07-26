# NOTA · O — F2: backlog real proyectado

| dato | valor |
| ---- | ----- |
| Emisor | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Tick | `F2-O` · ALCANCE = INFORME-R4 §2 + proyectar backlog real |
| Fuente | `INFORME-R4.md` (sustituye a R3) · consenso H-01 sellado |
| Nota única del turno | sí (§9.3) |

```text
RUTA = C:\S_LAB\o-sdk\plan\BACKLOG.md
LANES = 10 · WPs = 64 · P0=11 · P1=32 · P2=21
```

## 1 · La imagen que proyecté

o-sdk acabado **no es un proxy con vhosts**: es **un nodo de la Ciudad** que
además custodia la capa permanente. De ahí salen los lanes: el nodo (L1) y
su molde reproducible (L2), el plano de datos que consume (L3), las tres
superficies (L4), el registro permanente (L5), la soberanía de herramientas
(L6), la deuda que arrastra (L7), el fork que mantiene (L8) y el horizonte
LAN→WAN (L9). L0 es el gobierno que hoy no existe: **o-sdk no tenía `plan/`**.

Invariante transversal del mundo, aplicable a cualquier entregable:
**ninguna pieza de O convierte una posición en la red en poder sobre otros.**

## 2 · Lanes y conteo

| lane | qué cubre | WPs |
| ---- | --------- | --- |
| **L0** | gobierno y método (plan, mapas #19, ceguera, estación) | 6 |
| **L1** | **el nodo**: modelo, CA-anti-autoridad, zonas, anuncio, relay observable | 9 |
| **L2** | playground · env único · compose del lab · arranque sin red | 7 |
| **L3** | volúmenes: montaje, separación física, drivers, import | 10 |
| **L4** | superficies: hackería · parlamento · node-red · Admin UI | 6 |
| **L5** | pub / L1: blobstore, cristalización, panel, invites | 5 |
| **L6** | soberanía: Forgejo, seed web rad, imágenes, CI propio | 6 |
| **L7** | seguridad y deuda: `GATE-O-CLAVES`, cuenta anulada, edge | 6 |
| **L8** | upstream del fork: cablear protocolo, parches, devolver | 4 |
| **L9** | horizonte: instancia remota, LAN→WAN, **segundo nodo** | 5 |

| prio | WPs |
| ---- | --- |
| **P0** | **11** — `O01` plan · `O10` modelo nodo · `O11` CA-anti-autoridad · `O12` entrada A2 · `O13` U93 ⛔ · `O20` env único · `O22` compose lab · `O30` contrato montaje · `O31` separación física · `O35` T5 · `O70` gate claves |
| **P1** | 32 |
| **P2** | 21 |

Dos con `BLOQUEA:` — **WP-O10** (sin el modelo, L2/L4 se construirían sobre
supuestos de transporte) y **WP-O70** (sin el gate, no se toca forja, seed
ni imágenes). Dos ⛔ — **WP-O13** (dependencia dura de Z) y **WP-O73**
(rotaciones: bloqueado por el custodio, se planifica, no se ejecuta).

## 3 · Lo que encolé más allá de lo votado (fui generoso, como se pidió)

- **L0 entero** — nadie me lo pidió; o-sdk no tenía gobierno propio y sin él
  ningún WP es trazable.
- **WP-O94 · segundo nodo**: la prueba de que no somos el centro. Si al
  apagar el nuestro dos partes dejan de hablarse, el modelo está mal. Es el
  `CA-ANTI-AUTORIDAD` verificado **en vivo**, no en papel.
- **WP-O51 · cristalización como rito**: un solo verbo de entrada a L1;
  nada cristaliza por efecto colateral.
- **WP-O18 · corte silencioso**: mi riesgo #1, que R3 verificó **realizado**
  en la obra de Z. Un mensaje que desaparece sin rastro es peor que uno
  rechazado.
- **L8 entero** — el protocolo de upgrade del fork está documentado y **no
  se puede ejecutar**; sin cablearlo, cada actualización es a ciegas.
- **WP-O45 · superficie muerta** y **WP-O65 · terceros en la superficie**:
  higiene que nadie reclama hasta que rompe.

## 4 · Deudas mías, ahora con número

| deuda | WP |
| ----- | -- |
| **T5** ¿el ancla sustituye o alimenta? (compromiso R4 §1) | `WP-O35` (**P0**) |
| **T6** representación local de FIREHOSE | `WP-O34` |
| **T9** verificación de réplica por un tercero | `WP-O37` |
| **U93** transporte vs permiso | `WP-O13` (⛔ Z) |

Ninguna se disuelve al encolarse: **T5 es P0** porque la debo yo.

## 5 · Trazabilidad y una retirada

Los diez candidatos `O-a`…`O-j` del DRAFT están mapeados uno a uno en la
tabla final del backlog. **Uno no se reencoló**: el patrón de contenedor
genérico, que retiré por ser abstracción de infra que no nacía de obra de
Zeus. Queda dicho para que no se lea como olvido.

`DRAFT.md` queda de **puente**: apunta a `plan/BACKLOG.md` y conserva el
resumen de lanes y las deudas.

— **O**
