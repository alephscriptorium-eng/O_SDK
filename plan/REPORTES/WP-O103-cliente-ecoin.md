# Reporte · WP-O103 · ECOin en la app cliente

- **Fecha**: 2026-09-18 · **Rama**: `wp/O103-cliente-ecoin` · **BRIEF**: `plan/BRIEFS/WP-O103-cliente-ecoin.md` · **Asiento**: D-O19.
- **Resultado**: protocolo **asentado en `main`**. Cualquier habitante puede sacarse su cartera siguiendo `docs/CLIENT-PROTOCOL.md` §8.
- **Fuera de alcance por decisión del custodio**: aplicarlo a su identidad scriptorium. Son dos temas independientes; el suyo lo hará él cuando se publique Oasis 1.1.3. Su cliente no se tocó.

## Qué se entregó

| Pieza | Commit |
|---|---|
| BRIEF del WP | `ee12c6d` |
| Entrypoint raíz: estado persistente del cliente y cableado real de la cartera | `584dd90` |
| Compose raíz: `ecoin-wallet` sin puertos, volumen externo, `wallet.url` vacía por defecto; `.env.example` | `366ccb5` |
| Scripts: `ecoin-init.sh`, `backup-wallet.sh`, `guard-destroy.sh`, `ecoin-verify.sh`, compose del drill | `941426b` |
| npm: `ecoin:*` sin credenciales en la línea de comandos; `client:ecoin:*`, `client:wallet:*` | `e36b451` |
| Docs: `CLIENT-PROTOCOL.md` §8, `client/README.md`, referencias cruzadas | `4f4eed3` |
| Arreglo del drill: `git check-ignore` con ruta relativa | `9ae038b` |
| Lo que enseñó el drill | `fa15955` |

## Respuesta a la pregunta del custodio

«¿La app necesita un `ecoind` corriendo o solo una identidad?» — **Dos niveles.**
(i) **Solo dirección**: aparecer, recibir y reclamar RBU. El claim es un mensaje SSB y paga el `ecoind`
del banco. (ii) **Cartera propia**: saldo, envíos e historial exigen un `ecoind` propio con `wallet.dat`
propia. En ambos la dirección sale de una cartera que controlas y tienes respaldada. El cliente nunca
apunta al `ecoind` del VPS. Importar una identidad SSB no trae dirección ECOin: son claves sin relación.

## Criterios de aceptación · evidencia (drill con identidad desechable, proyecto `o-sdk-drill`)

| CA | Resultado |
|---|---|
| RPC por DNS de servicio e inaccesible desde el host | ✅ `docker port` vacío; 7474, 7408 y 12000 rechazados desde el host; 200 desde el cliente |
| Credenciales generadas, nunca las de por defecto | ✅ `ecoinrpc` → 401; contraseña vacía o `ecoinrpc` → `ecoind` sale con 1; 0 apariciones en logs |
| Las `ECOIN_RPC_*` dejan de estar muertas | ✅ `oasis-config.json` cableado desde el entorno y persistido por symlink |
| Exactamente 1 mensaje `wallet` tras N recreates | ✅ tras `--force-recreate`, rebuild, `down -v` y nuevas visitas a `/`, `/banking` y `/wallet` |
| Config de la GUI y estado bancario sobreviven | ✅ idioma y página de inicio cambiados desde la GUI persisten; mapa de direcciones con el mismo sha256 |
| `down -v` no borra la cartera | ✅ el volumen externo sobrevive; `ismine: true` después |
| Backup y restore | ✅ sha256 contenedor = host; con la cartera apartada `ismine: false`, tras el restore `true`; la intermedia se aparta, no se sobrescribe |
| El cliente arranca sin el perfil `ecoin` | ✅ `wallet.url = ""`, sin RPC saliente, `/banking` sin latencia |
| Guarda anti-remoto | ✅ URL remota → error en el log y `wallet.url = ""`, vaciando incluso una URL ya persistida |
| Guarda de destrucción | ✅ sin confirmación rehúsa; con `wallet.dat` sin backup de menos de 24 h rehúsa |
| `src/` sin diff; pub, HUB y bot-2 sin regresión | ✅ 4 guards; entrypoint nuevo comparado con el antiguo sobre la imagen del pub (modo `server` y `backend` con config `:ro`): idéntico |
| No interferencia | ✅ el cliente real del custodio con el mismo `StartedAt` y el mismo `secret`; drill limpiado sin restos |

## Hallazgos

1. **El healthcheck no genera direcciones**: pide `/` sin seguir el 302. La dirección la fija la primera visita a `/wallet`, `/banking` o `/activity`.
2. La publicación automática de la dirección **no ocurre** en 1.1.2 (fallo de upstream); se hace con el alta manual, **una vez** (el POST no es idempotente). Una 1.1.3 puede cambiarlo: de ahí el aviso de hacer backup antes de abrir la GUI con la cartera cableada.
3. Compose interpola también los perfiles inactivos: las credenciales no pueden ser `${VAR:?}`. El fail-closed lo da la imagen (`ECOIN_REQUIRE_CREDS=1`).
4. Fallo previo corregido en el entrypoint: `CONFIG_FILE` era global y `setup_ssb_config` la reasignaba, así que `aiMod` nunca se ajustaba.
5. Bajo `MSYS_NO_PATHCONV=1`, `git -C /c/…` falla en silencio: `ecoin-init.sh` rechazaba siempre su propio `.env`. Corregido con ruta relativa.
6. `docker compose down` sin `--profile ecoin` no ve `ecoin-wallet`: al pasar a «solo dirección» hay que parar antes `ecoind`.

## Seguimiento

- El custodio aplicará §8 a su cliente tras Oasis 1.1.3. Antes: releer §8.2 y el preflight de `docs/PUB/ECOIN-PROTOCOL.md` §5 (la 1.1.3 anuncia autodetección de `ecoind`).
- Su banco será `azofaifo-scriptorium-wallet-bot-2` (`@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519`), hoy con el motor de RBU apagado hasta la dote.
- La próxima vez que se ejecute `npm run up`, el cliente arrancará con el compose nuevo en modo «solo dirección» y `wallet.url` vacía: sin cartera ni RPC hasta que se pida expresamente.
