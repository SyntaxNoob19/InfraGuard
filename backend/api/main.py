"""
FastAPI Server instance.
Provides REST endpoints for the Flutter frontend to fetch status and resolve active threats.
"""
from fastapi import FastAPI, Depends, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from backend.proxy.models import LogType
from backend.proxy.state_manager import StateManager
from backend.proxy.execution_controller import ExecutionController

class ResolveRequest(BaseModel):
    incident_id: str
    action: str

security = HTTPBearer()
API_KEY = "hackathon-secret-key"

def verify_token(credentials: HTTPAuthorizationCredentials = Security(security)) -> str:
    if credentials.credentials != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid token")
    return credentials.credentials

def create_app(state_manager: StateManager, execution_controller: ExecutionController) -> FastAPI:
    app = FastAPI(title="InfraGuard API")
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    @app.get("/")
    def health_check():
        return {"service": "InfraGuard", "status": "running"}
        
    @app.get("/api/status")
    def get_status():
        return state_manager.get_state()
        
    @app.post("/api/resolve")
    def resolve_incident(req: ResolveRequest, token: str = Depends(verify_token)):
        incident_id = req.incident_id
        action = req.action.upper()
        
        if not execution_controller.is_paused(incident_id):
            raise HTTPException(status_code=404, detail="Incident not found or not paused")
            
        if action == "ALLOW":
            execution_controller.resume(incident_id, action)
            state_manager.add_log(LogType.ADMIN, f"Admin Action: ALLOW")
            state_manager.add_log(LogType.SUCCESS, "Execution Resumed")
            state_manager.clear_incident(incident_id, action)
        elif action == "BLOCK" or action == "BLOCK_COMMAND":
            execution_controller.resume(incident_id, action)
            state_manager.add_log(LogType.ADMIN, f"Admin Action: BLOCK_COMMAND")
            state_manager.add_log(LogType.SUCCESS, "Execution Resumed")
            state_manager.clear_incident(incident_id, action)
        elif action == "QUARANTINE":
            execution_controller.terminate(incident_id, action)
            state_manager.add_log(LogType.ADMIN, f"Admin Action: QUARANTINE")
            state_manager.add_log(LogType.WARNING, "Agent Quarantined")
            state_manager.clear_incident(incident_id, action)
        else:
            raise HTTPException(status_code=400, detail="Invalid action")
            
        return {"success": True, "message": f"Action {action} applied to incident {incident_id}"}
        
    return app
