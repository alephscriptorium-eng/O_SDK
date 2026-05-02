# Scriptorium Parlament — landing de respaldo

> Segmento público del OASIS PUB: `/scriptorium_parlament/`.

## Decisión

Sí hay material suficiente para publicar una landing MVP sin esperar a más refinamiento. Los cinco índices de `VibeCodingSuite/SCRIPTORIUM/` ya cubren el big picture:

1. `Parliament.md` — main ↔ layer2 ↔ main.
2. `ArrakisBoe.md` — BOE append-only y pipeline ARG.
3. `ScriptorioumRoom.md` — Room como espacio layer2 con inhabitants.
4. `Firehose.md` — feeds de participantes hacia conversaciones BOE.
5. `Future-machine.md` — rack de solidificación hacia producción/retorno.

## Plan público

La landing cuenta el proceso en 3 etapas:

| Etapa | Nombre | Función |
|---|---|---|
| A | hands-in | arranca sesión: snapshot, room, inhabitants, BOE inicial |
| B | hands-on | producción layer2: firehoses, piezas, future-machine |
| C | hands-off | cierre: summary_out, firmas, BOE final, retorno a Oasis |

## Reglas DRY

- La landing resume; no sustituye los índices técnicos.
- Los enlaces profundos apuntan a la codebase del Scriptorium.
- Si se añaden páginas hijas, deben extender las 3 etapas sin duplicar los cinco índices.
- Mantener estética del PUB: `assets/fanzine.css`, diagramas ASCII, tablas y cutouts.

## Futuras páginas opcionales

```text
/scriptorium_parlament/hands-in/   → arranque de sesión
/scriptorium_parlament/hands-on/   → producción layer2
/scriptorium_parlament/hands-off/  → cierre y regreso a Oasis
```

Por ahora el MVP deja esas tres etapas dentro de `index.html` para que el enlace público sea simple.