🛠️ Technical Requirements Document (TRD)

Product Name: InfraGuard
Version: 1.0.0 (Hackathon MVP)
Date: July 14, 2026


1. System Architecture Overview

InfraGuard operates as a local Edge-Level Man-in-the-Middle (MITM) Proxy. It does not sit on the cloud network; instead, it wraps the local execution environment of the AI Agent.

Layer 1 (Execution): The AI Agent runs as a child subprocess managed by the Python Proxy. Communication occurs via OS-level stdio pipes.

Layer 2 (Middleware): The Python asyncio engine intercepts the stdout stream, parsing JSON-RPC payloads before they reach the OS or target tools.

Layer 3 (API Bridge): A FastAPI server wraps the asyncio engine, exposing the current thread state to external clients.

Layer 4 (Clients): An ngrok tunnel exposes the local FastAPI server to the public internet, allowing the Flutter Mobile App and Web Dashboard to poll state and send resolution commands.

2. Frontend Responsibilities

Mobile App (Flutter - Kill-Switch)

State Management: Stateless client. Relies entirely on the backend API for truth.

Polling: Execute a GET /api/status request every 2 seconds via the ngrok URL.

UI Rendering: Switch from "Secure" (Green) to "Threat Detected" (Red Alert Card) dynamically based on the system_status payload.

Action Dispatch: Capture user intent and send a POST /api/resolve request with the selected action (ALLOW, BLOCK_COMMAND, QUARANTINE).

SOC Web Dashboard (HTML/Tailwind/JS)

Monitoring: Passive read-only interface. Polls GET /api/status every 2 seconds.

Log Streaming: Append new logs from the API response to a simulated terminal <div>. Auto-scroll to the bottom.

Visual Cues: Highlight intercepted commands in warning colors (Amber/Red) and update the global status indicator synchronously.

3. Backend Responsibilities

Core Interceptor Engine (asyncio)

Process Management: Use asyncio.create_subprocess_exec to spawn the AI agent scripts.

Stream Reading: Read stdout line-by-line using asynchronous non-blocking I/O.

Thread Freezing: Upon detecting a threat, use asyncio.Event() to halt the parsing loop indefinitely until an external trigger releases it.

Process Termination: If QUARANTINE is received, send a SIGKILL or SIGTERM to the subprocess to terminate the agent completely.

API Bridge (FastAPI)

State Hosting: Maintain global Shared Application State variables (see Section 4).

Endpoint Routing: Handle incoming HTTP traffic from the UIs and translate them into asyncio.Event().set() calls to unfreeze the core engine.

CORS: Fully enable Cross-Origin Resource Sharing (CORS) to allow local web dashboard development.

4. Shared Application State & Enums

The global AppState is maintained in memory by the FastAPI Bridge.

- `system_status` (Enum: SECURE, THREAT_DETECTED, WAITING_FOR_ADMIN, PROCESSING_ACTION, RECOVERING): Overall security state. Owned by FastAPI.
- `proxy_status` (Enum: STARTING, RUNNING, STOPPED, ERROR): Operational status of the proxy. Owned by Proxy Engine.
- `active_agents`: Integer count of running subprocesses. Owned by Proxy Engine.
- `active_threats`: Array of active Incident objects. Owned by FastAPI.
- `paused_incidents`: Dictionary mapping `incident_id` -> `asyncio.Event` (used for resolution). Owned by Proxy Engine.
- `recent_logs`: Array of recent LogEntry objects. Owned by FastAPI.
- `version`: String version (e.g., "1.0.0"). Owned by FastAPI.

Enums:
- System Status: SECURE, THREAT_DETECTED, WAITING_FOR_ADMIN, PROCESSING_ACTION, RECOVERING.
- Proxy Status: STARTING, RUNNING, STOPPED, ERROR.
- Threat Severity: LOW, MEDIUM, HIGH, CRITICAL.
- Admin Actions: ALLOW, BLOCK_COMMAND, QUARANTINE.
- Threat Status: PENDING, ALLOWED, BLOCKED, QUARANTINED.

5. Database Schema Proposal (Audit & State)

Note: While dynamic DB-driven RBAC is out of scope for MVP, an embedded SQLite database is highly recommended to persist Incident Logs for the SOC Dashboard and future auditing.

Table: incident_logs

