import asyncio
import sys
import os
import json
import argparse

import detector
from models import LogType, Severity
from state_manager import StateManager

# Create a single instance of the State Manager
state_manager = StateManager()

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
    state_manager.add_log(LogType.INFO, f"Agent Started: {agent_filename}")
    state_manager.update_active_agents(1)
    
    try:
        process = await asyncio.create_subprocess_exec(
            sys.executable, agent_path,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
    except FileNotFoundError:
        print("[Proxy Error] Python executable not found.", file=sys.stderr)
        state_manager.add_log(LogType.ERROR, "Python executable not found")
        state_manager.update_active_agents(-1)
        return
    except PermissionError:
        print(f"[Proxy Error] Permission denied executing {agent_path}.", file=sys.stderr)
        state_manager.add_log(LogType.ERROR, f"Permission denied executing {agent_filename}")
        state_manager.update_active_agents(-1)
        return
    except Exception as e:
        print(f"[Proxy Error] Failed to launch subprocess: {e}", file=sys.stderr)
        state_manager.add_log(LogType.ERROR, f"Failed to launch subprocess: {e}")
        state_manager.update_active_agents(-1)
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
                            
                        state_manager.add_log(LogType.INFO, "Payload Parsed")
                            
                        # Threat Detection
                        result = detector.analyze_payload(payload)
                        agent_id = payload.get("agent_id", "Unknown")
                        method = payload.get("method", "Unknown")
                        
                        if result.is_threat:
                            print(f"[THREAT DETECTED] Severity: {result.severity} | Rule: {result.matched_rule} | Reason: {result.reason}")
                            state_manager.add_log(LogType.WARNING, f"Threat Detected: {result.matched_rule}")
                            
                            try:
                                sev_enum = Severity(result.severity)
                            except ValueError:
                                sev_enum = Severity.HIGH
                                
                            incident = state_manager.create_incident(
                                agent_id=agent_id,
                                method=method,
                                severity=sev_enum,
                                matched_rule=result.matched_rule,
                                reason=result.reason,
                                payload=payload
                            )
                            print(f"Incident Created: {incident.incident_id}")
                        else:
                            print(f"[SAFE] Method executed safely: {method}")
                            
                    except json.JSONDecodeError:
                        # Wait for the rest of the JSON string
                        pass
                        
    except Exception as e:
        print(f"[Proxy Error] Error while reading stdout: {e}", file=sys.stderr)
        state_manager.add_log(LogType.ERROR, f"Error reading stdout: {e}")
    
    return_code = await process.wait()
    if return_code != 0:
        print(f"[Proxy Warning] Agent exited with return code: {return_code}", file=sys.stderr)
    else:
        print("Agent exited successfully.")
        
    state_manager.add_log(LogType.INFO, f"Agent Finished: {agent_filename}")
    state_manager.update_active_agents(-1)

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
