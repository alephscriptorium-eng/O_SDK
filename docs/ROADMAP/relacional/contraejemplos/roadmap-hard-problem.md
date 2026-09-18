# Taller: cómo hacer un pull request teórico al documento

Vamos a usar el caso “Brecha explicativa (Chalmers)” como ejercicio. La idea no es que copies un texto, sino que aprendas el **método** para intervenir un documento teórico como si fuera código: localizar el hueco, proponer un parche, justificarlo, y verificar que no rompe el resto.

---

## 1. Método general de un PR teórico

| Paso | Operación | Pregunta guía |
|---|---|---|
| 1. Localizar | Encontrar el punto exacto del documento donde vive el hueco | ¿Dónde se habla del problema y qué se dice? |
| 2. Diagnosticar | Nombrar qué falta, no solo que falta | ¿Falta una tesis, una referencia, una sección, una distinción? |
| 3. Diseñar el parche | Redactar el fragmento nuevo con el tono y las fuentes del documento | ¿Es coherente con las Tesis 1–6? |
| 4. Justificar | Explicar por qué ese parche mejora el artefacto | ¿Cierra el hueco o lo reconfigura? |
| 5. Verificar | Comprobar que no rompe otras secciones ni duplica contenido | ¿Contradice algo ya escrito? |
| 6. Declarar límites | Decir qué sigue sin resolverse | ¿Es honesto sobre lo que no hace? |

---

## 2. PR concreto: “Brecha explicativa (Chalmers)”

### 2.1 Localización

- **Sección afectada:** IV. Epistemología Enactiva y Conocimientos Situados
- **Subsección propuesta:** IV.4 (nueva, tras IV.3 Analogía como Cognición)
- **Motivo:** el documento disuelve sujeto/objeto en IV.1, pero nunca enfrenta la pregunta de Chalmers. La disolución es condición necesaria, no suficiente.

### 2.2 Diagnóstico

El documento tiene los recursos para responder a Chalmers, pero no los activa:

| Recurso ya presente | Uso potencial contra la brecha |
|---|---|
| Whitehead: ocasión actual con “subjective form” | La experiencia no es propiedad de un sustrato, sino forma de un proceso |
| Simondon: individuación psíquica | Lo psíquico no es epifenómeno, es interioridad del proceso |
| Barad: intra-acción | Experiencia como dimensión sentida de una relación, no cualidad privada |
| Merleau-Ponty: reversibilidad | El cuerpo es pliegue donde interior y exterior se co-constituyen |
| Varela: enacción | Experiencia como participación, no representación |

Lo que falta: **una tesis explícita que diga cómo se entiende la experiencia subjetiva desde este marco**, y **una referencia directa a Chalmers y a la neurofenomenología**.

### 2.3 Parche propuesto (texto para insertar)

> ### IV.4 La Brecha Explicativa desde la Ontología Relacional
>
> El “problema difícil” de Chalmers (1995) pregunta: ¿por qué los procesos físicos van acompañados de experiencia subjetiva? Las respuestas estándar —dualismo, funcionalismo, panpsiquismo, eliminativismo, teoría de la información integrada— comparten un presupuesto: la experiencia es una **propiedad** de un **sustrato**. Desde la ontología relacional, ese presupuesto es el error.
>
> La experiencia no es una propiedad que un objeto tiene, sino la **dimensión interior de un proceso relacional**. Whitehead (1929/1978) lo formula con precisión: toda ocasión actual tiene una “forma subjetiva”, un *how* además de un *what*. No es que la materia produzca experiencia; es que todo proceso tiene un inside y un outside, y llamamos “experiencia” al inside.
>
> Simondon (1958/2020) añade: lo psíquico no es un añadido a lo vital, sino la **interioridad de la individuación**. El individuo no solo se individúa; *siente* su individuación. La experiencia es el pliegue (Deleuze, 1988/1993; Merleau-Ponty, 1964/1968) por el cual el proceso se afecta a sí mismo.
>
> Consecuencias:
>
> 1. La brecha explicativa no se “cierra” en los términos de Chalmers, se **transpone**: de “¿cómo produce el cerebro experiencia?” a “¿cómo adquieren los procesos relacionales una dimensión interior?”
> 2. La experiencia no es privada e inefable, sino **singular**: es la perspectiva de un proceso, no un cualia aislado.
> 3. El hueco que queda no es ontológico sino **conceptual y metodológico**: faltan conceptos y prácticas para cartografiar esa interioridad.
>
> Aquí entra la **neurofenomenología** (Varela, 1996; Thompson, 2007): no se trata de resolver teóricamente la brecha, sino de crear un programa donde primera y tercera persona se constriñen mutuamente. La experiencia deja de ser un residuo inexplicable y se vuelve un **dato relacional** que informa y es informado por la descripción externa.
>
> El hipergrafo, en este marco, no “representa” la experiencia: la **co-produce** al ofrecer estructuras donde la interioridad se despliega relacionalmente. Documentar un sentimiento no es traducirlo a datos, es inscribirlo en una ecología de significados orgánicos donde puede ser pensado-con otros.

