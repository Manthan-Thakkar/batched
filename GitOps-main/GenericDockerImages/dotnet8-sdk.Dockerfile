ARG IMAGE_TAG

FROM mcr.microsoft.com/dotnet/sdk:${IMAGE_TAG}

# Detect architecture
ARG TARGETARCH

# Install AWS CLI with architecture detection
RUN apt update && apt install -y curl unzip && \
    if [ "$TARGETARCH" = "arm64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    else \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    fi && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws