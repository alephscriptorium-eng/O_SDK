#!/usr/bin/env node
// template-seed · plantilla de organización → infraestructura Oasis 1.2.3.
//
// Lee una plantilla (pub/templates/<org>.json, contrato en pub/templates/SCHEMA.md), la valida y:
//   --guion   emite un guion markdown para activarla a mano desde la UI (WP-O129)
//   --cold    siembra en un directorio SSB aislado           (pendiente WP-O130)
//   --hot     siembra desde una identidad «secretaría»        (pendiente WP-O131)
// Método: docs/PUB/TEMPLATE-PROTOCOL.md. No toca SSB en modo --guion: es JSON → markdown.
//
// Uso:
//   node pub/tools/template-seed.js --template pub/templates/acampada26s.json \
//        [--organigrama <json de entrada>] [--out <fichero.md>] --guion

const fs = require('fs');
const path = require('path');

const ROOM_STATUS = ['OPEN', 'INVITE-ONLY'];
const INVITE_MODES = ['strict', 'open'];
const TRIBE_CONTENT = ['feed', 'forum', 'event', 'task', 'report', 'votation', 'market', 'job', 'project', 'media', 'pixelia'];
const RECURRENCES = ['diaria', 'semanal', 'mensual', 'anual', 'variable'];
const LIST_TYPES = ['OPEN', 'CLOSED'];
const EDIT_POLICIES = ['open', 'author', 'tribe'];
const MAP_TYPES = ['SINGLE', 'OPEN', 'CLOSED'];
const EMERGENCY_CATEGORIES = ['WEATHER', 'INFRASTRUCTURE', 'HEALTH', 'SECURITY', 'LOST', 'NEIGHBORHOOD'];
const COURT_METHODS = ['JUDGE', 'DICTATOR', 'POPULAR', 'MEDIATION', 'KARMATOCRACY'];
const VOTE_MIN_DAYS = 7;
const WEEKDAYS = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

function parseArgs(argv) {
  const args = { yes: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--guion' || a === '--cold' || a === '--hot' || a === '--verify') args.mode = a.slice(2);
    else if (a === '--template' || a === '--organigrama' || a === '--out' || a === '--ledger') args[a.slice(2)] = argv[++i];
    else if (a === '--yes') args.yes.push(argv[++i]);
    else if (a === '-h' || a === '--help') args.help = true;
    else { console.error(`argumento desconocido: ${a}`); process.exit(2); }
  }
  return args;
}

