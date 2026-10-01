---
rol: tu-pub
orden: 4
puerta: Hazlo tuyo
lema: Cualquiera puede tener su pub, con su nombre, su dominio, su piel y su gente.
encargos:
  - id: instancia-propia
    titulo: Preparar la ficha y la configuración de mi propia instancia
    estado: en-obras
    medido: '2026-10-01'
    falta: plantillas sin datos de la demo para el despliegue, la config de red y la página de inicio (WP-O117)
---

# Hazlo tuyo

Este repo separa dos cosas:

- **El método**: los contenedores, los scripts y los protocolos. Es genérico. Sirve igual para un
  pub de barrio, de un colectivo o de una sola persona.
- **La instancia**: el nombre, el dominio, las claves, el texto de la página de inicio, las obras.
  Es de quien la monta.

El repo trae una instancia de demostración que ejerce el método de punta a punta. Tiene nombre
propio, pero es eso: una demo. **Para tener tu pub no necesitas nada de ella.** Su ficha es pública
y sirve de ejemplo de cómo se rellena la tuya.

## Estado

- Instancia propia: <Sello rol="tu-pub" id="instancia-propia" />

**Qué funciona hoy.** Los datos de acceso al servidor ya van por instancia (`devops/hosts/`), hay
ficha vacía para rellenar y los protocolos no cambian de una instancia a otra. **Qué no:** varias
piezas del despliegue llevan todavía los datos de la demo escritos dentro (nombres de contenedor,
dominios extra en el servidor web, la dirección pública en la configuración de red, la página de
inicio). Hasta que salgan a plantillas, el agente las tiene que señalar una a una y no desplegar
con ellas puestas.

## Qué le dices a tu agente

```text
Quiero mi propio pub Oasis, con mi nombre y mi dominio,
sin nada de la demo.
Empieza por la ficha de mi instancia:
lee docs/roles/tu-pub.md y pregúntame lo que necesites.
```

## Qué necesitas tener decidido

- **Un nombre** para la instancia (una palabra, en minúsculas: se usa para carpetas).
- **Un dominio** (o una IP fija, para empezar).
- **Quién responde por el pub**: el custodio. Es quien da el permiso en cada paso sin vuelta atrás.

## Qué hará el agente

| Paso | Qué | Salida esperada | |
|---|---|---|---|
| 1 | Copiar la ficha vacía a `docs/PUB/` con tu nombre y rellenarla contigo | tu ficha de instancia | **DECISIÓN**: nombre, dominio, custodio |
| 2 | Copiar `devops/hosts/ejemplo/` a `devops/hosts/` con tu nombre y rellenar `host.env` | los scripts de `devops/` apuntan a tu servidor | usa siempre `DEVOPS_HOST` con tu nombre |
| 3 | Guardar tu clave SSH en `devops/.ssh/` | fuera de git | no se imprime |
| 4 | Listar lo que el despliegue trae escrito de la demo y qué habría que cambiar en cada sitio | un inventario, sin tocar nada | **en obras**: hoy se hace a mano |
| 5 | Elegir el nombre de los bots de soporte, si los habrá | nombres cortos que digan qué son y de quién | ver [nombres de los bots](/AGENTES#_5-nombres-de-los-bots-de-soporte) |
| 6 | Seguir por la puerta [Pub Oasis](/roles/pub) | | |

## Lo que cambia de una instancia a otra, y lo que no

| Es de la instancia (lo pones tú) | Es del método (no se toca) |
|---|---|
| nombre, dominio, IP, usuario y clave del servidor | los protocolos y sus reglas |
| identidad del pub y de sus bots (`secret`): nacen en tu servidor | la imagen y sus tres modos |
| nombre y descripción del pub y de los bots | las herramientas de `devops/` |
| página de inicio, piel, obras, lore | los gates y lo que comprueban |
| idioma y tema por defecto de la lectura pública | la lista de acciones sin vuelta atrás |

## Lo que no tiene vuelta atrás

- **El nombre público** del pub y de cada bot: se puede cambiar publicando otro, pero el anterior
  queda en el historial.
- **Las identidades**: nacen en tu servidor y no viajan. Sin copia, no se recuperan.

## Protocolo de fondo

- [Ficha de instancia · plantilla](/PUB/INSTANCIA-PLANTILLA): la que rellenas.
- [Ficha de la instancia de demostración](/PUB/INSTANCIA-SCRIPTORIUM): el ejemplo relleno.
- [Protocolo para agentes](/AGENTES): método genérico, datos en la ficha.
- Siguiente puerta: [Mantener](/roles/mantener).
