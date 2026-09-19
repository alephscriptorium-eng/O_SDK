# 03 · Lo que añade nuestro pub, y por dónde se engancha a Oasis

Principio: **ni una línea en `src/`**. El fork mantiene Oasis 1-1 con upstream más 5 guards contados;
todo lo de aquí vive en `pub/`, `devops/` y `docs/`, al lado.

## El reparto

| Necesidad | Oasis (upstream) | Pub (extensión o-sdk) |
| :-- | :-- | :-- |
| Anunciar una obra en la red | ✅ mensaje `torrent` + blob `.torrent`, etiquetas, opiniones, tribus | lo usa tal cual: el `.torrent` que publica lo genera el pub |
| Verlo desde la web abierta | ✅ `/c/torrents/<id>` y `/c/blob/<id>` con MIME de torrent | la ficha P2P de la obra enlaza ese id |
| Servir los bytes | ❌ | ✅ HTTPS con `Range` (ya existía) declarado como **semilla web** del torrent |
| Una fuente que no cambie | ❌ | ✅ URL inmutable por generación (`…/gen/<fecha>-<sha8>/`), enlace duro al zip vigente |
| Infohash, magnet, ed2k, metalink | ❌ | ✅ calculados en el despliegue (`mktorrent`, `rhash`) dentro de un contenedor efímero |
| Procedencia del contenido | firma del feed del autor | ✅ sha256 + firma ed25519 + `MANIFEST.sha256` del Teatro, extendidos a `p2p.json` |
| Sembrar | ❌ | ✅ opcional: `seed-bt` (transmission) y `seed-ed2k` (amuled 3.0.1, Kad-only), solo-semilla |
| Moderar el hardware | — | ✅ **cartelera** por obra + topes globales por variable de entorno |
| Operar y medir | — | ✅ `teatro-p2p.sh status|publicar|cartelera|red|retirar|seed|medir|podar` |

## Cartelera

El pub es un hub: **lanza** obras, no las custodia para siempre.

| Estado | HTTPS del zip (semilla web) | Semillas del pub | Fichas P2P |
| :-- | :-- | :-- | :-- |
| `cartelera` | ✅ | ✅ | ✅ |
| `red` | ❌ retirado | ✅ (o no) | ✅ |
| `retirada` | ❌ | ❌ | ✅ hashes y enlaces quedan |

Las páginas para leer y navegar la obra no cambian de estado: solo se modera el zip y las semillas.
Cuando una obra pasa a `retirada`, sus fichas siguen diciendo qué bytes son los buenos: cualquiera que
la tenga puede verificarla y seguir sembrándola. La red la sostiene; el pub la certificó.

## Cómo se ve en el Teatro

Una puerta más, **«P2P»**, junto a las de leer, navegar y descargar: estado de cartelera, y por cada
fichero `.torrent` · magnet · ed2k · metalink · sha256 · firma, con «cómo verificar» y «cómo ayudar:
deja tu cliente sembrando». HTML estático, sin JavaScript, como el resto.

## Por qué así

- **Stack de semillas independiente** (`pub/teatro-seed/compose.seed.yml`, proyecto compose propio):
  ningún despliegue del pub lo arrastra y no toca el edge compartido. Un demonio p2p lleva puertos
  propios, no vhost (mismo criterio que se fijó para Radicle).
- **Nada en el camino de arranque**: si las semillas caen, el pub y el HUB ni se enteran.
- **El manifiesto firmado es la raíz de confianza**; torrent, magnet y ed2k son caminos hacia bytes
  que se comprueban igual que hoy.

## Lo que podría interesar a upstream (sin pedir nada)

Observaciones al usar el módulo Torrents como catálogo de contenido verificable; son ideas, no peticiones:

1. **Leer el `.torrent` al publicarlo**: infohash, nombre, tamaño real y semillas web están en el
   bencode; hoy `size` se teclea. Mostrar el infohash daría identidad verificable a la entrada.
2. **Campos opcionales `magnet` y `ed2k`** en el mensaje `torrent`: hoy solo caben como texto en la descripción.
3. **Campo opcional de procedencia** (`sha256` del contenido, URL de firma): la red sabría qué bytes son los buenos.
4. `/c/blob/:id` sin `Range` y en memoria es correcto para un `.torrent`; si algún día sirviera
   contenido mayor, `Range` lo haría apto como semilla web.
5. Un pub que ofrezca «semilla de cartelera» es un servicio de nodo de soporte natural, como el HUB
   clearnet: lo que este dosier describe puede ser un patrón reutilizable por otros pubs.
