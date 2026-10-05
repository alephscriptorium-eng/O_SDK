---
rol: cliente
orden: 1
puerta: Cliente Oasis
lema: Tu nodo en tu máquina. Tu identidad, tu muro, tu cartera si la quieres.
encargos:
  - id: cliente
    titulo: Arrancar un cliente Oasis en mi máquina
    estado: ejercido
    medido: '2026-10-05'
    prueba: plan/REPORTES/WP-O124-upgrade-oasis-1.2.2.md
    falta: que arranque también sin GPU NVIDIA y sin el modelo de IA; prueba en frío (WP-O116)
  - id: cliente-con-cartera
    titulo: Arrancar un cliente Oasis con cartera ECOin
    estado: ejercido
    medido: '2026-10-05'
    prueba: plan/REPORTES/WP-O124-upgrade-oasis-1.2.2.md
    falta: lo mismo, y una secuencia única de principio a fin; prueba en frío (WP-O116)
---

# Cliente Oasis

Un nodo personal de Oasis en tu ordenador: la aplicación web en `http://localhost:3000`, tu
identidad en un fichero tuyo y, si quieres, una cartera ECOin también tuya.

## Estado

- Cliente: <Sello rol="cliente" id="cliente" />
- Cliente con cartera: <Sello rol="cliente" id="cliente-con-cartera" />

**Qué funciona hoy.** El cliente corre de verdad en la demo, con su identidad y su cartera, en una
máquina con GPU NVIDIA; y se ha ensayado con una identidad desechable. **Con qué condición:** el
arranque normal exige esa GPU (`docker-compose.yml` reserva el dispositivo) y, si no se le dice lo
contrario, descarga un modelo de IA de unos 4 GB. En una máquina sin ella el arranque falla: el
agente tiene que parar y decírtelo; no debe improvisar un arreglo sobre tu identidad real.
**Qué no:** las llamadas y salas de voz de Oasis (Phone y Rooms) no funcionan dentro del
contenedor, que no tiene acceso al micrófono ni a los altavoces de la máquina.

## Qué le dices a tu agente

```text
Hola. He clonado o-sdk y tengo Docker Desktop arrancado.
Arráncame un cliente Oasis con cartera.
Lee docs/roles/cliente.md y sigue esa receta.
```

Sin cartera, quita «con cartera».

## Qué necesitas tener

- Docker Desktop arrancado, y `git`, `bash` (en Windows, Git Bash) y `npm`.
- Sitio para una imagen de unos 5 GB (y 4 GB más si quieres la IA) y, la primera vez, 10-20
  minutos de construcción.
- Hoy, además: GPU NVIDIA con su runtime de Docker. Sin ella el arranque falla; quitar ese requisito
  es trabajo pendiente (WP-O116).
- Un sitio **fuera de la máquina** donde guardar dos copias: la de tu identidad y la de tu cartera.

## Qué hará el agente

| Paso | Comando | Salida esperada | |
|---|---|---|---|
| 1 | `docker info` | el motor responde; lista el runtime `nvidia` | si no lo lista: **parar** |
| 2 | — | ¿identidad nueva o una que ya tienes? ¿con IA o sin ella? ¿solo dirección o cartera propia? | **DECISIÓN** |
| 3 | `npm run build` | imagen del cliente construida | |
| 4 | `npm run setup` | carpetas de datos en `volumes-dev/` | |
| 5 | `npm run ecoin:build` | imagen de la cartera; el paquete se verifica por su huella | solo con cartera |
| 6 | `npm run client:ecoin:init -- --mode own` | credenciales generadas, volumen de la cartera creado | solo con cartera |
| 7 | `npm run ecoin:up` | cartera `healthy` | solo con cartera |
| 8 | `npm run client:wallet:backup` | copia de la cartera con su huella | **antes** de abrir la aplicación |
| 9 | — | abrir la aplicación con la cartera conectada **publica tu dirección** | **PERMISO** |
| 10 | `docker compose up -d oasis-client` | contenedor `healthy`; tres parches aplicados; versión en el log | |
| 11 | `npm run client:ecoin:verify -- --expect-wallet-msgs 1` | todo en PASS; exactamente un mensaje `wallet` | solo con cartera |
| 12 | `npm run client:backup-keys` | copia de tu identidad | llévala fuera de la máquina |
| 13 | — | ¿a qué red te unes? Un pub te da un invite; redimirlo te conecta | **DECISIÓN** y **PERMISO** |

Si traes una identidad que ya existe, el camino es otro y más delicado: el agente sigue
[importar una identidad](/CLIENT-PROTOCOL#_2-importar-una-identidad-existente) y no usa el paso 10
hasta haber sincronizado.

## Lo que no tiene vuelta atrás

- **Publicar la dirección de tu cartera** (paso 9). Con la cartera conectada ocurre sola al abrir la
  aplicación. Por eso la copia va antes.
- **Redimir un invite** (paso 13): publica que sigues a ese pub.
- **El botón «desconectar cartera»** de los ajustes: no es un interruptor, publica una dirección
  vacía. No se usa.
- **Arrancar la aplicación con una identidad traída de otro sitio y el historial vacío**: parte tu
  cuenta en dos.

La tabla completa, con la puerta de cada una: [acciones irreversibles](/AGENTES#_3-acciones-irreversibles-y-su-puerta).

## Cómo se comprueba

- `docker ps`: `oasis-client` en `healthy`.
- La aplicación abre en `http://localhost:3000` y los ajustes muestran la versión.
- Con cartera: el paso 11 da todo en PASS y cuenta **un** mensaje `wallet`.
- La lista completa: [comprobaciones del cliente](/CLIENT-PROTOCOL#_5-healthcheck).

## Si algo no sale

El agente para y te cuenta el comando y su salida. No busca otro camino sobre tu identidad. Si lo
que se ha roto es el disco, el repo o la identidad: [recuperación](/PUB/RECOVERY-PROTOCOL), y no se
toca nada antes de su primer paso.

## Protocolo de fondo

- [Protocolo del cliente](/CLIENT-PROTOCOL): alta, importar identidad, subir de versión, volver atrás.
- [Cartera en el cliente](/CLIENT-PROTOCOL#_8-ecoin-en-el-cliente): los dos niveles, copia y
  restauración, y el [ensayo con identidad desechable](/CLIENT-PROTOCOL#_8-9-drill-con-identidad-desechable).
- Conectar una cuenta de Mastodon: [guía de upstream](/FEDIVERSE/MASTODON/connect) (en inglés).
- Siguiente puerta: [Economía Oasis](/roles/economia).
