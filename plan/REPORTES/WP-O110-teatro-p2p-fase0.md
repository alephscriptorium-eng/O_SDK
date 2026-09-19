# Reporte · WP-O110 · Teatro P2P · fase 0 (Aleph Cero)

- **Fecha**: 2026-09-19 · **Rama**: `wp/O110-teatro-p2p` · **Asiento**: D-O24 · plan en `docs/ROADMAP/p2p/06`, revisión en `07`.
- **Resultado**: los dos zips de *Aleph Cero* están **congelados**, tienen torrent con semilla web, magnet, ed2k y
  metalink publicados y firmados, y están **anunciados en Oasis** desde la cuenta del custodio. Sin demonios nuevos.
- **Cambio respecto al plan**: el custodio congela la edición («no se toca en al menos un año»). Eso sustituye a las
  «generaciones con enlaces duros»: la URL actual pasa a ser inmutable **por política**, con guarda en el deploy.

## Qué se entregó

| Pieza | Commit |
|---|---|
| Congelación: guarda y sufijo en `deploy-teatro.sh`, `pub/teatro-seed/tools/congelar.py` | `4cbc169` |
| `teatro-p2p-tools` (Dockerfile) + `gen_p2p.py` | `5bd71b9` |
| `devops/scripts/teatro-p2p.sh` `status · congelar · publicar` | `9aaa1b9` |
| `docs/PUB/TEATRO-P2P-PROTOCOL.md`, índices, ficha de instancia, este reporte | (cierre) |

## Evidencia

| Paso | Resultado |
|---|---|
| Gate local del generador (fichero de prueba) | torrent con semilla web, magnet, ed2k con AICH, metalink, `p2p.json`, ficha; 2.ª pasada: `.torrent` idéntico (idempotente) |
| `congelar` en el VPS | `CONGELADO.json` con sha256 `39d726c8…2c1d` (1 631 937 463 B) y `634feaf4…24bf` (35 064 225 B), iguales a los `.sha256` publicados; zips en solo lectura |
| `publicar` | infohash `7b50c7cdaffc37099997241ccf75bffac29c704c` y `14eb4b43908efb2f1e60dad4515474092843c2f8`; `p2p.json` firmado; desde fuera: `p2p/` 200, `.torrent`/`.meta4` 200, zips **206** |
| **Descarga real** | contenedor Alpine en otra máquina: `aria2c` con DHT desactivado completa `aleph-cero-cerebro.zip` solo con el `.torrent`; sha256 = el esperado |
| MIME | Caddy ya sirve `.torrent` como `application/x-bittorrent`: **no se tocó el edge** |
| Feed antes de publicar | `seq_pub` = secuencia local = 72 |
| Anuncio en Oasis (GO del custodio, textos literales) | `POST /torrents/create` ×2 → 302; conteo de `torrent` propios 0 → 1 → 2; mensajes 73 y 74; blobs con el mismo sha256 que los `.torrent` del Teatro; `seq_pub` = 74 |
| Ids | `https://pub.escrivivir.co/teatro/aleph-cero/p2p/oasis.json` |

## Hallazgos

1. La revisión del plan (dosier `07`) evitó dos errores: activar la visibilidad en clearnet por `curl` (habría
   publicado un perfil vacío) y anunciar antes de tener ficha y URL estable.
2. `python3-minimal` no trae `html` ni `json` completos: la imagen usa `python3`.
3. El magnet del anuncio va en forma mínima (infohash + nombre): trackers y semilla web ya viajan en el `.torrent`.
4. La licencia y el correo de call4obras del texto vienen del plan original; el agente no pudo verificarlos y lo
   dijo al pedir el GO; el custodio aprobó el texto tal cual.

## Pendiente

- **Casilla «Torrents» en clearnet** del perfil del custodio, desde el navegador (protocolo §4.4) → `/c/torrents/…`.
- Puerta «P2P» en el sitio de la obra y en el catálogo del Teatro (`build_site.py`, plantilla): hoy la ficha existe
  pero nada la enlaza desde las páginas; test del sidecar con `p2p/` presente.
- Publicidad: `C:\S_META\F4\dosier-publicidad-rrss` (ficha de obra, banners) desde `p2p.json`.
- Fases siguientes de `06`: semillas propias (BT, amuled Kad-only), cartelera, medición; `backup-teatro.sh` debe
  respaldar `p2p/` y `CONGELADO.json`.
