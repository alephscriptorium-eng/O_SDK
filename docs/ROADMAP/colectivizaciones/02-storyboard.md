# Storyboard — «La Colectividad» (título de trabajo) · rev. 2 (envoltura fair)

Patrón «Trecho del continuo»: N tramos = N layouts = N actos. Rev. 2: seis
actos — cuatro verificados, el puerto sobre sustrato vendor, y la deuda que
encoge (el huerto sale de la oscuridad hacia la penumbra).

## Reparto

| Personaje | Papel | Fuente |
| :-- | :-- | :-- |
| LEVAL | cronista-testigo, narra entre zonas | Colectividades libertarias en España |
| CABEZA DE FAMILIA | cobra el carnet por hogar, no vota por dos | Tamarite art. 15-16 |
| LA DELEGADA | mandato previo firmado, revocable; certifica en el ateneo | Carrasquer (Binéfar en Caspe) |
| EL INDIVIDUALISTA | delibera sin votar; **monedero propio** | Leval p. 130 · Oliete · `electrumfair` |

## Actos

| Acto | Zona/layout | Beat central | Interacciones (offers) | Things | Fuente |
| :-- | :-- | :-- | :-- | :-- | :-- |
| I «La plaza» | PLAZA | asamblea de presentes: mayoría de quienes acuden, sin quórum, voto público. Asistir = derecho; deber solo en algunos reglamentos (multas a nuevos miembros, Seidman p. 212; mujeres en Tamarite art. 16) | VOTAR (mano alzada) — ausente en el menú del INDIVIDUALISTA; CONVOCAR | campana, acta, libro de multas (solo nuevos miembros) | D'01 |
| II «El hogar» | HOGAR | escala decreciente por persona: 1 + 0,5 + 0,15 + 0,10; carnet al cabeza de familia | COBRAR (semanal, por hogar) | carnet-hogar, letrero-escala | D'02 |
| III «La imprenta parada» | ALMACÉN + CAJA + IMPRENTA | carnet = cupo; vales TIME complemento. Rev. 2: la imprenta de moneda local **existe** (`fairchains-tool`: génesis desde JSON) y la asamblea vota no encenderla — Caspe como renuncia, no carencia | RETIRAR (contra cupo) · GASTAR VALE · ENCENDER IMPRENTA (offer presente, votada NO: queda bloqueada) | carnet-cupo, vale, imprenta-parada, letrero-cita `fairchains-tool.cpp` | D'03 + vendor |
| IV «El ateneo» | ATENEO | delegada con mandato previo revocable; acuerdos válidos desde el voto. Rev. 2: la federación **certifica** operadores como los criterios socio-políticos CVN (§4.1) y los remueve (§4.5) | MANDATAR · REVOCAR · FEDERAR · CERTIFICAR CVN | estatutos de Caspe, credencial, letrero-cita guide §4.1 | D'04 + vendor |
| V «El puerto» *(nuevo)* | PUERTO + TELAR REA | el trigo sale, el FAIR entra: exterior en moneda cooperativa, no estatal; la caja de compensación asienta cuenta entre pueblos en el telar REA; el INDIVIDUALISTA pasa por el puerto con su monedero; el MIRADOR publica el tesoro | EXPORTAR · COMPENSAR (asiento REA) · ABRIR MONEDERO (individualista) · MIRAR TABLÓN | monedero `electrumfair`, cuenta-REA, tablón (`faircoin-exporter`), letrero-cita `poc.cpp` | D'03 ✓ mecánica + vendor |
| VI «La deuda» | zona oscura (encogida) | lo no investigado no se ilumina — pero encoge: el huerto pasó a penumbra (mecánica cubierta, doctrina D'05 pendiente). Quedan a oscuras Decreto vs práctica, derechos sociales, hogar (D'06–D'08) | LEER (índice de deuda); en el huerto en penumbra: ABRIR MONEDERO sí, VOTAR no, su estatuto ilegible | letrero-deuda, monedero-en-penumbra | draftv1 §2 |

## Mecánicas que ya existen en el editor

- Offer presente pero bloqueada por voto (ENCENDER IMPRENTA): offers
  condicionadas por `machineState` — mejor beat que el thing que desaparece.
- Menú sin VOTAR para el INDIVIDUALISTA: probado (demo-novel).
- Penumbra por zona: auditoría de materiales `scene_eval` (precedente LUZ).
- Letreros: `thing.prop.text` con `offsetY` — ahora también letreros-cita
  con el formato `vendor/<id>/ruta#Lx-Ly` del repo.

## Lo que habría que escribir (no viene gratis)

- 6 layouts (chalk primero, patrón `layout-zona-*`) — uno más que en rev. 1.
- El anillo fair entra como atrezzo + letrero-cita: **nada de runtime FAIR
  dentro de la obra** (el editor no simula; el sustrato es citable, no vivo).
- Scripts de unit si la escala salarial o el asiento REA deben computar
  (opcional en F1).
- Backlog propio: citar vendor desde colectivizaciones pide su tarea de
  draft en `dev/colectivizaciones` (la fase B del plan solo cubre res_publica).
- Leaf ids nuevos en ciudad-lifecycle si el barrio entra en la obra de 10.
