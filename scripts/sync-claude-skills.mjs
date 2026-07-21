#!/usr/bin/env node
// scripts/sync-claude-skills.mjs — WP-I71 · Materialización a .claude/skills/
//
// Copia las skills del paquete instalado (@alephscript/skills-scriptorium) a
// .claude/skills/ como ESPEJO auditable y commiteado. La FUENTE DE VERDAD sigue
// siendo la dependencia versionada (package-lock.json); este dir es derivado.
//
// - Excluye `_plantilla` (andamiaje del paquete, no una skill activable).
// - Para cada skill: borra-y-recrea SU dir (no arrasa otros contenidos de .claude/).
// - Regenera README.md de procedencia con nombre+versión LEÍDOS del package.json
//   del paquete instalado (nunca hardcodeados).
//
// Uso: `npm run skills:sync` (idempotente).

import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import {
  cpSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from 'node:fs';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..');
const PKG = '@alephscript/skills-scriptorium';

const PKG_DIR = join(ROOT, 'node_modules', PKG);
const SRC_ROOT = join(PKG_DIR, 'skills');
const DEST_ROOT = join(ROOT, '.claude', 'skills');
const EXCLUDE = new Set(['_plantilla']);

// Procedencia: nombre + versión leídos del paquete instalado (NO hardcode).
if (!existsSync(join(PKG_DIR, 'package.json'))) {
  console.error(
    `[sync-claude-skills] paquete no instalado: ${PKG}\n` +
      `  ejecuta 'npm install' antes de sincronizar.`,
  );
  process.exit(1);
}
const { name, version } = JSON.parse(
  readFileSync(join(PKG_DIR, 'package.json'), 'utf8'),
);

if (!existsSync(SRC_ROOT)) {
  console.error(`[sync-claude-skills] fuente no encontrada: ${SRC_ROOT}`);
  process.exit(1);
}

// Skills a sincronizar = subdirectorios de la fuente menos exclusiones, ordenadas.
const skills = readdirSync(SRC_ROOT, { withFileTypes: true })
  .filter((d) => d.isDirectory() && !EXCLUDE.has(d.name))
  .map((d) => d.name)
  .sort();

mkdirSync(DEST_ROOT, { recursive: true });

for (const skill of skills) {
  const dest = join(DEST_ROOT, skill);
  rmSync(dest, { recursive: true, force: true }); // borra-y-recrea SOLO este dir
  cpSync(join(SRC_ROOT, skill), dest, { recursive: true });
  console.log(`[sync-claude-skills] OK  ${skill}`);
}

// README de procedencia (determinista → idempotente).
const readme = `<!-- GENERADO por scripts/sync-claude-skills.mjs — NO editar a mano -->
# .claude/skills/ — espejo materializado

Estas skills son un **espejo** del paquete instalado. La **fuente de verdad**
es la dependencia versionada (fijada en \`package-lock.json\`), no este directorio.

| dato | valor |
| ---- | ----- |
| procedencia | \`${name}@${version}\` |
| origen | \`node_modules/${name}/skills/\` |
| generador | \`scripts/sync-claude-skills.mjs\` (\`npm run skills:sync\`) |
| skills | ${skills.map((s) => `\`${s}\``).join(', ')} |

Actualizar: \`npm install\` (resuelve la versión del lock) y luego
\`npm run skills:sync\`. No edites estos ficheros a mano — cada dir se
borra-y-recrea en la siguiente sincronización.
`;
writeFileSync(join(DEST_ROOT, 'README.md'), readme);
console.log(`[sync-claude-skills] OK  README.md (${name}@${version})`);
console.log(
  `[sync-claude-skills] listo: ${skills.length} skills -> ${DEST_ROOT}`,
);
