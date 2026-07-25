# Integración Aleph Scriptorium ↔ Oasis Network

> **Submódulo**: `alephscript-network-sdk`  
> **Rama de integración**: `integration/beta/scriptorium`  
> **Plugin destino**: `.github/plugins/network/`

---

## Propósito

Este submódulo dockeriza **Oasis**, un cliente de la red **Scuttlebutt** (protocolo P2P descentralizado). La integración con Aleph Scriptorium permite:

1. **Sincronizar BOEs** entre Scriptoriums de diferentes usuarios
2. **Teatro distribuido**: Obras ARG con participantes remotos
3. **Comunicación P2P**: Sin servidor central, funciona offline

---

## Arquitectura

```
┌─────────────────────────────────────────────┐
│           ALEPH SCRIPTORIUM                 │
├─────────────────────────────────────────────┤
│  Plugin Teatro  →  BOE  →  Plugin Network   │
│                            ↓                │
│                    alephscript-network-sdk  │
│                    (Docker: Oasis)          │
│                            ↓                │
│                    Scuttlebutt Network      │
└─────────────────────────────────────────────┘
```

---

## Cómo funciona

### 1. Publicar BOE a la red

```
Usuario → @teatro → genera BOE → Plugin Network → serializador → Feed Oasis
```

### 2. Recibir BOE de la red

```
Feed Oasis → Plugin Network → deserializador → merge con BOE local → @teatro
```

### 3. Sincronización multi-Scriptorium

```
Alice (Scriptorium A)                    Bob (Scriptorium B)
        │                                        │
        ├─── arranca obra ────────────────────▶ │
        │                                        │
        │ ◀──────────────── se inscribe ────────┤
        │                                        │
        ├─── ronda de acciones ──────────────▶  │
        │                                        │
        │ ◀────────────── responde ─────────────┤
        │                                        │
        └─────── BOE sincronizado ──────────────┘
```

---

## Requisitos

| Requisito | Versión | Notas |
|-----------|---------|-------|
| Docker | 20.10+ | Para ejecutar Oasis |
| Docker Compose | 2.0+ | Orquestación |
| Node.js | 18+ | Solo si se desarrolla localmente |

---

## Inicio rápido

### 1. Arrancar Oasis (Docker)

```bash
cd alephscript-network-sdk
docker-compose up -d
```

### 2. Acceder a la interfaz

```
http://localhost:3000
```

### 3. Configurar identidad

Oasis genera una identidad criptográfica automáticamente. Esta identidad se usa para firmar mensajes del BOE.

---

## Integración con ARG_BOARD

El plugin `network` extiende las **plataformas de comunicación** de ARG_BOARD:

| Plataforma | Tipo | Uso |
|------------|------|-----|
| `vscode` | Local | Interacción con Copilot |
| `github` | Remoto | Issues, PRs, Wiki |
| `email` | Asíncrono | Notificaciones |
| **`oasis`** | **P2P** | **Sincronización de BOEs** |

---

## Formato de mensaje BOE en Oasis

```json
{
  "type": "scriptorium-boe",
  "version": "1.0.0",
  "obra_id": "hola_mundo",
  "entrada": {
    "timestamp": "2025-12-24T10:00:00Z",
    "tipo": "accion",
    "actor": "alice",
    "contenido": "Iniciar escena 1",
    "firma": "sig:abc123..."
  },
  "origen": {
    "scriptorium_id": "alice-scriptorium",
    "autor_pubkey": "@abc123.ed25519"
  }
}
```

---

## Suposiciones de Integración

| ID | Suposición | Verificar con |
|----|------------|---------------|
| S1 | Oasis expone API HTTP local | Documentación Oasis |
| S2 | Los feeds son públicos por defecto | Configuración Oasis |
| S3 | El formato del mensaje es extensible | Schema de Scuttlebutt |
| S4 | Docker está disponible en el sistema | Usuario |
| S5 | La red Scuttlebutt tiene peers activos | Conexión de prueba |

---

## Archivos de integración

| Archivo | Propósito |
|---------|-----------|
| `README-SCRIPTORIUM.md` | Este documento |
| `docker-compose.yml` | Orquestación de Oasis |
| `src/` | Código del cliente Oasis |

---

## Roadmap de integración

1. **Sprint 1.11.0**: Crear plugin `network` básico
2. **Sprint 1.12.0**: Implementar sincronización bidireccional
3. **Sprint 1.13.0**: Demo Alice-Bob funcional
4. **Futuro**: Propuesta formal a proyecto Oasis

---

## Referencias

- [Oasis README](README.md)
- [Scuttlebutt Protocol](https://ssbc.github.io/scuttlebutt-protocol-guide/)
- [Plugin Network (Scriptorium)](../.github/plugins/network/)
