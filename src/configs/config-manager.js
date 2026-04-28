const fs = require('fs');
const path = require('path');

const configFilePath = path.join(__dirname, 'oasis-config.json');
const LOCAL_WALLET_URL = 'http://localhost:7474';
const DEFAULT_WALLET_FEE = '5';

const isBlank = (value) => typeof value !== 'string' || value.trim() === '';

const getWalletDefaults = () => ({
  url: process.env.ECOIN_RPC_URL || LOCAL_WALLET_URL,
  user: process.env.ECOIN_RPC_USER || '',
  pass: process.env.ECOIN_RPC_PASS || '',
  fee: process.env.ECOIN_RPC_FEE || DEFAULT_WALLET_FEE,
});

const resolveWalletConfig = (wallet = {}) => {
  const defaults = getWalletDefaults();

  return {
    ...wallet,
    url: wallet.url === LOCAL_WALLET_URL && process.env.ECOIN_RPC_URL
      ? process.env.ECOIN_RPC_URL
      : (wallet.url || defaults.url),
    user: isBlank(wallet.user) && process.env.ECOIN_RPC_USER
      ? process.env.ECOIN_RPC_USER
      : (wallet.user || defaults.user),
    pass: isBlank(wallet.pass) && process.env.ECOIN_RPC_PASS
      ? process.env.ECOIN_RPC_PASS
      : (wallet.pass || defaults.pass),
    fee: (!wallet.fee || wallet.fee === DEFAULT_WALLET_FEE) && process.env.ECOIN_RPC_FEE
      ? process.env.ECOIN_RPC_FEE
      : (wallet.fee || defaults.fee),
  };
};

if (!fs.existsSync(configFilePath)) {
  const defaultConfig = {
    "themes": {
      "current": "Dark-SNH"
    },
    "modules": {
      "popularMod": "on",
      "topicsMod": "on",
      "summariesMod": "on",
      "latestMod": "on",
      "threadsMod": "on",
      "multiverseMod": "on",
      "invitesMod": "on",
      "walletMod": "on",
      "legacyMod": "on",
      "cipherMod": "on",
      "bookmarksMod": "on",
      "videosMod": "on",
      "docsMod": "on",
      "audiosMod": "on",
      "tagsMod": "on",
      "imagesMod": "on",
      "trendingMod": "on",
      "eventsMod": "on",
      "tasksMod": "on",
      "marketMod": "on",
      "votesMod": "on",
      "tribesMod": "on",
      "reportsMod": "on",
      "opinionsMod": "on",
      "padsMod": "on",
      "calendarsMod": "on",
      "transfersMod": "on",
      "feedMod": "on",
      "pixeliaMod": "on",
      "agendaMod": "on",
      "aiMod": "on",
      "forumMod": "on",
      "gamesMod": "on",
      "jobsMod": "on",
      "shopsMod": "on",
      "projectsMod": "on",
      "bankingMod": "on",
      "parliamentMod": "on",
      "courtsMod": "on",
      "favoritesMod": "on",
      "logsMod": "on",
      "mapsMod": "on",
      "chatsMod": "on",
      "torrentsMod": "on"
    },
    "wallet": getWalletDefaults(),
    "walletPub": {
      "pubId": ""
    },
    "ai": {
      "prompt": "Provide an informative and precise response."
    },
    "ssbLogStream": {
      "limit": 2000
    },
    "homePage": "activity",
    "language": "en",
    "wish": "whole",
    "pmVisibility": "whole"
  };
  fs.writeFileSync(configFilePath, JSON.stringify(defaultConfig, null, 2));
}

const getConfig = () => {
  const configData = fs.readFileSync(configFilePath);
  const cfg = JSON.parse(configData);
  if (cfg.wish !== 'whole' && cfg.wish !== 'mutuals') cfg.wish = 'whole';
  if (cfg.pmVisibility !== 'whole' && cfg.pmVisibility !== 'mutuals') cfg.pmVisibility = 'whole';
  cfg.wallet = resolveWalletConfig(cfg.wallet);
  return cfg;
};

const saveConfig = (newConfig) => {
  fs.writeFileSync(configFilePath, JSON.stringify(newConfig, null, 2));
};

module.exports = {
  getConfig,
  saveConfig,
};
