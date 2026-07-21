"""
Zero-Trust Proxy Engine.
Intercepts stdout from AI agent subprocesses, parses JSON-RPC, validates against security rules,
and delegates to the ExecutionController to pause threads when threats are detected.
Runs alongside the FastAPI HTTP layer.
"""
import asyncio
import sys
import os
import json
import argparse
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger('ProxyEngine')
import uvicorn

import detector
from models import LogType
from state_manager import StateManager
from execution_controller import ExecutionController

base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(base_dir))
from backend.api.main import create_app

async def run_proxy(agent_filename: str, state_manager: StateManager, execution_controller: ExecutionController) -> None:
    """
    Launches an AI agent subprocess, relays non-JSON stdout transparently,
    and parses/validates JSON-RPC payloads through the threat detector.
    """
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    agent_path = os.path.join(base_dir, "agents", agent_filename)
    
    if not os.path.isfile(agent_path):
        logger.error(f"[Proxy Error] Agent file not found: {agent_path}")
        return

    logger.info("====================================")
    logger.info("InfraGuard Runtime Started")
    logger.info("Monitoring Agent:")
    logger.info(agent_filename)
    logger.info("====================================")
    state_manager.add_log(LogType.INFO, f"Agent Started: {agent_filename}")
    state_manager.update_active_agents(1)
    
    try:
        process = await asyncio.create_subprocess_exec(
            sys.executable, agent_path,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
    except FileNotFoundError:
        logger.error("[Proxy Error] Python executable not found.")
        state_manager.add_log(LogType.ERROR, "Python executable not found")
        state_manager.update_active_agents(-1)
        return
    except PermissionError:
        logger.error(f"[Proxy Error] Permission denied executing {agent_path}.")
        state_manager.add_log(LogType.ERROR, f"Permission denied executing {agent_filename}")
        state_manager.update_active_agents(-1)
        return
    except Exception as e:
        logger.error(f"[Proxy Error] Failed to launch subprocess: {e}")
        state_manager.add_log(LogType.ERROR, f"Failed to launch subprocess: {e}")
        state_manager.update_active_agents(-1)
        return

    had_incident = False
    was_quarantined = False
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
                        
                        logger.info("\nPayload Received\n↓")
                        
                        # Schema Validation
                        required_fields = {"jsonrpc", "id", "agent_id", "method", "params", "timestamp"}
                        if not isinstance(payload, dict) or not required_fields.issubset(payload.keys()):
                            logger.info("Invalid JSON-RPC payload")
                            continue
                            
                        logger.info("JSON Schema Validated\n↓")
                        state_manager.increment_payload_count()
                        state_manager.add_log(LogType.INFO, "Payload Parsed")
                            
                        # Threat Detection
                        logger.info("Threat Analysis Started\n↓")
                        result = detector.analyze_payload(payload)
                        agent_id = payload.get("agent_id", "Unknown")
                        method = payload.get("method", "Unknown")
                        
                        if result.is_threat:
                            had_incident = True
                            logger.info("Threat Detected")
                            logger.info(f"[THREAT DETECTED] Severity: {result.severity.name} | Rule: {result.matched_rule} | Reason: {result.reason}")
                            state_manager.add_log(LogType.WARNING, f"Threat Detected: {result.matched_rule}")
                            
                            incident = state_manager.create_incident(
                                agent_id=agent_id,
                                method=method,
                                severity=result.severity,
                                matched_rule=result.matched_rule,
                                reason=result.reason,
                                payload=payload
                            )
                            
                            # Freeze Execution
                            context = execution_controller.create_execution_context(incident.incident_id, process)
                            logger.info("====================================")
                            logger.info("Incident Created")
                            logger.info(f"ID       : {incident.incident_id}")
                            logger.info(f"Severity : {incident.severity.name}")
                            logger.info(f"Agent    : {incident.agent_id}")
                            logger.info(f"Rule     : {incident.matched_rule}")
                            logger.info("====================================")
                            logger.info("Waiting For Admin...")
                            state_manager.add_log(LogType.INFO, "Waiting For Admin")
                            
                            await execution_controller.pause(incident.incident_id)
                            
                            action = context.resolution_action
                            if action == "ALLOW":
                                logger.info(f"Admin Action: ALLOW\nExecution resumed.\nAgent completed successfully.")
                            elif action == "BLOCK" or action == "BLOCK_COMMAND":
                                logger.info(f"Admin Action: BLOCK_COMMAND\nMalicious payload discarded.\nExecution resumed.\nAgent completed successfully.")
                            elif action == "QUARANTINE":
                                was_quarantined = True
                                logger.info(f"Admin Action: QUARANTINE\nSubprocess terminated.\nAgent forcefully quarantined.")
                            else:
                                logger.info(f"Execution Resumed with action: {action}")
                            
                            execution_controller.remove(incident.incident_id)
                            
                            logger.info("====================================")
                            logger.info("Incident Closed")
                            logger.info(f"System Status : {state_manager.get_state().system_status.name}")
                            logger.info("====================================")
                        else:
                            logger.info(f"[SAFE] Method executed safely: {method}")
                            
                    except json.JSONDecodeError:
                        # Wait for the rest of the JSON string
                        pass
                        
    except Exception as e:
        logger.error(f"[Proxy Error] Error while reading stdout: {e}")
        state_manager.add_log(LogType.ERROR, f"Error reading stdout: {e}")
    
    return_code = await process.wait()
    if not had_incident:
        if return_code != 0:
            logger.error(f"[Proxy Warning] Agent exited with return code: {return_code}")
        else:
            logger.info("Agent exited successfully.")
        
    state_manager.add_log(LogType.INFO, f"Agent Finished: {agent_filename}")
    state_manager.update_active_agents(-1)

async def run_everything(agent_filename: str, state_manager: StateManager, execution_controller: ExecutionController) -> None:
    app = create_app(state_manager, execution_controller)
    
    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="error")
    server = uvicorn.Server(config)
    
    # Run the server in a background task
    server_task = asyncio.create_task(server.serve())
    
    # Wait briefly to ensure server starts
    await asyncio.sleep(0.5)
    
    # Run the proxy logic
    await run_proxy(agent_filename, state_manager, execution_controller)
    
    # Tell server to shutdown after proxy finishes
    server.should_exit = True
    await server_task

def main() -> None:
    if sys.platform == 'win32':
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
        
    parser = argparse.ArgumentParser(description="InfraGuard Proxy Engine")
    parser.add_argument("agent", nargs="?", default="db_safe.py", help="Agent script to run (default: db_safe.py)")
    args = parser.parse_args()
    
    # Dependency Injection
    state_manager = StateManager()
    execution_controller = ExecutionController()
    
    try:
        asyncio.run(run_everything(args.agent, state_manager, execution_controller))
    except KeyboardInterrupt:
        logger.error("\n[Proxy] Shutting down due to KeyboardInterrupt.")

if __name__ == "__main__":
    main()
