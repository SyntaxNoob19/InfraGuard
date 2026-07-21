import os
import sys
import subprocess

def main():
    agents_dir = os.path.join(os.path.dirname(__file__), "agents")
    agents = [f for f in os.listdir(agents_dir) if f.endswith(".py") and f != "common.py" and not f.startswith("__")]
    agents.sort()
    
    print("=== InfraGuard Agent Simulator ===")
    print("Available Agents:")
    for i, agent in enumerate(agents):
        print(f"{i + 1}. {agent}")
    print("0. Exit")
    
    while True:
        try:
            choice = input("\nSelect an agent to run (0 to exit): ").strip()
            if not choice:
                continue
            choice = int(choice)
            if choice == 0:
                break
            if 1 <= choice <= len(agents):
                agent_filename = agents[choice - 1]
                print(f"\n--- Running {agent_filename} via Proxy Engine ---\n")
                # Run the proxy engine which intercepts the agent's stdout and provides the backend API
                proxy_script = os.path.join(os.path.dirname(__file__), "proxy", "proxy_engine.py")
                subprocess.run([sys.executable, proxy_script, agent_filename])
                print("\n--- Finished ---")
            else:
                print("Invalid choice.")
        except ValueError:
            print("Please enter a valid number.")
        except KeyboardInterrupt:
            print("\nExiting...")
            break
        except Exception as e:
            print(f"Error running agent: {e}")

if __name__ == "__main__":
    main()
