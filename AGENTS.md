# AGENTS.md · o-sdk

Eres un agente (o una persona) que llega a este repo a **operar**: levantar un pub de Oasis, añadirle
piezas, subirlo de versión o recuperarlo. Este fichero es la puerta; el manual está en
**[`docs/AGENTES.md`](docs/AGENTES.md)**. Léelo entero antes de ejecutar nada.

## Qué es esto

Un fork dockerizado de [Oasis](https://github.com/epsylon/oasis) (red social sobre SSB) con todo lo
necesario para desplegar un **pub** en un VPS y una **app cliente** en local. `src/` es upstream más
**5 guards** contados; todo lo demás (`pub/`, `ecoin/`, `client/`, `devops/`, `docs/`) es del fork.

El repo separa **método** e **instancia**. El método es genérico: sirve a cualquier pub, con su
dominio, sus pieles y su lore. La instancia que lo ejercita es Scriptorium (`pub.escrivivir.co`), y
sus datos viven en [`docs/PUB/INSTANCIA-SCRIPTORIUM.md`](docs/PUB/INSTANCIA-SCRIPTORIUM.md). Si
despliegas otro pub, copias esa ficha y la rellenas con lo tuyo; los protocolos no cambian.

## Cinco leyes sin excepción

1. **No asumas el estado: mídelo.** Antes de tocar un host, `devops/scripts/deploy-status.sh`. Lo que
   dice un documento es lo que había el día que se escribió.
2. **Parada dura ante desviación.** Si un paso no da la salida esperada, paras y lo cuentas. No
   improvisas un camino alternativo sobre un host vivo.
3. **Lo irreversible pide permiso expreso, cada vez.** Un mensaje SSB no se borra; una `wallet.dat` o un
   `secret` perdidos no se recuperan. La tabla está en `docs/AGENTES.md` §3.
4. **Los secretos nacen en el destino y no viajan.** Ni en git, ni en logs, ni en reportes, ni en tu
   salida: credenciales RPC, invites con semilla, `secret`, `.env.prod`.
5. **Evidencia = comando + salida.** No escribas en un reporte una observación que no hayas hecho.

## No confundir

`pub/rrss-sidecar/twitter_x/AGENTS.md` es otra cosa: instrucciones para agentes **lectores de una
obra** del Teatro. No es un manual de operación.
