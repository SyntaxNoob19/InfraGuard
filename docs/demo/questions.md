#  Questions & Answers


**1. What is the core problem InfraGuard solves?**
It provides human-in-the-loop Zero-Trust security for autonomous AI agents, stopping malicious payloads before they execute.

**2. Why not just use existing firewalls?**
Firewalls inspect network traffic. InfraGuard inspects application-layer JSON-RPC payloads generated dynamically by LLMs, which firewalls can't understand.

**3. How does the Threat Detection Engine work?**
It analyzes the payload structure, commands, and arguments against a dynamic ruleset and risk-scoring algorithm to flag dangerous actions like file deletion or unauthorized data exfiltration.

**4. What tech stack did you use?**
FastAPI for the backend, Python for the proxy/engine, WebSockets for real-time sync, Flutter for the cross-platform admin app, and HTML/JS/CSS for the SOC dashboard.

**5. Why did you choose FastAPI?**
FastAPI provides asynchronous execution and native WebSocket support, which is critical for the sub-millisecond latency required to intercept and broadcast AI agent actions.

**6. How is the mobile app synchronized with the web dashboard?**
Both clients maintain a persistent WebSocket connection to the FastAPI state manager. When an admin makes a decision on the mobile app, the backend broadcasts the state change to all connected clients instantly.

**7. Can it handle multiple AI agents simultaneously?**
Yes, the Zero-Trust Proxy is asynchronous and can queue/route requests from multiple agents, assigning unique session IDs to track each payload's lifecycle.

**8. What happens if the WebSocket connection drops?**
The Flutter app and Web dashboard have auto-reconnect logic. The backend safely queues pending alerts and will re-sync the state once the client reconnects.

**9. How do you handle latency when waiting for an admin decision?**
The execution controller suspends the specific JSON-RPC thread asynchronously. The AI agent waits for a response (or hits a timeout), while the rest of the system continues processing other requests.

**10. What does "QUARANTINE" actually do?**
It isolates the payload and the originating agent session, preventing the agent from sending further commands until a full security audit is performed.

**11. Is the Flutter app native?**
Flutter compiles to native ARM/x86 code for both iOS and Android, providing near-native performance with a single codebase.

**12. Why build a mobile app instead of just a web dashboard?**
AI agents run 24/7. Admins need immediate push notifications and the ability to block threats from their pocket, no matter where they are.

**13. How secure is the WebSocket connection?**
In production, it runs over WSS (WebSocket Secure) with TLS encryption, and requires JWT authentication for both the mobile app and the web dashboard.

**14. Did you use any third-party APIs for threat detection?**
Currently, we use an in-house algorithmic ruleset for latency reasons, but the architecture allows for async calls to LLM-based security evaluators if needed.

**15. What was the hardest technical challenge?**
Managing the asynchronous state between the AI agent's HTTP request, the WebSocket broadcasts, and the admin's asynchronous response without blocking the main event loop.

**16. How does the system scale?**
The FastAPI backend can be scaled horizontally behind a load balancer, using Redis pub/sub to sync WebSocket states across multiple server instances.

**17. What happens if an admin doesn't respond?**
The system has a configurable timeout. If no decision is made within the window, the system fails secure (defaults to BLOCK).

**18. Can the AI agent bypass the proxy?**
No, in a secure deployment, the target infrastructure is network-isolated and only accepts connections from the InfraGuard proxy IP.

**19. How do you prevent replay attacks?**
Every payload is assigned a cryptographic nonce and timestamp. The execution controller rejects duplicate or expired nonces.

**20. What is the memory footprint of the proxy?**
It is highly lightweight, using Python's `asyncio`. It consumes less than 50MB of RAM per instance, making it suitable for edge deployments.

**21. Can you export logs to a SIEM like Splunk?**
Yes, the State Manager logs all incidents in structured JSON format, which can be easily forwarded via standard log agents.

**22. How do you test the system?**
We use a mock AI agent script that fires a mix of safe and malicious payloads at randomized intervals to simulate real-world load.

**23. Why didn't you use gRPC instead of JSON-RPC?**
JSON-RPC was chosen for its ubiquity and human-readability during the hackathon, but the architecture abstracts the protocol layer, allowing easy migration to gRPC.

**24. What are your next steps for this project?**
Integrating a machine-learning model into the Threat Detection Engine to catch zero-day prompt injection attacks based on behavioral anomalies.

**25. Does the Flutter app support offline mode?**
It requires an active connection to receive live alerts, but it caches the incident timeline locally using SQLite for offline review of past events.

**26. How do you handle false positives?**
Admins can easily hit 'ALLOW' for flagged payloads. The system logs these overrides to help tune the detection engine's thresholds.

**27. What if the admin phone is compromised?**
The mobile app requires biometric authentication (FaceID/Fingerprint) before allowing an admin to approve or block a critical payload.

**28. How is the Web Dashboard styled?**
We used vanilla CSS with modern variables for glassmorphism and real-time CSS animations triggered by WebSocket state changes.

**29. Can it integrate with Slack or Teams?**
Yes, the backend can trigger webhooks to post alerts in Slack channels simultaneously with the mobile push notifications.

**30. What makes this a "Zero-Trust" architecture?**
Zero-Trust means "never trust, always verify." We do not trust any payload inherently, even if it comes from an authenticated internal AI agent. Every single command is verified before execution.
