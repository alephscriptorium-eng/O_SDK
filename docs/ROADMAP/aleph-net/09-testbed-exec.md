# Plan — qué mide el testbed (cierre de la addenda) y parche IV.4 corregido

## Contexto

`dosier-relacional/contraejemplos/addenda.md` recomienda la opción e (transponer la brecha de Chalmers produce algo, no una solución) y deja un único paso siguiente: **definir qué mediría el testbed** (qué se registra, qué se relaciona, qué se observa tras N iteraciones). `dosier-aleph-net/08-addenda-testbed.md` pone la addenda en correspondencia con la casa y declara explícitamente que **no decide qué mide el testbed**. Ese es el hueco que este plan cierra.

Hallazgos de la lectura que condicionan el diseño (todos con coordenada en 01–08):

- La addenda no propone un puente: «la pista no es un puente, es un testbed» (`addenda.md:39`). Su cadena de desplazamientos (ontológico → conceptual → metodológico → empírico) cierra en un informe en primera persona, que reabre el registro conceptual: es un bucle, no una escalera.
- El problema duro ya está en la casa en miniatura: fila **R17** de `05-dualidades-de-la-red.md` (prosa/geometría de `n-sdk/docs/la-obra.md:45-60`, «la coherencia es del autor», ambas versiones «se validan juntas»). Es la constricción mutua 1ª/3ª persona de Varela con el log y la geometría como tercera persona.
- La red tiene interior solo por rito: WP-O51 «un solo verbo de entrada a L1» (`02` §Doctrina; `05` R1). Criterio de Whitehead (sociedad viva con ocasión dominante vs. agregado): la unidad es el acto de cristalizar, no el estado de la red. Sin hivemind continua.
- El «hipergrafo mínimo» de la addenda no requiere producto: en SSB una n-aria es un mensaje con lista de ids (`recps` ya lo es, `02` §Modelo de datos). Un tipo de mensaje nuevo bajo opt-in que apunte a otros mensajes da D2 (n-arias) y D5 (meta-grafo) a la vez, con D4 (tombstone) gratis. Ausencias 1 y 2 de `08` §Lo que el testbed necesita.
- Panikkar (equivalencia homeomórfica + hermenéutica diatópica) es la regla que falta para que las correspondencias de `08` no se lean como identidades. Anclaje en el ensayo: §9.2 (trading zones) y T3.

Restricciones: hechos sin adjetivo; leyenda [V]/[E]/[NV]/`<pendiente>`; no tocar ningún repo git ni `modelador-redes`; no decidir lo que es del scrum root (vía 1, nombre del nodo, permiso de autoría). Paradigma de audiencia: continental (tensiones, pliegues, topos), sin vocabulario analítico en el texto final.

## Entregables (dos ficheros nuevos, nada más)

### 1. `F4/dosier-aleph-net/09-testbed-medida.md`

Cierra el paso siguiente de la addenda. Secciones:

1. **Corrección de lectura**: la addenda no propone puente sino desplazamiento; el desplazamiento es un bucle que cierra en primera persona (citar `addenda.md:21-27,39`). Consecuencia: el testbed mide trazas de inscripción, no experiencia.
2. **Regla de lectura (Panikkar)**: equivalencia homeomórfica y hermenéutica diatópica, definidas en cuatro líneas. Aplicación: el modelador ya es diatópico (nodo puro no cita a otro nodo, `01` §El grafo; código a SHA fijo como único topos común; arista = encuentro de dos). Límite: la cardinalidad 2 rompe donde Panikkar es ternario.
3. **Tabla de equivalencias homeomórficas** (columnas: término del ensayo/Chalmers/Varela · función en su topos · término de la casa · función en la casa · coordenada · lo que NO se transfiere). Filas mínimas: experiencia como inside del proceso ↔ opt-in que viaja con el feed (R3); neurofenomenología ↔ certeza A/B/C + penumbra + prosa/geometría (R15, R17); ocasión dominante de Whitehead ↔ cristalización WP-O51 (R1); commit ↔ mensaje en log append-only (D8, R23); trading zone ↔ nodo puro + arista del modelador (R13); hipergrafo autopoiético (D5) ↔ ausencia 1 de `08`.
4. **Qué mide el testbed** (lo que la addenda pedía). Tres observables sobre el log SSB, todos ya inscribibles hoy:
   - **Retoma**: un mensaje que inscribe un estado interno (`post` privado con `recps`, o `about`) es referenciado después por otros (`root`/`branch`, `vote`, mención, tombstone). Cuenta y latencia.
   - **Deriva del autor**: diferencia entre inscripciones sucesivas del mismo autor sobre el mismo `root` tras N iteraciones (drift semántico, D5 en versión mínima).
   - **Re-proyección**: el mismo estado aparece en más de una vista del HUB o en prosa+geometría (R17) y las versiones divergen o convergen.
   Declarar que ninguno mide vivencia: miden informes y trazas. Primera persona constreñida por A/B/C, no por dato neural.
