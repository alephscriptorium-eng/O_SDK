#!/usr/bin/env node
// upgrade-closure.js — qué ficheros de src/ puede cargar un punto de entrada de Oasis.
//
// «El pub en modo server solo ejecuta src/server/» es falso: SSB_server.js hace require de
// ../models/banking_model.js, ../configs/state-manager y otros. El riesgo de un upgrade para un
// rol es el CIERRE de requires de su punto de entrada, no su carpeta.
//
// Uso: node devops/scripts/upgrade-closure.js <ref-git> <entrada> [<entrada>…]
//      node devops/scripts/upgrade-closure.js oasis-upstream/main src/server/SSB_server.js
// Salida: una ruta por línea (relativa al repo), ordenada.
//
// Es una sobreaproximación estática: sigue todo require()/import con ruta relativa literal,
// también los que están dentro de funciones (carga perezosa). No sigue node_modules ni rutas
// calculadas. Lee los ficheros de git (`git show ref:ruta`), no del árbol de trabajo.
'use strict';
const { execFileSync } = require('child_process');
const path = require('path').posix;

const [ref, ...entries] = process.argv.slice(2);
if (!ref || !entries.length) { console.error('uso: upgrade-closure.js <ref> <entrada>…'); process.exit(2); }

const tree = new Set(execFileSync('git', ['ls-tree', '-r', '--name-only', ref, '--', 'src'], { encoding: 'utf8', maxBuffer: 64 << 20 }).split('\n').filter(Boolean));
const read = (p) => execFileSync('git', ['show', `${ref}:${p}`], { encoding: 'utf8', maxBuffer: 64 << 20 });
const resolve = (from, spec) => {
  const base = path.normalize(path.join(path.dirname(from), spec));
  for (const c of [base, `${base}.js`, `${base}.mjs`, `${base}.json`, `${base}/index.js`]) if (tree.has(c)) return c;
  return null;
};

const seen = new Set();
const queue = entries.filter((e) => tree.has(e));
if (!queue.length) { console.error(`ninguna entrada existe en ${ref}: ${entries.join(' ')}`); process.exit(2); }
const RE = /(?:require\(\s*|from\s+|import\(\s*)(['"])(\.{1,2}\/[^'"]+)\1/g;
while (queue.length) {
  const f = queue.pop();
  if (seen.has(f)) continue;
  seen.add(f);
  if (!/\.(js|mjs)$/.test(f)) continue;
  let src;
  try { src = read(f); } catch (_) { continue; }
  for (const m of src.matchAll(RE)) {
    if (m[2].includes('node_modules')) continue;
    const r = resolve(f, m[2]);
    if (r && !seen.has(r)) queue.push(r);
  }
}
console.log([...seen].sort().join('\n'));
