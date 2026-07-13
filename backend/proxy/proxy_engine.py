import asyncio
import sys
import os

async def run_proxy() -> None:
    """
    Launches an AI agent subprocess and relays its stdout transparently.
    """
    # Construct absolute path to the agent script
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    agent_path = os.path.join(base_dir, "agents", "db_safe.py")
    
    if not os.path.isfile(agent_path):
        print(f"[Proxy Error] Agent file not found: {agent_path}", file=sys.stderr)
        return

    print("Launching Agent...", flush=True)
    
    try:
        # Create subprocess using asyncio
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

    # Transparent relay of stdout
    try:
        if process.stdout is not None:
            async for line in process.stdout:
                # Print the line directly without modification or parsing
                sys.stdout.buffer.write(line)
                sys.stdout.flush()
    except Exception as e:
        print(f"[Proxy Error] Error while reading stdout: {e}", file=sys.stderr)
    
    # Wait for the subprocess to finish
    return_code = await process.wait()
    
    if return_code != 0:
        print(f"[Proxy Warning] Agent exited with return code: {return_code}", file=sys.stderr)
    else:
        print("Agent Finished.")

def main() -> None:
    try:
        asyncio.run(run_proxy())
    except KeyboardInterrupt:
        print("\n[Proxy] Shutting down due to KeyboardInterrupt.", file=sys.stderr)

if __name__ == "__main__":
    main()
