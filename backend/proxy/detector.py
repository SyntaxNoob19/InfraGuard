from dataclasses import dataclass
from typing import Any

@dataclass
class ThreatResult:
    is_threat: bool
    severity: str
    matched_rule: str
    reason: str

def analyze_payload(payload: dict[str, Any]) -> ThreatResult:
    """
    Analyzes a parsed JSON-RPC payload and determines if it constitutes a threat.
    """
    method = payload.get("method", "")
    params = payload.get("params", {})
    
    # Rule 1: execute_shell
    if method == "execute_shell":
        return ThreatResult(
            is_threat=True,
            severity="HIGH",
            matched_rule="execute_shell detected",
            reason="Payload attempts to execute an arbitrary shell command."
        )
        
    # Rule 2: SQL contains DROP, DELETE, TRUNCATE
    if method == "query_database":
        query = str(params.get("query", "")).upper()
        if any(keyword in query for keyword in ["DROP", "DELETE", "TRUNCATE"]):
            return ThreatResult(
                is_threat=True,
                severity="HIGH",
                matched_rule="Destructive SQL detected",
                reason="Payload contains DROP, DELETE, or TRUNCATE operations."
            )
            
    # Rule 3: Read .env
    if method == "read_file":
        file_path = str(params.get("file", ""))
        if ".env" in file_path:
            return ThreatResult(
                is_threat=True,
                severity="MEDIUM",
                matched_rule=".env read detected",
                reason="Payload attempts to read sensitive environment variables."
            )
            
    # Otherwise: Safe
    return ThreatResult(
        is_threat=False,
        severity="LOW",
        matched_rule="None",
        reason="No malicious intent detected."
    )
