#!/bin/bash
set -e

# Starte den MCP Server mit SSE Transport über FastAPI/Uvicorn
# LibreChat benötigt HTTP/SSE Transport
exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-3001} --proxy-headers
