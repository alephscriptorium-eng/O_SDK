#!/usr/bin/env node
// count-feed-type.js — cuenta los mensajes de un tipo publicados por UN autor en el log de un
// `.ssb` (`flume/log.offset` en Oasis <= 1.1.x, `db2/log.bipf` en >= 1.2), SIN arrancar ni
// consultar ningún sbot (solo lectura). Lo usa
// client/scripts/ecoin-verify.sh para el CA «exactamente 1 mensaje `wallet`» (WP-O103).
//
// Uso:  node count-feed-type.js <dir-.ssb> [tipo=wallet] [feedId]
//       (sin feedId se lee el `id` de <dir-.ssb>/secret; la clave privada ni se toca ni se imprime)
//       Dentro del contenedor:  docker exec -i oasis-client node - /home/oasis/.ssb wallet < count-feed-type.js
// Salida: una línea JSON {feed,type,format,count,distinct,seqs,records,ok}. Exit 0 si el log está íntegro.
// Un `.ssb` sin ningún log (identidad recién creada) da 0 y ok. Una guarda de migración sin
// `db2/log.bipf` al lado NO es «0 mensajes»: es un error.
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

// --- Log db2 (Oasis >= 1.2): `db2/log.bipf`, bloques de 64 KiB con registros [longitud u16LE][BIPF
// de {key,value,timestamp}]; longitud 0 = fin de bloque; un registro borrado va a ceros. Tras migrar,
// `flume/log.offset` es un fichero-guarda de texto. Mismo recorrido que pub/tools/log-bipf.js.
const GUARD = 'OASIS: this log was migrated';
const isGuard = (f) => {
  try { return fs.statSync(f).size < 4096 && fs.readFileSync(f, 'utf8').startsWith(GUARD); } catch (_) { return false; }
};
const loadBipf = () => {
  const tries = [process.env.OASIS_BIPF, '/app/src/server/node_modules/bipf',
    path.resolve(__dirname, '../../../src/base/node_modules/bipf'), path.resolve(process.cwd(), 'src/base/node_modules/bipf')];
  for (const t of tries) { if (!t) continue; try { return require(t); } catch (_) { /* siguiente */ } }
  throw new Error('no encuentro el módulo bipf (src/base/node_modules/bipf): hace falta para leer db2/log.bipf');
};
// scanDb2(fichero, cb) → { records, bad, partial }; cb recibe cada mensaje {key, value, timestamp}
const scanDb2 = (file, cb) => {
  const bipf = loadBipf();
  const BLOCK = 64 * 1024;
  const fd = fs.openSync(file, 'r');
  const size = fs.fstatSync(fd).size;
  const block = Buffer.alloc(BLOCK);
  const res = { records: 0, bad: 0, partial: false, fileSize: size };
  for (let start = 0; start < size; start += BLOCK) {
    const len = fs.readSync(fd, block, 0, BLOCK, start);
    let off = 0;
    while (off + 2 <= len) {
      const n = block.readUInt16LE(off);
      if (n === 0) break;
      if (off + 2 + n > len) { res.partial = true; break; }
      const data = block.subarray(off + 2, off + 2 + n);
      off += 2 + n;
      if (data.every((x) => x === 0)) continue;       // borrado
      let m;
      try { m = bipf.decode(data, 0); } catch (_) { res.bad++; continue; }
      res.records++;
      cb(m);
    }
  }
  fs.closeSync(fd);
  return res;
};

const type = typeArg || 'wallet';
const out = { feed: null, type, format: null, count: 0, distinct: 0, seqs: [], records: 0, ok: false };

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
  const db2 = path.join(dir, 'db2', 'log.bipf');
  if (fs.existsSync(db2)) {
    out.format = 'db2';
    const values = new Set();
    const r = scanDb2(db2, (m) => {
      const v = m && m.value;
      if (v && v.author === feed && v.content && typeof v.content === 'object' && v.content.type === type) {
        out.count++;
        out.seqs.push(v.sequence);
        values.add(JSON.stringify(v.content.address !== undefined ? v.content.address : v.content));
      }
    });
    out.records = r.records;
    out.distinct = values.size;
    out.seqs.sort((a, b) => a - b);
    out.ok = r.bad === 0;
    console.log(JSON.stringify(out));
    process.exit(out.ok ? 0 : 1);
  }
  if (isGuard(file)) throw new Error('flume/log.offset es la guarda de un log migrado y falta db2/log.bipf');
  if (!fs.existsSync(file)) {          // identidad recién creada, aún sin log: 0 mensajes
    out.ok = true;
    console.log(JSON.stringify(out));
    process.exit(0);
  }
  out.format = 'flume';
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
