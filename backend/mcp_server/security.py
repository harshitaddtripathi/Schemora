"""Security, Authorization & Scoping module for Schemora MCP Server."""

from typing import Dict, Any, Optional
from fastapi import HTTPException, status
from app.models.user import User
from mcp_server.schemas.tool_schemas import UserContext

# Sensitive keys that must NEVER be returned to LLM or exposed via MCP tools
BLOCKED_SENSITIVE_KEYS = {
    "password", "hashed_password", "firebase_uid", "secret", 
    "api_key", "aadhaar_number", "pan_number", "raw_content", "otp"
}


def create_user_context(user: User) -> UserContext:
    """Extract authenticated UserContext from FastAPI User model."""
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required for MCP tool execution."
        )
    return UserContext(
        user_id=user.id,
        firebase_uid=user.firebase_uid,
        role=user.role
    )


def verify_user_authorization(context: Optional[UserContext], target_user_id: Optional[str] = None) -> UserContext:
    """Enforce authorization and user data isolation."""
    if not context:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthenticated MCP tool execution. UserContext required."
        )
    if target_user_id and context.user_id != target_user_id and context.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Cannot access another user's profile, documents, or data."
        )
    return context


def sanitize_output_data(data: Any) -> Any:
    """Recursively strip sensitive credentials and raw unmasked PII from dictionary outputs."""
    if isinstance(data, dict):
        cleaned = {}
        for key, val in data.items():
            if key in BLOCKED_SENSITIVE_KEYS:
                continue
            cleaned[key] = sanitize_output_data(val)
        return cleaned
    elif isinstance(data, list):
        return [sanitize_output_data(item) for item in data]
    return data
