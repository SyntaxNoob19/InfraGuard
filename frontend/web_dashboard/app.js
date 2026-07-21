// InfraGuard Enterprise SOC Dashboard Logic

const HEADERS = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${API_KEY}`,
    'ngrok-skip-browser-warning': 'true'
};

// State
let selectedIncidentId = null;
let currentPayload = null;
let isConnected = false;
let lastLogCount = 0;

// DOM Elements
const appBody = document.getElementById('app-body');
const mainHeader = document.getElementById('main-header');
const systemStatusBadge = document.getElementById('system-status-badge');
const statusIndicator = document.getElementById('status-indicator');
const statusText = document.getElementById('status-text');
const liveClock = document.getElementById('live-clock');
const footerSync = document.getElementById('footer-sync');
const notificationCount = document.getElementById('notification-count');
const notificationList = document.getElementById('notification-list');

// Stats
const statAgents = document.getElementById('stat-agents');
const statThreats = document.getElementById('stat-threats');
const statBlocked = document.getElementById('stat-blocked');
const statPayloads = document.getElementById('stat-payloads');

// Sections
const runtimeStream = document.getElementById('runtime-stream');
const incidentTimeline = document.getElementById('incident-timeline');
const threatPanel = document.getElementById('threat-panel');
const heroPipeline = document.getElementById('hero-pipeline');

// Threat Detail
const detailExecState = document.getElementById('detail-exec-state');
const detailAgent = document.getElementById('detail-agent');
const detailMethod = document.getElementById('detail-method');
const detailRule = document.getElementById('detail-rule');
const detailCommand = document.getElementById('detail-command');
const detailSeverity = document.getElementById('detail-severity');
const detailPayload = document.getElementById('detail-payload');
const detailImpact = document.getElementById('detail-impact');

// Buttons
document.getElementById('btn-quarantine').addEventListener('click', (e) => resolveAction(e, selectedIncidentId, 'QUARANTINE'));
document.getElementById('btn-block').addEventListener('click', (e) => resolveAction(e, selectedIncidentId, 'BLOCK'));
document.getElementById('btn-allow').addEventListener('click', (e) => resolveAction(e, selectedIncidentId, 'ALLOW'));

// Utility: parseEnum
function parseEnum(raw) {
    if (!raw) return '';
    if (typeof raw === 'string') return raw;
    if (typeof raw === 'object') return Object.values(raw)[0];
    return String(raw);
}

// Clock
setInterval(() => {
    const now = new Date();
    liveClock.innerText = now.toISOString().split('T')[1].split('.')[0] + ' UTC';
}, 1000);

let ws = null;
let reconnectTimer = null;

function initWebSocket() {
    ws = new WebSocket(WS_URL);
    
    ws.onopen = () => {
        setConnectionState(true);
        if (reconnectTimer) {
            clearInterval(reconnectTimer);
            reconnectTimer = null;
        }
    };
    
    ws.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            if (data.event === 'state_update') {
                updateDashboard(data);
            }
        } catch (e) {
            console.error('Error parsing WS message:', e);
        }
    };
    
    ws.onclose = () => {
        setConnectionState(false);
        if (!reconnectTimer) {
            reconnectTimer = setInterval(initWebSocket, 2000);
        }
    };
    
    ws.onerror = (e) => {
        ws.close();
    };
}

function setConnectionState(online) {
    isConnected = online;
    const now = new Date();
    const timeStr = `${now.getHours().toString().padStart(2,'0')}:${now.getMinutes().toString().padStart(2,'0')}:${now.getSeconds().toString().padStart(2,'0')}`;
    
    if (online) {
        footerSync.innerText = `Last Sync: ${timeStr}`;
        if (statusText.innerText === 'SYNCING...') {
            statusText.innerText = 'SECURE';
        }
    } else {
        footerSync.innerText = `Last Sync: Disconnected`;
        statusText.innerText = 'SYNCING...';
        statusIndicator.className = 'w-3.5 h-3.5 rounded-full bg-ig-warning pulse';
        systemStatusBadge.className = 'flex items-center gap-3 px-6 py-2.5 rounded bg-ig-secondary border border-ig-warning transition-colors duration-300';
        statusText.className = 'text-sm font-bold uppercase tracking-widest text-ig-warning';
    }
}

function updateDashboard(data) {
    const status = parseEnum(data.system_status) || 'UNKNOWN';
    const threats = data.active_threats || [];
    const resolved = data.resolved_threats || [];
    const logs = data.recent_logs || [];
    
    // Top Status & Red Alert Mode
    const telemetryCards = document.querySelectorAll('.telemetry-card');
    
    if (status === 'SECURE') {
        appBody.classList.remove('red-alert-mode');
        mainHeader.classList.remove('red-alert-header');
        heroPipeline.classList.remove('red-alert-card');
        telemetryCards.forEach(c => c.classList.remove('red-alert-card'));
        
        statusText.innerText = 'SECURE';
        statusIndicator.className = 'w-3.5 h-3.5 rounded-full bg-ig-primary pulse';
        systemStatusBadge.className = 'flex items-center gap-3 px-6 py-2.5 rounded bg-ig-secondary border border-ig-border transition-colors duration-300';
        statusText.className = 'text-sm font-bold uppercase tracking-widest text-ig-primary';
    } else {
        appBody.classList.add('red-alert-mode');
        mainHeader.classList.add('red-alert-header');
        heroPipeline.classList.add('red-alert-card');
        telemetryCards.forEach(c => c.classList.add('red-alert-card'));
        
        statusText.innerText = 'THREAT DETECTED';
        statusIndicator.className = 'w-3.5 h-3.5 rounded-full bg-ig-danger pulse-danger';
        systemStatusBadge.className = 'flex items-center gap-3 px-6 py-2.5 rounded bg-[#2A0810] border border-ig-danger transition-colors duration-300';
        statusText.className = 'text-sm font-bold uppercase tracking-widest text-ig-danger';
    }

    // Cards
    statAgents.innerText = data.active_agents || 0;
    statThreats.innerText = threats.length + resolved.length;
    
    let blocks = 0;
    resolved.forEach(r => {
        if (r.resolved_action === 'BLOCK' || r.resolved_action === 'BLOCK_COMMAND' || r.resolved_action === 'QUARANTINE') {
            blocks++;
        }
    });
    statBlocked.innerText = blocks;
    statPayloads.innerText = data.total_payloads || 0;

    // Terminal & Notifications
    updateTerminalAndNotifications(logs);

    // Pipeline
    updatePipeline(status, threats.length > 0);

    // Timeline
    updateTimeline(threats, resolved);
}

function updatePipeline(status, hasThreats) {
    const nodes = ['agent', 'json', 'proxy', 'parser', 'engine', 'exec', 'state', 'fastapi', 'clients'];
    
    nodes.forEach(n => {
        const el = document.getElementById(`node-${n}`);
        if (el) el.className = 'pipeline-node'; // Reset
    });

    const packet = document.getElementById('packet-dot');

    if (hasThreats || status === 'THREAT_DETECTED') {
        // Red Alert Pipeline
        document.getElementById('node-agent').classList.add('active');
        document.getElementById('node-json').classList.add('active');
        document.getElementById('node-proxy').classList.add('active');
        document.getElementById('node-parser').classList.add('threat');
        document.getElementById('node-engine').classList.add('threat');
        document.getElementById('node-exec').classList.add('threat');
        
        packet.classList.remove('packet-moving'); 
        packet.classList.add('packet-halted'); // Stops exactly at Execution Controller
    } else {
        // Green Pipeline
        nodes.forEach(n => {
            document.getElementById(`node-${n}`).classList.add('active');
        });
        
        // Make the parser the "active processing node" just for visual effect if secure, or proxy
        document.getElementById('node-proxy').classList.add('node-processing');
        
        packet.classList.remove('packet-halted');
        packet.classList.add('packet-moving');
    }
}

function updateTerminalAndNotifications(logs) {
    if (logs.length === 0) {
        runtimeStream.innerHTML = '<div class="text-ig-textMuted opacity-50">Monitoring Runtime... Waiting for AI agents.</div>';
        notificationList.innerHTML = '<div class="p-3 text-center text-ig-textMuted">No new notifications</div>';
        return;
    }

    const unreadCount = logs.length > lastLogCount ? (logs.length - lastLogCount) : 0;
    if (unreadCount > 0) {
        notificationCount.innerText = unreadCount;
        notificationCount.classList.remove('hidden');
    }

    // Terminal
    runtimeStream.innerHTML = '';
    logs.forEach(l => {
        const type = parseEnum(l.type) || 'INFO';
        let colorCls = 'log-info';
        
        if (type === 'SUCCESS') colorCls = 'log-success';
        else if (type === 'WARNING') colorCls = 'log-warning';
        else if (type === 'ERROR' || type === 'THREAT') colorCls = 'log-error';
        else if (type === 'ADMIN') colorCls = 'log-admin';

        const line = document.createElement('div');
        line.className = 'log-line flex gap-3';
        line.innerHTML = `
            <span class="text-ig-textMuted select-none">&gt;</span>
            <span class="${colorCls}">[${type}]</span>
            <span class="text-ig-textBase">${l.message}</span>
        `;
        runtimeStream.appendChild(line);
    });
    
    runtimeStream.scrollTop = runtimeStream.scrollHeight;

    // Notifications Dropdown (Reversed for newest first)
    const reversedLogs = [...logs].reverse().slice(0, 10);
    notificationList.innerHTML = '';
    reversedLogs.forEach(l => {
        const type = parseEnum(l.type) || 'INFO';
        let colorCls = 'text-ig-blue';
        if (type === 'SUCCESS') colorCls = 'text-ig-primary';
        else if (type === 'WARNING') colorCls = 'text-ig-warning';
        else if (type === 'ERROR' || type === 'THREAT') colorCls = 'text-ig-danger';
        else if (type === 'ADMIN') colorCls = 'text-ig-purple';

        const notif = document.createElement('div');
        notif.className = 'p-3 border-b border-ig-border flex flex-col gap-1 hover:bg-ig-panel cursor-pointer';
        notif.innerHTML = `
            <span class="${colorCls} font-bold">${type}</span>
            <span class="text-ig-textBase">${l.message}</span>
            <span class="text-[10px] text-ig-textMuted font-mono">${l.timestamp.split('T')[1].replace('Z','')}</span>
        `;
        notificationList.appendChild(notif);
    });
}

function updateTimeline(active, resolved) {
    const all = [...active, ...resolved].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    if (all.length === 0) {
        incidentTimeline.innerHTML = '<div class="p-6 text-sm font-bold text-ig-textMuted text-center mt-12 opacity-50">Monitoring...<br><br>Waiting for Runtime Events...</div>';
        if (!selectedIncidentId) {
            threatPanel.classList.add('opacity-50', 'pointer-events-none');
            threatPanel.classList.remove('shadow-[0_0_20px_rgba(255,42,77,0.2)]');
        }
        return;
    }

    incidentTimeline.innerHTML = '';
    
    all.forEach(t => {
        const incidentId = t.incident_id;
        const severity = parseEnum(t.severity) || 'HIGH';
        const isActive = active.some(x => x.incident_id === incidentId);
        const isSelected = incidentId === selectedIncidentId;
        
        const row = document.createElement('div');
        row.className = `p-4 border-b border-ig-border cursor-pointer transition-colors hover:bg-ig-panel flex flex-col gap-2 ${isSelected ? 'bg-ig-panel border-l-4 border-l-ig-blue' : 'border-l-4 border-l-transparent'}`;
        row.onclick = () => selectThreat(t, isActive);
        
        let sevColor = severity === 'HIGH' ? 'text-ig-danger' : 'text-ig-warning';
        
        let badge = '';
        if (isActive) {
            badge = `<span class="bg-ig-danger text-white text-[10px] px-2 py-0.5 rounded font-bold uppercase tracking-wider">PAUSED</span>`;
        } else {
            const resAction = t.resolved_action || 'RESOLVED';
            badge = `<span class="bg-ig-secondary text-ig-textMuted border border-ig-border text-[10px] px-2 py-0.5 rounded font-bold uppercase tracking-wider">${resAction}</span>`;
        }

        row.innerHTML = `
            <div class="flex justify-between items-start">
                <span class="font-bold text-sm ${sevColor}">${t.matched_rule || 'Threat Detected'}</span>
                ${badge}
            </div>
            <div class="flex justify-between items-center text-xs">
                <span class="text-ig-textMuted font-mono">Agent: ${t.agent_id}</span>
                <span class="text-ig-textMuted font-mono">${t.timestamp.split('T')[1].split('Z')[0]}</span>
            </div>
        `;
        incidentTimeline.appendChild(row);
        
        // Refresh the Threat Panel if this incident is currently selected
        if (isSelected) {
            selectThreat(t, isActive);
        }
    });
    
    // Auto-select next active threat, or clear panel if none active
    if (active.length > 0) {
        const currentlySelectedActive = active.some(x => x.incident_id === selectedIncidentId);
        if (!currentlySelectedActive) {
            selectThreat(active[0], true);
        }
    } else {
        selectedIncidentId = null;
        threatPanel.classList.add('opacity-50', 'pointer-events-none');
        threatPanel.classList.remove('shadow-[0_0_20px_rgba(255,42,77,0.2)]');
        detailAgent.innerText = '--';
        detailMethod.innerText = '--';
        detailRule.innerText = '--';
        detailSeverity.innerText = '--';
        detailCommand.innerText = '--';
        detailExecState.innerText = 'WAITING...';
        detailPayload.innerHTML = '';
        detailImpact.innerText = '--';
        
        document.getElementById('btn-quarantine').disabled = true;
        document.getElementById('btn-block').disabled = true;
        document.getElementById('btn-allow').disabled = true;
        document.getElementById('btn-quarantine').classList.add('opacity-50');
        document.getElementById('btn-block').classList.add('opacity-50');
        document.getElementById('btn-allow').classList.add('opacity-50');
    }
}

function selectThreat(incident, isActive) {
    selectedIncidentId = incident.incident_id;
    currentPayload = incident.payload || {};
    
    threatPanel.classList.remove('opacity-50', 'pointer-events-none');
    
    detailAgent.innerText = incident.agent_id || 'Unknown';
    detailMethod.innerText = incident.method || 'Unknown';
    detailRule.innerText = incident.matched_rule || 'Unknown';
    detailSeverity.innerText = parseEnum(incident.severity) || 'HIGH';
    
    // Extract command from payload if present
    let commandStr = '--';
    if (currentPayload.params) {
        if (typeof currentPayload.params === 'object' && currentPayload.params.command) {
            commandStr = currentPayload.params.command;
        } else if (typeof currentPayload.params === 'string') {
            commandStr = currentPayload.params;
        } else if (Array.isArray(currentPayload.params)) {
            commandStr = currentPayload.params.join(' ');
        }
    }
    detailCommand.innerText = commandStr;
    
    // Execution State
    if (isActive) {
        detailExecState.innerText = 'PAUSED - Waiting Admin';
        detailExecState.className = 'text-xs bg-ig-danger text-white px-3 py-1 rounded font-bold uppercase tracking-wider';
        document.getElementById('btn-quarantine').disabled = false;
        document.getElementById('btn-block').disabled = false;
        document.getElementById('btn-allow').disabled = false;
        document.getElementById('btn-quarantine').classList.remove('opacity-50');
        document.getElementById('btn-block').classList.remove('opacity-50');
        document.getElementById('btn-allow').classList.remove('opacity-50');
        threatPanel.classList.add('shadow-[0_0_20px_rgba(255,42,77,0.2)]');
    } else {
        const action = incident.resolved_action || 'RESOLVED';
        detailExecState.innerText = action;
        detailExecState.className = 'text-xs bg-ig-textMuted text-white px-3 py-1 rounded font-bold uppercase tracking-wider';
        document.getElementById('btn-quarantine').disabled = true;
        document.getElementById('btn-block').disabled = true;
        document.getElementById('btn-allow').disabled = true;
        document.getElementById('btn-quarantine').classList.add('opacity-50');
        document.getElementById('btn-block').classList.add('opacity-50');
        document.getElementById('btn-allow').classList.add('opacity-50');
        threatPanel.classList.remove('shadow-[0_0_20px_rgba(255,42,77,0.2)]');
    }

    const jsonStr = JSON.stringify(currentPayload, null, 2);
    detailPayload.innerHTML = syntaxHighlight(jsonStr);

    const rule = (incident.matched_rule || '').toLowerCase();
    if (rule.includes('shell')) {
        detailImpact.innerText = 'Remote Command Execution (RCE)';
    } else if (rule.includes('database')) {
        detailImpact.innerText = 'Unauthorized Database Manipulation';
    } else if (rule.includes('file')) {
        detailImpact.innerText = 'Sensitive File Access';
    } else {
        detailImpact.innerText = 'Enterprise Policy Violation';
    }
}

function syntaxHighlight(json) {
    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
        let cls = 'json-number';
        if (/^"/.test(match)) {
            if (/:$/.test(match)) {
                cls = 'json-key';
            } else {
                cls = 'json-string';
            }
        } else if (/true|false/.test(match)) {
            cls = 'json-boolean';
        } else if (/null/.test(match)) {
            cls = 'json-boolean';
        }
        return '<span class="' + cls + '">' + match + '</span>';
    });
}

async function resolveAction(event, incidentId, action) {
    if (!incidentId) return;
    try {
        const response = await fetch(`${API_BASE_URL}/api/resolve`, {
            method: 'POST',
            headers: HEADERS,
            body: JSON.stringify({ incident_id: incidentId, action: action })
        });
        if (response.ok) {
            showToast(`Action ${action} successful`);
        } else {
            alert('Action failed. Backend may be offline or incident already resolved.');
        }
    } catch (e) {
        console.error('Resolve Error:', e);
        alert('Network error communicating with Proxy Engine.');
    }
}

function showToast(message) {
    const toast = document.createElement('div');
    toast.className = 'fixed bottom-5 right-5 bg-ig-primary text-black px-6 py-3 rounded shadow-lg font-bold z-50 transform transition-all duration-300 translate-y-10 opacity-0';
    toast.innerText = message;
    document.body.appendChild(toast);
    
    // animate in
    requestAnimationFrame(() => {
        toast.classList.remove('translate-y-10', 'opacity-0');
    });
    
    // remove after 3s
    setTimeout(() => {
        toast.classList.add('translate-y-10', 'opacity-0');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Clear notification count on click
document.querySelector('.ph-bell').parentElement.addEventListener('click', () => {
    notificationCount.innerText = '0';
    notificationCount.classList.add('hidden');
    lastLogCount = document.querySelectorAll('.log-line').length; // Reset
});

// Init
initWebSocket();
// Ping to register client ID
setInterval(() => {
    if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send('ping: SOC-Dashboard');
    }
}, 10000);
