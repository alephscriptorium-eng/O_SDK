# Sidecar de ficheros (WP-S14) — imagen out-of-process, hermana de panel-api.
# bookworm-slim (no alpine): ssb-client arrastra sodium-native, que trae prebuilds glibc.
FROM node:20-bookworm-slim

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY src ./src

EXPOSE 8790
CMD ["node", "src/servidor.mjs"]
