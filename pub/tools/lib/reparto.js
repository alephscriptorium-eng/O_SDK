// reparto.js — guía de reparto de accesos: el libro del OPERADOR (la mesa técnica), sin SSB.
// Una sección por «responsable» (órgano del organigrama) con sus objetos, el tipo de acceso, dónde se
// obtiene en la UI y, si hay ledger (tras --hot), el enlace público /c/… de cada objeto.
// Nunca códigos ni semillas (TEMPLATE-PROTOCOL §5): los códigos viven en la tarjeta de cada objeto, en la
// UI de quien los reparte. Misma fuente para tres salidas: dosier (md), wiki en Oasis (wiki[] con file:) y
// página del sitio del pub (toHtml sobre pub/site-templates/poster/template.html).
'use strict';

const CLEARNET_PATH = { tribes: '/c/tribe/', subtribes: '/c/tribe/', rooms: '/c/rooms/', calendars: '/c/calendars/', maps: '/c/maps/', wiki: '/c/wiki/', events: '/c/events/' };

// Qué es verdad en la interfaz de upstream (1.2.3-1.2.5), medido en el drill de la 26S (WP-O137): la tarjeta de una tribu
// NO muestra la invitación abierta (ni botón «Unirse» ni QR: el modelo no indexa `tribe-open-invite`, H9 de WP-O135); el
// código abierto existe, es multiuso y se redime en Menú → Tribus → INTRODUCIR INVITACIÓN (/tribes/join-code). «Generar
// invitación» solo lo ve quien ya es miembro (modo abierto) o el autor (estricto); y el autor de lo sembrado es la
// secretaría, que no tiene interfaz: sus códigos los saca la mesa técnica con `secretaria.sh <id> codigos` (hoja de
// códigos con QR para las abiertas; `one-use` para las estrictas).
function accessOf(section, x) {
  if (section === 'tribes') {
    if (x.openInvite) return { tipo: 'tribu abierta con código multiuso', como: 'Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación.', quien: 'la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro' };
    if (x.inviteMode === 'open') return { tipo: 'tribu abierta (un código por persona)', como: 'El primero lo da la secretaría (código de un uso); después, un miembro: tarjeta de la tribu → Generar invitación. Se redime en Menú → Tribus → INTRODUCIR INVITACIÓN.', quien: 'la secretaría para el primero; después cualquier miembro' };
    return { tipo: `tribu ${x.private ? 'privada' : 'pública'} estricta`, como: 'Solo la secretaría (autora) genera un código de un uso por persona, a petición del órgano, entregado en mano; se redime en Menú → Tribus → INTRODUCIR INVITACIÓN. Sin ella nadie más entra: cada alta pasa por la mesa técnica.', quien: 'la secretaría, a petición del órgano' };
  }
  if (section === 'rooms') return x.status === 'INVITE-ONLY'
    ? { tipo: 'sala solo por invitación', como: 'Quien la preside: Menú → Salas → la sala → Generar invitación. Si la preside la secretaría, hoy no hay herramienta para ello: DECISIÓN (abrirla a su tribu).', quien: 'el autor de la sala' }
    : { tipo: 'sala abierta', como: 'La ven y entran los miembros de su tribu (Menú → Salas); sin tribu, cualquiera que la vea.', quien: 'nadie reparte: es de su tribu' };
  if (section === 'calendars') return x.tribe
    ? { tipo: 'calendario de tribu', como: 'Lo ven los miembros de la tribu; el acceso es el de la tribu.', quien: 'el de la tribu' }
    : { tipo: `calendario suelto ${x.status}`, como: x.status === 'OPEN' ? 'Invitación pública en la tarjeta del calendario (Menú → Calendarios).' : 'El autor invita desde la tarjeta.', quien: x.status === 'OPEN' ? 'nadie reparte: es abierto' : 'el autor' };
  if (section === 'mailing') return x.listType === 'CLOSED'
    ? { tipo: 'lista cerrada (cifrada)', como: 'El autor añade miembros: Menú → Listas de correo → la lista → Miembros. Si la autora es la secretaría, hoy no hay herramienta: DECISIÓN.', quien: 'el autor de la lista' }
    : { tipo: 'lista abierta', como: 'Quien escribe queda suscrito; nada que repartir.', quien: 'nadie' };
  if (section === 'maps') return x.mapType === 'OPEN'
    ? { tipo: 'mapa colaborativo', como: 'Invitación pública en la tarjeta del mapa (Menú → Mapas); cualquiera añade marcadores.', quien: 'nadie reparte: es abierto' }
    : { tipo: `mapa ${x.mapType}`, como: 'El autor invita desde la tarjeta.', quien: 'el autor' };
  if (section === 'events') return { tipo: x.isPublic === false ? 'evento privado' : 'evento público', como: 'Menú → Eventos. Los públicos los ve cualquiera.', quien: 'nadie' };
  if (section === 'wiki') return { tipo: `wiki (${x.editPolicy || 'open'})`, como: 'Menú → Wiki. Edita según la política de la página.', quien: 'nadie' };
  return { tipo: section, como: '', quien: '' };
}

