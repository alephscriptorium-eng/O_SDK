# ¿Quién llega?

Oasis es una red social que corres tú. Este repo la empaqueta en contenedores y trae el método para
operarla. **No hace falta saber Docker ni SSB para empezar**: clonas el repo, abres en él un agente
de código y le dices qué quieres. El agente lee la receta de tu puerta, hace el trabajo y se para
donde la decisión es tuya.

Las puertas van de menos a más: un cliente en tu máquina, un pub en tu servidor, la economía de la
red y, al final, una instancia que es tuya de arriba abajo.

<Puertas />

## Cómo se usa una puerta

1. Clona el repo: `git clone https://github.com/alephscriptorium-eng/O_SDK.git`
2. Abre un agente de código en esa carpeta. El repo le dice cómo comportarse: `AGENTS.md` en la raíz
   y el [protocolo para agentes](/AGENTES), con sus cinco leyes.
3. Dile el **encargo** de tu puerta, tal cual o con tus palabras.
4. El agente te preguntará lo que solo tú puedes decidir y te pedirá permiso antes de cada paso que
   no tiene vuelta atrás. Eso no es un fallo del agente: es la regla.

## Qué significa el sello

Cada encargo lleva el estado **medido**, no el deseado.

| Sello | Qué garantiza |
|---|---|
| **probado en frío** | Un agente sin contexto, solo con el repo y el encargo, lo completó. Cita el reporte. |
| **ejercido en la demo** | Se ha hecho de verdad en el pub de demostración, siguiendo el protocolo, por quien lo escribió. Cita el reporte. Falta la prueba en frío. |
| **en obras** | Hoy no se cumple entero. Dice qué falta. El agente puede avanzar hasta ahí y debe decírtelo. |

Hoy ningún encargo está «probado en frío». Lo que hay es un pub de demostración en producción que
ejerce cada pieza, y un protocolo por pieza. Las pruebas en frío son el trabajo siguiente.

## Lo que vale para todas las puertas

- **Tu identidad es un fichero**: `secret`. Si lo pierdes, pierdes la cuenta; si se publica algo
  con él, no se borra. El agente no lo imprime ni lo copia a ningún sitio sin decírtelo.
- **Un mensaje publicado no se retira.** Por eso hay una
  [tabla de acciones sin vuelta atrás](/AGENTES#_3-acciones-irreversibles-y-su-puerta) y el agente
  pide permiso cada vez.
- **Primero se ensaya.** Lo que publica o toca una cartera se prueba antes con una identidad
  desechable.
