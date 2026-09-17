#!/usr/bin/env node
// inspect-log-offset.js — inspecciona un `flume/log.offset` (ssb-db / flumelog-offset) SIN arrancar
// ningún sbot. Sirve para verificar la integridad de un log antes de importarlo y para leer el
// último `sequence` propio (criterio de sincronización de docs/CLIENT-PROTOCOL.md §2-§3).
//
// Uso:  node client/scripts/lib/inspect-log-offset.js <log.offset> [feedId]
//       FULL_SCAN=1 node ... <log.offset> <feedId>   # recorre el log entero (records/feeds totales)
// Salida: una línea JSON. Exit 0 si el fichero está íntegro (tailOk && badFrames == 0), 1 si no.
//
// Formato flumelog-offset (offsets de 32 bits, big-endian):
//   [len u32][json (len bytes)][len u32][endOffset u32]  … repetido; el último u32 == tamaño del fichero.
// Se recorre en INVERSO: el seq propio suele estar cerca del final y así es instantáneo aunque el
// log tenga cientos de MB. Es binario: NO buscar bytes NUL aquí (son legítimos).

'use strict';
const fs = require('fs');

const [file, feed] = process.argv.slice(2);
if (!file) {
  console.error('uso: inspect-log-offset.js <log.offset> [feedId]');
  process.exit(2);
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
