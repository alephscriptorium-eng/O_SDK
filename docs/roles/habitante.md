---
rol: habitante
orden: 0
puerta: Habitante
lema: Solo quieres entrar y usar la red, con tu móvil. Sin servidor, sin terminal y sin agente.
encargos:
  - id: entrar-con-el-movil
    titulo: Instalar Oasis en mi móvil y entrar en la red de un pub
    estado: en-obras
    medido: '2026-10-05'
    falta: que alguien recorra el manual de principio a fin con un móvil contra un pub desplegado con este SDK, y lo deje escrito
---

# Habitante

Un **habitante** es una persona en Oasis. Esta puerta es para quien no va a montar nada: instala
la app en su móvil, alguien le da un código de invitación y ya está dentro. Las demás puertas
hablan con un agente de código; **esta no lo necesita**.

## Estado

- Entrar con el móvil: <Sello rol="habitante" id="entrar-con-el-movil" />

**Qué hay hoy.** El manual de la red, publicado aquí como plantilla, y la lista de lo que cambia
cuando el pub corre con este SDK. **Qué no:** el camino del móvil no se ha medido en este repo. Lo
que sí está medido es el otro extremo: el pub, su ventana web y el cliente de escritorio (puertas
[Pub](/roles/pub) y [Cliente](/roles/cliente)).

## Dos cosas distintas, y cuál es cuál

| | Qué es | De quién es |
|---|---|---|
| **El manual de la red** | Cómo instalar la app, entrar con una invitación, encontrar gente, usar tribus, cuidar tu identidad. Vale en **cualquier** pub de Oasis | Del proyecto Oasis: está hecho con sus materiales |
| **Lo de este SDK** | Cómo reparte invitaciones, qué ofrece y qué acota un pub desplegado con estos contenedores | De este repo |
| **Lo de cada casa** | El dominio, cómo se entra, qué servicios tiene encendidos | De quien monta el pub: va en su ficha |

Empieza por el manual:

**[Manual de bienvenida a la red →](/habitante/manual)**

Es una plantilla: tiene huecos (el Wi-Fi, la mesa técnica, el dominio) que rellena cada pub antes
de imprimirlo o repartirlo.

## Si tu pub corre con este SDK

::: tip De este SDK
Esta sección **no es el manual de la red**: es lo que este repo hace a su manera. El manual
describe un pub instalado directamente (`./oasis.sh …`). Un pub de este SDK corre en contenedores,
así que para **quien organiza** cambian los comandos, y para **quien entra** cambian unas pocas
cosas. Nada de esto contradice el manual: lo concreta.
:::

| El manual dice | Con este SDK |
|---|---|
| «Pide un código en la mesa técnica» (`./oasis.sh invite`) | El operador los genera con `bash devops/scripts/generate-invite.sh [usos]`. Además, la **portada del pub** que trae el SDK muestra un código de muchos usos (1000 si no se cambia `PUB_INVITE_USES`): quien llega a la web del pub puede copiarlo de ahí |
| «Te entrega una instantánea del contenido reciente» | El pub la reconstruye él solo cada 6 horas (`OASIS_PUB_SNAPSHOT_HOURS`). Solo se la da a quien ya ha entrado con su invitación |
| «La ventana pública es `https://<dominio>/c`» | La sirve un nodo de soporte aparte, de solo lectura, detrás de una caché. Solo enseña lo que cada habitante ha marcado como público |
| «Vigila la red: `./oasis.sh status`» | `bash devops/scripts/deploy-status.sh` |
| «Gente nueva con portátil: `git clone` … `./oasis.sh`» | La puerta [Cliente](/roles/cliente): el mismo Oasis en un contenedor, con tu identidad en un fichero tuyo |
| Phone y Rooms (llamadas y salas de voz, desde Oasis 1.2.2) | El pub hace de relevo de llamadas **acotado**: solo para la gente que ha entrado por él, y con aforo limitado en las salas. En el cliente de escritorio en contenedor **no funcionan**: el contenedor no tiene micrófono ni altavoces |
| «Los PUB que se apuntan pagan una renta básica» | Depende de que el pub tenga cartera y fondos: puerta [Economía](/roles/economia) |

Los detalles para quien opera están en los protocolos: [HUB clearnet](/PUB/HUB-PROTOCOL) (la
ventana `/c`, la instantánea, el relevo de llamadas) y [protocolo para agentes](/AGENTES).

## Lo de cada casa

Cada pub rellena su hoja: dominio, cómo se entra y qué tiene encendido. La
[ficha de instancia en blanco](/PUB/INSTANCIA-PLANTILLA) trae el bloque «Hoja del habitante» para
eso. Como ejemplo relleno, [la hoja de la demo](/PUB/INSTANCIA-SCRIPTORIUM-HABITANTE).

## Lo que conviene saber antes de entrar

- **Tu identidad es una clave en tu móvil.** Si la pierdes sin copia, nadie puede devolvértela.
  Haz la copia el primer día (sección 9 del manual).
- **Lo público es público y no se borra.** Un mensaje publicado se queda en los dispositivos de
  quien te sigue.
- **El pub no puede leer tus mensajes privados**, ni escuchar las llamadas que retransmite. Sí
  ve quién se conecta y cuándo.
