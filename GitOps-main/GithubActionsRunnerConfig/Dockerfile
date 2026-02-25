ARG RUNNER_VERSION

FROM ghcr.io/actions/actions-runner:${RUNNER_VERSION}

RUN sudo apt update && sudo apt install -y \
    curl \
    wget \
    unzip \
    zip \
    jq \
    lsb-release \
    gpg

# Switch to root to perform certificate installation
USER root

RUN curl "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" -o /usr/local/share/ca-certificates/global-bundle.crt \
    && update-ca-certificates \
    && curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg \
    && chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg

# Optionally, switch back to your non-root runner user if required
USER runner

# Update package lists and install msodbcsql18, mssql-tools18, and unixodbc-dev
RUN curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list \
    && sudo apt update \
    && sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev \
    && sudo rm -rf /var/lib/apt/lists/*

RUN arch=$(uname -m) && \
    echo "Detected architecture: $arch" && \
    if [ "$arch" = "x86_64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    elif [ "$arch" = "aarch64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    else \
        echo "Unsupported architecture: $arch" && exit 1; \
    fi && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm -rf awscliv2.zip aws

RUN echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list \
    && sudo apt update \
    && sudo apt upgrade -y \
    && sudo apt install -y dotnet-sdk-8.0 \
    && sudo apt install -y redis-tools \
    && dotnet tool install --global dotnet-sonarscanner --version 10.2.0 \
    && dotnet tool install --global microsoft.sqlpackage --version 170.0.94 \
    && dotnet tool list --global

# Install kubectl
RUN sudo curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && sudo chmod +x /usr/local/bin/kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

ENV PATH="$PATH:/opt/mssql-tools18/bin"
