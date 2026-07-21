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
---

## Empezar

```bash
git clone https://github.com/alephscriptorium-eng/O_SDK.git
cd O_SDK
docker compose up -d oasis-dev      # cliente + SSB + IA
# GUI en http://localhost:3000
```

Fork dockerizado de Oasis 0.8.8. Código **FOSS**:
[github.com/alephscriptorium-eng/O_SDK](https://github.com/alephscriptorium-eng/O_SDK).
