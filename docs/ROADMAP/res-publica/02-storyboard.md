# Storyboard — «La República Pura» (título de trabajo)

Patrón «Trecho del continuo»: 5 actos = 5 layouts. I–III sobre fichas
verificadas en fuentes; IV–V en penumbra declarada. El tiempo del modelo
(ciclos 60 d, desfase 30 d, plazos 7/21 d) se comprime a beats.

## Reparto (propuesta)

| Personaje | Papel | Fuente |
| :-- | :-- | :-- |
| EL REVISOR | narrador; escribe el grado A/B/C en cada letrero | revision/00-indice.md |
| LA REPRESENTANTE | mandato imperativo firmado; cada voto se coteja | cap. I, III (D02, D08) |
| EL PRESIDENTE | del C. de Gobierno; no disuelve sin dimitir | cap. VI (D06) |
| LA JUEZA | nombrada por mérito (School + antigüedad), no electa | cap. V (D07) |

## Actos

| Acto | Zona/layout | Beat central | Interacciones (offers) | Things | Fuente |
| :-- | :-- | :-- | :-- | :-- | :-- |
| I «La mónada» | LA MÓNADA | el hash asigna el colegio (igualdad sí, proximidad no — tensión de la ficha 02); mandato firmado antes de la 1ª vuelta; doble vuelta partida en el ciclo | PUBLICAR MANDATO · VOTAR 1ª · VOTAR 2ª (solo entre los dos más votados) | semilla/hash, mandato firmado, urna | fichas 01-02 ✓ · D01-D04 |
| II «La cámara» | LA CÁMARA | voto nominal público cotejado contra el mandato; la deslealtad es medible en el log; revocación por mayoría absoluta del censo de la mónada | PROPONER (solo representantes) · VOTAR NOMINAL · REVOCAR | acta de cotejo, escaño, letrero-lealtad≠fidelidad | ficha 03 ✓ · D02-D03-D08 |
| III «La promulgación» | C. LEGISLACIÓN (pasillo desde la Cámara) | fuerza directiva → fuerza coactiva: solo la ley promulgada produce lawId; devolución motivada una sola vez; silencio a 7 días = promulgación tácita | PROMULGAR · DEVOLVER (una vez, luego desaparece del menú) | ley-con-lawId, índice consolidado, reloj-de-7-días (letrero) | ficha 04 ✓ · D05, G05 |
| IV «La puerta» | C. GOBIERNO ◐ | el presidente ejecuta (llaves de cadena, tesoro multisig) solo con lawId y dentro del presupuesto; la puerta DISOLUCIÓN solo abre con la dimisión en la mano (mecánica puertas Gödel/Cohen) | INTERPELAR (respuesta obligada) · REPROBAR (sin derribo) · DISOLVER-Y-DIMITIR (offer única compuesta) | informe firmado de ciclo, llaves chain-admin (atrezzo), presupuesto | ficha 06 ◐ · D06, D18, G06, G10 |
| V «La constituyente» | CONSTITUYENTE ◐ (cerrada al empezar) | se abre por acción: FIRMAR LLAMADA hasta el 25 %, o 2 ciclos de ANARCHY; dentro, las constantes provisionales grabadas («nadie las constituyó»); la asamblea solo redacta; ratifica el referéndum; se disuelve al ratificar | FIRMAR LLAMADA · REDACTAR (80 %) · RATIFICAR (quórum 50 %) · DISOLVERSE | constantes-provisionales (TERM_DAYS 60), borrador, papeleta | fichas 07-08 ◐ · D09, D12, TK-78 |

## Mecánicas que ya existen en el editor

- La puerta que solo abre legalmente: `actor_interact(OPEN)` — probada en el
  Acto V del Trecho (Gödel y Cohen).
- DEVOLVER que desaparece del menú tras usarse una vez: offers condicionadas
  por `machineState` (demo-novel).
- Penumbra por zona: materiales auditables con `scene_eval` (precedente
  ceguera/LUZ).
- Letreros con grado A/B/C: `thing.prop.text` con `offsetY` (piedra numerada).

## Lo que habría que escribir (no viene gratis)

- 5 layouts (chalk primero, `layout-zona-*`).
- La compresión temporal: guionizar ciclos/plazos como beats (sin reloj).
- Nada del carril C/B/F/E entra en escena: si se quiere «sala de máquinas»,
  es atrezzo con un letrero, no funcionalidad.
- Carril D pendiente si se quiere citar el libro en letrero (hoy: certeza del
  revisor, grado en tiza).
