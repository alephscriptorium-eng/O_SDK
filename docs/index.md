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

## Empezar

```bash
git clone https://github.com/alephscriptorium-eng/O_SDK.git
cd O_SDK
npm run setup                          # crea volumes-dev/{ssb-data,ai-models,logs,ecoin-data} (sin esto el bind falla)
docker compose up -d oasis-client      # cliente + SSB + IA  (o `npm run up`, que hace ambos)
# GUI en http://localhost:3000
```

Fork dockerizado de Oasis 1.1.2. Código **FOSS**:
[github.com/alephscriptorium-eng/O_SDK](https://github.com/alephscriptorium-eng/O_SDK).
