#!/usr/bin/env node
// count-feed-type.js — cuenta los mensajes de un tipo publicados por UN autor en un
// `flume/log.offset`, SIN arrancar ni consultar ningún sbot (solo lectura). Lo usa
// client/scripts/ecoin-verify.sh para el CA «exactamente 1 mensaje `wallet`» (WP-O103).
//
// Uso:  node count-feed-type.js <dir-.ssb> [tipo=wallet] [feedId]
//       (sin feedId se lee el `id` de <dir-.ssb>/secret; la clave privada ni se toca ni se imprime)
//       Dentro del contenedor:  docker exec -i oasis-client node - /home/oasis/.ssb wallet < count-feed-type.js
// Salida: una línea JSON {feed,type,count,distinct,seqs,records,ok}. Exit 0 si el log está íntegro.
//
// Los mensajes privados van cifrados (content es una cadena): no tienen tipo visible y no cuentan.
// Formato flumelog-offset: ver inspect-log-offset.js (mismo recorrido en inverso).

'use strict';
const fs = require('fs');
const path = require('path');

const [dir, typeArg, feedArg] = process.argv.slice(2);
if (!dir) {
  console.error('uso: count-feed-type.js <dir-.ssb> [tipo=wallet] [feedId]');
  process.exit(2);
}
const type = typeArg || 'wallet';
const out = { feed: null, type, count: 0, distinct: 0, seqs: [], records: 0, ok: false };

try {
  let feed = feedArg;
  if (!feed) {
    const raw = fs.readFileSync(path.join(dir, 'secret'), 'utf8');
    const json = raw.split('\n').filter((l) => !l.trim().startsWith('#')).join('\n');
    feed = JSON.parse(json).id;
  }
  if (!/^@[A-Za-z0-9+/]{43}=\.ed25519$/.test(feed || '')) throw new Error('feed inválido');
  out.feed = feed;

  const file = path.join(dir, 'flume', 'log.offset');
  if (!fs.existsSync(file)) {          // identidad recién creada, aún sin log: 0 mensajes
    out.ok = true;
    console.log(JSON.stringify(out));
    process.exit(0);
  }
  const fd = fs.openSync(file, 'r');
  const size = fs.fstatSync(fd).size;  // foto del tamaño: lo que el sbot añada después no se mira
  const u32 = (pos) => { const b = Buffer.alloc(4); fs.readSync(fd, b, 0, 4, pos); return b.readUInt32BE(0); };
  const values = new Set();
  let end = size;
  let bad = size !== 0 && !(size >= 12 && u32(size - 4) === size);
  while (end > 0 && !bad) {
    if (end < 12) { bad = true; break; }
    const len = u32(end - 8);
    const start = end - 12 - len;
    if (start < 0 || u32(start) !== len || u32(end - 4) !== end) { bad = true; break; }
    const b = Buffer.alloc(len);
    fs.readSync(fd, b, 0, len, start + 4);
    let m;
    try { m = JSON.parse(b.toString('utf8')); } catch (_) { bad = true; break; }
    out.records++;
    const v = m && m.value;
    if (v && v.author === feed && v.content && typeof v.content === 'object' && v.content.type === type) {
      out.count++;
      out.seqs.push(v.sequence);
      values.add(JSON.stringify(v.content.address !== undefined ? v.content.address : v.content));
    }
    end = start;
  }
  fs.closeSync(fd);
  out.distinct = values.size;
  out.seqs.sort((a, b) => a - b);
  out.ok = !bad;
} catch (e) {
  out.error = e.message;
}
console.log(JSON.stringify(out));
process.exit(out.ok ? 0 : 1);
