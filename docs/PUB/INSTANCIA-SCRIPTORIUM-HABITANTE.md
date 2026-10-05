---
title: Hoja del habitante · Scriptorium
---

# Hoja del habitante · Scriptorium (`pub.escrivivir.co`)

::: warning De esta casa
Esta página es **de una instancia concreta**: el pub de demostración de este SDK. No es el manual
de la red ni vale para otro pub. El manual, que es común a toda la red, está en
[Manual de bienvenida](/habitante/manual); lo que cambia con este SDK, en la puerta
[Habitante](/roles/habitante). Aquí solo va lo que el manual deja en blanco y lo que esta casa
hace a su manera.
:::

Es la hoja de [la ficha de instancia](./INSTANCIA-SCRIPTORIUM.md) vista desde quien entra. Solo
lleva datos medidos; la fecha de cada medida está en la ficha y en sus reportes.

## Los huecos del manual, rellenos

| El manual pide | En esta casa |
|---|---|
| `<dominio>` | `pub.escrivivir.co` |
| La ventana pública de solo lectura | `https://pub.escrivivir.co/c`, en español por defecto; se cambia de idioma con `?lang=` |
| Dónde conseguir la invitación | En la portada, `https://pub.escrivivir.co`: muestra un código de 1000 usos con su botón de copiar. No hay que pedírselo a nadie |
| Wi-Fi del nodo y mesa técnica | **No aplica.** Esta casa es un pub en internet, no un campamento: no hay Wi-Fi propio ni mesa presencial. La sincronización entre móviles en una misma red local sigue funcionando como dice el manual |
| Dónde conseguir la app | Las *releases* del proyecto o Google Play (sección 3 del manual). La casa no reparte el APK |

## Qué ofrece el pub

| Servicio | Estado |
|---|---|
| Relevo entre habitantes | Sí. El pub se llama `pub.escrivivir.co` en la red |
| Instantánea para quien entra | Sí. El pub la rehace cada 6 horas; llega al aceptar la invitación |
| Ventana web `/c` | Sí. La sirve un nodo de soporte, `clearnet.escrivivir.co`; solo enseña lo que cada habitante marca como público |
| Llamadas y salas de voz (Phone y Rooms) | El pub hace de relevo para quien ha entrado por él; las salas que aloja admiten 12 personas. **No se ha probado todavía una llamada real** a través del pub |
| ECOin y renta básica | El pub tiene banco (`ecoin.escrivivir.co`) y está en la lista de pubs de Banking, **sin fondos**: hoy no reparte nada |
| Teatro | Obras alojadas en `https://pub.escrivivir.co/teatro` |

## Lo que conviene saber de esta casa

- **Es una demo en producción.** Ejerce cada pieza del SDK. El historial del ciclo de red actual es
  de pruebas y está previsto un salto de ciclo.
- **El pub ve quién se conecta y cuándo**, y quién llama a quién si la llamada pasa por él. No
  puede leer los mensajes privados ni escuchar las llamadas.
- **La versión de Oasis** del pub se ve en la portada, que la lee en vivo.

Para operar la casa (no para entrar en ella): [ficha de instancia](./INSTANCIA-SCRIPTORIUM.md).
