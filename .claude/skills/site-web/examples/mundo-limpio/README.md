# Ejemplo · mundo limpio (fixture inventada)

Mundo ficticio **nexo-atlas** para ejercitar el skill sin datos de ningún
mundo real. Calibración + bases rellenadas + esqueleto de portal
publicable.

## Calibración

| clave | valor |
| ----- | ----- |
| `mundo.id` | `nexo-atlas` |
| `mundo.docs` | `docs/` |
| `mundo.dominio` | `atlas.ejemplo.co` |
| `mundo.base_env` | `DOCS_BASE` |
| `mundo.registry` | `(ninguno en el ejemplo)` |
| `mundo.ceguera` | `nexo-secreto\|atlas-interno` |
| `mundo.lexico_no` | `milicia\|municiones` |

## Cómo usar

1. Leer `SKILL.md` del skill.
2. Tomar este directorio como «mundo limpio».
3. Ejecutar `scripts/generar-sitio.sh` apuntando a un dir temporal, **o**
   copiar a mano `docs/` de aquí como portal mínimo.
4. Resultado esperado: sitio con `index.md`, CNAME, config con guard,
   workflow y bases — publicable tras `npm i vitepress` + `docs:build` en
   el destino.

No consultar canteras ajenas. Todo el copy de este ejemplo es inventado.