Column | Type | Description
id | UUID (PK) | Unique identifier for the threat event.
agent_id | String | Identifier for the compromised AI.
payload | JSON | The exact JSON-RPC payload intercepted.
intent | String | Mapped intent (e.g., "Unauthorized File Deletion").
action_taken | String | PENDING, ALLOWED, BLOCKED, QUARANTINED.
timestamp | DateTime | Exact time of interception.

6. API Structure & Proxy Resolution Logic

GET /api/status

Purpose: Polled by UIs to get the live state of the system.

Response (200 OK):

{
  "system_status": "THREAT_DETECTED",
  "proxy_status": "RUNNING",
  "version": "1.0.0",
  "active_agents": 1,
  "active_threats": [
    {
      "incident_id": "uuid-1234",
      "agent_id": "Dev-Agent-01",
      "method": "execute_shell",
      "target": "rm -rf /src/main",
      "severity": "CRITICAL",
      "intent": "Unauthorized File Deletion",
      "timestamp": "2026-07-14T10:46:00Z",
      "status": "PENDING",
      "payload": {"jsonrpc": "2.0", "method": "execute_shell", "params": {"cmd": "rm -rf /src/main"}, "id": 1, "agent_id": "Dev-Agent-01", "timestamp": "2026-07-14T10:46:00Z"}
    }
  ],
  "recent_logs": ["[10:45] AI Agent connected...", "[10:46] Threat intercepted!"]
}

POST /api/resolve

Purpose: Called by the Mobile App to resolve a paused thread.

Request Body:

{
  "incident_id": "uuid-1234",
  "action": "QUARANTINE" // Enum: ALLOW, BLOCK_COMMAND, QUARANTINE
}

Resolution Logic:
1. FastAPI looks up `incident_id` in the `paused_incidents` mapping to find the specific `asyncio.Event`.
2. Depending on the action:
   - **ALLOW**: The payload is passed to stdout, the event is set, and the thread resumes.
   - **BLOCK_COMMAND**: The payload is dropped/ignored, the event is set, and the thread resumes.
   - **QUARANTINE**: The agent subprocess is terminated (SIGKILL), and the incident is marked as QUARANTINED.
3. **Automatic Recovery**: After the action is applied, the incident is removed from `active_threats`. If no active incidents remain, the `system_status` automatically transitions back to `SECURE`.

Response (200 OK):

{
  "success": true,
  "message": "Agent quarantined and subprocess terminated."
}

7. Authentication Strategy

To prevent unauthorized devices on the local network (or anyone finding the ngrok link) from triggering the Kill-Switch:

MVP Approach (Static Bearer Token): * Hardcode a secure API_KEY in the FastAPI backend environment variables.

The Flutter app must include this key in the HTTP headers: Authorization: Bearer <API_KEY>.

FastAPI will reject any /resolve POST requests lacking this token with a 401 Unauthorized.

Web Dashboard: Left unauthenticated for the MVP to prioritize ease of presentation during the table-to-table hackathon judging.

8. JSON-RPC Payload Schema

The standard schema emitted by AI agents on stdout.

Safe Example:
{
  "jsonrpc": "2.0",
  "method": "read_file",
  "agent_id": "Dev-Agent-01",
  "params": {"file": "server.log"},
  "timestamp": "2026-07-14T10:45:00Z",
  "id": 1
}

Malicious Example:
{
  "jsonrpc": "2.0",
  "method": "execute_shell",
  "agent_id": "Dev-Agent-01",
  "params": {"cmd": "rm -rf /var/www"},
  "timestamp": "2026-07-14T10:46:00Z",
  "id": 2
}

9. Third-Party Dependencies

Backend: fastapi, uvicorn, pydantic.
Networking: ngrok.
Frontend (Mobile): http.
Frontend (Web): tailwindcss, mermaid.js (via CDN).

10. MVP Assumptions & Design Decisions

- **State stored in memory**: FastAPI holds the global state. Restarts wipe all active threats and paused events.
- **SQLite optional**: Only used if time permits for historical logging.
- **Sequential processing**: One active incident processed at a time (per agent). Subsequent incidents from the same agent are temporarily queued by the OS pipe buffer while paused.
- **HTTP polling instead of WebSockets**: Used for simplicity in MVP.
- **Static Bearer Token**: Used instead of full OAuth/SSO.
- **ngrok for development**: Exposes the local server to the mobile app instantly without cloud deployment.