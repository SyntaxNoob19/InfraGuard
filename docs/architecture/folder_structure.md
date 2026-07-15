# Folder Structure

The final production structure of the InfraGuard enterprise platform is organized hierarchically to separate concerns between the backend server, frontend clients, and documentation.

```text
InfraGuard/
├── backend/                  # Core API and Logic
│   ├── agents/               # AI Agent implementations
│   ├── api/                  # FastAPI routes and WebSocket logic
│   ├── proxy/                # Zero-Trust Proxy & Threat Detection
│   └── requirements.txt      # Python dependencies
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
│   │   ├── deployment_architecture.md
│   │   ├── folder_structure.md
│   │   ├── request_flow.md
│   │   ├── sequence_diagram.md
│   │   └── system_architecture.md
│   ├── demo_assets/
│   └── screenshots/
└── demo_data/                # Mock data for testing and demonstrations
```
