# Superset MCP image based on the official Apache Superset image
# Override SUPERSET_BASE_IMAGE for mirrored/air-gapped registries.

ARG SUPERSET_BASE_IMAGE=apache/superset:latest
FROM ${SUPERSET_BASE_IMAGE}

ENV MCP_HOST=0.0.0.0 \
    MCP_PORT=5008

EXPOSE 5008

# Keep default non-root runtime behavior from the base image.
CMD ["superset", "mcp", "run", "--host", "0.0.0.0", "--port", "5008"]
