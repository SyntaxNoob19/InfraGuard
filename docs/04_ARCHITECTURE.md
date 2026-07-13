# InfraGuard Architecture

## Purpose

InfraGuard is a Zero-Trust Middleware Security Proxy.

It sits between AI Agents and Enterprise Infrastructure.

Its responsibility is to intercept suspicious AI commands before execution and require administrator approval.

---

## High-Level Flow

AI Agent
↓

Proxy Engine

↓

Threat Detection

↓

Pause Execution

↓

FastAPI

↓

Flutter App / Web Dashboard

↓

Admin Decision

↓

Allow / Block / Quarantine

---

## State Machine

The system transitions through the following states to manage threats securely:

- **SECURE**: Normal operation, no threats detected.
- **THREAT_DETECTED**: A malicious payload is intercepted.
- **WAITING_FOR_ADMIN**: The system awaits an OOB resolution via the API.
- **PROCESSING_ACTION**: The admin's decision is being applied.
- **RECOVERING**: The thread is resuming or terminating, preparing to return to normal.

### Transitions:
- **SECURE → THREAT_DETECTED**: Occurs immediately when the Proxy Engine detects a malicious payload on the stdio pipe.
- **THREAT_DETECTED → WAITING_FOR_ADMIN**: Occurs instantly after the Proxy successfully halts the subprocess thread and updates the global state.
- **WAITING_FOR_ADMIN → PROCESSING_ACTION**: Occurs when a `POST /api/resolve` request is received and authenticated from the Flutter app.
- **PROCESSING_ACTION → RECOVERING**: Occurs after the action (ALLOW, BLOCK_COMMAND, or QUARANTINE) is applied to the thread and the asyncio.Event is triggered.
- **RECOVERING → SECURE**: Occurs when no active incidents remain in the system.

---

## Module Responsibilities

### AI Agents

Responsible for:

- generating JSON-RPC payloads
- simulating attacks

Must NOT:

- communicate with Flutter
- access Dashboard directly

---

### Proxy

Responsible for:

- spawning subprocesses
- reading stdout
- detecting threats
- pausing execution

---

### FastAPI

Responsible for:

- exposing APIs
- maintaining shared state

No business logic.

---

### Flutter

Responsible for:

- displaying alerts
- sending admin actions

---

### Dashboard

Responsible for:

- monitoring
- displaying logs

Read-only.