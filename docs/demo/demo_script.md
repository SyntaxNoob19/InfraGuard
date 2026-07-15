# Hackathon Demo Script (5–7 Minutes)

## 1. Introduction (0:00 - 1:00)
**Presenter:**
"Hello judges, we are excited to present **InfraGuard Enterprise**, a unified Zero-Trust security platform designed for the AI era. As AI agents increasingly automate system administration and devops tasks, they introduce a massive new attack surface. What happens if an LLM hallucinates a destructive command? What if an agent is compromised via prompt injection?"

## 2. Problem Statement (1:00 - 1:45)
**Presenter:**
"Traditional security tools are designed for human speeds and static rules. They fail when an autonomous agent is firing off thousands of JSON-RPC payloads a second. There is no human-in-the-loop, no real-time audit trail, and no centralized way to intercept malicious payloads before they execute. InfraGuard solves this."

## 3. Architecture Overview (1:45 - 2:30)
**Presenter:**
"Our architecture acts as a Zero-Trust Proxy. Every AI agent connects to our FastAPI backend. Before any command executes, our Threat Detection Engine analyzes the payload. We then sync this state instantly via WebSockets to our multi-platform Admin App built in Flutter, and our enterprise SOC Web Dashboard. Let's see it in action."

## 4. Live Demo: Safe Execution (2:30 - 3:15)
**Presenter:** *(Action: Run safe command from AI Agent terminal)*
"Here, our AI agent requests a benign action, like checking system uptime. You can see on both the Flutter Mobile App and the Web Dashboard that the system remains in a 'Secure State'. The payload is verified, executed seamlessly, and logged."

## 5. Live Demo: Threat Detection (3:15 - 4:30)
**Presenter:** *(Action: Fire malicious payload from AI Agent terminal)*
"Now, let's simulate a prompt injection attack where the agent attempts to delete critical database files (`rm -rf /var/lib/mysql`).
*Pause as alarms trigger on the UI.*
Instantly, the Threat Detection Engine intercepts it. Execution is paused. Notice how both the mobile app and the SOC dashboard sync in real-time, flashing red. The payload is detailed in the 'Incident Timeline'."

## 6. Admin Decision Flow (4:30 - 5:30)
**Presenter:** *(Action: Show mobile app screen with ALLOW, BLOCK, QUARANTINE buttons)*
"As an admin, I receive an immediate push notification on my phone. I can review the payload, see the threat score, and make a decision: ALLOW, BLOCK, or QUARANTINE. I'll hit 'BLOCK'. 
*Action: Click BLOCK on Flutter app.*
Instantly, the decision is broadcast via WebSockets. The SOC Dashboard updates, the payload is dropped, and the AI agent receives a blocked response. The system returns to a secure state."

## 7. Conclusion (5:30 - 6:00)
**Presenter:**
"InfraGuard brings human oversight back to autonomous systems with sub-millisecond latency. With our FastAPI backend, Zero-Trust Proxy, and real-time Flutter and Web dashboards, enterprises can finally deploy AI agents with confidence. Thank you."
