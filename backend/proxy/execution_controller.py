from typing import Dict, Optional
import asyncio
from dataclasses import dataclass
from datetime import datetime, timezone

@dataclass
class ExecutionContext:
    incident_id: str
    pause_event: asyncio.Event
    created_at: str
    process: asyncio.subprocess.Process
    resolution_action: Optional[str] = None

class ExecutionController:
    """
    Owns the execution lifecycle (pausing, resuming, terminating subprocess threads).
    """
    def __init__(self) -> None:
        self._contexts: Dict[str, ExecutionContext] = {}
        
    def create_execution_context(self, incident_id: str, process: asyncio.subprocess.Process) -> ExecutionContext:
        context = ExecutionContext(
            incident_id=incident_id,
            pause_event=asyncio.Event(),
            created_at=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            process=process
        )
        self._contexts[incident_id] = context
        return context
        
    async def pause(self, incident_id: str) -> None:
        context = self._contexts.get(incident_id)
        if context:
            await context.pause_event.wait()
            
    def resume(self, incident_id: str, action: str = "ALLOW") -> None:
        context = self._contexts.get(incident_id)
        if context:
            context.resolution_action = action
            context.pause_event.set()
            
    def terminate(self, incident_id: str, action: str = "QUARANTINE") -> None:
        """Terminates the subprocess entirely for Quarantine scenarios."""
        context = self._contexts.get(incident_id)
        if context and context.process:
            try:
                context.process.kill()
            except ProcessLookupError:
                pass
            context.resolution_action = action
        # Setting the event resumes the python await so it can exit cleanly
        self.resume(incident_id, action)
            
    def remove(self, incident_id: str) -> None:
        if incident_id in self._contexts:
            del self._contexts[incident_id]
            
    def is_paused(self, incident_id: str) -> bool:
        context = self._contexts.get(incident_id)
        return context is not None and not context.pause_event.is_set()
        
    def get_execution_context(self, incident_id: str) -> Optional[ExecutionContext]:
        return self._contexts.get(incident_id)
