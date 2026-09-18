# ARCHIVO/ — territorios vivos

`ARCHIVO/` (en mayúsculas, en castellano) es una convención heredada del monorepo Scriptorium. **No es
[`archive/`](../archive/)**: aquello es el histórico congelado del refactor de 2026-07 (bitácoras y
documentos supersedidos, todo en git, no se toca). Esto son territorios en uso:

| Territorio | En git | Qué es |
| :-- | :-- | :-- |
| [`DISCO/`](DISCO/) | ✅ | **Plan + evidencia** de un paquete de trabajo: lo que se pensó y se comprobó antes de construir. Lo que se mantiene en el tiempo es la doc viva (`docs/`); esto queda como rastro. Hoy: [`oasis-clearweb/`](DISCO/oasis-clearweb/) (el hub a la web abierta → [`docs/PUB/HUB-PROTOCOL.md`](../docs/PUB/HUB-PROTOCOL.md)) |
| [`LORE/`](LORE/) | ❌ (solo `README.md` y `.gitignore`) | **Datos del usuario**: exports de cuentas, stores no regenerables y la capa curada de cada obra del Teatro. Contiene datos personales: deny-by-default, nunca `git add -f`. Ver [`LORE/README.md`](LORE/README.md) |

Regla para añadir un territorio: si es **plan o evidencia** de algo que acabó en `docs/`, va a `DISCO/`;
si son **datos de alguien**, a `LORE/`; si es **prospectivo** (hacia dónde vamos), no va aquí sino a
[`docs/ROADMAP/`](../docs/ROADMAP/index.md), que es lo que publica la web.
