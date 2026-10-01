---
rol: pub
orden: 2
puerta: Pub Oasis
lema: Un pub en tu servidor. El punto de encuentro donde tu gente se sincroniza.
encargos:
  - id: pub-minimo
    titulo: Desplegar un pub simple en mi servidor
    estado: ejercido
    medido: '2026-10-01'
    prueba: plan/REPORTES/WP-O114-aplicacion-vps-1.1.10.md
    falta: la variante de solo el pub, sin las piezas de la demo (WP-O117); prueba en frío
  - id: hub-clearnet
    titulo: Añadir a mi pub la lectura pública en la web (HUB clearnet)
    estado: ejercido
    medido: '2026-10-01'
    prueba: plan/REPORTES/WP-O114-aplicacion-vps-1.1.10.md
    falta: prueba en frío (WP-O118)
  - id: teatro
    titulo: Acoger una obra en el Teatro de mi pub
    estado: ejercido
    medido: '2026-09-18'
    prueba: plan/REPORTES/WP-O100-teatro-puerta-semantica.md
    falta: prueba en frío (WP-O118)
---

# Pub Oasis

Un pub es un nodo siempre encendido, con dirección pública, al que los clientes se conectan para
sincronizarse entre sí. No guarda cuentas ni contraseñas: replica lo que sus habitantes publican.
Corre la misma imagen que el cliente, en otro modo.

## Estado

- Pub simple: <Sello rol="pub" id="pub-minimo" />
- HUB clearnet: <Sello rol="pub" id="hub-clearnet" />
- Teatro: <Sello rol="pub" id="teatro" />

**Qué funciona hoy.** Hay un pub de demostración en producción, con su HUB, su economía y su
Teatro, desplegado y subido de versión con este repo, y un protocolo por pieza. **Con qué
condición:** el despliegue que trae el repo levanta el pub **y** las piezas de la demo (lectura
web, panel, página de inicio, otros dominios). No existe todavía el «pub y nada más». Si es eso lo
que quieres, el agente puede preparar tu servidor y tu ficha, y debe parar antes de desplegar algo
que no has pedido.

## Qué le dices a tu agente

```text
Mira, esta es mi clave SSH para entrar en mi servidor.
Despliega un pub Oasis simple, mío, sin nada de la demo.
Lee docs/roles/pub.md y sigue esa receta.
```

Para ampliar un pub que ya corre:

```text
Mi pub ya funciona.
Añádele la lectura pública en la web (el HUB clearnet).
Lee docs/roles/pub.md y el protocolo del HUB.
```

## Qué necesitas tener

- Un servidor con Linux y acceso por SSH. El método está medido en Debian 13 con 4 GB de memoria.
- Tu clave SSH. El agente la usa desde `devops/.ssh/`, que queda fuera de git; no la imprime.
- Un dominio, o al menos una IP fija. Con dominio hay certificado y web; con IP sola basta para que
  los clientes se conecten.
- El puerto 8008 abierto (y 80/443 si vas a servir web).

## Qué hará el agente

| Paso | Qué | Salida esperada | |
|---|---|---|---|
| 1 | Leer el [protocolo para agentes](/AGENTES): reglas e irreversibles | — | |
| 2 | Crear tu instancia: `devops/hosts/` con tu host, tu usuario y el nombre de tu clave | los scripts apuntan a **tu** servidor | ver [Hazlo tuyo](/roles/tu-pub) |
| 3 | Medir el servidor sin tocarlo: sistema, disco, memoria, puertos, Docker | un informe | **solo lectura** |
| 4 | Preparar la base del servidor | Docker, cortafuegos, carpetas de datos | **PERMISO**: escribe en tu servidor. El script actual pide un segundo disco y lo formatea: si no lo tienes, **parar** |
| 5 | Desplegar el pub | el pub responde en el 8008. **Hoy, parar aquí** si lo quieres sin las piezas de la demo: el despliegue del repo las arrastra | **DECISIÓN**. La variante de solo el pub está pendiente (WP-O117) |
| 6 | Dar nombre al pub y anunciarlo | perfil publicado, pub visible | **PERMISO**: son mensajes que no se retiran |
| 7 | Generar un invite y comprobarlo con un cliente | un cliente se conecta y se sincroniza | |

## Ampliar un pub que ya corre

Cada pieza es un contenedor más, con identidad propia, que no toca al pub.

| Pieza | Para qué | Receta |
|---|---|---|
| HUB clearnet | que lo que tus habitantes marcan como público se lea en la web, con caché, mapa del sitio y RSS | [Protocolo del HUB](/PUB/HUB-PROTOCOL) |
| Teatro | publicar obras como sitios estáticos firmados, con su catálogo | [Protocolo del Teatro](/PUB/TEATRO-PROTOCOL) · [curaduría](/PUB/TEATRO-CURADURIA-PROTOCOL) · [redes](/PUB/RRSS-SIDECAR-PROTOCOL) · [P2P](/PUB/TEATRO-P2P-PROTOCOL) |
| Banco | cartera del pub y renta básica | puerta [Economía Oasis](/roles/economia) |

## Lo que no tiene vuelta atrás

- **El nombre y la descripción del pub**, y **su anuncio**: mensajes publicados.
- **Seguir a otro pub o redimir un invite**: cambia qué se replica.
- **Formatear un disco** al preparar el servidor.
- **Perder el `secret` del pub**: es su identidad; sin copia, el pub es otro.

La tabla completa: [acciones irreversibles](/AGENTES#_3-acciones-irreversibles-y-su-puerta).

## Cómo se comprueba

- `npm run devops:status`: qué versión corre cada nodo, si está sano y si el pub aparece en el
  directorio de la red.
- Un cliente redime un invite del pub y ve su contenido.
- Con el HUB: la [matriz pública](/PUB/HUB-PROTOCOL) del visor.

## Si algo no sale

Parada dura: el agente no improvisa sobre un servidor vivo. Te cuenta el comando y su salida.
Si el daño ya está hecho: [recuperación](/PUB/RECOVERY-PROTOCOL).

## Protocolo de fondo

- [Protocolo para agentes](/AGENTES): reglas universales, irreversibles y trampas conocidas.
- [Hazlo tuyo](/roles/tu-pub): la ficha de tu instancia.
- [Mantener](/roles/mantener): subir de versión y recuperar.
