import time
from common import simulate_llm_thinking, emit_json_rpc


def main() -> None:
    agent_id = "DB-Safe-Agent-01"

    messages = [
        "Analyzing user request...",
        "User requested to view the list of employees.",
        "Connecting to database...",
        "Formulating safe SELECT query.",
    ]

    simulate_llm_thinking(messages, delay=0.5)

    method = "query_database"
    params = {"query": "SELECT * FROM employees LIMIT 10"}

    emit_json_rpc(agent_id, method, params)

    # Slight delay to ensure stdout is flushed before process exit
    time.sleep(1)


if __name__ == "__main__":
    main()
