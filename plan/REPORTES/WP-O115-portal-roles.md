# Reporte · WP-O115 · Portal: puertas por rol con estado medido, sin canibalizar lo que hay

- **Fecha**: 2026-10-01 · **Rama**: `wp/O115-portal-roles` · **Asiento**: D-O26.
- **Resultado**: el portal (`o-sdk.escrivivir.co`) gana una entrada por rol en la que cada página es
  a la vez la receta que lee el agente, con el encargo literal y un sello de estado por encargo.
  La versión de Oasis deja de escribirse a mano. Un gate nuevo impide publicar un sello sin reporte,
  una versión escrita a mano o el nombre de la demo en una puerta.
- **Origen**: la portada decía «Oasis 1.1.2» (va por 1.1.10) y el banner «todavía no es útil de
  verdad — faltan ~7 releases», con un pub en producción que tiene HUB, cartera y Teatro. La
  navegación era una lista plana de once protocolos: servía a quien ya sabía qué buscaba.
- **Decidido con el custodio**: solo la web, con estado honesto (el trabajo de repo que haría verdad
  los encargos «en obras» va al backlog); el banner conserva la voz y cambia el hecho; la doctrina
  del portal se mantiene. Estructura de menos a más: cliente → pub → economía → «cualquiera puede
  hacer su pub». La demo tiene nombre propio y fuera de su ficha no hace falta.
- **Publicación**: el push a `main` despliega el sitio. Queda a la espera del GO del custodio.

## Qué se entregó

| Pieza | Commit |
|---|---|
| `docs/roles/` (índice y cinco puertas), `Sello`, `Puertas`, `Vivo`, cargador `roles.data.mjs`, navegación, ficha plantilla | `3821e8c` |
| Banner al día, misma voz, con la versión inyectada | `590d1e6` |
| Portada: acción y sección «¿Quién llega?»; «Empezar» → «Llévatela» | `51e1dea` |
| Lo que enseñó la vista previa: banner y navegación en anchos medios y móvil, encargos que desbordaban | `40fed3a` |
| `docs/AGENTES.md` §0 «¿Quién te manda?»; `AGENTS.md` | `337fdd3` |
| `BASE-1/2/3` al día: versión paramétrica, agente y demo como actores, ceguera por ámbito | `a1328f4` |
| `legacy.html` deja de publicarse → `ARCHIVO/portal/` | `e50978c` |
| `CLIENT-PROTOCOL.md` sin los datos de una ejecución; ficha de la demo al día | `d1ee369` |
| `README.md` y `docs/proyecto.md`: puertas, versión viva, requisito de GPU corregido, «Contribuir» | `277316e` |
| Dos menciones a la cuenta anulada en el Roadmap | `b50e223` |
| Gate: `verdad-checks.json`, `docs-ceguera.sh` + base, `docs:verificar`, CI | `385d332` |

## Estado que publica cada puerta

Medido el 2026-10-01. **Ningún encargo está «probado en frío»**: nadie lo ha completado todavía con
un agente sin contexto.

| Puerta | Encargo | Sello | Prueba o lo que falta |
|---|---|---|---|
| Cliente Oasis | arrancar un cliente | en obras | el compose pide GPU NVIDIA y baja un modelo de ~4 GB (`docker-compose.yml:72-79`) → WP-O116 |
| Cliente Oasis | cliente con cartera | en obras | ídem → WP-O116 |
| Pub Oasis | pub simple | en obras | no existe «el pub y nada más» → WP-O117 |
| Pub Oasis | lectura web (HUB clearnet) | ejercido en la demo | reporte WP-O114 |
| Pub Oasis | acoger una obra (Teatro) | ejercido en la demo | reporte WP-O100 |
| Economía Oasis | cartera en el cliente | ejercido en la demo | reporte WP-O113 |
| Economía Oasis | banco del pub y renta básica | ejercido en la demo | reporte WP-O114 |
| Hazlo tuyo | instancia propia | en obras | WP-O117 |
| Mantener | subir de versión | ejercido en la demo | reporte WP-O114 |
| Mantener | recuperar | ejercido en la demo | reporte WP-O98 |

Los dos encargos que motivaron el trabajo («arráncame un cliente Oasis con cartera en mi Docker
Desktop», «despliega un pub simple sin nada de la demo») salen publicados **en obras**, con lo que
falta y dónde se hace. La receta le dice al agente hasta dónde puede llegar hoy y dónde para.

## Criterios de aceptación · evidencia

