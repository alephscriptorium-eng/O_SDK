// reparto.js — guía de reparto de accesos: el libro del OPERADOR (la mesa técnica), sin SSB.
// Una sección por «responsable» (órgano del organigrama) con sus objetos, el tipo de acceso, dónde se
// obtiene en la UI y, si hay ledger (tras --hot), el enlace público /c/… de cada objeto.
// Nunca códigos ni semillas (TEMPLATE-PROTOCOL §5): los códigos viven en la tarjeta de cada objeto, en la
// UI de quien los reparte. Misma fuente para tres salidas: dosier (md), wiki en Oasis (wiki[] con file:) y
// página del sitio del pub (toHtml sobre pub/site-templates/poster/template.html).
'use strict';

const CLEARNET_PATH = { tribes: '/c/tribe/', subtribes: '/c/tribe/', rooms: '/c/rooms/', calendars: '/c/calendars/', maps: '/c/maps/', wiki: '/c/wiki/', events: '/c/events/' };

function accessOf(section, x) {
  if (section === 'tribes') {
    if (x.openInvite) return { tipo: 'tribu abierta con invitación abierta', como: 'Tarjeta de la tribu → botón «Unirse a la tribu» y código QR (Menú → Tribes → la tribu). Imprimir el QR si es de calle.', quien: 'cualquier miembro puede invitar' };
    if (x.inviteMode === 'open') return { tipo: 'tribu abierta', como: 'Un miembro: Menú → Tribes → la tribu → Generate invite (un código por persona).', quien: 'cualquier miembro' };
    return { tipo: `tribu ${x.private ? 'privada' : 'pública'} estricta`, como: 'Solo el autor: Menú → Tribes → la tribu → Generate invite, un código por persona, entregado en mano.', quien: 'el autor de la tribu' };
  }
  if (section === 'rooms') return x.status === 'INVITE-ONLY'
    ? { tipo: 'sala solo por invitación', como: 'Quien la preside: Menú → Rooms → la sala → Generate invite.', quien: 'el autor de la sala' }
    : { tipo: 'sala abierta', como: 'Entra cualquier miembro de su tribu; sin tribu, cualquiera que la vea en Rooms.', quien: 'nadie reparte: es abierta' };
  if (section === 'calendars') return x.tribe
    ? { tipo: 'calendario de tribu', como: 'Lo ven los miembros de la tribu; el acceso es el de la tribu.', quien: 'el de la tribu' }
    : { tipo: `calendario suelto ${x.status}`, como: x.status === 'OPEN' ? 'Invitación pública en la tarjeta del calendario (Menú → Calendars).' : 'El autor invita desde la tarjeta.', quien: x.status === 'OPEN' ? 'nadie reparte: es abierto' : 'el autor' };
  if (section === 'mailing') return x.listType === 'CLOSED'
    ? { tipo: 'lista cerrada (cifrada)', como: 'El autor añade miembros: Menú → Mailing → la lista → Members.', quien: 'el autor de la lista' }
    : { tipo: 'lista abierta', como: 'Quien escribe queda suscrito; nada que repartir.', quien: 'nadie' };
  if (section === 'maps') return x.mapType === 'OPEN'
    ? { tipo: 'mapa colaborativo', como: 'Invitación pública en la tarjeta del mapa (Menú → Maps); cualquiera añade marcadores.', quien: 'nadie reparte: es abierto' }
    : { tipo: `mapa ${x.mapType}`, como: 'El autor invita desde la tarjeta.', quien: 'el autor' };
  if (section === 'events') return { tipo: x.isPublic === false ? 'evento privado' : 'evento público', como: 'Menú → Events. Los públicos los ve cualquiera.', quien: 'nadie' };
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

function reparto(t, { template, ledger, pending, organigrama } = {}) {
  const m = t.meta;
  const rep = m.reparto || {};
  const sections = ['tribes', 'rooms', 'calendars', 'mailing', 'maps', 'events', 'wiki'];
  const byResp = new Map();
  sections.forEach(section => (t[section] || []).forEach(x => {
    const r = x.responsable || '<pendiente: responsable>';
    if (!byResp.has(r)) byResp.set(r, []);
    byResp.get(r).push({ section, x });
  }));
  const keyOf = (section, id) => {
    if (!ledger) return null;
    const blocks = section === 'tribes' ? ['tribes', 'subtribes'] : [section];
    for (const b of blocks) if (ledger[b] && ledger[b][id] && ledger[b][id].key) return ledger[b][id].key;
    return null;
  };
  const publicInC = (section, x) => section === 'events' ? x.clearnetPublic === true : (x.clearnetPublic === true && !x.tribe);

  const md = [];
  const out = (s = '') => md.push(s);
  out(`# Guía de reparto de accesos · ${m.nombre}`);
  out();
  out(`Libro del **operador** (la mesa técnica): a qué órgano le toca cada tribu, sala, calendario, lista o mapa, qué tipo de acceso lleva y dónde se obtiene. Generada por \`pub/tools/template-seed.js --reparto\` desde \`${template ? require('path').basename(template) : 'la plantilla'}\`; no se edita a mano.`);
  out();
  out('> **Aquí no hay ningún código.** Los códigos de invitación viven en la tarjeta de cada objeto, dentro del Oasis de quien lo reparte, y se entregan en mano o por QR impreso. Esta guía dice *quién* y *dónde*, nunca *cuál*.');
  out();
  out('## 0. Cómo se entrega');
  out();
  out(`- Mesa técnica: ${rep.mesa_tecnica || '<pendiente>'}`);
  out(`- Modo de entrega: ${rep.entrega || '<pendiente>'}`);
  out(`- Quién ejecuta la plantilla: la secretaría del pub (bot de soporte), que crea los objetos y custodia las claves de las tribus privadas. Quién dentro de cada órgano recibe el acceso: ${m.autoria || '<DECISIÓN del colectivo>'}`);
  out(`- Lo público se lee sin cuenta en la web abierta del pub (\`/c\`): ${ledger ? 'enlaces abajo' : 'los enlaces aparecen al regenerar esta guía con `--ledger` tras la activación'}.`);
  out();

  let n = 1;
  for (const [resp, items] of byResp) {
    out(`## ${n++}. ${orgName(organigrama, resp)}  \`responsable: ${resp}\``);
    out();
    out('| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |');
    out('|---|---|---|---|---|');
    for (const { section, x } of items) {
      const a = accessOf(section, x);
      const key = keyOf(section, x.id);
      let pub = '—';
      if (section === 'tribes') pub = x.private ? 'no (privada)' : (key ? `[/c/tribe/…](${CLEARNET_PATH.tribes}${encodeURIComponent(key)})` : 'cuando tenga contenido expuesto');
      else if (publicInC(section, x)) pub = key ? `[${CLEARNET_PATH[section]}…](${CLEARNET_PATH[section]}${encodeURIComponent(key)})` : 'sí (tras la activación)';
      else pub = 'no';
      out(`| **${x.title}** (${section === 'tribes' && x.parent ? 'sub-tribu' : section}) | ${a.tipo} | ${a.quien} | ${a.como} | ${pub} |`);
    }
    out();
  }

  out('## Reglas que no cambian');
  out();
  out('- Un acceso entregado no se retira: en una tribu privada, sacar a alguien rota la clave y lo publicado antes ya está leído.');
  out('- Los códigos de un solo uso se consumen al usarse; las invitaciones abiertas valen hasta que el autor las retira.');
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
