# System Architecture

The following diagram illustrates the core components and data flow of the InfraGuard platform, highlighting the real-time pipeline from AI agent execution through the Zero-Trust Proxy, down to the multi-platform admin and SOC dashboards.

```mermaid
flowchart TD
    A[AI Agent] -->|JSON-RPC| B[Zero-Trust Proxy]
    B --> C[Threat Detection Engine]
    C --> D[Execution Controller]
    D --> E[State Manager]
    E --> F[FastAPI Backend]
    F -->|WebSocket Broadcast| G[Flutter Admin App]
    F -->|WebSocket Broadcast| H[Enterprise SOC Dashboard]
```