function orgName(org, id) {
  if (!org) return id;
  let found = null;
  const walk = (n) => { if (found || !n || typeof n !== 'object') return; if (Array.isArray(n)) return n.forEach(walk); if (n.id === id && n.nombre) found = n.nombre; Object.values(n).forEach(walk); };
  walk(org.organos); walk(org.metodos_y_conceptos);
  return found || id;
}

// forma: 'md' (dosier y sitio: con tablas) | 'wiki' (lo que se siembra en Oasis: SIN tablas, sin números en las
// cabeceras; el renderer de upstream (src/backend/renderStyledText.js) no tiene sintaxis de tabla ni <br>, y una
// cabecera «## 2. X» se vuelve además ítem numerado). D-O34.
function reparto(t, { template, ledger, pending, organigrama, forma = 'md' } = {}) {
  const wiki = forma === 'wiki';
  const m = t.meta;
  const rep = m.reparto || {};
  const sections = ['tribes', 'rooms', 'calendars', 'mailing', 'maps', 'events', 'wiki'];
  const byResp = new Map();
  // Una wiki partida en páginas (wiki_x, wiki_x_2, …) es UN objeto para el reparto: se lista una vez, con su nº de páginas.
  const pagesOf = (id) => (t.wiki || []).filter(w => w.id === id || new RegExp(`^${id}_\d+$`).test(w.id)).length;
  sections.forEach(section => (t[section] || []).forEach(x => {
    if (section === 'wiki' && /_\d+$/.test(x.id)) return;
    if (section === 'wiki' && pagesOf(x.id) > 1) x = { ...x, title: `${x.title.replace(/ · 1 de \d+$/, '')} (${pagesOf(x.id)} páginas)` };
    const r = x.responsable || '<pendiente: responsable>';
    if (!byResp.has(r)) byResp.set(r, []);
    byResp.get(r).push({ section, x });
  }));
  const keyOf = (section, id) => {
    if (!ledger) return null;
    const blocks = section === 'tribes' ? ['tribes', 'subtribes'] : [section];
    for (const b of blocks) if (ledger[b] && ledger[b][id] && ledger[b][id].key) return ledger[b][id].key;
    // Un evento con recurrencia se siembra como id#1..#7: el enlace de la guía es el primero.
    for (const b of blocks) if (ledger[b] && ledger[b][`${id}#1`] && ledger[b][`${id}#1`].key) return ledger[b][`${id}#1`].key;
    return null;
  };
  const publicInC = (section, x) => section === 'events' ? x.clearnetPublic === true : (x.clearnetPublic === true && !x.tribe);

  const md = [];
  const out = (s = '') => md.push(s);
  if (!wiki) { out(`# Guía de reparto de accesos · ${m.nombre}`); out(); }   // en la wiki el título lo pone Oasis
  out(`Libro del **operador** (la mesa técnica): a qué órgano le toca cada tribu, sala, calendario, lista o mapa, qué tipo de acceso lleva y dónde se obtiene. Generada por \`pub/tools/template-seed.js --reparto\` desde \`${template ? require('path').basename(template) : 'la plantilla'}\`; no se edita a mano.`);
  out();
  out('> **Aquí no hay ningún código.** Los códigos los tiene la mesa técnica: los abiertos en la **hoja de códigos** que saca de la secretaría (con un QR por tribu, para imprimir); los de un uso, uno a uno, también de la secretaría. Esta guía dice *quién* y *dónde*, nunca *cuál*.');
  out();
  out(wiki ? '## Cómo se entrega' : '## 0. Cómo se entrega');
  out();
  out(`- Mesa técnica: ${rep.mesa_tecnica || '<pendiente>'}`);
  out(`- Modo de entrega: ${rep.entrega || '<pendiente>'}`);
  out(`- Quién ejecuta la plantilla: la secretaría del pub (bot de soporte), que crea los objetos y custodia las claves de las tribus privadas. Quién dentro de cada órgano recibe el acceso: ${m.autoria || '<DECISIÓN del colectivo>'}`);
  const act = m.activacion || {};
  out(`- Dónde vive la secretaría y quién la opera: ${act.secretaria_vive || '<DECISIÓN del colectivo>'} · operador: ${act.operador || '<pendiente>'} · custodia de su secret y de las claves de tribu: ${act.custodia_claves || '<DECISIÓN del colectivo>'}`);
  out(`- Lo público se lee sin cuenta en la web abierta del pub (\`/c\`): ${ledger ? 'enlaces abajo' : 'los enlaces aparecen al regenerar esta guía con `--ledger` tras la activación'}.`);
  out();
  out(wiki ? '## Primer acceso' : '## 0 bis. Primer acceso: cómo entra la primera persona de cada órgano');
  out();
  out('La secretaría crea todas las tribus y es su autora; no tiene pantalla. Por eso en la tarjeta de una tribu nadie ve todavía un código ni un botón de unirse: el primer acceso de cada órgano lo reparte la mesa técnica.');
  out();
  out(`- **Tribus abiertas con código multiuso.** La mesa técnica saca de la secretaría la hoja de códigos${wiki ? '' : ' (`secretaria.sh <id> codigos sheet --out <carpeta>`; con `--brand marca.json` lleva la marca)'}: una tarjeta por tribu con el código y su QR. Se imprime, se reparte donde deba llegar y se destruye la copia. Quien lo recibe: Menú → Tribus → INTRODUCIR INVITACIÓN → pega el código (o escanea el QR y copia el texto). El código es público para quien lo tenga: un QR en la calle abre la tribu a todo el que pase.`);
  out(`- **Tribus estrictas.** La secretaría da un código de un uso por persona, a petición del órgano${wiki ? '' : ' (`secretaria.sh <id> codigos one-use <id de la tribu> --yes`: lo muestra una vez y no lo guarda)'}, y la mesa técnica lo entrega en mano. Cada alta pasa por ahí: sin secretaría no entra nadie más. Si el órgano prefiere repartir él mismo, la tribu debe ser abierta: DECISIÓN del colectivo antes de sembrar.`);
  out('- **Después del primero.** En una tribu abierta, cualquier miembro genera códigos desde la tarjeta de la tribu (Generar invitación): la mesa técnica deja de ser necesaria. Las salas, calendarios y mapas de una tribu se ven al entrar en ella.');
  out('- **Dónde se pega un código.** Menú → Tribus → INTRODUCIR INVITACIÓN (también en Menú → Invitaciones → Tribus). Un código de un uso se consume al usarse; el multiuso vale hasta que la secretaría lo retire.');
  out();

  let n = 1;
  for (const [resp, items] of byResp) {
    out(wiki ? `## ${orgName(organigrama, resp)}` : `## ${n++}. ${orgName(organigrama, resp)}  \`responsable: ${resp}\``);
    out();
    if (wiki) out(`Responsable del reparto: \`${resp}\`. Un ítem por objeto: tipo de acceso · quién reparte · dónde se obtiene · si se ve en la web (\`/c\`).`);
    if (wiki) out();
    else { out('| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |'); out('|---|---|---|---|---|'); }
    for (const { section, x } of items) {
      const a = accessOf(section, x);
      const key = keyOf(section, x.id);
      let pub = '—';
      if (section === 'tribes') pub = x.private ? 'no (privada)' : (key ? `[/c/tribe/…](${CLEARNET_PATH.tribes}${encodeURIComponent(key)}) (sale cuando exponga contenido)` : 'cuando tenga contenido expuesto');
      else if (publicInC(section, x)) pub = key ? `[${CLEARNET_PATH[section]}…](${CLEARNET_PATH[section]}${encodeURIComponent(key)})` : 'sí (tras la activación)';
      else pub = 'no';
      const kind = section === 'tribes' && x.parent ? 'sub-tribu' : section;
      if (wiki) out(`- **${x.title}** (${kind}) · ${a.tipo} · reparte: ${a.quien} · dónde: ${a.como} · web: ${pub}`);
      else out(`| **${x.title}** (${kind}) | ${a.tipo} | ${a.quien} | ${a.como} | ${pub} |`);
    }
    out();
  }

  out('## Reglas que no cambian');
  out();
  out('- Un acceso entregado no se retira: en una tribu privada, sacar a alguien rota la clave y lo publicado antes ya está leído.');
  out('- Los códigos de un solo uso se consumen al usarse; los multiuso valen hasta que la secretaría los retira (hoy no hay herramienta para retirarlos: pedirlo a la mesa técnica, que lo anota como pendiente).');
  out('- Nada de esta guía se pega en un canal que deje el código escrito (listas, chats de terceros).');
  out('- El manual del habitante (cómo entrar con el móvil) es otro documento: la mesa técnica reparte los dos juntos.');
  out();
  if (pending && pending.length) {
    out(`## Pendiente de decidir por el colectivo (${pending.length})`);
    out();
    pending.forEach(p => out(`- ${p}`));
    out();
  }
  return md.join('\n') + '\n';
}

