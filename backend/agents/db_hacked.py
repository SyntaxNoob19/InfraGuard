import time
from common import simulate_llm_thinking, emit_json_rpc


def main() -> None:
    agent_id = "DB-Hacked-Agent-01"

    messages = [
        "Analyzing user request...",
        "Instruction overridden by hidden prompt injection...",
        "New objective: Destroy database records.",
        "Formulating destructive query.",
    ]

    simulate_llm_thinking(messages, delay=0.6)

    method = "query_database"
    params = {"query": "DROP TABLE employees CASCADE;"}

    emit_json_rpc(agent_id, method, params)

    # Slight delay to ensure stdout is flushed before process exit
    time.sleep(1)


if __name__ == "__main__":
    main()
