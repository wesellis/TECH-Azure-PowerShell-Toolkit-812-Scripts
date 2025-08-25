# Multi-stage Dockerfile for Azure PowerShell Scripts
FROM mcr.microsoft.com/powershell:latest AS base

# Install Azure PowerShell modules
RUN pwsh -c "Install-Module -Name Az -AllowClobber -Force -Scope AllUsers"
RUN pwsh -c "Install-Module -Name Az.Security -Force -Scope AllUsers"
RUN pwsh -c "Install-Module -Name Az.Monitor -Force -Scope AllUsers"
RUN pwsh -c "Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers"
RUN pwsh -c "Install-Module -Name Pester -Force -Scope AllUsers"

# Install additional tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Create app directory
WORKDIR /azure-toolkit

# Copy scripts
COPY automation-scripts/ ./automation-scripts/
COPY modules/ ./modules/
COPY tools/ ./tools/
COPY *.ps1 ./

# Set environment variables
ENV AZURE_TOOLKIT_PATH=/azure-toolkit
ENV PSModulePath=/azure-toolkit/modules:$PSModulePath

# Create volume for persistent data
VOLUME ["/azure-toolkit/data", "/azure-toolkit/logs"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD pwsh -c "Test-Path /azure-toolkit/Launch-AzureToolkit.ps1"

# Default command
ENTRYPOINT ["pwsh", "-NoProfile", "-Command"]
CMD ["./Launch-AzureToolkit.ps1", "-Interactive"]