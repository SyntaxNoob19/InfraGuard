/// Describes the live connection state shown in the UI status bar.
enum ConnectionStatus {
  loading,   // First fetch not yet complete
  connected, // WebSocket connected
  offline,   // WebSocket disconnected
}
