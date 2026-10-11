#!/usr/bin/env node
// wiki-render-check.js — pasa un cuerpo de wiki por el renderer REAL de Oasis (src/backend/renderStyledText.js) y
// falla si queda alguna línea con «|» literal (tabla sin renderizar), si hay HTML de tabla, o si pasa de MAX_BYTES (6000:
// por encima el cuerpo viaja en bodyBlob y un cliente que llega después lo ve vacío; D-O34).
// Corre donde existan las dependencias de src/ (dentro de un contenedor de esta imagen): por stdin, como ssb-probe.
//
//   docker exec -i <ctr> sh -lc 'cd /app/src/server && node - /app/pub/assets/<plantilla>/wiki/<id>.md' < pub/tools/wiki-render-check.js
//   (o con el cuerpo por WIKI_BODY_FILE=<ruta>)   Salida: JSON {file, bytes, pipeLines, tableHtml, ok}
'use strict';
const fs = require('fs');
const path = require('path');
const MAX_BYTES = Number(process.env.WIKI_MAX_BYTES || 6000);   // > 6000 B el cuerpo va a un blob que un cliente no pide solo (wiki_model.js:50,53-57)
const file = process.argv[2] || process.env.WIKI_BODY_FILE;
if (!file) { console.error('uso: node - <cuerpo.md>'); process.exit(2); }
const body = fs.readFileSync(file, 'utf8');
const { renderStyledText } = require(path.resolve('/app/src/backend/renderStyledText.js'));
// Misma partición que renderWikiBody (src/views/wiki_view.js:33): bloques entre líneas en blanco.
const paras = String(body).replace(/\r\n/g, '\n').split(/\n{2,}/).map(p => p.trim()).filter(Boolean);
const plain = [];
for (const p of paras) {
  const nodes = renderStyledText(p, { wikiLink: (t) => `/wiki/${t}` });
  const text = (Array.isArray(nodes) ? nodes : [nodes]).map(n => typeof n === 'string' ? n : (n && n.outerHTML) || '').join('');
  plain.push(text);
}
const html = plain.join('\n');
const pipeLines = html.split('\n').filter(l => /^\s*\|/.test(l.replace(/<[^>]+>/g, ''))).length;
const out = { file, bytes: Buffer.byteLength(body), paragraphs: paras.length, pipeLines, tableHtml: /<table/i.test(html) ? 1 : 0,
  headers: (html.match(/rt-header/g) || []).length, items: (html.match(/rt-item/g) || []).length, links: (html.match(/<a /g) || []).length };
out.ok = out.pipeLines === 0 && out.tableHtml === 0 && out.bytes <= MAX_BYTES;
console.log(JSON.stringify(out));
process.exit(out.ok ? 0 : 1);
