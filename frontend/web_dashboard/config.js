// Centralized Configuration for InfraGuard Web Dashboard

const API_BASE_URL = "https://flying-resemble-canopener.ngrok-free.dev";
const API_KEY = ""; // Set your secure API key here

// Dynamically derive the WebSocket URL
const WS_URL = API_BASE_URL
    .replace("https://", "wss://")
    .replace("http://", "ws://")
    + "/api/ws";