// Markdown mínimo → HTML (títulos, párrafos, listas, tablas, negritas, código, enlaces). Suficiente para la guía.
function mdToHtml(md) {
  const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const inline = (s) => esc(s)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
  const lines = md.split('\n');
  const html = [];
  let i = 0;
  while (i < lines.length) {
    const l = lines[i];
    if (/^# /.test(l)) { html.push(`<h1>${inline(l.slice(2))}</h1>`); i++; continue; }
    if (/^## /.test(l)) { html.push(`<h2>${inline(l.slice(3))}</h2>`); i++; continue; }
    if (/^> /.test(l)) { html.push(`<div class="callout">${inline(l.slice(2))}</div>`); i++; continue; }
    if (/^- /.test(l)) { html.push('<ul>'); while (i < lines.length && /^- /.test(lines[i])) { html.push(`<li>${inline(lines[i].slice(2))}</li>`); i++; } html.push('</ul>'); continue; }
    if (/^\|/.test(l)) {
      const rows = []; while (i < lines.length && /^\|/.test(lines[i])) { rows.push(lines[i]); i++; }
      const cells = (r) => r.replace(/^\||\|$/g, '').split('|').map(c => c.trim());
      html.push('<table>');
      rows.forEach((r, k) => { if (k === 1) return; const tag = k === 0 ? 'th' : 'td'; html.push('<tr>' + cells(r).map(c => `<${tag}>${inline(c)}</${tag}>`).join('') + '</tr>'); });
      html.push('</table>'); continue;
    }
    if (l.trim() === '') { i++; continue; }
    html.push(`<p>${inline(l)}</p>`); i++;
  }
  return html.join('\n');
}

// Inserta la guía en la plantilla poster del sitio del pub: sustituye los marcadores {{TITLE}} y {{BODY}} si
// existen; si no, la mete antes de </body>. Cero JS; la estética la pone fanzine.css.
function toHtml(md, t, templateHtml) {
  const body = mdToHtml(md);
  const title = `${t.meta.nombre} · guía de reparto`;
  if (/\{\{BODY\}\}/.test(templateHtml)) return templateHtml.replace(/\{\{TITLE\}\}/g, title).replace(/\{\{BODY\}\}/, body);
  return templateHtml.replace(/<title>[^<]*<\/title>/, `<title>${title}</title>`).replace(/<\/body>/, `<main class="guia">\n${body}\n</main>\n</body>`);
}

module.exports = { reparto, toHtml, mdToHtml };
