# 06 — Elementos de diseño del ensayo (D1–D16), extraídos sin juicio

Leyenda: [V] leído · [E] · [NV] · `<pendiente>`. Fuente única:
`../dosier-relacional/01-relacional.md` [V] (líneas del markdown extraído;
cotejo humano contra el PDF `<pendiente>`, ver `00-dictamen.md`).

Qué es un «elemento de diseño»: una frase del ensayo que pide algo a un
sistema (estructura, operación, interfaz, política), no una tesis filosófica
por sí sola. Las seis tesis (§VIII, `:321-343`) se citan como T1–T6 y se
cruzan con los D.

| id | Sección · línea | Enunciado operacional (verbatim o casi) | Tesis |
| :-- | :-- | :-- | :-- |
| D1 | §3.1 `:132` | «Un nodo sin aristas es un potencial no actualizado. El nodo "es lo que es" por sus conexiones… Un hipergrafo sin relaciones no es nada; las relaciones son el grafo.» | T1 |
| D2 | §3.2 `:136-142` | Relaciones **n-arias** no reducibles a binarias. Ejemplo: «relación de tipo COLLABORATION con source_nodes={A,B} y target_nodes={C}». | T2 |
| D3 | §3.3 `:146-152` | Un mismo hipergrafo admite múltiples **proyecciones** (perspectivas, atributos) que generan grafos distintos: «Filtrar por atributo X genera grafo G_X; filtrar por Y genera G_Y… actualizaciones parciales de un virtual.» Atributos = operadores de actualización, no decoraciones. | T3 |
| D4 | §3.4 `:156-166` | «Borrar un archivo solo borra una proyección. Si borras el archivo, puedes recuperarlo por fragmentos.» Un archivo = configuración de fragmentos; la recuperación es re-individuación desde trazas, no restauración de copia. | T4 |
| D5 | §3.5 `:174-176` | **Meta-grafo autopoiético**: «un hipergrafo que registra su propio uso (nodos sobre nodos, relaciones sobre relaciones)… Cada consulta perturba el grafo (crea nuevas relaciones: "consulta X activó nodos Y, Z")». Drift semántico; «metabolismo semántico». | T5 |
| D6 | §4.2 `:198` | «Cada usuario construye un grafo desde su propia trayectoria… haces de grafos situados que pueden interoperar (compartir nodos, traducir ontologías). La objetividad emerge de la capacidad de conexión.» | T3 |
| D7 | §4.3 `:208` | Similitud por posición isomorfa en estructuras relacionales, no por propiedades intrínsecas: «embeddings, graph kernels. La navegación semántica es navegación por analogías.» | T5 |
| D8 | §5.1 `:228` | «Cada commit (versión) es una cristalización provisional, pero el grafo "vivo" incluye el flujo de modificaciones. El versionado git no es añadido externo sino temporalidad inmanente del grafo.» | T4 |
| D9 | §9.1 `:349-351` | **Interfaces enactivas**: «no deben "mostrar datos" sino invitar a co-producciones. El navegador de hipergrafo es espacio de exploración activa: arrastrar nodos, crear relaciones, filtrar perspectivas. El usuario no consume información sino que piensa-haciendo.» | T5 |
| D10 | §9.2 `:353-357` | **Interoperabilidad sin imperialismo ontológico**: trading zones, pidgins locales; «una comunidad usa taxonomía arbórea, otra folksonomy. El hipergrafo permite ambas como proyecciones del mismo substrato relacional. La interoperabilidad es parcial, pragmática.» | T3 |
| D11 | §9.3 `:359-361` | **Documentación como metabolismo**: «editables, versionados, relacionables. No hay versión final, solo palimpsestos (textos sobrescritos que conservan trazas).» | T4, T5 |
| D12 | §9.4 `:363-372` | **Texto como hipergrafo**: seleccionar una palabra y ver co-ocurrencias, etimología, intertextualidad, semántica distribucional (embeddings). «La lectura se vuelve hipertextual-relacional, no lineal.» | T5 |
| D13 | §9.5 `:374-382` | **Ética de la incompletitud**: no aspirar a mapear todo; «valorar las lagunas como espacios de potencial»; «documentar lo que no se sabe tanto como lo que se sabe (meta-ignorancia)»; «aquí hay dragones». | — (§2.6) |
| D14 | §2.5 `:98-105` | **Free hypergraph**, cuatro libertades: ontológica (múltiples ontologías coexisten), epistemológica (múltiples perspectivas sobre los mismos nodos), política (licencias abiertas, gobernanza horizontal), técnica (interoperabilidad, estándares abiertos). «No basta con descentralización técnica si el contenido es propietario.» | T3 |
| D15 | §2.5 `:92-96` | «Un hipergrafo es descentralizado pero no necesariamente distribuido (no todos conectados con todos)»; rizoma: «algunos nodos más conectados que otros (power-law), pero no hay jerarquía estructural». | — |
| D16 | §6.3 `:276` | «La elección de qué relaciones registrar, qué ontología usar, qué hacer visible, es ético-política. El hipergrafo no es espejo sino agente en la configuración de mundos.» | T6 |

## Otras frases del ensayo con carga de diseño (no numeradas; para ampliar D si hace falta)

- §2.1 `:40`: «cada nodo es simultáneamente privado (perspectiva singular) y
  público (potencialmente relacional)»; «gradientes de intimidad en un
  continuum relacional» (`:46`).
- §2.2 `:58`: strange loops: «un nodo puede ser fuente y destino
  simultáneamente, las categorías pueden contener sus propias instancias, el
  sistema puede observarse a sí mismo».
- §2.3 `:70`: «El hipergrafo registra trayectorias pasadas (las relaciones ya
  establecidas constriñen) pero permite nuevas conexiones imprevisibles…
  procesual-abierta.»
- §2.4 `:88`: «El hipergrafo no almacena datos sino que cultiva ecologías de
  sentido donde los significados emergen de las conexiones actualizadas en
  cada consulta/navegación.»
- §2.6 `:117-119`: «cartografía situada… La "verdad" del grafo es su utilidad
  pragmática»; «grafos mejores/peores según criterios pragmáticos
  (coherencia, fertilidad, apertura)».
- §5.2 `:240`: «cristalizaciones provisionales (documentos, nodos)… deben
  permanecer porosas (editables, relacionables)… morfologías fluidas».
- §7.3 `:313-315`: «vincular A con B produce un sentido que no estaba ni en A
  ni en B por separado. La escritura hipergrafo es generativa, no
  representativa.»
- §X `:394`: «pensar-con, no pensar-sobre… companion species».
- Fin `:454`: «Como todo texto, es caricatura de lo que intenta decir, y por
  tanto requiere lectores que lo completen relacionándolo con sus propias
  trayectorias.»

## Las seis tesis (§VIII `:321-343`, verbatim de encabezado)

T1 Primacía de la relación · T2 Irreductibilidad de lo múltiple · T3
Perspectivismo sin relativismo · T4 Devenir como realidad última · T5
Enacción del conocimiento · T6 Ética inmanente.

## Datos del documento (de `00-dictamen.md` [V])

Ensayo en castellano, 29 págs., ~5.800 palabras; subtítulo «Hipergrafo como
Onto-lógica de la Individuación Transindividual»; autor declarado «Síntesis
conceptual de conversación Marc/Dídac», 2025-12-26; 10 secciones, 29
subsecciones, 6 tesis, 4 citas reinterpretadas, 47 referencias. **Licencia:
ninguna declarada.** Permiso de autoría `<pendiente>` antes de publicar
derivados bajo GPL-3.0 + Animus Iocandi (`00-dictamen.md:99-102`).
