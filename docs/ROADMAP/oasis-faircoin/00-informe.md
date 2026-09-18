# Informe aguas arriba — para gente de Oasis y de FairCoin

**2026-09-10 · Dosier F4 · audiencia: mantenedores/comunidad upstream**

Qué cuenta este dosier: cómo usa vuestro código el catálogo `modelador-redes`
y sus derivados, qué reglas nos hemos dado, qué encontramos leyéndolo, dónde
entra en el roadmap y qué NO os pedimos. Sin jerga del editor teatral (el
derivado de dramatización se menciona en una tabla y punto).

## Las tres vías

1. **Catálogo (main)** — hecho/aprobado: 12 repos clonados a commits fijos
   (`vendor.json`), solo lectura, citas fichero:línea, deriva = error.
2. **Modelo res_publica** — backlog sin implementar: roadmap «Faircoin3»
   (génesis NUEVO con fairchains-tool; no relanza vuestra cadena), Banking
   multi-moneda sobre el seam de Oasis, federación CVN.
3. **Modelo colectivizaciones** — proyección de dosier: citas escénicas
   (vuestras piezas aparecen citadas, no ejecutadas).

## Reglas de la casa (garantías)

- Solo lectura; vuestro código nunca se commitea en nuestro repo.
- `scripts/vendor.sh --check`: SHA distinto = DERIVA, exit 1; nunca toca un clon.
- Hechos sin adjetivo: «faircoin: sin commits desde 2022-02-05, código
  completo, MIT, citable» — no «muerto».
- Licencias leídas del fichero de cada clon; sin fichero de licencia
  (faircoin-seeder, coopshares) → solo cita, sin reuso.
- Catálogo propio: GPL-3.0-or-later AND LicenseRef-Animus-Iocandi.

## Hallazgos leyendo vuestro código (por si os sirven; no consta reporte upstream)

**Oasis (Banking):** timeout 1500 ms puede producir doble envío · hash de
época no publicado · `POST /update` borra `src/configs/*.json` trackeados ·
dinero solo en `sendtoaddress` (banking_model.js:1004, :1416) · regex `^E` ×12.

**FairCoin:** claves chain-admin y CVN hardcodeadas en `chainparams.cpp` ·
modo `-cvn=file` (cvn.pem) además de Fasito · RPC admin completo
(addcvn/removecvn/bancvn/setchainparameters/addcoinsupply).

**fairchains:** génesis desde JSON sin recompilar (`fairchains-tool.cpp`) —
pieza clave de nuestro camino por defecto.

**Red (hechos):** fair-coin.org «Cooling down FairCoin» (2024-06-17) · DNS de
FairCoop caídos · explorador offline · `seed1:40404` abierto.

## Roadmap (backlog res_publica; defaults, nada implementado)

Sprint 0 rescate (citas, nombre) → 1-2 Banking → 3 testnet+puente ∥ gobernanza
→ 4 federación CVN → 5 economía real → 6 constitución + mainnet.

Piezas: emisión solo a tesoro multisig por ley (`addcoinsupply`, TK-48) ·
admin = ejecutivo electo (TK-49/G06) · criterios CVN guía §4.1/§4.5 ·
custodia Fasito vs `-cvn=file` (TK-82).

**La única petición real hoy (TK-80):** el nombre. «Faircoin3» solo si rasos /
fair-coin.org no objeta en 30 días; aviso: FairCoinOfficial es OTRA moneda.

## Qué NO hacemos / no os pedimos

No fork ejecutado · no revival de vuestra cadena · no snapshot UTXO por
defecto (es alternativa B) · no marcas sin hablar · no PRs no solicitados.
El propio catálogo migrará su remoto canónico de GitHub a Radicle.

Preview publicable: `preview.html`
