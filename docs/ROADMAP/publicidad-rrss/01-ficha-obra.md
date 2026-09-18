# 01 · Ficha de la obra — «Aleph Cero», generación 2026-09-18

Todo [V] contra `https://pub.escrivivir.co` el 2026-09-18, salvo donde se indica.

## Identidad

| | |
| :-- | :-- |
| Obra | Aleph Cero · Obra Nº 1 del Teatro del Scriptorium |
| Fuente | archivo oficial de X de `@_dev_aleph_1` (αlephillΩ) |
| Cubre | 2024-06-30 → 2026-09-18 04:20 UTC |
| Generaciones | 3: 2026-07-08 · 2026-08-21 · **2026-09-18** (primaria) |
| Sello | Escrivivir · Scriptorium Skins · Animus Iocandi · F.A.R.O. · licencia **AIGPL** (Animus Iocandi; la de la casa) [C] |

## Cifras

| Dato | Valor | Corte anterior (2026-08-21) |
| :-- | --: | --: |
| Posts visibles | **1940** | 1454 |
| Posts nuevos / borrados por el autor | +490 / −4 (los borrados no se publican) | — |
| Media | 1844 (+553 ficheros) | — |
| Hilos (≥ 2 posts propios) | 259 | — |
| Hashtags | 76 | — |
| Voces ajenas recuperadas (RT, padres, **citas**; 2 niveles) | 891 | 537 (sin citas) |
| Enlaces externos traídos a Markdown | 331 (+27 solo enlace, 6 desaparecidos) | 0 |
| Conversaciones con agentes | 38 | 0 |
| Interlocutores | 274 cuentas | — |
| Constructos («El sistema») / cortes («El cantar») | 22 / 13 | — |
| Ficheros servidos (con hash en `MANIFEST.sha256`) | 14442 | — |

## Dónde queda fijado el delta

Último post dentro de la obra: **`2100802059889000553`** · 2026-09-18 04:20:16 UTC · «🫰» (cita).
Todo lo publicado en X después de ese id **no está** en la obra; entrará con la próxima generación.
El post del anuncio es, por definición, posterior al delta.

## Tres maneras de entrar

| | URL | Notas |
| :-- | :-- | :-- |
| Leer (sin JavaScript) | `https://pub.escrivivir.co/teatro/aleph-cero/` | puertas: El sistema, El cantar, Cronología, Hilos, Enlaces, Conversaciones, Interlocutores, Externos, Hashtags, Tipos, Segundo cerebro |
| Navegar (visor de X) | `https://pub.escrivivir.co/teatro/aleph-cero/navegador.html` | el visor que X entrega con el export, limpiado: sin datos privados, sin CDNs, vídeo múltiple. Única página con JS (excepción declarada) |
| Descargar | `https://pub.escrivivir.co/teatro/aleph-cero/aleph-cero.zip` | todo: páginas + corpus + media |
| Descargar (ligero) | `https://pub.escrivivir.co/teatro/aleph-cero/aleph-cero-cerebro.zip` | solo texto, índices, `AGENTS.md` y el generador: para agentes |
| Catálogo | `https://pub.escrivivir.co/teatro/` | |

## Checksums

| Fichero | Bytes | SHA-256 |
| :-- | --: | :-- |
| `aleph-cero.zip` | 1 631 937 463 (1,52 GiB) | `39d726c8bdad2c5a9c9c789ae1b92cc25ca3403615b28c2bc947e85dff1b2c1d` |
| `aleph-cero-cerebro.zip` | 35 064 225 (33,4 MiB) | `634feaf422054ce911ceb52168a987aa527f5f0eb9cbcbf6a936e65ec95c24bf` |

Firma ed25519 del VPS, identidad `teatro@escrivivir.co`:
`…/aleph-cero.zip.sha256.sig`, `…/aleph-cero-cerebro.zip.sha256.sig`, `…/MANIFEST.sha256.sig`,
clave pública en `…/allowed_signers`.

```bash
sha256sum -c aleph-cero.zip.sha256
ssh-keygen -Y verify -f allowed_signers -I teatro@escrivivir.co -n file \
  -s aleph-cero.zip.sha256.sig < aleph-cero.zip.sha256
```

**Ojo**: los checksums cambian en cada deploy (el zip se regenera en el VPS). Antes de publicar un
banner, recomprobar: `curl -s https://pub.escrivivir.co/teatro/aleph-cero/aleph-cero.zip.sha256`.

## Garantías que se pueden afirmar (son invariantes con guarda automática)

Texto verbatim · citar por id · nada inventado · sin JavaScript (salvo el visor) · sin recursos
externos, rastreadores ni CDNs · no se publica nada privado del export (IPs, teléfono, DMs, bloqueos,
likes, borrados) · curado y mecánico separados · citas de la capa curada verificadas literales (151).
