"""
Common utilities for AI agents.
Provides functions to simulate LLM thinking and emit structured JSON-RPC payloads.
"""
import sys
import time
import json
from datetime import datetime, timezone
from typing import Any
import uuid


def simulate_llm_thinking(messages: list[str], delay: float = 0.5) -> None:
    """
    Simulates an LLM thinking by printing messages gradually.
    Flushes stdout after each print to ensure real-time delivery to the proxy.
    """
    for msg in messages:
        print("[AI Thinking]")
        print(msg)
        sys.stdout.flush()
        time.sleep(delay)


def emit_json_rpc(agent_id: str, method: str, params: dict[str, Any]) -> None:
    """
    Generates and emits the final JSON-RPC payload.
    Follows the schema defined in the TRD / Data Models.
    """
    print("[AI Action]\nGenerating JSON-RPC...")
    sys.stdout.flush()
    time.sleep(0.5)

    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "agent_id": agent_id,
        "params": params,
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "id": str(uuid.uuid4()),
    }

    print(json.dumps(payload, indent=2))
    sys.stdout.flush()
