# Dictamen — ¿Sale del tirón el modelo colectivista en Novelist?

**2026-09-10 · Dosier F4 · rev. 2 (envoltura fair) · decisión pendiente del scrum root**

Pregunta: modelizar `colectivizaciones` (modelador-redes, draftv1) como obra/barrio
en el editor Novelist (m-sdk). ¿Del tirón, o editor equivocado?

## Rev. 2 — qué cambia

La rev. 1 marcaba dos orillas como **no cubiertas**: el huerto del individualista
(D'05 pendiente) y el exterior (moneda estatal). `vendor/NEXT_VENDOR_REFACTOR.md`
cambia el tablero: el ecosistema FairCoop queda **vendorizado y citable**
(12 repos, SHA pineados, fichero:línea), y rige la regla «hechos sin adjetivo»
(«sin commits desde 2022-02-05, código completo, MIT, citable» — no «muerto»).

Aplicada la misma disciplina al dosier: las orillas no eran zonas muertas, eran
zonas **sin sustrato asignado**. La envoltura fair se lo da:

| Mecánica histórica (1936-37) | Pieza fair (vendor) | Cubre |
| :-- | :-- | :-- |
| Moneda exterior desde la caja (pesetas) | FAIR por el puerto (`faircoin`, PoC) | orilla exterior |
| Cuenta corriente del individualista (Oliete) | monedero `electrumfair` | orilla individualista |
| Bonos locales impresos — suprimidos en Caspe | `fairchains-tool` (génesis desde JSON): la imprenta que la asamblea vota **no usar** | beat de Caspe |
| Caja de compensación comarcal, cuenta entre pueblos | contabilidad REA (`valuenetwork`, `faircoin-nrp`) | orilla exterior |
| Delegados mandatados que certifican | criterios socio-políticos de certificación CVN (`doc/CVN-operators-guide.md` §4.1, removal §4.5) | ATENEO |
| Custodia de claves por cargos revocables | `fasito` / `-cvn=file` | COMISIÓN |
| Tablón público del tesoro | `faircoin-exporter` | mirador |

## Del tirón — SÍ (sin cambios de la rev. 1, más la envoltura)

- 4 actos con carril D' verificado (asamblea, hogar, Caspe/moneda, federación).
- El individualista sin VOTAR en su menú (offers nativas) — **y ahora con
  monedero**: su cuenta corriente tiene sustrato citable.
- Letreros con cifras reales; y ahora también **letreros-cita de código**
  (`vendor/<id>/fichero#L…`), el mismo formato que draftv3 de res_publica.
- La imprenta parada es un beat mejor que el bono que desaparece: la máquina
  de imprimir moneda local **existe y la asamblea decide no encenderla**
  (acuerdo de Caspe, escenificado como renuncia, no como carencia).

## Del tirón — NO (fricciones que quedan)

1. **El editor sigue sin simular.** La envoltura fair da sustrato *citable*,
   no runtime de la obra: FAIR, REA y el exporter entran como atrezzo y
   letrero-cita, no como economía viva dentro de Novelist.
2. **La deuda doctrinal no se envuelve.** D'05–D'08 siguen sin investigar:
   la envoltura cubre la *mecánica* del individualista (monedero), no su
   *doctrina* (estatuto, readmisión). El huerto pasa de oscuro a penumbra.
3. **Traducción diegética de parches CL-n**: sigue siendo trabajo de guion.
4. **Alcance del vendor**: la fase B del plan cierra TK-C00 en `res_publica`;
   para colectivizaciones, citar vendor implica su propia tarea de backlog
   (nuevo sufijo de draft en su rama). El dosier lo proyecta, no lo ejecuta.

## Proyección (no decisión)

Editor correcto para la **obra**; la auditoría vive en el repo. Con la
envoltura fair el barrio queda **cerrado por el perímetro**: isla (interior
sin moneda, D'01–D'04) + anillo fair (puerto, imprenta, custodia, telar REA).
F1 montable del tirón: 4 actos verificados + acto VI «El puerto» sobre
sustrato vendorizado; en penumbra el huerto (mecánica sí, doctrina D'05 no).

Bonus de arista: el anillo fair es el **mismo sustrato** que cita el carril C
de res_publica (draftv3) — la arista de contraste en pausa gana un suelo común.

Croquis: `01-croquis.md` · Storyboard: `02-storyboard.md` · Preview: `preview.html`
