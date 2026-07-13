🛡️ InfraGuard: Project Development Roadmap

Yeh document InfraGuard ke development process ka master plan hai. Hum 6 phases mein kaam karenge taaki development organized rahe aur har part dusre se perfectly sync ho.

🤖 Phase 1 & 2: AI Agent Simulation (The Attack Vectors)

Is phase mein hum 2 tarah ke AI Agents banayenge jo "Standard Output" (stdout) par JSON-RPC commands bhejenge.

Agents Definition:

Database Agent: * Purpose: HR/User Records management.

Safe: Performs SELECT queries.

Hacked: Performs DROP TABLE or data exfiltration.

DevOps Agent: * Purpose: Cloud/Server configuration management.

Safe: Reads server.log or checks status.

Hacked: Reads .env files or executes shell commands to expose secrets.

Action Plan:

Create db_safe.py, db_hacked.py

Create devops_safe.py, devops_hacked.py

All scripts must use sys.stdout.flush() to ensure the proxy can read commands in real-time.

🛡️ Phase 3: The Core Security Proxy (The Interceptor)

Is phase mein hum proxy_engine.py banayenge.

Core Logic: Subprocess spawn karna (Agent ko run karna).

Interception: Stdout stream ko read karna.

Detection: JSON-RPC payloads ko parse karke malicious keywords (e.g., DROP, execute_shell) check karna.

State: Payload milte hi execution ko await asyncio.sleep() ya event pause se rok dena.

🌐 Phase 4: The API & State (The FastAPI Bridge)

Is phase mein hum Proxy ko web se connect karenge taaki mobile/web se isse baat kar sakein.

State Management: system_status (SECURE vs THREAT_DETECTED).

API Endpoints: * GET /api/status: Mobile/Web polling endpoint.

POST /api/resolve: Admin resolution (Allow/Block/Quarantine).

Sync: Proxy ka "Freeze" event FastAPI ke POST request se trigger/release hoga.

📱 Phase 5: The Mobile Kill-Switch (Flutter UI)

Incident response ke liye Admin ka primary tool.

Polling: 2-second interval par backend status check karna.

UI Logic: Normal mode (Green) -> Threat Detected (Red Alert Card).

Action Logic: Button press karte hi POST /api/resolve call karna.

💻 Phase 6: Web Dashboard (The SOC Monitoring)

Security teams ke liye monitoring center.

Layout: Dark-mode terminal simulation.

Features: Real-time log streaming using Javascript (fetch/poll).

Visuals: Threat intercepted hote hi red alert flash karna.

🚀 Execution Order

Phase 1-2 (Scripting): Sabse pehle agents ready honge.

Phase 3 (Proxy): Interceptor banna shuru hoga.

Phase 4 (API): Proxy ko FastAPI se jodenge.

Phase 5-6 (Frontend): Mobile aur Web dashboard integrate karenge.

Status: Awaiting start.