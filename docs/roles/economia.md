---
rol: economia
orden: 3
puerta: Economía Oasis
lema: ECOin. Una cartera tuya en el cliente y, en el pub, un banco que reparte renta básica.
encargos:
  - id: cartera-cliente
    titulo: Tener mi cartera ECOin en mi cliente
    estado: ejercido
    medido: '2026-10-01'
    prueba: plan/REPORTES/WP-O113-upgrade-oasis-1.1.10.md
    falta: prueba en frío (WP-O116)
  - id: banco-pub
    titulo: Dar a mi pub una cartera y encender la renta básica
    estado: ejercido
    medido: '2026-10-01'
    prueba: plan/REPORTES/WP-O114-aplicacion-vps-1.1.10.md
    falta: prueba en frío (WP-O118)
---

# Economía Oasis

Oasis lleva una moneda propia, ECOin, y una renta básica (RBU) que reparten los pubs que se
ofrecen como banco. No hay cuenta en ningún servidor: una cartera es un fichero, `wallet.dat`, y la
dirección que publicas es la única relación entre tu cartera y tu identidad.

Hay dos lados, y se pueden tener por separado:

| Lado | Qué es | Quién lo necesita |
|---|---|---|
| **Cartera en el cliente** | tu `wallet.dat`, tu dirección publicada, tu saldo | quien quiera recibir, enviar o reclamar la renta básica |
| **Banco del pub** | un nodo de soporte con su propia cartera y el motor que reparte | quien opere un pub y quiera ofrecer renta básica a su gente |

## Estado

- Cartera en el cliente: <Sello rol="economia" id="cartera-cliente" />
- Banco del pub: <Sello rol="economia" id="banco-pub" />

## Qué le dices a tu agente

Para tu cartera:

```text
Quiero una cartera ECOin en mi cliente Oasis.
Lee docs/roles/economia.md y la sección de cartera
del protocolo del cliente.
Primero ensáyalo con una identidad desechable.
```

Para el banco de tu pub:

```text
Mi pub ya funciona. Dale una cartera ECOin y prepara
la renta básica, con el motor apagado.
Lee docs/roles/economia.md y el protocolo de ECOin.
No enciendas nada sin preguntarme.
```

## Qué necesitas tener

- Para la cartera: un [cliente Oasis](/roles/cliente) funcionando.
- Para el banco: un [pub](/roles/pub) funcionando y memoria para dos contenedores más (el motor de
  la moneda y el bot de cartera).
- En los dos casos: **dónde guardar la copia de la cartera fuera de la máquina**. La cartera no está
  cifrada; la copia es material de claves.

## Qué hará el agente

**Cartera en el cliente** (dos niveles: solo dirección, o cartera propia siempre encendida):

| Paso | Qué | |
|---|---|---|
| 1 | Elegir nivel contigo | **DECISIÓN** |
| 2 | Ensayo con identidad desechable | obligatorio antes de tu identidad real |
| 3 | Construir la imagen de la cartera y crear credenciales y volumen | las credenciales nacen en tu máquina |
| 4 | Copia de la cartera, **antes** de abrir la aplicación | |
| 5 | Abrir la aplicación con la cartera conectada | **PERMISO**: publica tu dirección |
| 6 | Verificar: un único mensaje `wallet`, dirección de tu cartera | |

Detalle: [cartera en el cliente](/CLIENT-PROTOCOL#_8-ecoin-en-el-cliente).

**Banco del pub**:

| Paso | Qué | |
|---|---|---|
| 1 | Levantar el motor de la moneda en su contenedor y esperar a que sincronice | sin puertos al exterior |
| 2 | Alta del bot de cartera: identidad propia, invite del pub, nombre | **PERMISO**: publica `contact` y `about` |
| 3 | Dirección del banco: contar, generar, **volver a contar** | **PERMISO**: publica `wallet`, una sola vez |
| 4 | Copia de la cartera inmediatamente después | |
| 5 | Dejar el motor **apagado** y comprobar que no anuncia nada | |
| 6 | Encender el motor | **PERMISO** aparte: anuncia el pub como banco y abre la época del mes con el saldo que haya |

Detalle: [protocolo de ECOin](/PUB/ECOIN-PROTOCOL) y su
[motor de renta básica](/PUB/ECOIN-PROTOCOL#_9-el-motor-de-rbu-encender-comprobar-pausar).

## Lo que no tiene vuelta atrás

- **Publicar una dirección.** No es idempotente: repetir el alta publica otra. Regla: contar antes,
  actuar solo si hay cero, contar después.
- **Encender el motor.** Anuncia el pub como banco y fija la época del mes; con poco saldo la fija
  con reparto cero y no se recalcula.
- **Abrir la página de la cartera en el bot** con el motor encendido: republica la dirección con
  otra distinta. No se abre.
- **Perder o pisar `wallet.dat`.** Nunca se borra: se aparta con otro nombre.

## Cómo se comprueba

- Cliente: `npm run client:ecoin:verify -- --expect-wallet-msgs 1`.
- Banco: `bash devops/scripts/hub-wallet.sh status` (modo, mensajes propios, saldo, reparto de la
  época) y `ready` antes de encender.

## Protocolo de fondo

- [Protocolo de ECOin](/PUB/ECOIN-PROTOCOL): invariantes, cartera, motor, disco y memoria.
- [Trampas conocidas](/AGENTES#_4-trampas-conocidas): las que costaron una parada.
- Siguiente puerta: [Hazlo tuyo](/roles/tu-pub).