| Criterio | Comando | Salida |
|---|---|---|
| Gate completo en verde | `npm run docs:verificar` | `html=73` · `enlaces internos rotos: 0` · `anclas rotas: 0` · `verdad de contenido: 0 fallo(s)` · `[verificar-piel] OK: piel «familia-vp» renderiza en home` · `[verificar-contraste-piel] OK` (sobre `docs/.vitepress/theme/custom.css`) · `CEGUERA OK` |
| La versión sale del sistema | `node -p "require('./src/server/package.json').version"` frente al `dist` | `1.1.10`; en `dist/index.html`: «Hoy lleva Oasis 1.1.10». El patrón `data-vivo="oasisVersion">\d+\.\d+\.\d+<` aparece 62 veces |
| Todo sello «ejercido» cita reporte | recuento de `class="zine-sello"` en el `dist` | `ejercido` con `data-prueba="…"`: 18 · `en-obras`: 12 · `ejercido` sin prueba: 0 |
| El gate de verdad muerde | copia del `dist` con un sello «ejercido» al que se le quita `data-prueba`; `verificar-sitio.mjs` sobre la copia | `✗ VERDAD una puerta dice «probado» o «ejercido» sin citar su reporte` · `rc=1` |
| Cada check prohibitivo caza su caso | los cinco patrones `noDebeAparecer` contra un caso malo sintético | cinco `true`; en el `dist` real, cinco `0` |
| Las puertas no nombran a la demo | `grep -rnE 'escrivivir\|[Ss]criptorium' docs/roles docs/PUB/INSTANCIA-PLANTILLA.md` | una línea: la URL de la forja en `roles/index.md` (excepción declarada) |
| El gate de ceguera muerde | añadir «visita pub.escrivivir.co» a `docs/roles/pub.md`; `docs-ceguera.sh` | `FALLA ámbito ciego` · `docs/roles/pub.md:117` · `rc=1` (revertido) |
| Trinquete de los protocolos de método | `docs-ceguera.sh` | `52 menciones en los protocolos de método (base 52)` |
| Las URL publicadas se conservan | lista de `*.html` del `dist` de `main` (67) frente al nuevo (73) | desaparece `./legacy.html`; entran `PUB/INSTANCIA-PLANTILLA.html` y `roles/{cliente,economia,index,mantener,pub,tu-pub}.html` |
| Vista previa | capturas con Chrome sin cabeza a 1280, 1000, 820 y 500 px: portada, `/roles/`, puerta del cliente, puerta del pub | banner, navegación, tarjetas y bloques de encargo sin desbordar. En tema oscuro, `/roles/` y la puerta del pub a 1280 px: sellos y tarjetas legibles |

## Qué se conserva

Hero y líneas-sello, las cuatro fichas de la portada, la piel, `proyecto.md`, los once protocolos y
el grupo «Operación», el Roadmap, el pie y la marca. Todo lo nuevo es aditivo. Único borrado de lo
publicado: `legacy.html`, que enlazaba a la cuenta anulada y cargaba fuentes de terceros y a la que
nada enlazaba.

## Lo que encontró el gate al montarlo

1. **Dos menciones a la cuenta de origen anulada** en dosieres publicados del Roadmap
   (`aleph-net/02`, `aleph-net/07`). Corregidas (`b50e223`). Es deuda de WP-O72, que sigue abierto
   para lo que no es el portal.
2. **El gate de contraste del skill medía su propia plantilla**, no el CSS del portal. Medido sobre
   `custom.css` fallaba un par de cuatro («enlace base: texto tinta»), ya antes de este WP: el color
   llegaba heredado de `--vp-c-brand-1`, que ya era la tinta. La regla ahora lo declara; revisado en
   capturas de `/roles/` y `/roles/pub` tras el cambio.
3. **La piel que pasa es `familia-vp`** con tokens de fanzine; `--piel fanzine` falla. No se cambia
   de piel: el gate usa la que el sitio tiene.

## Correcciones durante el trabajo

- El cargador de datos tiene que ser `roles.data.mjs`: el `package.json` del repo no declara
  `"type": "module"` y un `.data.js` no carga.
- `vitepress preview` guarda la lista de ficheros: tras cada build hay que reiniciarlo o sirve la
  página sin estilos.
- El banner tiene altura fija por tramo de ancho: con el texto nuevo desbordaba a 1000 px y por
  debajo de 520 px. Tramos ajustados.
- Un `data-prueba` vacío sale en el HTML como atributo sin valor (`data-prueba>`): el patrón del
  gate cubre las dos formas.
- Dos afirmaciones de la exploración inicial resultaron falsas al medirlas (que faltaba
  `verificar-sitio.mjs` en local; que el Roadmap tiene seis dosieres: son siete). No entraron.

## Límites de lo que se ha comprobado

- El tema oscuro se ha mirado en dos páginas y a un solo ancho; la portada y el móvil, solo en claro.
- El contraste se comprueba por reglas declaradas en el CSS, no midiendo la página pintada.
- La CI nueva corrió con el push de la rama (run `36909134770`, commit `1ad2bee`): `docs:build: success`,
  con `html=73`, `verdad de contenido: 0 fallo(s)`, piel y contraste `OK`, `CEGUERA OK`;
  `deploy Pages: skipped`. El despliegue en sí solo se verá con el push a `main`.
- Los sellos «ejercido» se apoyan en reportes de trabajos hechos sobre la demo; ninguno es una
  prueba de la receta tal como está escrita. Eso es WP-O118.

## Qué queda abierto

| WP | Qué | Efecto en el portal |
|---|---|---|
| WP-O116 | Cliente sin GPU ni modelo por defecto; secuencia única con cartera; unirse a una red como decisión | Cliente → probado |
| WP-O117 | Pub mínimo por instancia; guardas en los scripts que publican el nombre de la demo por defecto (`publish-profile.sh:4-5`, `announce-pub.sh:9`) | Pub simple y «Hazlo tuyo» → probado |
| WP-O118 | Prueba de agente en frío de las puertas ejercidas | ejercido → probado |
| WP-O72 | Cuenta anulada fuera del portal | — |
