"""FastMCP / MCPServer instance for Schemora."""

import asyncio
from typing import Dict, Any, Optional
from mcp.server import MCPServer
from mcp_server.registry import mcp_tool_registry

# Instantiate MCPServer
mcp_server_app = MCPServer("SchemoraMCPServer")


# Register tools on MCPServer instance dynamically from registry
def register_mcp_server_tools(app: MCPServer) -> None:
    for tool_name, tool_info in mcp_tool_registry.list_tools().items():
        desc = tool_info["description"]
        
        # Attach tool to MCPServer
        @app.tool(name=tool_name, description=desc)
        async def _mcp_tool_wrapper(arguments: Dict[str, Any] = {}) -> Dict[str, Any]:
            # Standalone transport tool handler
            return {
                "notice": f"Schemora MCP Tool '{tool_name}' invoked via MCPServer transport.",
                "status": "ready",
            }


register_mcp_server_tools(mcp_server_app)


if __name__ == "__main__":
    print("Starting Schemora FastMCP Server...")
    mcp_server_app.run()
