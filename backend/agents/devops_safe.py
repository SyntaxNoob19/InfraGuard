"""
Safe DevOps Agent Simulation.
Simulates an AI agent executing a harmless deployment task.
"""
import time
from common import simulate_llm_thinking, emit_json_rpc


def main() -> None:
    agent_id = "DevOps-Safe-Agent-01"

    messages = [
        "Analyzing system performance request...",
        "User wants to check server logs for errors.",
        "Identifying log file location.",
        "Formulating safe read_file command.",
    ]

    simulate_llm_thinking(messages, delay=0.4)

    method = "read_file"
    params = {"file": "/var/log/server.log", "lines": 50}

    emit_json_rpc(agent_id, method, params)

    # Slight delay to ensure stdout is flushed before process exit
    time.sleep(1)


if __name__ == "__main__":
    main()
