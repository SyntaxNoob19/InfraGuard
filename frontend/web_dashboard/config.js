// Centralized Configuration for InfraGuard Web Dashboard

const API_BASE_URL = "https://flying-resemble-canopener.ngrok-free.dev";
const API_KEY = "YOUR_API_KEY_HERE";

// Dynamically derive the WebSocket URL
const WS_URL = API_BASE_URL
    .replace("https://", "wss://")
    .replace("http://", "ws://")
    + "/api/ws";
