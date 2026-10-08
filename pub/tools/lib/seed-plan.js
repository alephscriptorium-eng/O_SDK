// seed-plan.js — planificador PURO de la siembra (sin SSB). Plantilla → lista ordenada de llamadas por
// bloque, con el número de mensajes que cada una va a publicar. Lo usa el dry-run de --hot (en el host o
// en el contenedor) y la ejecución real (seed-hot.js), que recorre exactamente esta lista.
//
// Recuento por llamada, medido en src/models (Oasis 1.2.3):
//   createTribe 1 · generateOpenInvite 2 (tribe-invite-msg + tribe-open-invite)
//   createRoom 1 (+1 tribe-keys si INVITE-ONLY sin tribu)
//   createCalendar sin tribu: calendar + tribe-keys + (OPEN: calendar reemplazo + tombstone) + calendarDate = 5 ó 3; con tribu: 2
//   addDate 1 · createEvent 1 (+1 tribe-keys si privado) · createList OPEN 1 / CLOSED ⌈miembros/6⌉ (solo el autor: 1)
//   createPage 1 (idempotente por slug) · createMap 1 (+1 tribe-keys si SINGLE/CLOSED sin tribu; OPEN sin tribu: +0)
//   addMarker 1 · clearnetItem 1 por objeto
// Fechas: hoy + offsetDays + hora. «diaria» no existe en el modelo: 7 fechas con intervalo semanal.
'use strict';

const BLOCKS = ['tribes', 'subtribes', 'invites', 'rooms', 'calendars', 'events', 'mailing', 'wiki', 'maps', 'clearnet'];
const WEEKDAY_OFFSETS = [0, 1, 2, 3, 4, 5, 6];
const CLEARNET_KINDS = { rooms: 'rooms', calendars: 'calendars', maps: 'maps', wiki: 'wiki', events: 'events' };

function dateAt(base, offsetDays, hora) {
  const d = new Date(base);
  d.setUTCHours(0, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() + offsetDays);
  const m = /^(\d{1,2}):(\d{2})$/.exec(String(hora || ''));
  if (m) d.setUTCHours(Number(m[1]), Number(m[2]), 0, 0);
  else d.setUTCHours(12, 0, 0, 0);   // hora <pendiente>: mediodía, y el guion lo lista como pendiente
  return d.toISOString();
}

function recurrence(r) {
  return { weekly: r === 'semanal' || r === 'diaria', monthly: r === 'mensual', yearly: r === 'anual' };
}

