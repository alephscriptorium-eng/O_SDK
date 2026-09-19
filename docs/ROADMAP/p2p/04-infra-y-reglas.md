# 04 · El VPS y las reglas de la casa que condicionan el diseño

[E] de las exploraciones sobre o-sdk y s-sdk, con su fuente; [V] donde se comprobó a mano.

## El terreno

| Dato | Valor | Fuente |
| :-- | :-- | :-- |
| Host | VPS Debian 13, **4 GB de RAM** | `o-sdk/docs/PUB/INSTANCIA-SCRIPTORIUM.md` |
| Datos | volumen aparte de **40 GB** en `/srv/oasis` (7,3 GB usados el 2026-09-18 [V]) | `o-sdk/plan/DECISIONES.md`, salida del deploy |
| Cortafuegos | UFW: solo 22, 80, 443, 8008 | `o-sdk/devops/README.md`, `bootstrap-` y `verify-debian13-base.sh` |
| Edge | un Caddy compartido por 6 vhosts: `validate` + `reload`, nunca `restart` | `o-sdk/docs/AGENTES.md` §2.6 |
| Stack vivo | corre desde un directorio **sin git** en el VPS | `o-sdk/docs/PUB/TEATRO-PROTOCOL.md` §6 |
| Ancho de banda / cuota | **no documentado en ningún repo** → `pendiente`, se mide | — |
| Peso de una obra | zip completo 1,52 GiB · zip ligero 33,4 MiB (Aleph Cero) | ficha de la obra |

## Lo que ya existe y se reutiliza

- **`Range` ya funciona y ya se prueba**: el despliegue del Teatro exige un 206 sobre un `.mp4`.
  Una semilla web no necesita tocar el edge; solo falta el tipo MIME de `.torrent` y `.meta4`.
- **El zip se genera en el VPS**, después del manifiesto. Los artefactos P2P se generan ahí mismo, en el
  paso siguiente, y quedan fuera del manifiesto y del propio zip (si no, los hashes se morderían la cola).
- **Las guardas de publicación** no restringen el esquema de un enlace en HTML generado: `magnet:` y
  `ed2k://` pasan. En Markdown curado se degradarían a `#` (lista blanca `http/https/mailto`): por eso
  las fichas P2P son HTML generado.
- **Patrón de servicio opcional** ya probado con la cartera ECOin: perfil de compose, sin puertos por
  defecto, `mem_limit`/`cpus`, rutas validadas bajo el volumen de datos, script de medición con
  `--json` a un journal, protocolo propio y fila en la ficha de instancia.
- **Precedente para un demonio p2p**: «no es un vhost; puertos propios y cortafuegos; solo su cara web
  pasa por el edge» (decisión tomada para Radicle).
- **WP-O93, «contenido pesado direccionable»**: objetos inmutables referenciados desde manifiestos
  firmados, jamás en el camino de arranque. Este trabajo es su primera encarnación práctica.

## Trampas localizadas antes de escribir código

| Trampa | Remedio en el plan |
| :-- | :-- |
| `TEATRO_DELETE=1` (rsync espejo) borraría lo generado en el VPS | excluir `p2p/` y `gen/` del rsync |
| `backup-teatro.sh --verify` cuenta ficheros y no conoce los nuevos | ignorar `p2p/` y `gen/` en el recuento |
| Cuando el zip se retira, `.torrent` y hashes son el único registro | entran en el backup |
| El puente a WSL solo propaga variables de una lista blanca | añadir `TEATRO_P2P` |
| La comprobación de *placeholders* sin estampar solo conoce `__…SHA256__` | ampliarla a `__P2P_…__` |
| Otro agente tenía modificados el compose del pub y los `.env` de ejemplo | stack de semillas en ficheros propios |

## Reglas que aplican

- **Medir, no asumir**; parada dura ante desviación; evidencia = comando + salida.
- **GO del custodio** antes de cada despliegue en el host vivo y de cada acción irreversible.
- **Irreversibles** aquí: recargar el edge, abrir puertos, y sobre todo **publicar en SSB** (el anuncio
  en el módulo Torrents es un mensaje que no se borra: texto literal aprobado).
- **Un servicio cada vez** (`up -d --no-deps`), nunca un `up` global.
- **Método genérico, datos de instancia aparte**: el protocolo vale para cualquier pub; infohash,
  enlaces, puertos y topes de Scriptorium van a su ficha.
- **Hostil-omite**: lo ausente se deniega — sin firma no se siembra; sin estado, `retirada`.
