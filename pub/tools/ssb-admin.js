#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const defaultServerPackage = '/app/src/server/package.json';
const fallbackServerPackage = path.resolve(__dirname, '../../src/server/package.json');
const serverPackage = process.env.OASIS_SERVER_PACKAGE || (fs.existsSync(defaultServerPackage) ? defaultServerPackage : fallbackServerPackage);
const serverRequire = createRequire(serverPackage);
const ssbClient = serverRequire('ssb-client');
const config = serverRequire('./ssb_config');

function connect() {
  return new Promise((resolve, reject) => {
    const done = (err, sbot) => (err ? reject(err) : resolve(sbot));

    try {
      ssbClient(config.keys, config, done);
    } catch (firstError) {
      try {
        ssbClient(config, done);
      } catch (secondError) {
        try {
          ssbClient(done);
        } catch (thirdError) {
          reject(thirdError || secondError || firstError);
        }
      }
    }
  });
}

function close(sbot) {
  return new Promise((resolve) => {
    if (!sbot || typeof sbot.close !== 'function') return resolve();
    try {
      sbot.close(resolve);
    } catch (_) {
      resolve();
    }
  });
}

function call(sbot, methodPath, args = []) {
  const fn = methodPath.split('.').reduce((target, key) => target && target[key], sbot);
  if (typeof fn !== 'function') {
    throw new Error(`SSB method not available: ${methodPath}`);
  }

  return new Promise((resolve, reject) => {
    fn(...args, (err, result) => (err ? reject(err) : resolve(result)));
  });
}

function print(value) {
  if (typeof value === 'string') {
    console.log(value);
  } else {
    console.log(JSON.stringify(value, null, 2));
  }
}

async function main() {
  const [command, ...args] = process.argv.slice(2);
  if (!command || command === 'help' || command === '--help') {
    print({
      usage: 'node ssb-admin.js <command>',
      commands: [
        'whoami',
        'invite.create [uses]',
        'publish-about <name> [description] [--image <ruta png>]',
        'announce-pub <host> [port]',
        'follow <feedId>',
        'publish-json <json>'
      ]
    });
    return;
  }

  const sbot = await connect();
  try {
    if (command === 'whoami') {
      print(await call(sbot, 'whoami'));
      return;
    }

    if (command === 'invite.create') {
      const uses = Number(args[0] || 1);
      if (!Number.isInteger(uses) || uses < 1) throw new Error('uses must be a positive integer');
      print(await call(sbot, 'invite.create', [uses]));
      return;
    }

    if (command === 'publish-about') {
      // --image <ruta>: sube el fichero como blob (mismo camino que publishProfileEdit, main_models.js:1973-1988)
      // y lo publica en el mismo `about`. Un `about` es irreversible (AGENTES.md §3): una sola llamada, contada antes y después.
      const imgAt = args.indexOf('--image');
      const imagePath = imgAt >= 0 ? args[imgAt + 1] : null;
      const rest = imgAt >= 0 ? args.filter((_, i) => i !== imgAt && i !== imgAt + 1) : args;
      const name = rest[0];
      const description = rest.slice(1).join(' ');
      if (!name) throw new Error('publish-about requires a name');
      const identity = await call(sbot, 'whoami');
      const content = {
        type: 'about',
        about: identity.id,
        name
      };
      if (description) content.description = description;
      if (imagePath) {
        const pull = serverRequire('pull-stream');
        const buf = fs.readFileSync(imagePath);
        if (!/\.(png|jpe?g|webp)$/i.test(imagePath)) throw new Error('--image: solo png/jpg/webp');
        if (buf.length > 50 * 1024 * 1024) throw new Error('--image: máximo 50 MB');
        const blobId = await new Promise((resolve, reject) => pull(pull.values([buf]), sbot.blobs.add((err, id) => (err ? reject(err) : resolve(id)))));
        await call(sbot, 'blobs.push', [blobId]).catch(() => {});
        content.image = blobId;
      }
      print(await call(sbot, 'publish', [content]));
      return;
    }

    if (command === 'announce-pub') {
      const host = args[0] || process.env.OASIS_PUB_HOST || 'pub.escrivivir.co';
      const port = Number(args[1] || process.env.OASIS_PUB_PORT || 8008);
      const identity = await call(sbot, 'whoami');
      print(await call(sbot, 'publish', [{
        type: 'pub',
        address: {
          key: identity.id,
          host,
          port
        }
      }]));
      return;
    }

    if (command === 'follow') {
      const feedId = args[0];
      if (!feedId) throw new Error('follow requires a feed id');
      print(await call(sbot, 'publish', [{
        type: 'contact',
        contact: feedId,
        following: true
      }]));
      return;
    }

    if (command === 'publish-json') {
      const raw = args.join(' ');
      if (!raw) throw new Error('publish-json requires a JSON object');
      print(await call(sbot, 'publish', [JSON.parse(raw)]));
      return;
    }

    throw new Error(`Unknown command: ${command}`);
  } finally {
    await close(sbot);
  }
}

main().catch((error) => {
  console.error(`[ssb-admin] ${error.message}`);
  process.exit(1);
});
