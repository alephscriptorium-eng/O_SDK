const fs = require('fs');
const path = require('path');

const log = (msg) => console.log(`[OASIS] [PATCH] ${msg}`);

// === Patch ssb-ref ===
const ssbRefPath = path.resolve(__dirname, '../src/server/node_modules/ssb-ref/index.js');
if (fs.existsSync(ssbRefPath)) {
  let data = fs.readFileSync(ssbRefPath, 'utf8');
  let changed = false;

  // parseAddress
  if (!/exports\.parseAddress\s*=\s*parseAddress(?!\s*\()/.test(data)) {
    const p = data.replace(
      /exports\.parseAddress\s*=\s*deprecate\(\s*['"][^'"]*['"]\s*,\s*parseAddress\s*\)/,
      'exports.parseAddress = parseAddress'
    );
    if (p !== data) { data = p; changed = true; log('ssb-ref: removed deprecate wrapper from parseAddress'); }
    else log('ssb-ref: parseAddress patch skipped – unexpected format');
  }

  // parseLegacyInvite
  if (/exports\.parseLegacyInvite\s*=\s*deprecate\(/.test(data)) {
    const p = data.replace(
      /exports\.parseLegacyInvite\s*=\s*deprecate\(\s*['"][^'"]*['"]\s*,\s*parseLegacyInvite\s*\)/,
      'exports.parseLegacyInvite = parseLegacyInvite'
    );
    if (p !== data) { data = p; changed = true; log('ssb-ref: removed deprecate wrapper from parseLegacyInvite'); }
    else log('ssb-ref: parseLegacyInvite patch skipped – unexpected format');
  }

  // parseMultiServerInvite
  if (/exports\.parseMultiServerInvite\s*=\s*deprecate\(/.test(data)) {
    const p = data.replace(
      /exports\.parseMultiServerInvite\s*=\s*deprecate\(\s*['"][^'"]*['"]\s*,\s*parseMultiServerInvite\s*\)/,
      'exports.parseMultiServerInvite = parseMultiServerInvite'
    );
    if (p !== data) { data = p; changed = true; log('ssb-ref: removed deprecate wrapper from parseMultiServerInvite'); }
    else log('ssb-ref: parseMultiServerInvite patch skipped – unexpected format');
  }

  // parseInvite (inline anonymous function wrapped in deprecate)
  if (/exports\.parseInvite\s*=\s*deprecate\(/.test(data)) {
    const p = data.replace(
      /exports\.parseInvite\s*=\s*deprecate\(\s*['"][^'"]*['"]\s*,\s*(function\s*\(invite\)\s*\{[\s\S]*?\})\s*\)/,
      'exports.parseInvite = $1'
    );
    if (p !== data) { data = p; changed = true; log('ssb-ref: removed deprecate wrapper from parseInvite'); }
    else log('ssb-ref: parseInvite patch skipped – unexpected format');
  }

  // toLegacyAddress
  if (/exports\.toLegacyAddress\s*=\s*deprecate\(/.test(data)) {
    const p = data.replace(
      /exports\.toLegacyAddress\s*=\s*deprecate\(\s*['"][^'"]*['"]\s*,\s*toLegacyAddress\s*\)/,
      'exports.toLegacyAddress = toLegacyAddress'
    );
    if (p !== data) { data = p; changed = true; log('ssb-ref: removed deprecate wrapper from toLegacyAddress'); }
    else log('ssb-ref: toLegacyAddress patch skipped – unexpected format');
  }

  if (changed) {
    fs.writeFileSync(ssbRefPath, data);
    log('ssb-ref patched successfully');
  } else {
    log('ssb-ref no necesita patch');
  }
} else {
  log('ssb-ref patch skipped: file not found at ' + ssbRefPath);
}

// === Patch ssb-blobs ===
const ssbBlobsPath = path.resolve(__dirname, '../src/server/node_modules/ssb-blobs/inject.js');
if (fs.existsSync(ssbBlobsPath)) {
  let data = fs.readFileSync(ssbBlobsPath, 'utf8');

  const marker = 'want: function (id, cb)';
  const startIndex = data.indexOf(marker);
  if (startIndex !== -1) {
    const endIndex = data.indexOf('},', startIndex);
    if (endIndex !== -1) {
      const before = data.slice(0, startIndex);
      const after = data.slice(endIndex + 2);

      const replacement = `
  want: function (id, cb) {
    id = toBlobId(id);
    if (!isBlobId(id)) return cb(new Error('invalid id:' + id));

    if (blobStore.isEmptyHash(id)) return cb(null, true);

    if (wantCallbacks[id]) {
      if (!Array.isArray(wantCallbacks[id])) wantCallbacks[id] = [];
      wantCallbacks[id].push(cb);
    } else {
      wantCallbacks[id] = [cb];
      blobStore.size(id, function (err, size) {
        if (err) return cb(err);
        if (size != null) {
          while (wantCallbacks[id].length) {
            const fn = wantCallbacks[id].shift();
            if (typeof fn === 'function') fn(null, true);
          }
          delete wantCallbacks[id];
        }
      });
    }

    const peerId = findPeerWithBlob(id);
    if (peerId) get(peerId, id);

    if (wantCallbacks[id]) registerWant(id);
  },`;

      const finalData = before + replacement + after;
      fs.writeFileSync(ssbBlobsPath, finalData);
      log('Patched ssb-blobs to fix wantCallbacks handling');
    } else {
      log('ssb-blobs patch skipped: end of want function not found');
    }
  } else {
    log('ssb-blobs patch skipped: want function not found');
  }
}
