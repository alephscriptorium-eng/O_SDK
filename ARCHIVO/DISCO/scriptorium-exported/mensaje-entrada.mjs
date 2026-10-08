#!/usr/bin/env node
// mensaje-entrada.mjs — genera el «mapa de entrada» a la exposición Campamento que publica el bot nº 3
// (retro.escrivivir.co) como entrada de Blog (type: 'post'). Un solo mensaje, DRY: enlaza lo que ya existe
// (tribus, salas, calendarios, evento, wikis, mapas, Sala 02, portada, manual, código) y no crea nada.
//
// Lee la plantilla y el ledger del VPS (claves reales de cada objeto) y escribe:
//   mensaje-entrada.md    el texto, para aprobarlo literal
//   mensaje-entrada.json  el mensaje listo para `ssb-admin.js publish-json` (sin clearnetItem: va después)
// Reglas medidas en el visor /c (Oasis 1.2.3): solo URL absolutas (las relativas salen como texto);
// text < 6500 B para que quepa en un mensaje; sin códigos de invitación (TEMPLATE-PROTOCOL §5).
//
//   node ARCHIVO/DISCO/scriptorium-exported/mensaje-entrada.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '../../..');
const PUB = 'https://pub.escrivivir.co';
const DOCS = 'https://o-sdk.escrivivir.co';
const REPO = 'https://github.com/alephscriptorium-eng/O_SDK';
const BOT = 'retro.escrivivir.co';

const t = JSON.parse(fs.readFileSync(path.join(ROOT, 'pub/templates/campamento.json'), 'utf8'));
const ledger = JSON.parse(fs.readFileSync(path.join(HERE, 'vps/ledger-vps.json'), 'utf8'));

const key = (block, id) => (ledger[block] && ledger[block][id] && ledger[block][id].key) || null;
const enc = (k) => encodeURIComponent(k);
// Slug clearnet de una wiki: <título-slugificado>-<8 primeros alfanuméricos de la clave> (main_views.js:191-199).
const slugify = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const shortId = (k) => String(k).replace(/[^a-z0-9]/gi, '').slice(0, 8).toLowerCase();
const wikiUrl = (w) => { const k = key('wiki', w.id); return k ? `${PUB}/c/wiki/${enc(`${slugify(w.title)}-${shortId(k)}`)}` : null; };
const byId = (arr, id) => arr.find(x => x.id === id);

const tribe = (id) => { const x = byId(t.tribes, id); const k = key('tribes', id) || key('subtribes', id); return x && k ? `[${x.title}](${PUB}/c/tribe/${enc(k)})` : null; };
const wiki = (id) => { const w = byId(t.wiki, id); const u = w && wikiUrl(w); return u ? `[${w.title}](${u})` : null; };
const cal = byId(t.calendars, 'cal_asamblea_general'); const calK = key('calendars', 'cal_asamblea_general');
const map = byId(t.maps, 'mapa_nodos'); const mapK = key('maps', 'mapa_nodos');
const ev = byId(t.events, 'evento_asamblea_general'); const evK = key('events', 'evento_asamblea_general#1');

const nodos = ['nodo_norte', 'nodo_oeste', 'nodo_centro', 'nodo_este', 'nodo_sur'].map(tribe).filter(Boolean);
const comisiones = t.tribes.filter(x => x.id.startsWith('comision_')).map(x => tribe(x.id)).filter(Boolean);
const subs = t.tribes.filter(x => x.parent === 'comision_comunicacion').length;

const text = `**Campamento** es una plantilla de organización (asamblea general, nodos territoriales, comisiones, portavocías) convertida en objetos de Oasis 1.2.3 y sembrada en este pub por su secretaría, ${BOT}, como exposición: para que quien opera otro pub vea cómo queda un organigrama real hecho tribus, salas, calendarios, listas, wikis y mapas, se pasee por él y se lleve el método.

**Dónde está el código y el método**
- Repositorio: ${REPO}
- Protocolo de plantilla (del organigrama al pub, tres vías de activación): ${DOCS}/PUB/TEMPLATE-PROTOCOL
- Guía de reparto de accesos (el libro del operador, generada desde la plantilla): ${PUB}/parlament/campamento/

**Cómo entrar**
- La portada ${PUB} muestra un código de invitación abierto (1000 usos): cópialo y pégalo en tu Oasis, Menú → Invites. No hay que pedírselo a nadie.
- Manual de bienvenida (instalar la app, unirse, tribus, copia de la identidad): ${DOCS}/habitante/manual
- Sin app, de solo lectura: ${PUB}/c

**Itinerario** (en tu Oasis, por menús; los enlaces son la vista pública)
1. Tribes → ${tribe('asamblea_general')}: tribu abierta, con botón «Unirse a la tribu» y QR en su tarjeta. Dentro: feed y foro.
2. Los nodos territoriales, abiertos: ${nodos.join(' · ')}.
3. Las comisiones de trabajo, abiertas: ${comisiones.join(' · ')}. La de Comunicación tiene ${subs} sub-tribus (redes, audiovisual, diseño, cultura, prensa, crisis, corrección…).
4. Calendars → [${cal.title}](${PUB}/c/calendars/${enc(calK)}): cada día a las ${cal.dates[0].hora}, siete fechas semanales.
5. Events → [${ev.title}](${PUB}/c/events/${enc(evK)}).
6. Rooms → «Sala · Asamblea General» y una sala por nodo (voz y texto; se ven desde dentro de cada tribu).
7. Wiki → ${wiki('wiki_organigrama')} · ${wiki('wiki_semaforo')} · ${wiki('wiki_portavocias')} · ${wiki('wiki_reparto')} · ${wiki('wiki_onboarding')}.
8. Maps → [${map.title}](${PUB}/c/maps/${enc(mapK)}) (colaborativo: cada nodo marca dónde se reúne).
9. Mailing → «Acuerdos de la Asamblea General» y «Comunicados» (abiertas: quien escribe queda suscrito).

**Qué no es**: no hay datos de nadie ni dinero; las tribus privadas (Asamblea Internodos) y las listas cerradas no se ven; los lugares están «pendientes» a propósito (la plantilla no inventa lo que el colectivo no ha decidido). Cada tribu, sala y página lleva su imagen generada por el kit visual de la plantilla.

Firmado: ${BOT}, bot de soporte nº 3 de ${PUB.replace('https://', '')} · familia Azofaifo. #oasis #campamento #plantilla`;

const post = { type: 'post', contentWarning: 'Exposición «Campamento»: mapa de entrada', text, allowComments: true, mentions: [] };
const bytes = Buffer.byteLength(JSON.stringify(post), 'utf8');
fs.writeFileSync(path.join(HERE, 'mensaje-entrada.md'), `# Mensaje de entrada (Blog, ${BOT})\n\n**Título:** ${post.contentWarning}\n\n${text}\n`);
fs.writeFileSync(path.join(HERE, 'mensaje-entrada.json'), JSON.stringify(post, null, 2) + '\n');
const missing = (text.match(/\[[^\]]+\]\(null\)/g) || []).length;
console.log(JSON.stringify({ bytes, under6500: bytes < 6500, links: (text.match(/https?:\/\/[^\s)]+/g) || []).length, missingKeys: missing, codes: /[A-Za-z0-9+/]{44}=?~/.test(text) }));
if (missing || bytes >= 6500) process.exit(1);
