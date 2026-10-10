# Ficha de instancia · plantilla

> **Qué es esto.** Los protocolos de o-sdk son genéricos; los **datos de un despliegue concreto**
> viven en su ficha. Esta es la ficha vacía: cópiala como `INSTANCIA-«tu-nombre».md`, conserva los
> epígrafes y pon tus valores. Lo que va entre «comillas angulares» es lo que rellenas tú.
>
> **Qué no va aquí.** Secretos (nada de `.env` de producción, credenciales, invites, `secret`) ni
> datos que cambian solos (versión desplegada, memoria, disco): esos **se miden** con
> `devops/scripts/deploy-status.sh` y se registran en el journal (`deploy-log.sh`).
>
> Cómo se llega hasta aquí: puerta [Hazlo tuyo](/roles/tu-pub).

## 1. Identidad de la instancia

| Campo | Valor |
|---|---|
| Nombre de la instancia | «tu-nombre» (una palabra, en minúsculas; da nombre a `devops/hosts/«tu-nombre»/`) |
| Custodio | «quién responde por el pub y da el permiso en cada paso sin vuelta atrás» |
| Pub | «pub.tu-dominio» (o la IP fija, si empiezas sin dominio) |
| Host | «proveedor, sistema, memoria»; definición en `devops/hosts/«tu-nombre»/host.env` |
| Layout en el host | «carpeta del repo» · «carpeta de datos» |
| Acceso | SSH con la clave `devops/.ssh/«nombre-de-la-clave»` (carpeta fuera de git; nombre en `KEY_FILE` de `host.env`) |
| Nodos de Oasis | «qué contenedores corren y en qué modo»; versión de cada uno: `deploy-status.sh` |
| Datos | «dónde vive el estado de cada servicio» |
| Edge | «servidor web y cuántos dominios sirve» |
| Lectura pública (`/c`) | tema «…», idioma por defecto «…» (claves `themes.current` y `language` de la config del HUB) |
| Ciclo de red | «el de la red a la que te unes» |
| Feed del pub | se mide: `pub/scripts/whoami.sh` |

## 2. Pieles y lore

Una **piel** es una forma de organizar y mostrar lo que el pub sirve: su página de inicio, sus
salas, sus nombres. Aquí va la tuya, o ninguna. El método no depende de ello.

«Describe tu piel, si la hay: qué muestra la página de inicio, cómo se llaman las cosas.»

## 3. Registro de bots de soporte

Convención: [`AGENTES.md` §5](../AGENTES.md). Alta y renombrado: `HUB-PROTOCOL.md` §11-§12.
El **cardinal** es único en la serie del pub y no se reutiliza. El **feed id** es la identidad; el
nombre puede cambiar.

| # | Nombre | Tipo · piel | Qué sirve | Contenedor · estado | Feed id | Alta |
|---|---|---|---|---|---|---|
| 1 | «tipo.tu-dominio» | «tipo» · «piel» | «qué sirve» | «contenedor» · «carpeta de estado» | «se mide al darlo de alta» | «fecha» |
| «n» | «retro.tu-dominio» | retro (secretaría de plantillas) · «piel» · «dónde vive: en el host o en la máquina operadora (HUB §11, mudanza)» | «si activas una plantilla de organización (`TEMPLATE-PROTOCOL.md` §4.5): siembra tribus, salas, calendarios, listas, wikis y mapas con permiso por bloque; custodia las claves de las tribus que crea; modo `server`, sin ruta pública» | `oasis-pub-retro-bot` · `<datos>/oasis-retro-bot` | «se mide» | «fecha» |

## 4. `about` literal de cada bot

Lo que se publica se transcribe aquí **tal cual**, con fecha. Estado: *propuesto* hasta que el
reporte del trabajo que lo publica diga lo contrario. En el feed la descripción va en una sola línea.

```
name:        «tipo.tu-dominio»
description: Bot de soporte nº «n» de «tu pub» · tipo «…» · piel «…». «Qué sirve.» «Qué firma.»
             «Qué no hace.» Responde por él «tu pub».
image:       «ruta del PNG del avatar, si lo lleva: se sube en el mismo about (HUB §12)»
```

## 5. Qué hay activo y con qué protocolo

| Pieza | Protocolo | Registro |
|---|---|---|
| Pub (solo sbot) | `UPGRADE-PROTOCOL.md` | journal `deploy-log.sh` |
| «HUB clearnet, si lo activas» | `HUB-PROTOCOL.md` | su §10 |
| «Centralita de Phone y Rooms: encendida, acotada o apagada; aforo de sala» | `HUB-PROTOCOL.md` §14 | «reporte» |
| «Banco, si lo activas» | `ECOIN-PROTOCOL.md` | su §13 |
| «Teatro, si lo activas» | `TEATRO-PROTOCOL.md` | en el protocolo |

### Hoja del habitante

Lo que el [manual de bienvenida](/habitante/manual) deja en blanco y lo que tu pub hace a su
manera. Es lo que lee quien entra, no quien opera: puerta [Habitante](/roles/habitante).

| El manual pide | En tu pub |
|---|---|
| El dominio | «tu dominio» |
| La ventana pública de solo lectura | «`https://tu-dominio/c`, si activas el HUB» |
| Dónde conseguir la invitación | «la portada del pub, una persona de contacto, un QR…» |
| Wi-Fi del nodo y mesa técnica | «si es un pub presencial: nombre del Wi-Fi y dónde está la mesa. Si no: no aplica» |
| Dónde conseguir la app | «quién reparte el APK, o solo las *releases* y la tienda» |

Y qué ofrece: instantánea para quien entra, llamadas y salas de voz, banco y renta básica, lo que
tengas encendido. Solo lo que hayas medido.

Copias de seguridad: «dónde se guardan, fuera de la máquina». Particularidades de tu host que ya te
hayan costado una parada: apúntalas aquí.
