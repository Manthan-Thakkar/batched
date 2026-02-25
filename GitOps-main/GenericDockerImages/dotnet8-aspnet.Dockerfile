ARG IMAGE_TAG

FROM mcr.microsoft.com/dotnet/aspnet:${IMAGE_TAG}

# Detect architecture
ARG TARGETARCH

RUN apk update && \
    apk add --no-cache --no-scripts \
        curl \
        openssl \
        icu-libs \
        tzdata \
        sudo && \
    curl "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" -o "ca-cert.pem" && \
    cat ca-cert.pem >> /etc/ssl/certs/ca-certificates.crt

ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

# Add a non-root user
RUN addgroup -S appgroup && \
    adduser -S -G appgroup appuser
