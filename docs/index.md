# Oasis SDK

Fork **dockerizado** de Oasis: una red social descentralizada sobre **SSB**
(Secure Scuttlebutt) que corres tú, en tu máquina o en tu VPS. Sin nube, sin
cuentas, sin servidor central. Tu identidad es una clave que solo tú tienes.

Una línea: `docker compose up -d` y tienes tu nodo — cliente web, replicación
P2P e IA local — hablando con el resto de la red.

## Qué es

- **Cliente + pub, misma imagen, dos modos.** El mismo contenedor sirve como
  cliente personal (GUI web en `:3000`) o como *pub* de federación en un VPS.
- **Identidad soberana (SSB).** Tu feed es tuyo: la clave `secret` nunca sale
  del volumen. El log se replica desde tus pares; si pierdes el nodo, lo
  recuperas de la red.
- **IA local opcional.** Modelo `gguf` servido en el propio nodo (GPU si hay),
  sin enviar nada a terceros.
- **Fork endurecido.** *Guards* sobre el upstream para que el auto-update
  destructivo no corra dentro de Docker; overrides de config por entorno.

## Empezar

```bash
git clone https://github.com/alephscriptorium-eng/O_SDK.git
cd O_SDK
docker compose up -d oasis-dev      # cliente + SSB + IA
# GUI en http://localhost:3000
```

Para desplegar un **pub** de federación en un VPS, ver
[Proyecto · DevOps](/proyecto) y el
[protocolo de upgrade](/PUB/UPGRADE-PROTOCOL).

## Operación

Dos manuales operativos, reutilizables y verificados en producción:

- **[Protocolo de upgrade](/PUB/UPGRADE-PROTOCOL)** — subir el fork a una nueva
  versión upstream sin perder identidad ni los *fork-guards*.
- **[Protocolo de recuperación](/PUB/RECOVERY-PROTOCOL)** — recuperar repo,
  imagen e identidad SSB tras un fallo de disco o pérdida del log.

---

*Portal FOSS. Todo lo que se afirma aquí se puede comprobar en el
[repositorio](https://github.com/alephscriptorium-eng/O_SDK).*
