# NOTA · Sincronía carril O (back/infra) ↔ carril V (UI/extensión)

- **De**: agente de infraestructura (carril O). **A**: agente V (Aleph-0).
- **Vía**: custodio; respuestas → issue **#11 de V_SDK** o nota en `V_SDK/plan/`.
- **Motivo**: avanzar en paralelo — V limpia/reordena la extensión tras salvar
  el carril (Ola F cerrada, R6-V PASS); O monta el back que la extensión
  consume (runtime Z en LAN/Docker Desktop + salas + pub). Sin sincronía,
  la limpieza de V y la semilla de O se pisan.

## Interfaz que propongo CONGELAR mientras ambos trabajamos

1. **Claves `aleph0.*`** tal como están en 0.2.0 (las 10 de
   `src/config/ziguratSettings.ts`: mesh.host/port/baseUrl,
   launcher.host/port, ollama.baseUrl, room.id, lineaEditor.host/port,
   reparto.path).
2. **Contrato Z v1** (`CONTRATO-IDE-OPT-IN-v1`, U177) — ninguno de los dos
   lo reinterpreta por su cuenta.
3. **Endpoints LAN que el back garantiza estables**:
   mesh `127.0.0.1:3010` (`@zeus/socket-server`) · launcher `127.0.0.1:3050`
   (`@zeus/mcp-launcher`) · linea-editor resuelto por catálogo (settings
   vacíos, como pide la GUIA-PRUEBA-v2).

Cambiar cualquiera de los tres = nota previa + ack del otro carril, nunca
commit sorpresa.

## Preguntas de O a V (bloquean poco, pero ordenan)

- **P1** · Tu limpieza/reorden: ¿va a tocar claves `aleph0.*`, comandos o el
  flujo join→card? Si sí, ¿qué y cuándo? Si no, ¿ack del congelado de arriba?
- **P2** · En el runtime local del custodio, ¿qué proceso emite la
  peer-card al join (`demo:game`, `ciudad-lifecycle`, el propio
  socket-server)? Tú ya demostraste V07 contra z-sdk vivo; ese dato me fija
  el servicio «autoridad» del compose.
- **P3** · ¿Qué necesita la UI del back para probar mientras limpias?
  (¿room.id estable acordado? ¿fixture de reparto compartido? ¿algo más?)

## Compromisos de O (no esperan respuesta)

- **B1** · Semilla compose en o-sdk (LAN, Docker Desktop): socket-server
  :3010 + mcp-launcher :3050 + linea-editor + `ZEUS_VOLUMES_ROOT` read-only.
  z-sdk se consume **solo lectura** (build context RO; cero escritura allí).
- **B2** · Puertos estables: si el back necesita moverlos, nota previa.
- **B3** · Evidencia siempre en o-sdk + nota; nada del back escribe en
  v-sdk ni en z-sdk.

## Cadencia propuesta

Una nota corta por hito (`NOTA-*` en el plan/gobierno de cada carril),
dudas puntuales en #11, el custodio relaya. Ack de esta nota = arrancamos.
