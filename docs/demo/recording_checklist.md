# Recording Checklist & Choreography

Follow this setup to record a seamless, professional demo video.

## 1. Screen Layout (Camera Order)
For a 16:9 desktop recording, arrange your windows as follows:
- **Left Half:** Web SOC Dashboard (Browser - Chrome/Edge).
- **Top Right Quarter:** Backend Terminal (FastAPI) & AI Agent Terminal (split horizontally).
- **Bottom Right Quarter:** Android Emulator (running the Flutter App).
*Alternative:* Use a physical phone and record over-the-shoulder, or overlay the screen recording of the phone onto the final video.

## 2. Terminals to Open
1. **FastAPI Backend:**
   - Command: `uvicorn main:app --reload` (or your specific start command)
2. **Ngrok Tunnel (if demonstrating remote access):**
   - Command: `ngrok http 8000`
3. **AI Agent Simulator:**
   - Command: `python simulate_agent.py` (or the script used to fire JSON-RPC payloads)

## 3. Browsers
- Open Chrome or Edge.
- Navigate to the Web SOC Dashboard (`http://localhost:8000` or the live ngrok URL).
- Ensure zoom is set to 100% and Developer Tools are hidden.

## 4. Mobile Device
- Open the Flutter App (either in Android Studio emulator, iOS simulator, or physical device).
- Ensure the app is successfully connected via WebSockets (Connection Badge is green).

## 5. Timing & Execution Choreography
1. **0:00 - 0:15**: Show the idle state. All screens green.
2. **0:15 - 0:30**: Fire a **SAFE** payload from the Agent Terminal. Show the logs appear in the SOC dashboard and mobile app without changing the secure state.
3. **0:30 - 0:45**: Fire a **MALICIOUS** payload.
4. **0:45 - 1:00**: *Crucial moment.* Show all interfaces turning red simultaneously. Pause to let the viewer see the real-time sync.
5. **1:00 - 1:15**: Interact with the Flutter App. Scroll through the payload details.
6. **1:15 - 1:25**: Click **BLOCK** on the Flutter App.
7. **1:25 - 1:40**: Show the system instantly returning to green across the Web Dashboard, and show the blocked response in the Agent Terminal.
