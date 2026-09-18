# Croquis — barrio COLECTIVIZACIONES · rev. 2 (envoltura fair)

Dos escalas. En la obra-catálogo de 10 barrios, `colectivizaciones` es **un**
barrio. Por dentro: la isla multizona de la rev. 1, ahora **envuelta por el
anillo fair** — las dos orillas que estaban sin cubrir tienen sustrato
vendorizado y citable (`vendor.json`, 12 repos, SHA pineados).

## Escala 1 — la obra de 10 barrios

```
        [res_publica]───(arista: contraste, pausa)───[colectivizaciones]  ◀ este dosier
              │        ambos citan el mismo sustrato vendor ▲
           [clase]        + 7 barrios por nombrar           │
              └────────────── plaza central ────────────────┘
```

## Escala 2 — isla + anillo fair

```
┌─ ANILLO FAIR ── sustrato vendorizado, citable fichero:línea ────────────┐
│                                                                         │
│   PUERTO            IMPRENTA (parada)      TELAR REA         MIRADOR    │
│   FAIR exterior     fairchains-tool:       valuenetwork +    faircoin-  │
│   (faircoin PoC)    génesis desde JSON —   faircoin-nrp:     exporter:  │
│                     la asamblea vota       caja de           tablón del │
│                     NO encenderla (Caspe)  compensación      tesoro     │
│                                                                         │
│  ┌─ ISLA COLECTIVIZACIONES ── interior sin moneda ────────────────────┐ │
│  │                                                                    │ │
│  │  ┌─────────┐        ┌──────────┐        ┌──────────┐               │ │
│  │  │ PLAZA   │════════│ COMISIÓN │════════│ ATENEO   │               │ │
│  │  │ asamblea│        │ cargos · │        │federación│               │ │
│  │  │ D'01 ✓  │        │ custodia │        │ D'04 ✓ · │               │ │
│  │  └────╥────┘        │ (fasito) │        │ cert. CVN│               │ │
│  │       ║             └──────────┘        └──────────┘               │ │
│  │  ┌────╨────┐   ┌─────────┐   ┌─────────┐   ┌──────────────┐        │ │
│  │  │ HOGAR   │═══│ ALMACÉN │═══│  CAJA   │   │ zona oscura  │        │ │
│  │  │ D'02 ✓  │   │ D'03 ✓  │   │ D'03 ✓  │   │ D'06–D'08    │        │ │
│  │  └─────────┘   └─────────┘   └─────────┘   └──────────────┘        │ │
│  │                                                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│   EL HUERTO ◐ (individualista: monedero electrumfair = mecánica         │
│   cubierta; doctrina D'05 pendiente → penumbra, ya no oscuridad)        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Correspondencias (rev. 2)

| Zona | Mecanismo (ficha) | Verificación | Sustrato fair | Parches |
| :-- | :-- | :-- | :-- | :-- |
| PLAZA | asamblea soberana (01) | D'01 ✓ | — (interior puro) | CL-1, CL-7, CL-2 |
| COMISIÓN | cargos rotatorios (02) | parcial | custodia de claves: `fasito`, `-cvn=file` | CL-2, CL-11 |
| HOGAR | salario familiar (04) | D'02 ✓ | — | CL-4, CL-9, CL-10 |
| ALMACÉN | carnet = cupo (06) | D'03 ✓ | — | CL-6, CL-9 |
| CAJA | vales TIME · moneda† (06) | D'03 ✓ | asiento hacia el telar REA | CL-5, CL-6 |
| ATENEO | federación (05) | D'04 ✓ | certificación CVN: guide §4.1 / removal §4.5 | CL-8 |
| PUERTO | intercambio exterior | D'03 ✓ | FAIR (`faircoin`), compensación REA | CL-6 |
| IMPRENTA | bonos locales suprimidos | D'03 ✓ | `fairchains-tool` (parada por acuerdo) | CL-5 |
| EL HUERTO ◐ | individualistas | D'05 pte. | monedero `electrumfair` | — |
| zona oscura | Decreto vs práctica, derechos, hogar | D'06–D'08 pte. | — | CL-3, CL-10 |

† suprimida en Caspe 14-15/2/1937 — en rev. 2 no «desaparece»: la imprenta
existe y queda parada por acuerdo. Renuncia, no carencia.

Notas:
- Regla heredada del plan vendor: **hechos sin adjetivo** — `faircoin`: sin
  commits desde 2022-02-05, código completo, MIT, citable.
- La cita escénica usa el formato del repo: `vendor/<id>/ruta#Lx-Ly`.
- El anillo es el mismo sustrato del carril C de res_publica (draftv3):
  suelo común para la arista en pausa.
