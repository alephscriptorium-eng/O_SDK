#!/usr/bin/env node
// regen-node-configs.js — regenera los oasis-config.json de los nodos de soporte (HUB, bot de
// cartera) a partir del de upstream, re-aplicando las claves fijadas. Sustituye al «copiar el
// nuevo y re-aplicar a mano» de HUB-PROTOCOL §5.2 y ECOIN-PROTOCOL §5.2.
//
//   node pub/scripts/regen-node-configs.js            regenera los dos ficheros
//   node pub/scripts/regen-node-configs.js --check    no escribe; sale 1 si alguno no está al día
//
// Regla: cada fichero es una COPIA de src/configs/oasis-config.json con unas pocas claves fijadas.
// Se regenera, no se parchea: una clave que upstream retira desaparece sola de la copia.
//
// Claves fijadas (comunes a todo nodo de soporte):
//   modules.aiMod / aiNavMod = off      sin IA
//   ssbLogStream.limit = 20000          ventana de autores del visor y del motor
//   lanBroadcasting = false
//   inboxMutedBots = todos              (desde 1.1.10) el backend trae «bots» de aviso (político,
//                                       empleo, banca, recordatorios…) que se disparan con cualquier
//                                       petición y se envían a sí mismos un mensaje CIFRADO. Un nodo
//                                       de soporte no tiene quien lea su bandeja: silenciados, no
//                                       publican. La lista sale de INBOX_BOTS en src/models/pm_model.js.
// Solo HUB (D-O25: la presentación del visor es del pub; valores de instancia, se conservan):
//   themes.current, language
// Solo bot de cartera (plantilla .tpl; los marcadores los rellena render-wallet-bot-config.sh):
//   wallet.url = http://ecoin:7474 · wallet.user / wallet.pass = marcadores
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const SRC = path.join(ROOT, 'src/configs/oasis-config.json');
const HUB = path.join(ROOT, 'pub/config/hub/oasis-config.json');
const BOT = path.join(ROOT, 'pub/config/wallet-bot/oasis-config.json.tpl');
const PM_MODEL = path.join(ROOT, 'src/models/pm_model.js');
const check = process.argv.includes('--check');

const read = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
const src = read(SRC);

function knownBots() {
  const text = fs.readFileSync(PM_MODEL, 'utf8');
  const m = text.match(/const INBOX_BOTS = \{([\s\S]*?)\n\};/);
  if (!m) throw new Error('no encuentro INBOX_BOTS en src/models/pm_model.js: revisar cómo se silencian los avisos en esta versión');
  const keys = [...m[1].matchAll(/^\s*([a-zA-Z_]+)\s*:/gm)].map((x) => x[1]);
  if (!keys.length) throw new Error('INBOX_BOTS sin claves');
  return keys.concat(['reminders']);   // «reminders» no está en INBOX_BOTS; backend.js lo añade igual
}

function base() {
  const c = JSON.parse(JSON.stringify(src));
  c.modules.aiMod = 'off';
  c.modules.aiNavMod = 'off';
  c.ssbLogStream.limit = 20000;
  c.lanBroadcasting = false;
  c.inboxMutedBots = knownBots();
  return c;
}

const prevHub = fs.existsSync(HUB) ? read(HUB) : {};
const hub = base();
hub.themes.current = (prevHub.themes && prevHub.themes.current) || src.themes.current;
hub.language = prevHub.language || src.language;

const bot = base();
bot.wallet.url = 'http://ecoin:7474';
bot.wallet.user = '__ECOIN_RPC_USER__';
bot.wallet.pass = '__ECOIN_RPC_PASS__';

const flat = (o, p = '') => Object.entries(o).flatMap(([k, v]) => (v && typeof v === 'object' && !Array.isArray(v) ? flat(v, `${p}${k}.`) : [[p + k, JSON.stringify(v)]]));
function report(name, cfg) {
  const A = new Map(flat(src)); const B = new Map(flat(cfg));
  const keys = [...new Set([...A.keys(), ...B.keys()])].filter((k) => A.get(k) !== B.get(k));
  console.log(`${name}: ${keys.length} claves difieren de src/configs/oasis-config.json`);
  for (const k of keys) console.log(`   ${k}: ${A.has(k) ? A.get(k) : '(no existe)'} → ${String(B.get(k)).slice(0, 70)}`);
}

let stale = 0;
for (const [file, cfg, name] of [[HUB, hub, 'HUB'], [BOT, bot, 'bot de cartera']]) {
  const want = JSON.stringify(cfg, null, 2) + '\n';
  const have = fs.existsSync(file) ? fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n') : '';
  report(name, cfg);
  if (have === want) { console.log('   al día'); continue; }
  if (check) { console.log(`   NO está al día: node pub/scripts/regen-node-configs.js`); stale = 1; continue; }
  fs.writeFileSync(file, want);
  console.log(`   regenerado: ${path.relative(ROOT, file).replace(/\\/g, '/')}`);
}
process.exit(stale);
