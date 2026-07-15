# Request Flow Architecture

InfraGuard handles payloads dynamically based on their threat assessment and admin decisions. The flows below outline safe execution, malicious blocking, and administrative quarantine procedures.

## Core Flow Diagrams

```mermaid
flowchart TD
    Start((Incoming Payload)) --> Assessment{Threat Detection}
    Assessment -->|Low Risk| Safe[Safe Payload Flow]
    Assessment -->|High Risk| Malicious[Malicious Payload Flow]
    Assessment -->|Uncertain/Policy| Admin[Admin Decision Flow]

    subgraph Safe Flow
        Safe --> E[Execute Action]
        E --> Log1[Log Success]
    end

    subgraph Malicious Flow
        Malicious --> B[Block Execution]
        B --> Alert1[Alert Admin]
        Alert1 --> Log2[Log Incident]
    end

    subgraph Admin Decision Flow
        Admin --> Hold[Hold Execution]
        Hold --> Notify[Notify Admin via WebSocket]
        Notify --> Decision{Admin Decision}
        Decision -->|ALLOW| E2[Execute Action]
        Decision -->|BLOCK| B2[Drop Payload]
        Decision -->|QUARANTINE| Q[Isolate Payload]
    end
```