function usage() {
  console.log(fs.readFileSync(__filename, 'utf8').split('\n').slice(1, 13).map(l => l.replace(/^\/\/ ?/, '')).join('\n'));
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

// Todos los ids que un organigrama declara: órganos, sus miembros, métodos y el propio documento.
function organigramaIds(org) {
  const ids = new Set(['documento']);
  const walk = (node) => {
    if (!node || typeof node !== 'object') return;
    if (Array.isArray(node)) return node.forEach(walk);
    if (typeof node.id === 'string') ids.add(node.id);
    Object.values(node).forEach(walk);
  };
  walk(org.organos);
  walk(org.metodos_y_conceptos);
  return ids;
}

function validate(t, orgIds) {
  const errors = [];
  const pending = [];
  const err = (m) => errors.push(m);
  const isPending = (v) => typeof v === 'string' && /^<(pendiente|DECISI[ÓO]N)/i.test(v);
  const notePending = (where, v) => { if (isPending(v)) pending.push(`${where}: ${v}`); };
  const checkOrigen = (where, origen) => {
    if (!origen) return err(`${where}: falta "origen"`);
    if (orgIds && !orgIds.has(origen)) err(`${where}: "origen" ${origen} no existe en el organigrama`);
  };

  if (!t.meta || !t.meta.id) err('meta.id obligatorio');
  if (t.meta) Object.entries(t.meta).forEach(([k, v]) => notePending(`meta.${k}`, v));

  const tribeIds = new Set();
  (t.tribes || []).forEach((x, i) => {
    const w = `tribes[${i}] ${x.id || ''}`;
    if (!x.id) err(`${w}: falta id`);
    if (tribeIds.has(x.id)) err(`${w}: id repetido`);
    tribeIds.add(x.id);
    checkOrigen(w, x.origen);
    if (!x.title) err(`${w}: falta title`);
    if (typeof x.private !== 'boolean') err(`${w}: "private" debe ser true/false`);
    if (!INVITE_MODES.includes(x.inviteMode)) err(`${w}: inviteMode ∉ ${INVITE_MODES.join('|')}`);
    if (x.openInvite && x.inviteMode !== 'open') err(`${w}: openInvite exige inviteMode "open"`);
    (x.content || []).forEach(c => { if (!TRIBE_CONTENT.includes(c)) err(`${w}: content "${c}" no es un kind de tribes_content_model`); });
    notePending(w, x.description);
  });
  (t.tribes || []).forEach((x, i) => {
    if (x.parent && !tribeIds.has(x.parent)) err(`tribes[${i}] ${x.id}: parent ${x.parent} no existe`);
  });

  const refTribe = (w, ref) => { if (ref && !tribeIds.has(ref)) err(`${w}: tribe ${ref} no existe`); };

  (t.rooms || []).forEach((x, i) => {
    const w = `rooms[${i}] ${x.id || ''}`;
    checkOrigen(w, x.origen);
    if (!x.title) err(`${w}: falta title`);
    if (!ROOM_STATUS.includes(x.status)) err(`${w}: status ∉ ${ROOM_STATUS.join('|')}`);
    refTribe(w, x.tribe);
  });

  (t.calendars || []).forEach((x, i) => {
    const w = `calendars[${i}] ${x.id || ''}`;
    checkOrigen(w, x.origen);
    if (!x.title) err(`${w}: falta title`);
    refTribe(w, x.tribe);
    if (!Array.isArray(x.dates) || !x.dates.length) err(`${w}: dates[] vacío (el modelo exige firstDate)`);
    (x.dates || []).forEach((d, j) => {
      if (!(Number.isInteger(d.offsetDays) && d.offsetDays >= 1)) err(`${w}.dates[${j}]: offsetDays entero ≥ 1`);
      if (!RECURRENCES.includes(d.recurrencia)) err(`${w}.dates[${j}]: recurrencia ∉ ${RECURRENCES.join('|')}`);
      notePending(`${w}.dates[${j}].hora`, d.hora);
    });
  });

  (t.events || []).forEach((x, i) => {
    const w = `events[${i}] ${x.id || ''}`;
    checkOrigen(w, x.origen);
    if (!x.title) err(`${w}: falta title`);
    if (!(Number.isInteger(x.offsetDays) && x.offsetDays >= 1)) err(`${w}: offsetDays entero ≥ 1 (fecha futura obligatoria)`);
    if (x.recurrencia && !RECURRENCES.includes(x.recurrencia)) err(`${w}: recurrencia ∉ ${RECURRENCES.join('|')}`);
  });

  (t.mailing || []).forEach((x, i) => {
    const w = `mailing[${i}] ${x.id || ''}`;
    checkOrigen(w, x.origen);
    if (!x.title) err(`${w}: falta title`);
    if (!LIST_TYPES.includes(x.listType)) err(`${w}: listType ∉ ${LIST_TYPES.join('|')}`);
  });

  (t.wiki || []).forEach((x, i) => {
    const w = `wiki[${i}] ${x.id || ''}`;
    checkOrigen(w, x.origen);
    if (!x.title) err(`${w}: falta title`);
    if (!x.body && !x.file) err(`${w}: body o file`);
    if (x.file && !fs.existsSync(x.file)) err(`${w}: file ${x.file} no existe`);
    if (x.editPolicy && !EDIT_POLICIES.includes(x.editPolicy)) err(`${w}: editPolicy ∉ ${EDIT_POLICIES.join('|')}`);
    notePending(w, x.body);
  });

  (t.maps || []).forEach((x, i) => {
    const w = `maps[${i}] ${x.id || ''}`;
    checkOrigen(w, x.origen);
    if (typeof x.lat !== 'number' || typeof x.lng !== 'number') err(`${w}: lat/lng numéricos`);
    if (!MAP_TYPES.includes(x.mapType)) err(`${w}: mapType ∉ ${MAP_TYPES.join('|')}`);
    if (x.mapType === 'SINGLE' && (x.markers || []).length) err(`${w}: SINGLE no admite marcadores`);
  });

  if (t.votes) {
    const c = t.votes.convencion || {};
    checkOrigen('votes.convencion', c.origen);
    if (!Array.isArray(c.options) || c.options.length < 2) err('votes.convencion.options: ≥ 2 opciones');
    const e = t.votes.ejemplo;
    if (e) {
      checkOrigen('votes.ejemplo', e.origen);
      if (!(Number.isInteger(e.offsetDays) && e.offsetDays >= VOTE_MIN_DAYS)) err(`votes.ejemplo.offsetDays ≥ ${VOTE_MIN_DAYS}`);
    }
  }

  ((t.emergencies || {}).convencion || []).forEach((x, i) => {
    checkOrigen(`emergencies.convencion[${i}]`, x.origen);
    if (!EMERGENCY_CATEGORIES.includes(x.category)) err(`emergencies.convencion[${i}]: category ∉ ${EMERGENCY_CATEGORIES.join('|')}`);
  });

  if (t.courts && t.courts.convencion) {
    checkOrigen('courts.convencion', t.courts.convencion.origen);
    if (!COURT_METHODS.includes(t.courts.convencion.method)) err(`courts.convencion.method ∉ ${COURT_METHODS.join('|')}`);
  }

  (t.federation || []).forEach((x, i) => {
    checkOrigen(`federation[${i}] ${x.id || ''}`, x.origen);
    notePending(`federation[${i}].pub`, x.pub);
  });

  (t.addenda || []).forEach((x, i) => checkOrigen(`addenda[${i}] ${x.modulo || ''}`, x.origen));

  return { errors, pending };
}

// ---------- guion ----------

const md = [];
const out = (s = '') => md.push(s);
const li = (s) => out(`- ${s}`);
const yesNo = (b) => (b ? 'sí' : 'no');

function expandRecurrence(d) {
  switch (d.recurrencia) {
    case 'diaria':
      return `**diaria** → el modelo no tiene intervalo diario: crea **7 fechas**, una por día (${WEEKDAYS.join(', ')}), cada una con *intervalo semanal*`;
    case 'semanal': return 'intervalo **semanal**';
    case 'mensual': return 'intervalo **mensual**';
    case 'anual': return 'intervalo **anual**';
    default: return 'sin intervalo (**variable**): cada reunión se añade a mano con «Add date»';
  }
}

function guion(t, args) {
  const m = t.meta;
  const tribes = t.tribes || [];
  const byId = Object.fromEntries(tribes.map(x => [x.id, x]));
  const roots = tribes.filter(x => !x.parent);
  const subs = tribes.filter(x => x.parent);
  const title = (ref) => (ref && byId[ref] ? `«${byId[ref].title}»` : 'ninguna');

  out(`# Guion de activación · ${m.nombre}`);
  out();
  out(`Plantilla \`${path.basename(args.template)}\` (Oasis ${m.version_oasis}, workflow \`${m.workflow}\`). Generado por \`pub/tools/template-seed.js --guion\`.`);
  out(`Cada paso lo ejecuta **una persona desde su Oasis**; lo que publica queda en SSB para siempre (\`docs/AGENTES.md\` §3).`);
  out(`Quién crea cada objeto es decisión del colectivo: **${m.autoria}**.`);
  out();
  out('## 0. Antes de empezar');
  out();
  li(`Cada cliente: **Settings → Workflows → ${m.workflow}**. ${t.guion && t.guion.nota_workflow ? t.guion.nota_workflow : ''}`);
  li(`La mesa técnica crea el invite de la asamblea: \`${(t.guion && t.guion.invite_asamblea) || './oasis.sh invite 500'}\` (el código no se escribe en ningún documento).`);
  li('Quien vaya a crear tribus hace antes su copia de identidad (Tools → Backup → RECOVERY y EXPORT KEYS).');
  li('Fechas: los `offsetDays` cuentan desde el día de activación; eventos y calendarios exigen fecha futura.');
  out();

  out(`## 1. Tribus raíz (${roots.length}) — \`Menú → Tribes → Create Tribe\``);
  out();
  roots.forEach((x, i) => {
    out(`### 1.${i + 1} ${x.title}  \`origen: ${x.origen}\``);
    li(`Description: ${x.description}`);
    li(`Tags: ${(x.tags || []).join(', ')}`);
    li(`Status: **${x.private ? 'Privada' : 'Pública'}** · Mode: **${x.inviteMode === 'strict' ? 'Estricto (solo el autor invita)' : 'Abierta (cualquier miembro invita)'}**`);
    if (x.openInvite) li('Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.');
    if ((x.content || []).length) li(`Dentro se usará: ${x.content.join(', ')}`);
    if (x.nota) li(`Nota: ${x.nota}`);
    out();
  });

  out(`## 2. Sub-tribus (${subs.length}) — abrir la tribu madre → Create sub-tribe`);
  out();
  subs.forEach((x, i) => {
    out(`### 2.${i + 1} ${x.title}  \`origen: ${x.origen}\` · dentro de ${title(x.parent)}`);
    li(`Description: ${x.description}`);
    li(`Mode: **${x.inviteMode}** · privacidad heredada de la madre${x.openInvite ? ' · Open invitation → Create' : ''}`);
    if ((x.content || []).length) li(`Dentro se usará: ${x.content.join(', ')}`);
    out();
  });

  const rooms = t.rooms || [];
  out(`## 3. Salas (${rooms.length}) — \`Menú → Rooms → Create Room\``);
  out();
  out('Las crea la identidad que las vaya a presidir: el token de la sala se firma con sus claves. Crearlas con el pub conectado, si no quedan sin centralita.');
  out();
  rooms.forEach((x, i) => {
    out(`### 3.${i + 1} ${x.title}  \`origen: ${x.origen}\``);
    li(`Description: ${x.description}`);
    li(`Status: **${x.status}** · Tribe: ${title(x.tribe)}`);
    if (x.status === 'INVITE-ONLY') li('Después: Generate invite por cada persona que deba entrar.');
    out();
  });

  const cals = t.calendars || [];
  out(`## 4. Calendarios (${cals.length}) — \`Menú → Calendars → Create\``);
  out();
  cals.forEach((x, i) => {
    out(`### 4.${i + 1} ${x.title}  \`origen: ${x.origen}\``);
    li(`Status: ${x.status} · Tribe: ${title(x.tribe)}`);
    (x.dates || []).forEach(d => {
      li(`Fecha: día +${d.offsetDays} a las ${d.hora} · label «${d.label}» · ${expandRecurrence(d)}${d.nota ? ` · nota: ${d.nota}` : ''}`);
    });
    out();
  });

  const events = t.events || [];
  out(`## 5. Eventos (${events.length}) — \`Menú → Events → Create\``);
  out();
  events.forEach((x, i) => {
    out(`### 5.${i + 1} ${x.title}  \`origen: ${x.origen}\``);
    li(`Description: ${x.description}`);
    li(`Fecha: día +${x.offsetDays} a las ${x.hora} · Location: ${x.location}`);
    li(`Público: ${yesNo(x.isPublic)} · Visible en /c: ${yesNo(x.clearnetPublic)} · Recurrencia: ${expandRecurrence({ recurrencia: x.recurrencia || 'variable' })}`);
    out();
  });

  const lists = t.mailing || [];
  out(`## 6. Listas de correo (${lists.length}) — \`Menú → Mailing → Create list\``);
  out();
  lists.forEach((x, i) => {
    out(`### 6.${i + 1} ${x.title}  \`origen: ${x.origen}\``);
    li(`Description: ${x.description}`);
    li(`Type: **${x.listType}**${x.listType === 'CLOSED' ? ' (cifrada: añadir miembros al crearla)' : ' (pública: quien escribe queda suscrito)'}`);
    out();
  });

  const wikis = t.wiki || [];
  out(`## 7. Wikis (${wikis.length}) — \`Menú → Wiki → Create page\``);
  out();
  wikis.forEach((x, i) => {
    out(`### 7.${i + 1} ${x.title}  \`origen: ${x.origen}\``);
    li(`Edit policy: **${x.editPolicy || 'open'}** · Tags: ${(x.tags || []).join(', ')}`);
    li(x.file ? `Cuerpo: pegar \`${x.file}\`` : `Cuerpo: ${x.body}`);
    out();
  });

  const maps = t.maps || [];
  out(`## 8. Mapas (${maps.length}) — \`Menú → Maps → Create\``);
  out();
  maps.forEach((x, i) => {
    out(`### 8.${i + 1} ${x.title}  \`origen: ${x.origen}\``);
    li(`Type: **${x.mapType}** · centro ${x.lat}, ${x.lng} · ${x.description}`);
    (x.markers || []).forEach(k => li(`Marcador: ${k.lat}, ${k.lng} «${k.label}»`));
    if (x.nota) li(`Nota: ${x.nota}`);
    out();
  });

  if (t.votes) {
    const c = t.votes.convencion;
    out(`## 9. Votaciones — convención «${c.id}»  \`origen: ${c.origen}\``);
    out();
    li(`Cada propuesta que llega a ratificación es **una votación** (\`Menú → Votes → Create\`) con las opciones **${c.options.join(' / ')}** y plazo ≥ ${c.minDays || VOTE_MIN_DAYS} días.`);
    if (c.nota) li(c.nota);
    if (t.votes.ejemplo) li(`Ejemplo: «${t.votes.ejemplo.question}», plazo día +${t.votes.ejemplo.offsetDays}.`);
    out();
  }

  if (t.emergencies && t.emergencies.convencion) {
    out('## 10. Emergencias — quién usa qué categoría');
    out();
    t.emergencies.convencion.forEach(x => li(`\`origen: ${x.origen}\` → **${x.category}**: ${x.uso}`));
    out();
  }

  if (t.courts && t.courts.convencion) {
    const c = t.courts.convencion;
    out(`## 11. Tribunales — convención  \`origen: ${c.origen}\``);
    out();
    li(`Método **${c.method}**: ${c.uso}`);
    out();
  }

  const fed = t.federation || [];
  if (fed.length) {
    out(`## 12. Federación (${fed.length}) — otros pubs`);
    out();
    out('Un `follow` entre pubs es un `contact` irreversible: PERMISO expreso cada vez.');
    out();
    fed.forEach(x => {
      li(`**${x.nombre}** \`origen: ${x.origen}\` · pub: ${x.pub} · ${x.nota || ''}`);
      li(`  cuando se conozca: \`./oasis.sh follow <feedId del pub>\` y, si procede, \`./oasis.sh announce <host>\``);
    });
    out();
  }

  const add = t.addenda || [];
  if (add.length) {
    out(`## 13. Addenda · fuera del workflow \`${m.workflow}\` (roadmap)`);
    out();
    add.forEach(x => li(`**${x.modulo}** \`origen: ${x.origen}\`: ${x.porQue}`));
    out();
  }

  return md.join('\n');
}

// ---------- main ----------

(function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help || !args.template) { usage(); process.exit(args.help ? 0 : 2); }
  if (args.mode === 'cold' || args.mode === 'hot' || args.mode === 'verify') {
    console.error(`--${args.mode}: pendiente (${args.mode === 'cold' ? 'WP-O130' : 'WP-O131'}). Contrato en docs/PUB/TEMPLATE-PROTOCOL.md §4. Hoy solo --guion.`);
    process.exit(2);
  }
  if (args.mode !== 'guion') { console.error('modo obligatorio: --guion (--cold y --hot, pendientes)'); process.exit(2); }

  const t = readJson(args.template);
  const orgIds = args.organigrama ? organigramaIds(readJson(args.organigrama)) : null;
  const { errors, pending } = validate(t, orgIds);

  const counts = {
    tribes: (t.tribes || []).filter(x => !x.parent).length,
    subtribes: (t.tribes || []).filter(x => x.parent).length,
    rooms: (t.rooms || []).length,
    calendars: (t.calendars || []).length,
    events: (t.events || []).length,
    mailing: (t.mailing || []).length,
    wiki: (t.wiki || []).length,
    maps: (t.maps || []).length,
    federation: (t.federation || []).length,
    addenda: (t.addenda || []).length
  };
  console.error(`plantilla ${t.meta && t.meta.id}: ${JSON.stringify(counts)}`);
  console.error(`origen comprobado contra organigrama: ${orgIds ? `sí (${orgIds.size} ids)` : 'no (sin --organigrama)'}`);
  if (errors.length) {
    console.error(`\n${errors.length} error(es):`);
    errors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }

  let text = guion(t, args);
  if (pending.length) {
    text += `\n## 14. Pendiente de decidir por el colectivo (${pending.length})\n\n` + pending.map(p => `- ${p}`).join('\n') + '\n';
  }
  if (args.out) {
    fs.writeFileSync(args.out, text);
    console.error(`guion escrito en ${args.out} (${pending.length} pendientes)`);
  } else {
    process.stdout.write(text);
  }
})();