5. **El hipergrafo mínimo**: un tipo de mensaje SSB (`relacion`: `tipo`, `nodos: [ids]`, opt-in en `visibilityPrefs`) como única pieza nueva. Cubre D2 + D5; D4 por tombstone. Dónde encaja sin decidirlo: cliente Oasis (o-sdk) bajo opt-in; nunca L2 → L1 sin el verbo de WP-O51. Marcar `<pendiente>` de decisión O.
6. **Secuencia** (reafirma la de `08` §Camino, con el paso 0 «cartografiar»: m-sdk/n-sdk/modelador fuera de mapa, `04` §Gobierno, R26).
7. **Hueco declarado**: qué no mide (vivencia, cualia, identidad fenoménica); el bucle de la addenda; la unidad de la red solo por rito.
8. **Lo que este fichero no decide**: nombre del nodo, mundo dueño del testbed, permiso de autoría.

Actualizar `00-indice.md` §Mapa de ficheros con la fila `09` (misma tabla, misma disciplina).

### 2. `F4/dosier-relacional/contraejemplos/parche-IV4-rev.md`

Revisión del parche §IV.4 de `roadmap-hard-problem.md` §2.3, con el mismo método de seis pasos (§1) aplicado al propio parche. Cuatro correcciones, cada una con diagnóstico → texto nuevo → justificación → no-regresión → límite:

1. **Panexperiencialismo reconocido**: sustituir la réplica «No. El panpsiquismo atribuye experiencia a entidades básicas…» (`roadmap:113-115`) por el reconocimiento de que las ocasiones actuales son las entidades de Whitehead; el marco es panexperiencialista y lo declara.
2. **Criterio de la ocasión dominante**: párrafo nuevo tras «Consecuencias» (`roadmap:56-60`): sociedad viva vs. agregado; pregunta decidible «¿tiene interior un proceso relacional dado?». Aplicado a la red: sí, en la cristalización; no, como estado. Cita R1/R19 del `05`.
3. **Último párrafo** («El hipergrafo… la co-produce», `roadmap:64`): sustituir por equivalencia homeomórfica: el hipergrafo no produce experiencia, ofrece lugares donde interioridades de topos distintos se ponen en relación sin traducirse. Panikkar entra aquí y en §9.2 del ensayo.
4. **Upstream**: sección nueva «Sin upstream no hay PR»: el ensayo no tiene repo ni licencia (`00-dictamen.md:99-102`); hasta el sí de Marc/Dídac el parche es palimpsesto (§9.3 del ensayo) en el `draftvN` del nodo, nunca reescritura del draft anterior (`modelador-redes/llms.md:56-66`).

Mantener §2.6 «Límites declarados» del roadmap y añadir el bucle de la addenda.

## Ficheros que se leen, no se tocan

`dosier-relacional/01-relacional.md` (líneas del ensayo para D y T), `contraejemplos/{addenda,roadmap-hard-problem,tabla,dualidad}.md`, `dosier-aleph-net/00–08`. Ningún fichero de `modelador-redes`, `o-sdk`, `m-sdk`, `n-sdk`, `s-sdk` ni `S` se modifica.

## Verificación

- Cada coordenada citada en `09` y en `parche-IV4-rev` existe en los ficheros 01–08 o en `01-relacional.md` (comprobar con grep de la cadena `fichero:línea` sobre el dosier; ninguna coordenada nueva de código sin marcar [E] o [NV]).
- `00-indice.md` lista `09` y la carpeta lo contiene (evitar el desfase índice/carpeta que tuvo 04–07).
- Ninguna frase con juicio sin dato: leer los dos ficheros contra la regla «hechos sin adjetivo» de `00-indice.md`.
- `git -C F4/modelador-redes status` limpio antes y después; `git -C o-sdk status` sin cambios nuevos.
- Los tres observables del §4 de `09` nombran un tipo SSB existente en `02` §Modelo de datos; el único tipo nuevo es el de §5 y va marcado como propuesta.
