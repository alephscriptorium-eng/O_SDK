# 03 · call4obras (y call4cypherpunks)

## La proposición, en datos

1. «Aleph Cero» **es una obra**: el archivo de una cuenta de X convertido en sitio estático sin JS +
   visor + zips firmados, con una puerta que explica lo que sostiene [V].
2. El generador es **genérico y libre**: cualquier export de X produce una obra con los mismos
   comandos; la puerta semántica es opcional y la cura cada custodio [V]
   (`o-sdk/docs/PUB/RRSS-SIDECAR-PROTOCOL.md`, `TEATRO-CURADURIA-PROTOCOL.md`).
3. El Teatro de `pub.escrivivir.co` **puede acoger más obras** [C].
4. Quien prefiera no depender de nadie puede montar **su propio pub y su propio teatro** y, después,
   **federar** con este [C].

## Vía A — te acogemos

| | |
| :-- | :-- |
| Contacto | `secretaria@escrivivir.co` |
| Asunto | `call4obras` |
| Qué traer | el export oficial de tu cuenta (X hoy; otras fuentes, después: la costura del sidecar está preparada para más adaptadores) |
| Qué sale | `pub.escrivivir.co/teatro/<tu-obra>/`: puertas sin JS, visor, zip completo + zip ligero, `MANIFEST.sha256`, firma ed25519 |
| Qué no se publica nunca | IPs, teléfono, email, tokens de dispositivo, DMs, bloqueos, likes, posts borrados |

## Vía B — DIY

**Oficial (Oasis / SolarNET.HUB)**

- `https://solarnethub.com` — el proyecto
- `https://wiki.solarnethub.com` — documentación (`/socialnet/overview`, `/socialnet/snh-pub`)
- `https://github.com/epsylon/oasis` — código (espejo de `https://code.03c8.net/KrakensLab/oasis`)
- `https://pub.solarnethub.com/` — pub oficial · `https://oasis-project.pub/api/pubs` — lista de pubs

**No oficial (nuestro wrapper)**

- `https://o-sdk.escrivivir.co` — web y manuales
- `https://github.com/alephscriptorium-eng/O_SDK` — Oasis dockerizado (pub con base local para VPS +
  cliente aparte), hub clearnet, Teatro y sidecar de RRSS (Python ≥ 3.10, solo biblioteca estándar)

```bash
npm run teatro:lore:import -- --obra mi-obra --from <export-descomprimido>
npm run teatro:init   -- --obra mi-obra --title "Mi Obra"
npm run teatro:ingest -- --obra mi-obra
npm run teatro:fetch:voices -- --obra mi-obra --run
npm run teatro:fetch:links  -- --obra mi-obra --run
npm run teatro:build  -- --obra mi-obra
TEATRO_OBRA=mi-obra npm run devops:teatro:deploy
```

## Federar con este pub

Los datos de conexión **no se copian aquí**: cambian, y una copia se desfasa. La fuente única es el propio pub:

- <https://pub.escrivivir.co/public/status> — `host`, `port`, `feedId`, `connect` (multiserver), `capsShs` (las caps de la red) y versión de Oasis, en JSON;
- <https://pub.escrivivir.co> — los mismos datos con botón COPY, y el **invite vivo**;
- <https://pub.escrivivir.co/c> — el navegador en claro del pub.

En Oasis: *Invites → Tribus → pegar el invite*; o seguir el feed con el `connect`. Las `caps` deben
coincidir: son las de la red, no las de este pub.

## call4cypherpunks (una línea)

Verifica, no confíes: checksums, firma y manifiesto publicados; el generador viaja dentro del zip
(`tools/`); el archivo se lee sin JavaScript y sin terceros.
