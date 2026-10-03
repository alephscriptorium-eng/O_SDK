#!/usr/bin/env node
// log-bipf.js — lee `db2/log.bipf` (ssb-db2, Oasis >= 1.2) SIN arrancar ni consultar ningún sbot.
// Solo lectura: abre el fichero con 'r' y nada más. No usa async-append-only-log a propósito: al
// abrir un log, esa librería puede truncar un bloque final que considere corrupto, y aquí se lee un
// log que el nodo vivo está escribiendo.
//
// Autocontenido: se envía por stdin a un contenedor de la imagen (solo necesita `bipf`):
//
//   docker exec -i -u oasis -e HOME=/home/oasis -e SSB_FEED='@…=.ed25519' [-e SSB_LAST_TYPE=pubAvailability] <ctr> \
//     sh -lc 'cd /app/src/server && node -' < pub/tools/log-bipf.js
//
// Salida (una línea por dato; la consume devops/scripts/lib-node.sh):
//   S <n>      mayor `sequence` del feed pedido
//   R <tipo>   una por mensaje del feed: su `type`, `(cifrado)`, `(sin-type-inicial)` o `(cadena)`.
//              Misma clasificación que el grep sobre flume/log.offset: el tipo solo cuenta si es la
//              PRIMERA clave del contenido, para que la medida sea comparable antes y después de migrar.
//   L <json>   contenido del último mensaje de tipo SSB_LAST_TYPE (si se pide), recortado
//   T <n>      registros totales del log · D <n> borrados (puestos a cero) · A <n> autores distintos
//
// Formato del fichero: bloques de 64 KiB; cada registro es [longitud u16LE][datos BIPF de {key,value,timestamp}];
// longitud 0 = fin de bloque. Un registro borrado conserva su longitud y lleva los datos a cero.

'use strict';
const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const req = createRequire(process.env.OASIS_SERVER_PACKAGE || '/app/src/server/package.json');
const bipf = req('bipf');

const BLOCK = 64 * 1024;
const file = process.env.SSB_LOG || path.join(process.env.SSB_PATH || path.join(process.env.HOME || '/home/oasis', '.ssb'), 'db2', 'log.bipf');
const feed = process.env.SSB_FEED || '';
const lastType = process.env.SSB_LAST_TYPE || '';

const K_VALUE = bipf.allocAndEncode('value');
const K_AUTHOR = bipf.allocAndEncode('author');
const K_SEQUENCE = bipf.allocAndEncode('sequence');
const K_CONTENT = bipf.allocAndEncode('content');

const classify = (content) => {
  if (typeof content === 'string') return /\.box[0-9]*$/.test(content) ? '(cifrado)' : '(cadena)';
  if (content && typeof content === 'object') {
    const first = Object.keys(content)[0];
    if (first === 'type' && typeof content.type === 'string') return content.type;
  }
  return '(sin-type-inicial)';
};
const isZero = (buf) => { for (let i = 0; i < buf.length; i++) if (buf[i] !== 0) return false; return true; };

let fd;
try { fd = fs.openSync(file, 'r'); } catch (e) { console.error('log-bipf:', e.message); process.exit(1); }
const size = fs.fstatSync(fd).size;
const block = Buffer.alloc(BLOCK);
const authors = new Set();
const out = [];
let total = 0, deleted = 0, maxSeq = 0, last = null;

for (let start = 0; start < size; start += BLOCK) {
  const len = fs.readSync(fd, block, 0, BLOCK, start);
  let off = 0;
  while (off + 2 <= len) {
    const dataLen = block.readUInt16LE(off);
    if (dataLen === 0) break;                 // fin de bloque
    if (off + 2 + dataLen > len) break;       // registro a medio escribir (log vivo)
    const data = block.subarray(off + 2, off + 2 + dataLen);
    off += 2 + dataLen;
    total++;
    if (isZero(data)) { deleted++; continue; }
    const pValue = bipf.seekKey2(data, 0, K_VALUE, 0);
    if (pValue < 0) continue;
    const pAuthor = bipf.seekKey2(data, pValue, K_AUTHOR, 0);
    if (pAuthor < 0) continue;
    const author = bipf.decode(data, pAuthor);
    authors.add(author);
    if (author !== feed) continue;
    const pSeq = bipf.seekKey2(data, pValue, K_SEQUENCE, 0);
    const seq = pSeq < 0 ? 0 : bipf.decode(data, pSeq);
    if (seq > maxSeq) maxSeq = seq;
    const pContent = bipf.seekKey2(data, pValue, K_CONTENT, 0);
    const content = pContent < 0 ? null : bipf.decode(data, pContent);
    const kind = classify(content);
    out.push('R ' + kind);
    if (lastType && kind === lastType) last = content;
  }
}
fs.closeSync(fd);

console.log('S ' + maxSeq);
if (out.length) console.log(out.join('\n'));
if (last) console.log('L ' + JSON.stringify(last).slice(0, 400));
console.log('T ' + total);
console.log('D ' + deleted);
console.log('A ' + authors.size);
