#!/usr/bin/env node
// inspect-log-offset.js — inspecciona el log de un `.ssb` SIN arrancar ningún sbot: el
// `flume/log.offset` de Oasis <= 1.1.x (ssb-db / flumelog-offset) o el `db2/log.bipf` de Oasis >= 1.2
// (ssb-db2). Sirve para verificar la integridad de un log antes de importarlo y para leer el
// último `sequence` propio (criterio de sincronización de docs/CLIENT-PROTOCOL.md §2-§3).
//
// Uso:  node client/scripts/lib/inspect-log-offset.js <log.offset | log.bipf> [feedId]
//       FULL_SCAN=1 node ... <log.offset> <feedId>   # recorre el log entero (records/feeds totales)
// Si se le da un `flume/log.offset` que ya es la guarda de un log migrado, lee el `db2/log.bipf`
// de al lado. El campo `format` de la salida dice cuál leyó (`flume` o `db2`).
// Salida: una línea JSON. Exit 0 si el fichero está íntegro (tailOk && badFrames == 0), 1 si no.
//
// Formato flumelog-offset (offsets de 32 bits, big-endian):
//   [len u32][json (len bytes)][len u32][endOffset u32]  … repetido; el último u32 == tamaño del fichero.
// Se recorre en INVERSO: el seq propio suele estar cerca del final y así es instantáneo aunque el
// log tenga cientos de MB. Es binario: NO buscar bytes NUL aquí (son legítimos).

'use strict';
const fs = require('fs');
const path = require('path');

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

const [fileArg, feed] = process.argv.slice(2);
if (!fileArg) {
  console.error('uso: inspect-log-offset.js <log.offset | log.bipf> [feedId]');
  process.exit(2);
}

// ¿Qué fichero es el log de verdad?
let file = fileArg;
let format = /\.bipf$/.test(fileArg) ? 'db2' : 'flume';
if (format === 'flume' && (isGuard(fileArg) || !fs.existsSync(fileArg))) {
  const sibling = path.join(path.dirname(path.dirname(fileArg)), 'db2', 'log.bipf');
  if (fs.existsSync(sibling)) { file = sibling; format = 'db2'; }
  else if (isGuard(fileArg)) {
    console.log(JSON.stringify({ file: fileArg, error: 'es la guarda de un log migrado a db2 y no hay db2/log.bipf al lado' }));
    process.exit(1);
  }
}

if (format === 'db2') {
  const o = { file, format, fileSize: 0, tailOk: false, records: 0, badFrames: 0, feeds: 0, scannedToStart: true,
    mySeq: null, myLastKey: null, myLastTs: null, myLastType: null };
  try {
    const seen = new Set();
    const r = scanDb2(file, (m) => {
      const v = m && m.value; if (!v) return;
      if (v.author) seen.add(v.author);
      if (feed && v.author === feed && (o.mySeq === null || v.sequence > o.mySeq)) {
        o.mySeq = v.sequence; o.myLastKey = m.key || null;
        o.myLastTs = v.timestamp ? new Date(v.timestamp).toISOString() : null;
        o.myLastType = (v.content && v.content.type) || (typeof v.content === 'string' ? 'private' : null);
      }
    });
    o.fileSize = r.fileSize; o.records = r.records; o.badFrames = r.bad; o.tailOk = !r.partial; o.feeds = seen.size;
    if (feed && o.mySeq === null) o.mySeq = 0;
  } catch (e) { o.error = e.message; }
  console.log(JSON.stringify(o));
  process.exit(!o.error && o.tailOk && o.badFrames === 0 ? 0 : 1);
}

let fd;
try {
  fd = fs.openSync(file, 'r');
} catch (e) {
  console.log(JSON.stringify({ file, error: e.message }));
  process.exit(1);
}
const size = fs.fstatSync(fd).size;
const u32 = (pos) => {
  const b = Buffer.alloc(4);
  fs.readSync(fd, b, 0, 4, pos);
  return b.readUInt32BE(0);
};

const out = {
  file,
  format,
  fileSize: size,
  tailOk: size >= 12 && u32(size - 4) === size,
  records: 0,
  badFrames: 0,
  feeds: 0,
  scannedToStart: false,
  mySeq: null,
  myLastKey: null,
  myLastTs: null,
  myLastType: null,
};

const authors = new Set();
let end = size;
const fullScan = process.env.FULL_SCAN === '1' || !feed;

while (end > 0 && out.tailOk) {
  if (end < 12) { out.badFrames++; break; }
  const len = u32(end - 8);
  const start = end - 12 - len;
  if (start < 0 || u32(start) !== len || u32(end - 4) !== end) { out.badFrames++; break; }
  const b = Buffer.alloc(len);
  fs.readSync(fd, b, 0, len, start + 4);
  let m;
  try { m = JSON.parse(b.toString('utf8')); } catch (_) { out.badFrames++; break; }
  out.records++;
  const a = m && m.value && m.value.author;
  if (a) authors.add(a);
  if (feed && a === feed && out.mySeq === null) {
    out.mySeq = m.value.sequence;
    out.myLastKey = m.key || null;
    out.myLastTs = m.value.timestamp ? new Date(m.value.timestamp).toISOString() : null;
    out.myLastType = (m.value.content && m.value.content.type) || (typeof m.value.content === 'string' ? 'private' : null);
    if (!fullScan) break;
  }
  end = start;
}
out.feeds = authors.size;
out.scannedToStart = end === 0;
if (feed && out.mySeq === null) out.mySeq = 0;
fs.closeSync(fd);

console.log(JSON.stringify(out));
process.exit(out.tailOk && out.badFrames === 0 ? 0 : 1);
