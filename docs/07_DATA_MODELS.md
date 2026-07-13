# InfraGuard Data Models

This document defines the core data structures used throughout the InfraGuard system.

## 1. AppState

**Purpose**: Represents the global shared state of the system at any given moment, maintained by the FastAPI Bridge.

**Fields**:
- `system_status` (Enum: SECURE, THREAT_DETECTED, WAITING_FOR_ADMIN, PROCESSING_ACTION, RECOVERING): Overall security state of the system.
- `proxy_status` (Enum: STARTING, RUNNING, STOPPED, ERROR): Operational state of the proxy engine.
- `active_agents` (Integer): The number of active AI Agent subprocesses currently managed by the proxy.
- `active_threats` (Array of `Incident`): A list of currently intercepted threats pending or undergoing resolution.
- `paused_incidents` (Map<String, asyncio.Event>): A mapping of `incident_id` to the specific Python `asyncio.Event` object used to pause and resume the thread.
- `recent_logs` (Array of `LogEntry`): The latest logs for the SOC Dashboard.
- `version` (String): API/System version (e.g., "1.0.0").

**Relationships**: Contains arrays/maps of `Incident` and `LogEntry`.

---

## 2. Incident

**Purpose**: Represents a specific security event triggered by an intercepted malicious payload.

**Fields**:
- `incident_id` (String - UUID): Unique identifier for the threat event.
- `agent_id` (String): Identifier for the compromised AI agent.
- `method` (String): The JSON-RPC method that was intercepted (e.g., "execute_shell").
- `target` (String): The target arguments or command strings of the payload.
- `severity` (Enum: LOW, MEDIUM, HIGH, CRITICAL): Calculated severity of the threat.
- `intent` (String): A human-readable categorization of the threat (e.g., "Unauthorized File Deletion").
- `timestamp` (String - ISO8601): Exact time of interception.
- `status` (Enum: PENDING, ALLOWED, BLOCKED, QUARANTINED): The current resolution state of the incident.
- `payload` (`ThreatPayload`): The original JSON payload.

**Relationships**: Nested inside `AppState.active_threats`.

---

## 3. ThreatPayload

**Purpose**: Represents the raw JSON-RPC payload emitted by the AI Agent.

**Fields**:
- `jsonrpc` (String): Protocol version (e.g., "2.0").
- `method` (String): The action the agent wants to perform.
- `params` (Object): The arguments for the method.
- `id` (Integer/String): The JSON-RPC request identifier.
- `agent_id` (String): The identifier of the agent.
- `timestamp` (String - ISO8601): When the payload was emitted.

**Relationships**: Stored inside an `Incident`.

---

## 4. LogEntry

**Purpose**: A standardized format for system and audit logs streamed to the dashboard.

**Fields**:
- `type` (Enum: INFO, WARNING, ERROR, SUCCESS): The log level.
- `message` (String): The human-readable log content.
- `timestamp` (String - ISO8601): The exact time the log was generated.

**Relationships**: Nested inside `AppState.recent_logs`.

---

## 5. Agent

**Purpose**: Represents a running AI Agent subprocess.

**Fields**:
- `agent_id` (String): Unique identifier.
- `process_id` (Integer): The OS-level PID of the subprocess.
- `status` (Enum: RUNNING, PAUSED, TERMINATED): Current execution state.
- `started_at` (String - ISO8601): When the agent was started.

**Relationships**: Counted in `AppState.active_agents`. Subprocesses are directly managed by the Proxy Engine.
