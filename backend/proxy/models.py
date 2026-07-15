"""
Data models for the InfraGuard proxy.
Defines incidents, logs, system state, and severity levels.
"""
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, List, Dict

class Severity(Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"

class ThreatStatus(Enum):
    SAFE = "SAFE"
    THREAT_DETECTED = "THREAT_DETECTED"
    WAITING_FOR_ADMIN = "WAITING_FOR_ADMIN"

class SystemStatus(Enum):
    SECURE = "SECURE"
    THREAT_DETECTED = "THREAT_DETECTED"

class LogType(Enum):
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    SUCCESS = "SUCCESS"
    ADMIN = "ADMIN"

@dataclass
class LogEntry:
    type: LogType
    message: str
    timestamp: str

@dataclass
class Incident:
    incident_id: str
    agent_id: str
    method: str
    severity: Severity
    matched_rule: str
    reason: str
    status: ThreatStatus
    timestamp: str
    payload: Dict[str, Any]
    resolved_action: str | None = None
    resolution_timestamp: str | None = None

@dataclass
class AppState:
    system_status: SystemStatus = SystemStatus.SECURE
    active_agents: int = 0
    active_threats: List[Incident] = field(default_factory=list)
    resolved_threats: List[Incident] = field(default_factory=list)
    recent_logs: List[LogEntry] = field(default_factory=list)
    total_payloads: int = 0
    connected_clients: int = 0
