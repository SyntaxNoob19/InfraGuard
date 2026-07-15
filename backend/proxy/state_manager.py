"""
State Management module.
Manages the singleton AppState, incident history, and system status tracking.
"""
import copy
import uuid
from typing import Dict, Any, Callable
from datetime import datetime, timezone

from models import AppState, SystemStatus, Incident, ThreatStatus, Severity, LogEntry, LogType

MAX_LOG_ENTRIES = 100

class StateManager:
    """
    Owns the single AppState instance.
    Never exposes mutable internal state directly.
    """
    def __init__(self) -> None:
        self._state = AppState()
        self._clients: Dict[str, float] = {}
        self.on_state_change: Callable[[], None] | None = None
        
    def _notify(self) -> None:
        if self.on_state_change:
            self.on_state_change()
        
    def get_state(self) -> AppState:
        """Returns a deep copy of the application state."""
        # Prune old clients (e.g. older than 5 seconds)
        current_time = datetime.now(timezone.utc).timestamp()
        self._clients = {ip: ts for ip, ts in self._clients.items() if current_time - ts < 5}
        self._state.connected_clients = len(self._clients)
        return copy.deepcopy(self._state)
        
    def update_client_ping(self, client_id: str) -> None:
        self._clients[client_id] = datetime.now(timezone.utc).timestamp()
        self._notify()
        
    def increment_payload_count(self) -> None:
        self._state.total_payloads += 1
        self._notify()

        
    def add_log(self, log_type: LogType, message: str) -> None:
        """Appends a new log entry to the state, preventing unbounded growth."""
        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        log_entry = LogEntry(type=log_type, message=message, timestamp=timestamp)
        self._state.recent_logs.append(log_entry)
        
        if len(self._state.recent_logs) > MAX_LOG_ENTRIES:
            self._state.recent_logs.pop(0)
        self._notify()
            
    def set_system_status(self, new_status: SystemStatus) -> None:
        old_status = self._state.system_status
        if old_status != new_status:
            self._state.system_status = new_status
            # Add log handles the notification, so we don't need to call _notify here
            self.add_log(LogType.INFO, f"System status changed from {old_status.name} to {new_status.name}")
        
    def create_incident(self, agent_id: str, method: str, severity: Severity, matched_rule: str, reason: str, payload: Dict[str, Any]) -> Incident:
        """Creates a new incident, updates system status, and logs the event."""
        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        incident = Incident(
            incident_id=str(uuid.uuid4()),
            agent_id=agent_id,
            method=method,
            severity=severity,
            matched_rule=matched_rule,
            reason=reason,
            status=ThreatStatus.THREAT_DETECTED,
            timestamp=timestamp,
            payload=payload
        )
        self._state.active_threats.append(incident)
        self.set_system_status(SystemStatus.THREAT_DETECTED)
        
        self.add_log(LogType.WARNING, f"Incident Created: {incident.incident_id} for agent {agent_id}")
        self._notify()
        return incident
        
    def clear_incident(self, incident_id: str, action: str) -> bool:
        """Removes an incident from active threats, logs the resolution, and moves it to history."""
        target_incident = None
        for inc in self._state.active_threats:
            if inc.incident_id == incident_id:
                target_incident = inc
                break
                
        if not target_incident:
            return False
            
        target_incident.resolved_action = action
        target_incident.resolution_timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        self._state.resolved_threats.append(target_incident)
        
        self._state.active_threats = [
            inc for inc in self._state.active_threats if inc.incident_id != incident_id
        ]
        
        self.add_log(LogType.INFO, f"Incident Closed: {incident_id}")
        
        if len(self._state.active_threats) == 0:
            self.set_system_status(SystemStatus.SECURE)
            self.add_log(LogType.SUCCESS, "System Returned To Secure")
        
        self._notify()
        return True
        
    def update_active_agents(self, delta: int) -> None:
        """Adjusts the count of active agents."""
        self._state.active_agents += delta
        self._state.active_agents = max(0, self._state.active_agents)
        self._notify()
