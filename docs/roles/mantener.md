---
rol: mantener
orden: 5
puerta: Mantener
lema: Subir de versión sin publicar nada que no toque. Recuperar sin empeorar lo roto.
encargos:
  - id: subir-version
    titulo: Subir mi pub a la versión nueva de Oasis
    estado: ejercido
    medido: '2026-10-07'
    prueba: plan/REPORTES/WP-O128-upgrade-oasis-1.2.3.md
    falta: prueba en frío (WP-O118)
  - id: recuperar
    titulo: Algo se ha roto, recupéralo
    estado: ejercido
    medido: '2026-09-17'
    prueba: plan/REPORTES/WP-O98-cliente-fresco-identidad.md
    falta: prueba en frío (WP-O118)
---

# Mantener

Un nodo de Oasis no se instala y se olvida. Upstream publica versiones, los discos fallan. Esta
puerta es para quien ya tiene algo corriendo.

## Estado

- Subir de versión: <Sello rol="mantener" id="subir-version" />
- Recuperar: <Sello rol="mantener" id="recuperar" />

La última subida del pub de demostración, de 1.2.2 a 1.2.3, se hizo con este
protocolo: tres nodos, cada uno publicó su anuncio de versión y nada más, el mismo
día de la release y tras ensayarlo en local, donde una suposición leída del código
resultó falsa y se corrigió antes de tocar el servidor. La de 1.1.10 a 1.2.1 fue un
cambio de motor de base de datos, de los que no tienen vuelta atrás.

## Qué le dices a tu agente

Para subir de versión:

```text
Hay versión nueva de Oasis.
Sube mi pub siguiendo el protocolo de upgrade.
Lee docs/roles/mantener.md. Ensáyalo en local antes
y pídeme permiso en cada puerta.
```

Si algo se ha roto:

```text
Algo va mal con mi nodo. No toques nada todavía.
Lee el protocolo de recuperación, haz el triaje y dime qué hay.
```

## Qué necesitas tener

- Para subir: acceso al servidor, Docker en tu máquina para el ensayo y un rato sin prisa. Cada nodo
  se reinicia una vez.
- Para recuperar: paciencia. La regla es no usar nada hasta saber qué está sano.

## Qué hará el agente al subir de versión

| Paso | Qué | Salida esperada | |
|---|---|---|---|
| 1 | Medir qué hay desplegado | versión de cada nodo, deriva del servidor frente al repo | solo lectura |
| 2 | De qué versión a cuál, y qué código cambia para cada rol | dos commits de upstream | |
| 3 | Traer el código nuevo y reponer las cinco diferencias del fork | exactamente seis ficheros distintos de upstream | |
| 4 | Sacar **qué cambia de comportamiento** y disponer cada línea por escrito | ninguna línea sin leer | |
| 5 | Ensayo en local con identidades desechables: recrear cada nodo y medir **qué publica** | un anuncio de versión por nodo y nada más | si aparece otra cosa: **parar** |
| 5b | Si la versión cambia el motor de base de datos: ensayar la migración sobre una copia | los mismos registros antes y después | **DECISIÓN**: tras migrar no hay vuelta atrás |
| 6 | Copias de seguridad y preparación del rollback en el servidor | | **PERMISO**: escribe en el servidor |
| 7 | Subir el pub | sano, misma identidad | **PERMISO**: se reinicia y publica |
| 8 | Subir cada nodo de soporte | sano, misma identidad | **PERMISO** por nodo |
| 9 | Cerrar: medir, apuntar el despliegue, escribir el reporte | | |

Detalle: [protocolo de upgrade](/PUB/UPGRADE-PROTOCOL), con sus
[gates locales](/PUB/UPGRADE-PROTOCOL#_3-4-gates-locales) y el
[despliegue por rol](/PUB/UPGRADE-PROTOCOL#_4-deploy-por-rol-host).

## Qué hará el agente si algo se ha roto

1. **Nada**, hasta haber comprobado qué está entero: disco, repo, identidad, historial.
2. Poner a salvo lo irremplazable: el `secret` y las claves.
3. Reconstruir lo derivable (código, imagen, índices) desde su fuente.
4. Si se perdió el historial de una identidad: nodo sin aplicación hasta sincronizar, y la
   aplicación al final. Es la parte delicada.

Detalle: [protocolo de recuperación](/PUB/RECOVERY-PROTOCOL).

## Lo que no tiene vuelta atrás

- **Subir publica, y volver atrás también.** Cada nodo anuncia su versión cuando cambia; un
  rollback publica otro anuncio. Ningún rollback es gratis.
- **Arrancar una identidad con un historial más corto que el de la red** parte la cuenta en dos.
- **Borrar volúmenes** se lleva estado que no se puede reconstruir.

La tabla completa: [acciones irreversibles](/AGENTES#_3-acciones-irreversibles-y-su-puerta).

## Cómo se comprueba

- `npm run devops:status`: versión por nodo, salud, directorio de la red.
- `npm run devops:upgrade:gates -- --remote check` con el delta declarado: lo que cada nodo ha
  publicado desde la foto previa es lo previsto.

## Protocolo de fondo

- [Protocolo de upgrade](/PUB/UPGRADE-PROTOCOL) y sus anexos por pieza.
- [Protocolo de recuperación](/PUB/RECOVERY-PROTOCOL).
- [Reglas universales](/AGENTES#_2-reglas-universales) y [trampas conocidas](/AGENTES#_4-trampas-conocidas).
