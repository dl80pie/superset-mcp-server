# Apache Superset MCP Service - OpenShift Optimized (RHEL UBI9)
# Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements.

FROM registry.access.redhat.com/ubi9/python-311:latest

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN dnf update -y && \
    dnf install -y \
    gcc \
    gcc-c++ \
    make \
    curl \
    git \
    && dnf clean all

# Create app directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy Chrome and ChromeDriver from local files (air-gapped environment)
COPY chrome/ /tmp/chrome/
RUN rpm -i /tmp/chrome/google-chrome-stable_current_x86_64.rpm || true && \
    unzip /tmp/chrome/chromedriver_linux64.zip -d /tmp/ && \
    mv /tmp/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chrome

# Copy the MCP service code
COPY . .

# Create non-root user for OpenShift security
RUN useradd -m -u 1001 superset && \
    chown -R superset:superset /app

# Set Chrome/ChromeDriver permissions for non-root user (if Chrome was installed)
RUN chmod +x /usr/local/bin/chromedriver && \
    (chmod +x /usr/bin/google-chrome || true)

USER 1001

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5008/health || exit 1

# Expose port
EXPOSE 5008

# Default command
CMD ["python", "-m", "superset.mcp_service", "--host", "0.0.0.0", "--port", "5008"]
