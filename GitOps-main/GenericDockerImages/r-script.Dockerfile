ARG IMAGE_TAG

FROM alpine:${IMAGE_TAG}

# Set environment variables
ENV ACCEPT_EULA=Y \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH="$PATH:/opt/mssql-tools/bin"

# Install essential packages
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    gnupg \
    build-base \
    gcc \
    gfortran \
    musl-dev \
    libxml2-dev \
    unixodbc \
    unixodbc-dev \
    libcurl \
    libsodium-dev \
    zlib-dev \
    tzdata \
    openjdk11 \
    R \
    R-dev \
    && apk add --upgrade busybox curl

# Download and install Microsoft ODBC Driver 17 and tools for amd64
WORKDIR /tmp
RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.5.1-1_amd64.apk && \
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.apk && \
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.5.1-1_amd64.sig && \
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.sig && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --import - && \
    gpg --verify msodbcsql17_17.10.5.1-1_amd64.sig msodbcsql17_17.10.5.1-1_amd64.apk && \
    gpg --verify mssql-tools_17.10.1.1-1_amd64.sig mssql-tools_17.10.1.1-1_amd64.apk && \
    apk add --allow-untrusted msodbcsql17_17.10.5.1-1_amd64.apk && \
    apk add --allow-untrusted mssql-tools_17.10.1.1-1_amd64.apk && \
    rm -f /tmp/*.apk /tmp/*.sig

# Copy the R script for package installation
COPY package.R /usr/local/src/myscripts/package.R

# Install R packages from the package.R script
WORKDIR /usr/local/src/myscripts
RUN Rscript package.R

# Test plumber installation
RUN R -e "library(plumber); print('Plumber is successfully installed!')"