# Proyecto · DevOps

Cómo fluye Oasis SDK desde el código hasta el nodo corriendo. Las URLs
concretas (repo, registry, CI, Pages) viven en el pie y la navegación de este
portal — aquí va el **flujo**, no las direcciones duplicadas.

## Flujo: código → registry → CI → Pages

1. **Código.** Fork dockerizado de Oasis en la forja. La app upstream vive bajo
   `src/`; la capa fork (Docker, compose, entrypoint, `OASIS_PUB/`, devops) se
   mantiene *wholesale* sobre ella.
2. **Skills / tooling.** Las skills de agente (`@alephscript/skills-scriptorium`)
   se instalan desde el **registry privado** y se materializan a
   `.claude/skills/` con `npm run skills:sync` — espejo auditable, fuente de
   verdad en `package-lock`.
3. **CI.** GitHub Actions construye este portal de docs (VitePress) y lo publica
   en Pages en cada push a `main` que toque `docs/**`.
4. **Pages.** Este sitio, servido en `o-sdk.escrivivir.co` desde la propia forja.

## Roles de despliegue (misma imagen, dos modos)

| Rol | Cómo | Persistencia |
| --- | ---- | ------------ |
| **Cliente** | `docker compose up -d oasis-dev` | volumen `.ssb` (identidad) + modelos IA |
| **Pub** (VPS) | `OASIS_PUB/scripts/deploy.sh` | `.ssb` del pub + backup previo obligatorio |

El invariante en ambos: **preservar el `.ssb`** (la clave `secret` es la
identidad). Todo lo demás — índices, blobs, log — es derivable y se
re-replica desde la red.

## Manuales operativos

- **[Protocolo de upgrade](/PUB/UPGRADE-PROTOCOL)** — overlay del upstream,
  re-aplicación de los 4 *fork-guards*, deploy por rol y healthcheck.
- **[Protocolo de recuperación](/PUB/RECOVERY-PROTOCOL)** — triaje de
  integridad, salvamento del repo por *plumbing*, rebuild de imagen y la
  secuencia sbot-puro → sync → GUI que evita bifurcar el feed.

## Verificación

El portal se construye con `ignoreDeadLinks: false` y pasa el *gate* de enlaces
(`site-web/scripts/verificar-sitio.mjs`) sobre el `dist/` antes del deploy:
enlaces internos y anclas deben resolver. Nada se publica roto.
