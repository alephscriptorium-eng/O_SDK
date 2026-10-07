#!/usr/bin/env node
// =============================================================================
// upgrade-patches-audit.js — ¿qué parches de upstream trae ya lo vendorizado?
//
// Upstream parchea sus dependencias con `scripts/patch-node-modules.js` (lo corre
// install.sh, bare metal). Desde Oasis 1.2 las dependencias vienen vendorizadas en
// `src/base/node_modules` y el fork no corre ese script sobre el repo: lo que
// importa es si lo vendorizado YA lleva cada parche. Hasta WP-O124 eso se
// comprobaba con un grep a mano. Este script lo mide: ejecuta el
// patch-node-modules.js de la ref que se le pide EN SECO (fs.writeFileSync no
// escribe: registra) sobre el árbol de trabajo y dice, por parche, qué pasó.
//
// Uso: node devops/scripts/upgrade-patches-audit.js <ref> [--tree <dir>] [--tsv]
//   <ref>   commit de upstream cuyo scripts/patch-node-modules.js se audita (NEW_REF)
//   --tree  raíz del árbol a auditar (por defecto el repo). Dentro, `src/server/node_modules`
//           se resuelve a `src/base/node_modules` (en Windows el enlace del checkout es un
//           fichero de texto, y el Dockerfile lo recrea de todas formas).
//   --tsv   solo la tabla, sin cabecera
//
// Estados (uno por parche, en el orden del script de upstream):
//   aplicado     el script lo reconoce como ya aplicado («already patched»)
//   silencioso   el fichero existe y el script no escribiría ni dice nada. En el script
//                de upstream (medido en 1.2.2 y 1.2.3) cada bloque empieza por
//                `if (!data.includes(<marcador>))`: callar es «el marcador ya está».
//                Vale como aplicado; la única duda queda en ssb-box, que calla también
//                si su anclaje desapareció (se mira ese fichero si cambió en el ciclo)
//   pendiente    el script ESCRIBIRÍA: lo vendorizado no trae el parche. Se dispone:
//                o el entrypoint lo aplica (`apply_node_patches`) o se justifica
//   sin-anclaje  el fichero existe pero el script no encuentra dónde parchear:
//                upstream cambió la dependencia y su propio parche no casa
//   ausente      el fichero no existe en el árbol (p. ej. src/AI/node_modules: se
//                instala en el build, no viene vendorizado)
//
// Salida: tabla `n  estado  fichero  mensaje`. Exit 0 si no hay `pendiente` ni
// `sin-anclaje`; 1 si los hay; 2 si no pudo leer el script de la ref.
// No escribe nada: ni en el árbol ni fuera.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const Module = require('module');
const { execFileSync } = require('child_process');

const args = process.argv.slice(2);
const ref = args.find((a) => !a.startsWith('--'));
const tsvOnly = args.includes('--tsv');
const treeIdx = args.indexOf('--tree');
const repoRoot = path.resolve(__dirname, '..', '..');
const tree = path.resolve(treeIdx >= 0 ? args[treeIdx + 1] : repoRoot);
if (!ref) {
  console.error('uso: upgrade-patches-audit.js <ref> [--tree <dir>] [--tsv]');
  process.exit(2);
}

let script;
try {
  script = execFileSync('git', ['-C', repoRoot, 'show', `${ref}:scripts/patch-node-modules.js`], { encoding: 'utf8' });
} catch (e) {
  console.error(`no pude leer ${ref}:scripts/patch-node-modules.js: ${e.message.split('\n')[0]}`);
  process.exit(2);
}

// El script resuelve rutas con path.resolve(__dirname, '../src/...'): __dirname debe ser <tree>/scripts.
const fakeFile = path.join(tree, 'scripts', '__upgrade-patches-audit__.js');
const mapPath = (p) => {
  const abs = path.resolve(String(p));
  return abs.replace(/([\\/])src[\\/]server[\\/]node_modules([\\/])/, '$1src$1base$1node_modules$2');
};
const rel = (p) => path.relative(tree, mapPath(p)).split(path.sep).join('/');

// Un «sondeo» por existsSync: a él se le cuelgan la escritura y los mensajes que vengan después.
const probes = [];
let cur = null;
const fsShim = Object.assign({}, fs, {
  existsSync: (p) => {
    const ok = fs.existsSync(mapPath(p));
    cur = { file: rel(p), exists: ok, wrote: false, msgs: [] };
    probes.push(cur);
    return ok;
  },
  readFileSync: (p, ...rest) => fs.readFileSync(mapPath(p), ...rest),
  writeFileSync: (p, data) => {
    if (cur && rel(p) === cur.file) cur.wrote = true;
    else probes.push({ file: rel(p), exists: true, wrote: true, msgs: ['(escritura sin sondeo previo)'] });
  },
});

const realLog = console.log;
console.log = (...xs) => {
  const s = xs.join(' ');
  const m = s.match(/^\[OASIS\] \[PATCH\] (.*)$/);
  if (m && cur) cur.msgs.push(m[1]);
  else if (m) probes.push({ file: '?', exists: true, wrote: false, msgs: [m[1]] });
};
process.argv.push('--verbose');

const m = new Module(fakeFile, null);
m.filename = fakeFile;
m.paths = Module._nodeModulePaths(path.dirname(fakeFile));
m.require = (id) => (id === 'fs' ? fsShim : require(id));
try {
  m._compile(script, fakeFile);
} catch (e) {
  console.log = realLog;
  console.error(`el script de ${ref} falló al ejecutarse en seco: ${e.message}`);
  process.exit(2);
}
console.log = realLog;

const classify = (p) => {
  const msg = p.msgs.join(' | ');
  if (!p.exists) return 'ausente';
  if (p.wrote) return 'pendiente';
  if (/already/i.test(msg)) return 'aplicado';
  if (/skipped|not found|unexpected/i.test(msg)) return 'sin-anclaje';
  return 'silencioso';
};

let bad = 0;
const rows = probes.map((p, i) => {
  const st = classify(p);
  if (st === 'pendiente' || st === 'sin-anclaje') bad++;
  return [i + 1, st, p.file, p.msgs.join(' | ') || '-'];
});
if (!tsvOnly) {
  realLog(`# parches de ${ref}:scripts/patch-node-modules.js sobre ${tree}`);
  realLog('n\testado\tfichero\tmensaje');
}
for (const r of rows) realLog(r.join('\t'));
if (!tsvOnly) {
  const count = (s) => rows.filter((r) => r[1] === s).length;
  realLog(`# aplicado=${count('aplicado')} silencioso=${count('silencioso')} pendiente=${count('pendiente')} sin-anclaje=${count('sin-anclaje')} ausente=${count('ausente')}`);
}
process.exit(bad ? 1 : 0);
