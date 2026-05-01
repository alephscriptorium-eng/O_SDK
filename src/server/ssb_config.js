const fs = require('fs');
const path = require('path');
const Config = require('ssb-config/inject');
const minimist = require('minimist');

const configPath = path.resolve(__dirname, '../configs', 'server-config.json');
const configData = JSON.parse(fs.readFileSync(configPath, 'utf8'));

const argv = process.argv.slice(2);
const i = argv.indexOf('--');
const conf = argv.slice(i + 1);
const cliArgs = ~i ? argv.slice(0, i) : argv;

function mergeDeep(base, override) {
	if (!override || typeof override !== 'object' || Array.isArray(override)) return override;
	const merged = { ...(base || {}) };

	for (const [key, value] of Object.entries(override)) {
		if (value && typeof value === 'object' && !Array.isArray(value)) {
			merged[key] = mergeDeep(merged[key], value);
		} else {
			merged[key] = value;
		}
	}

	return merged;
}

let config = Config('ssb', minimist(conf));
config = mergeDeep(config, configData);

const overridePath = process.env.OASIS_SERVER_CONFIG_OVERRIDE;
if (overridePath && fs.existsSync(overridePath)) {
	const overrideData = JSON.parse(fs.readFileSync(overridePath, 'utf8'));
	config = mergeDeep(config, overrideData);
}

// Set blob size limit to 50MB
const megabyte = Math.pow(2, 20);
config.blobs = config.blobs || {};
config.blobs.max = 50 * megabyte;

module.exports = config;
