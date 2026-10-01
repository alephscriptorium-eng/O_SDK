---
layout: home
hero:
  name: O_SDK
  text: Oasis dockerizado
  tagline: |-
    Red social P2P sobre SSB que corres tú: cliente + pub + IA local.
    Tu nodo, tu identidad. Sin nube, sin cuentas, sin servidor central.
  actions:
    - theme: brand
      text: ¿Quién llega?
      link: /roles/
    - theme: alt
      text: Proyecto · DevOps
      link: /proyecto
    - theme: alt
      text: Protocolo de upgrade
      link: /PUB/UPGRADE-PROTOCOL
    - theme: alt
      text: Recuperación
      link: /PUB/RECOVERY-PROTOCOL
features:
  - title: Cliente + Pub
    details: Misma imagen, dos modos — GUI web personal en :3000 o pub de federación en un VPS.
    link: /proyecto
  - title: Identidad soberana (SSB)
    details: Tu clave nunca sale del volumen; el log se re-replica desde la red si pierdes el nodo.
    link: /proyecto
  - title: Operación verificada
    details: Protocolos de upgrade y recuperación reutilizables, probados en producción.
    link: /PUB/UPGRADE-PROTOCOL
  - title: Roadmap futuro
    details: Los dosieres de trabajo — la red de la casa, el modelo relacional, los modelos políticos y el call4obras. Prospectivo, con fecha y estado.
    link: /ROADMAP/
---

## ¿Quién llega?

No hace falta saber Docker ni SSB. Clonas el repo, abres en él un agente de código y le dices qué
quieres; el agente lee la receta de tu puerta y se para donde la decisión es tuya. Cada encargo
lleva su estado **medido**: lo que está ejercido, y lo que sigue en obras.

<Puertas />

Cómo se usa una puerta y qué garantiza cada sello: [¿Quién llega?](/roles/). Si eres el agente:
[protocolo para agentes](/AGENTES).

## Llévatela

::: code-group

```text [Díselo a tu agente]
Hola. He clonado o-sdk y tengo Docker Desktop arrancado.
Arráncame un cliente Oasis. Lee docs/roles/cliente.md y sigue esa receta.
```

```bash [A mano]
git clone https://github.com/alephscriptorium-eng/O_SDK.git
cd O_SDK
npm run setup                          # crea volumes-dev/{ssb-data,ai-models,logs,client-state} (sin esto el bind falla)
docker compose up -d oasis-client      # cliente + SSB + IA  (o `npm run up`, que hace ambos)
# GUI en http://localhost:3000
```

:::

Hoy ese arranque pide una GPU NVIDIA y descarga un modelo de IA de unos 4 GB: sin ella, mira el
estado de la puerta [Cliente Oasis](/roles/cliente) antes de empezar.

Fork dockerizado de Oasis <Vivo k="oasisVersion" />. Código **FOSS**:
[github.com/alephscriptorium-eng/O_SDK](https://github.com/alephscriptorium-eng/O_SDK).
