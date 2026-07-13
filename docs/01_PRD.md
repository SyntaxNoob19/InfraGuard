📄 Product Requirements Document (PRD)

Product Name: InfraGuard
Version: 1.0 (Hackathon MVP)
Date: July 14, 2026


1. Problem Statement

As enterprises increasingly deploy autonomous AI agents via the Model Context Protocol (MCP) to manage infrastructure, they introduce a critical vulnerability: Agent Goal Hijack (OWASP LLM07) / Indirect Prompt Injection.

Traditional network firewalls and API gateways fail to secure this vector because MCP tools often communicate via local standard I/O (stdio) pipes. If an AI agent reads a poisoned log file or dataset, it can be manipulated into executing destructive commands (e.g., dropping databases, opening firewall ports) using its legitimate, trusted permissions. Currently, there is no system that intercepts these local execution pipes in real-time to demand human authorization.

2. Target User

Primary User (Incident Responder): IT Administrators / Security Engineers who need to instantly approve, block, or investigate anomalous AI behavior on-the-go via mobile.

Secondary User (Monitoring): SOC (Security Operations Center) Analysts who monitor live AI-to-infrastructure traffic on a web dashboard.

Buyer: Enterprise CISOs / CTOs looking to safely deploy AI agents without risking infrastructure integrity.

3. Core User Flows

Flow A: The Threat Interception (Backend)

Hijacked AI Agent generates a destructive JSON-RPC payload (e.g., "method": "execute_shell", "cmd": "rm -rf").

InfraGuard Proxy (sitting on the stdio pipe) intercepts the payload.

The Proxy halts the OS subprocess thread instantly.

The Proxy updates the backend state to THREAT_DETECTED and triggers an alert via ngrok tunneling.

Flow B: Out-of-Band (OOB) Resolution (Mobile App)

IT Admin receives a real-time push notification/alert on their Flutter mobile app.

Admin opens the app to see the incident details (Agent ID, Intent, Payload).

Admin selects an action: [ALLOW], [BLOCK COMMAND], or [QUARANTINE AGENT].

The mobile app sends a POST request back to the Proxy.

The Proxy resolves the halted thread (executes, drops, or terminates the agent entirely).

Flow C: Passive Monitoring (Web Dashboard)

SOC Analyst opens the Web Dashboard.

The dashboard polls the backend and displays a live terminal stream of all AI actions.

Safe commands appear in green; intercepted threats flash red, syncing with the mobile app's resolution status.

4. Feature List (MVP vs. Future)

In Scope for MVP (V1)

Zero-Trust Proxy Engine (Python): asyncio based stdio pipe interception and strict JSON validation.

Keyword/Schema Engine: Hardcoded rule-engine to detect destructive payloads (e.g., DROP TABLE, execute_shell).

FastAPI Bridge: REST endpoints (/status, /resolve) to manage the pause/resume state of the OS thread.

Mobile Kill-Switch (Flutter): Single-screen UI fetching live threat data with 3 core action buttons (Allow, Block, Quarantine).

SOC Web Dashboard (HTML/JS): Dark-mode live log streaming UI to monitor agent connections and intercepted payloads.

Out of Scope for MVP (Future Roadmap)

Dynamic, cloud-synced Rule/Policy Engine (Database driven RBAC).

Persistent WebSocket connections (replacing ngrok HTTP polling).

Enterprise SSO / SAML login for the Mobile App.

Multi-admin routing (escalating unread alerts to secondary admins).

5. Edge Cases & Handling

Malformed JSON from AI: LLMs sometimes hallucinate broken JSON strings.

Handling: Strict try-except parsing. Any malformed string is automatically dropped with an "Invalid Payload" warning to prevent proxy crashes.

Network Failure / Admin Unreachable: The admin loses internet and cannot approve/deny the alert.

Handling: Fail-safe timeout. If the halted thread does not receive a resolution within 60 seconds, it defaults to DENY and drops the payload.

Brute-Force Attack by Hijacked AI: A compromised agent spams 100 malicious requests per second.

Handling: Auto-Quarantine threshold. If >5 threats are detected from a single agent within 10 seconds, the proxy automatically kills the agent's subprocess.

6. Non-Goals

We are not building an AI Agent or an LLM. We are building the security wrapper around them.

We are not building a network packet sniffer (like Wireshark). We operate strictly at the Inter-Process Communication (IPC) JSON-RPC layer.

We are not building a compliance or billing SaaS platform for this V1.

7. Success Metrics

Interception Latency: Time taken to detect and halt a threat should be < 50ms.

Detection Accuracy: 100% successful interception of hardcoded blacklisted methods in the demo scenario (0% false negatives).

Resolution Speed: System successfully resumes/drops the thread within < 2 seconds of the mobile app button tap.