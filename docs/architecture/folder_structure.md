# Folder Structure

The final production structure of the InfraGuard enterprise platform is organized hierarchically to separate concerns between the backend server, frontend clients, and documentation.

```text
InfraGuard/
├── backend/                  # Core API and Logic
│   ├── agents/               # AI Agent scripts (e.g. db_safe.py, devops_hacked.py)
│   ├── api/                  # FastAPI routes and WebSocket logic
│   ├── proxy/                # Zero-Trust Proxy & Threat Detection
│   ├── requirements.txt      # Python dependencies
│   └── simulate_agent.py     # Interactive CLI to run agents via the proxy engine
├── frontend/
│   ├── flutter_app/          # Mobile & Desktop Admin App
│   │   ├── android/
│   │   ├── ios/
│   │   ├── lib/              # Flutter Dart source code
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   ├── services/
│   │   │   ├── widgets/
│   │   │   └── main.dart
│   │   └── pubspec.yaml
│   └── web_dashboard/        # Enterprise SOC Dashboard (HTML/JS/CSS)
│       ├── assets/
│       ├── index.html
│       ├── style.css
│       └── app.js
├── docs/                     # Documentation Assets
│   ├── architecture/         # System Architecture documentation
│   │   ├── ARCHITECTURE.md
│   │   ├── folder_structure.md
│   │   ├── 03_component_pipeline.md
│   │   ├── 05_sequence_diagram.md
│   │   ├── 06_decision_flow.md
│   │   └── 07_deployment_architecture.md
│   ├── testing/
│   │   └── final_test_report.md
│   └── screenshots/
└── demo_data/                # Mock data for testing and demonstrations
```