function plan(t, opts = {}) {
  const base = opts.now ? new Date(opts.now) : new Date();
  const tribes = t.tribes || [];
  const roots = tribes.filter(x => !x.parent);
  const subs = tribes.filter(x => x.parent);
  const blocks = {};
  const add = (block, call) => { (blocks[block] = blocks[block] || []).push(call); };
  const assets = new Set();
  const needImage = (x) => { if (x.image) assets.add(x.image); return x.image || null; };

  roots.forEach(x => add('tribes', { id: x.id, fn: 'tribes.createTribe', msgs: 1, image: needImage(x),
    args: { title: x.title, description: x.description, tags: x.tags || [], isAnonymous: !!x.private, inviteMode: x.inviteMode, parentTribeId: null, status: 'OPEN' } }));
  subs.forEach(x => add('subtribes', { id: x.id, fn: 'tribes.createTribe', msgs: 1, image: needImage(x), parent: x.parent,
    args: { title: x.title, description: x.description, tags: x.tags || [], isAnonymous: !!x.private, inviteMode: x.inviteMode, status: 'OPEN' } }));
  tribes.filter(x => x.openInvite).forEach(x => add('invites', { id: x.id, fn: 'tribes.generateOpenInvite', msgs: 2, tribe: x.id }));

  (t.rooms || []).forEach(x => add('rooms', { id: x.id, fn: 'rooms.createRoom', image: needImage(x), tribe: x.tribe || null,
    msgs: 1 + (x.status === 'INVITE-ONLY' && !x.tribe ? 1 : 0),
    args: { title: x.title, description: x.description, status: x.status, tags: x.tags || [] } }));

  (t.calendars || []).forEach(x => {
    const dates = [];
    (x.dates || []).forEach(d => {
      const rec = d.recurrencia;
      if (rec === 'diaria') WEEKDAY_OFFSETS.forEach(k => dates.push({ date: dateAt(base, d.offsetDays + k, d.hora), label: d.label, ...recurrence('semanal') }));
      else dates.push({ date: dateAt(base, d.offsetDays, d.hora), label: d.label, ...recurrence(rec) });
    });
    const first = dates[0];
    const standalone = !x.tribe;
    const msgs = standalone ? (x.status === 'OPEN' ? 5 : 3) : 2;
    add('calendars', { id: x.id, fn: 'calendars.createCalendar', msgs, tribe: x.tribe || null,
      args: { title: x.title, status: x.status, tags: x.tags || [], firstDate: first.date, firstDateLabel: first.label, firstNote: (x.dates[0] || {}).nota || '',
        intervalWeekly: first.weekly, intervalMonthly: first.monthly, intervalYearly: first.yearly } });
    dates.slice(1).forEach((d, i) => add('calendars', { id: `${x.id}#${i + 2}`, fn: 'calendars.addDate', msgs: 1, calendar: x.id,
      args: { date: d.date, label: d.label, intervalWeekly: d.weekly, intervalMonthly: d.monthly, intervalYearly: d.yearly } }));
  });

  (t.events || []).forEach(x => {
    const rec = x.recurrencia || 'variable';
    const reps = rec === 'diaria' ? WEEKDAY_OFFSETS : [0];
    reps.forEach((k, i) => add('events', { id: reps.length > 1 ? `${x.id}#${i + 1}` : x.id, fn: 'events.createEvent', image: needImage(x),
      msgs: 1 + (x.isPublic === false ? 1 : 0),
      args: { title: x.title, description: x.description, date: dateAt(base, x.offsetDays + k, x.hora), location: x.location, tags: x.tags || [],
        isPublic: x.isPublic !== false, clearnetPublic: !!x.clearnetPublic, recurrence: rec === 'diaria' ? recurrence('semanal') : recurrence(rec) } }));
  });

  (t.mailing || []).forEach(x => add('mailing', { id: x.id, fn: 'mailing.createList', msgs: 1,
    args: { title: x.title, description: x.description, listType: x.listType, members: [], tags: x.tags || [] } }));

  (t.wiki || []).forEach(x => add('wiki', { id: x.id, fn: 'wiki.createPage', msgs: 1, image: needImage(x), file: x.file || null,
    args: { title: x.title, body: x.body || null, tags: x.tags || [], editPolicy: x.editPolicy || 'open' } }));

  (t.maps || []).forEach(x => {
    add('maps', { id: x.id, fn: 'maps.createMap', image: needImage(x), tribe: x.tribe || null,
      msgs: 1 + (!x.tribe && x.mapType !== 'OPEN' ? 1 : 0),
      args: { lat: x.lat, lng: x.lng, description: x.description, mapType: x.mapType, tags: x.tags || [], title: x.title, markerLabel: '' } });
    (x.markers || []).forEach((k, i) => add('maps', { id: `${x.id}#${i + 1}`, fn: 'maps.addMarker', msgs: 1, map: x.id, args: { lat: k.lat, lng: k.lng, label: k.label } }));
  });

  ['rooms', 'calendars', 'maps', 'wiki', 'events'].forEach(section => {
    (t[section] || []).forEach(x => {
      if (x.clearnetPublic === true && !x.tribe) add('clearnet', { id: `${section}:${x.id}`, fn: 'clearnet.setItem', msgs: 1, kind: CLEARNET_KINDS[section], ref: x.id, section });
    });
  });

  const summary = {};
  BLOCKS.forEach(b => { const calls = blocks[b] || []; summary[b] = { calls: calls.length, msgs: calls.reduce((n, c) => n + c.msgs, 0) }; });
  return { blocks: BLOCKS.map(b => ({ name: b, calls: blocks[b] || [] })), summary, assets: [...assets], base: base.toISOString() };
}

module.exports = { plan, BLOCKS, dateAt };