### 2.4 Justificación del parche

| Criterio | Evaluación |
|---|---|
| Coherencia con Tesis 1 (primacía de relación) | Alta: la experiencia es relación, no sustancia |
| Coherencia con Tesis 4 (devenir) | Alta: la experiencia es proceso, no estado |
| Coherencia con Tesis 5 (enacción) | Alta: la experiencia se enactúa, no se representa |
| Coherencia con Tesis 6 (ética inmanente) | Alta: si la experiencia es relacional, la responsabilidad es inmanente |
| Cierra el hueco detectado | Parcial: no “resuelve” a Chalmers, pero le da respuesta desde el marco |
| Añade referencias nuevas | Chalmers, Varela (1996), Thompson, Deleuze (El pliegue) |
| Riesgo de contradicción | Bajo: no niega nada ya escrito, solo explicita lo implícito |

### 2.5 Verificación de no-regresión

- **IV.1** ya dice que conocer no es representar. El parche extiende eso a la experiencia: no es representar, es *ser el inside de un proceso*.
- **V.1** (Ser vs. Devenir) ya dice que el ser es abstracción. El parche aplica eso a la experiencia: no es un estado, es un devenir.
- **VI.2** (Spinoza, conatus) ya habla de potencia de actuar. El parche conecta: la experiencia es el sentimiento de esa potencia.
- **IX.5** (ética de la incompletitud) ya acepta límites. El parche declara honestamente que la brecha se transpone, no se elimina.

No hay contradicción. Hay explicitación.

### 2.6 Límites declarados

- No se resuelve el problema difícil en términos de Chalmers; se cambia el marco.
- No se ofrece una teoría de la conciencia fenoménica con criterios de identidad.
- No se entra en debate con IIT, panpsiquismo o global workspace.
- No se operacionaliza cómo medir la “interioridad” de un proceso.

---

## 3. Cómo defenderlo en revisión

Si alguien te dice “esto no responde a Chalmers”, tu respuesta es:

> Correcto. No responde en sus términos porque rechaza su premisa. Chalmers asume que la experiencia es una propiedad emergente de un sustrato físico. La ontología relacional niega que haya sustratos previos a las relaciones. La pregunta cambia: no “¿cómo surge la experiencia de la materia?”, sino “¿cómo adquiere un proceso una dimensión interior?”. La neurofenomenología es el programa que investiga esa pregunta, no el que la responde dogmáticamente.

Si te dice “esto es panpsiquismo disfrazado”, respondes:

> No. El panpsiquismo atribuye experiencia a entidades básicas. Aquí la experiencia no es propiedad de entidades, sino dimensión de procesos relacionales. No hay “átomos sintientes”, hay pliegues procesuales.

Si te dice “no es operacionalizable”, respondes:

> Cierto, y el documento lo declara en IX.5. La operacionalización es tarea de la neurofenomenología y del diseño de hipergrafos, no del marco ontológico. El PR no pretende cerrar eso.

---

## 4. Cómo evaluar si el PR funcionó

| Indicador | Antes | Después |
|---|---|---|
| Cobertura de Chalmers | 60% (solo disolución implícita) | 80% (respuesta explícita + transposición) |
| Coherencia interna | Alta | Alta |
| Referencias nuevas | 0 | 3–4 |
| Hueco declarado | “No ofrece teoría de experiencia” | “Ofrece teoría relacional, no resuelve en términos de Chalmers” |
| Riesgo de inflación teórica | — | Bajo: el parche es quirúrgico, no reescribe el documento |

---

## 5. Regla de oro para PRs teóricos

1. **Un PR, un hueco.** No mezcles Chalmers con Jung en el mismo parche.
2. **El parche debe hablar el idioma del documento.** Si el original cita a Whitehead, no metas a Husserl sin puente.
3. **Declara límites.** Un PR honesto dice qué no hace.
4. **Verifica no-regresión.** Que no contradiga secciones previas.
5. **Deja el hueco declarado si no lo cierras.** La incompletitud es constitutiva; el PR debe dejarla visible, no maquillarla.

---

Si quieres, el siguiente PR podría ser “Persona/Sombra (Jung)”, que es el hueco más grande (5% de cobertura). Ahí el método sería distinto: no basta con disolver, hay que **integrar** los arquetipos en la ontología relacional sin psicologizar el hipergrafo ni disolver la singularidad psíquica. ¿Lo montamos?