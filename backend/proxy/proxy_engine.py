import asyncio
import sys
import os
import json
import argparse

import detector

async def run_proxy(agent_filename: str) -> None:
    """
    Launches an AI agent subprocess, relays non-JSON stdout transparently,
    and parses/validates JSON-RPC payloads through the threat detector.
    """
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    agent_path = os.path.join(base_dir, "agents", agent_filename)
    
    if not os.path.isfile(agent_path):
        print(f"[Proxy Error] Agent file not found: {agent_path}", file=sys.stderr)
        return

    print("Launching Agent...", flush=True)
    
    try:
        process = await asyncio.create_subprocess_exec(
            sys.executable, agent_path,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
    except FileNotFoundError:
        print("[Proxy Error] Python executable not found.", file=sys.stderr)
        return
    except PermissionError:
        print(f"[Proxy Error] Permission denied executing {agent_path}.", file=sys.stderr)
        return
    except Exception as e:
        print(f"[Proxy Error] Failed to launch subprocess: {e}", file=sys.stderr)
        return

    try:
        if process.stdout is not None:
            json_buffer = ""
            is_collecting_json = False
            
            async for line in process.stdout:
                line_str = line.decode('utf-8')
                stripped = line_str.strip()
                
                if not is_collecting_json:
                    if stripped == "{":
                        is_collecting_json = True
                        json_buffer = line_str
                    else:
                        sys.stdout.buffer.write(line)
                        sys.stdout.flush()
                else:
                    json_buffer += line_str
                    try:
                        payload = json.loads(json_buffer)
                        is_collecting_json = False
                        
                        # Schema Validation
                        required_fields = {"jsonrpc", "id", "agent_id", "method", "params", "timestamp"}
                        if not isinstance(payload, dict) or not required_fields.issubset(payload.keys()):
                            print("Invalid JSON-RPC payload")
                            continue
                            
                        # Threat Detection
                        result = detector.analyze_payload(payload)
                        
                        if result.is_threat:
                            print(f"[THREAT DETECTED] Severity: {result.severity} | Rule: {result.matched_rule} | Reason: {result.reason}")
                        else:
                            method = payload.get("method", "Unknown")
                            print(f"[SAFE] Method executed safely: {method}")
                            
                    except json.JSONDecodeError:
                        # Wait for the rest of the JSON string
                        pass
                        
    except Exception as e:
        print(f"[Proxy Error] Error while reading stdout: {e}", file=sys.stderr)
    
    return_code = await process.wait()
    if return_code != 0:
        print(f"[Proxy Warning] Agent exited with return code: {return_code}", file=sys.stderr)
    else:
        print("Agent exited successfully.")

def main() -> None:
    parser = argparse.ArgumentParser(description="InfraGuard Proxy Engine")
    parser.add_argument("agent", nargs="?", default="db_safe.py", help="Agent script to run (default: db_safe.py)")
    args = parser.parse_args()
    
    try:
        asyncio.run(run_proxy(args.agent))
    except KeyboardInterrupt:
        print("\n[Proxy] Shutting down due to KeyboardInterrupt.", file=sys.stderr)

if __name__ == "__main__":
    main()
