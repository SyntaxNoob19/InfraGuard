"""
FastAPI Server instance.
Provides REST endpoints for the Flutter frontend to fetch status and resolve active threats.
"""
from fastapi import FastAPI, Depends, HTTPException, Security, Request, WebSocket, WebSocketDisconnect
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.encoders import jsonable_encoder
import asyncio
from pydantic import BaseModel

from backend.proxy.models import LogType
from backend.proxy.state_manager import StateManager
from backend.proxy.execution_controller import ExecutionController

class ResolveRequest(BaseModel):
    incident_id: str
    action: str

security = HTTPBearer()
API_KEY = "YOUR_API_KEY_HERE"

def verify_token(credentials: HTTPAuthorizationCredentials = Security(security)) -> str:
    if credentials.credentials != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid token")
    return credentials.credentials

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections.copy():
            try:
                await connection.send_json(message)
            except Exception:
                self.disconnect(connection)

manager = ConnectionManager()

def create_app(state_manager: StateManager, execution_controller: ExecutionController) -> FastAPI:
    app = FastAPI(title="InfraGuard API")
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    def notify_state_change():
        state = state_manager.get_state()
        state_dict = jsonable_encoder(state)
        message = {"event": "state_update"}
        message.update(state_dict)
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(manager.broadcast(message))
        except RuntimeError:
            pass

    state_manager.on_state_change = notify_state_change

    @app.websocket("/api/ws")
    async def websocket_endpoint(websocket: WebSocket):
        await manager.connect(websocket)
        state = state_manager.get_state()
        state_dict = jsonable_encoder(state)
        message = {"event": "state_update"}
        message.update(state_dict)
        await websocket.send_json(message)
        try:
            while True:
                data = await websocket.receive_text()
                if data.startswith("ping:"):
                    client_id = data.split(":", 1)[1].strip()
                    state_manager.update_client_ping(client_id)
        except WebSocketDisconnect:
            manager.disconnect(websocket)
            
    @app.get("/")
    def health_check():
        return {"service": "InfraGuard", "status": "running"}
        
    @app.get("/api/status")
    def get_status(request: Request):
        client_ip = request.client.host if request.client else "unknown"
        # We can append a user agent or something to distinguish multiple clients on same IP if needed,
        # but for hackathon a simple host is fine. Or generate a client ID on frontend?
        # Let's use IP + User-Agent for better uniqueness.
        user_agent = request.headers.get("user-agent", "unknown")
        client_id = f"{client_ip}-{user_agent}"
        state_manager.update_client_ping(client_id)
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
