"""Structured Privacy-Preserving Agent Trace & Execution Logger for Schemora."""

import json
import logging
import time
from typing import Dict, Any, List, Optional
import uuid

logger = logging.getLogger("schemora.agent_trace")
logger.setLevel(logging.INFO)
if not logger.handlers:
    handler = logging.StreamHandler()
    formatter = logging.Formatter("[AGENT_TRACE] %(message)s")
    handler.setFormatter(formatter)
    logger.addHandler(handler)

# Sensitive keys to redact from trace logs
REDACT_KEYS = {
    "aadhaar_number", "pan_number", "raw_content", "otp", 
    "password", "firebase_uid", "api_key", "secret"
}


def sanitize_log_dict(data: Any) -> Any:
    """Recursively scrub sensitive keys from dictionaries before logging."""
    if isinstance(data, dict):
        cleaned = {}
        for k, v in data.items():
            if k in REDACT_KEYS:
                cleaned[k] = "[REDACTED]"
            else:
                cleaned[k] = sanitize_log_dict(v)
        return cleaned
    elif isinstance(data, list):
        return [sanitize_log_dict(item) for item in data]
    return data


class AgentExecutionTrace:
    """Trace container tracking orchestrator and specialized agent execution steps."""

    def __init__(self, request_id: Optional[str] = None, user_id: Optional[str] = None) -> None:
        self.request_id = request_id or str(uuid.uuid4())
        self.user_id = user_id or "anonymous"
        self.start_time = time.perf_counter()
        self.agent_calls: List[Dict[str, Any]] = []
        self.tool_calls: List[Dict[str, Any]] = []

    def record_agent_call(self, agent_name: str, status: str, duration_ms: float, summary: str) -> None:
        self.agent_calls.append({
            "agent": agent_name,
            "status": status,
            "duration_ms": round(duration_ms, 2),
            "summary": summary,
        })

    def record_tool_call(self, tool_name: str, status: str, duration_ms: float, arguments: Dict[str, Any]) -> None:
        self.tool_calls.append({
            "tool": tool_name,
            "status": status,
            "duration_ms": round(duration_ms, 2),
            "arguments": sanitize_log_dict(arguments),
        })

    def log_final_summary(self, final_status: str = "SUCCESS") -> Dict[str, Any]:
        total_duration = round((time.perf_counter() - self.start_time) * 1000, 2)
        summary_log = {
            "request_id": self.request_id,
            "user_id": self.user_id,
            "total_execution_time_ms": total_duration,
            "agents_executed": [a["agent"] for a in self.agent_calls],
            "mcp_tools_called": [t["tool"] for t in self.tool_calls],
            "status": final_status,
            "agent_details": self.agent_calls,
            "tool_details": self.tool_calls,
        }
        logger.info(json.dumps(summary_log))
        return summary_log
