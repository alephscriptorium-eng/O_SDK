# rrss-sidecar — de tus redes sociales a una obra del Teatro

Un *sidecar* del pub: no es parte de Oasis ni corre en el VPS. Convierte el archivo de una cuenta
en redes sociales en una **obra estática** que el pub sirve bajo `/teatro/<obra>/`
(`pub/site/teatro` es el mountpoint del **visor**; ver `docs/PUB/TEATRO-PROTOCOL.md`).

```
   LORE (tuyo, privado)              SIDECAR (git)                    VISOR (generado)
ARCHIVO/LORE/<fuente>/<obra>/  →  pub/rrss-sidecar/<fuente>/  →  volumes-dev/teatro/<obra>/
  exports/ + store/ + cache/        adaptador + protocolos          HTML sin JS + corpus Markdown
                                                                     ↓ devops/scripts/deploy-teatro.sh
                                                                 /srv/oasis/teatro/<obra>/  (volumen de datos del VPS)
```

| Carpeta | Qué es |
|---|---|
| `twitter_x/` | adaptador para el export oficial de X (Twitter). Hoy el único. |
| `CORPUS-SCHEMA.md` | el contrato del **corpus normalizado**: lo único que consume el visor. |

## La costura: fuente → corpus normalizado → visor

Todo lo específico de una red vive en **un módulo adaptador** (`<fuente>/lib/normalize.py` y lo que
lea su formato). Los generadores del visor (`tools/build_corpus.py`, `tools/build_site.py`) solo
conocen los registros de `CORPUS-SCHEMA.md`. Añadir una fuente = escribir otro adaptador que
produzca esos registros.

**Destino: B.O.E. (Arrakis).** El contexto de Scriptorium ya documenta un formato de origen de
información append-only (`type: "scriptorium-boe"`, `entrada{timestamp, tipo, actor, contenido,
firma}`, `evidenceHash`; referencias en `archive/README-SCRIPTORIUM.md` y `pub/site/parlament/`).
Cuando los orígenes se parseen a B.O.E., un adaptador `boe/normalize.py` mapeará
`entrada.timestamp → created_at`, `actor → actor`, `contenido → text`, `evidenceHash → evidence`, y
el visor no cambiará. Hasta entonces `twitter_x` es deliberadamente específico y a medida.

## Principios

- **Infra en git, datos fuera.** Nada de `ARCHIVO/LORE/` ni de `volumes-dev/` se versiona.
- **Autocontenido.** El lore del usuario vive dentro del repo (`ARCHIVO/LORE/`), con rutas relativas:
  ninguna ruta del generador apunta fuera de o-sdk. La obra «Aleph Cero» es un caso, no un supuesto.
- **Verbatim.** El texto de un post no se resume ni se completa; lo no recuperado se declara.
- **Sin dependencias.** Python ≥ 3.10, solo biblioteca estándar. Sin `pip`, sin `npm`.
- **Guardas.** `lib/guards.py` es la única definición de qué puede publicarse; la usan el build,
  `sidecar.py check` y el deploy.
